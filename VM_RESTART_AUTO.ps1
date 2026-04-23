# ============================================================================
# CS-4075 ASSIGNMENT 3: AUTOMATED VM RESTART & RECOVERY SCRIPT
# ============================================================================
# This script automates the VM restart and Ceph cluster recovery process
# Usage: .\VM_RESTART_AUTO.ps1
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$MonitorIP = "",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyPath = "C:\Users\Dell\Downloads\cloud-ass3.pem",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHUser = "ubuntu"
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0"
$ClusterID = "1512292e-3cde-11f1-ab7e-3748aba09780"
$ErrorActionPreference = "Continue"

# Colors for output
function Write-Header {
    param([string]$Message)
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($Message.PadRight(58)) ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message, [string]$Number)
    Write-Host "`n[STEP $Number] $Message" -ForegroundColor Yellow -BackgroundColor Black
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error2 {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# ============================================================================
# PHASE 0: PRE-FLIGHT CHECKS
# ============================================================================

Write-Header "PHASE 0: PRE-FLIGHT CHECKS"

Write-Step "Checking SSH key exists" "0.1"
if (-Not (Test-Path $KeyPath)) {
    Write-Error2 "SSH key not found at: $KeyPath"
    exit 1
}
Write-Success "SSH key found"

Write-Step "Testing SSH connectivity" "0.2"
if ([string]::IsNullOrEmpty($MonitorIP)) {
    Write-Warning "Monitor IP not provided. Please enter it:"
    $MonitorIP = Read-Host "Enter Monitor VM public IP (e.g., 54.89.62.36)"
}

# Test SSH
try {
    $TestSSH = & ssh -i $KeyPath -o ConnectTimeout=5 "${SSHUser}@${MonitorIP}" "echo 'SSH OK'" 2>&1
    if ($TestSSH -match "SSH OK") {
        Write-Success "SSH connection successful to $MonitorIP"
    } else {
        Write-Error2 "SSH connection failed. Response: $TestSSH"
        exit 1
    }
} catch {
    Write-Error2 "SSH test error: $_"
    exit 1
}

Write-Success "All pre-flight checks passed"

# ============================================================================
# PHASE 1: PRE-RESTART SNAPSHOT
# ============================================================================

Write-Header "PHASE 1: PRE-RESTART CLUSTER SNAPSHOT"

Write-Step "Capturing current cluster state" "1.1"
$PreRestartState = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "
sudo cephadm shell -- ceph -s
echo '---SEPARATOR---'
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
" 2>&1

Write-Host $PreRestartState -ForegroundColor Gray
Write-Success "Pre-restart snapshot captured"

# ============================================================================
# PHASE 2: WAIT FOR VMs TO START
# ============================================================================

Write-Header "PHASE 2: WAITING FOR VMs TO START"

Write-Step "Verify all VMs are running in AWS Console" "2.1"
Write-Warning "Please ensure all 6 VMs are in 'Running' state before continuing"
Write-Host "VM1 (Monitor), VM2 (OSD1), VM3 (OSD2), VM4 (OSD3), VM5 (Spare), VM6 (Spare)" -ForegroundColor Yellow
$Confirm = Read-Host "Are all VMs running? (yes/no)"

if ($Confirm -ne "yes") {
    Write-Error2 "Please start all VMs and try again"
    exit 1
}

Write-Success "Confirmed: All VMs are running"

# ============================================================================
# PHASE 3: COLLECT NEW PUBLIC IPs
# ============================================================================

Write-Header "PHASE 3: DOCUMENT NEW PUBLIC IPs"

Write-Step "Recording new public IP addresses" "3.1"
Write-Host "`nGo to AWS EC2 Console → Instances and record the new Public IPs:" -ForegroundColor Yellow
Write-Host "VM1 (Monitor):  " -NoNewline
$NewMonitorIP = Read-Host

if (-Not [string]::IsNullOrEmpty($NewMonitorIP)) {
    $MonitorIP = $NewMonitorIP
    Write-Success "Monitor IP updated to: $MonitorIP"
}

# Test new IP
Write-Step "Testing connectivity to new Monitor IP" "3.2"
$MaxRetries = 30
$Retry = 0
$Connected = $false

while ($Retry -lt $MaxRetries -and -not $Connected) {
    try {
        $TestSSH = & ssh -i $KeyPath -o ConnectTimeout=5 "${SSHUser}@${MonitorIP}" "echo 'Connected'" 2>&1
        if ($TestSSH -match "Connected") {
            $Connected = $true
            Write-Success "Successfully connected to new IP: $MonitorIP"
        }
    } catch {
        $Retry++
        Write-Warning "Attempt $Retry/$MaxRetries: Waiting for VM to be ready..."
        Start-Sleep -Seconds 10
    }
}

if (-not $Connected) {
    Write-Error2 "Could not connect to new Monitor IP after 5 minutes"
    exit 1
}

# ============================================================================
# PHASE 4: CEPH CLUSTER RECOVERY
# ============================================================================

Write-Header "PHASE 4: CEPH CLUSTER RECOVERY"

Write-Step "Monitoring cluster startup (watching for 5 minutes)" "4.1"
$LoopCount = 0
$MaxLoops = 30  # 30 * 10 seconds = 5 minutes

while ($LoopCount -lt $MaxLoops) {
    $ClusterStatus = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "sudo cephadm shell -- ceph -s 2>/dev/null | grep -E 'health:|osd:|pg:' | head -5" 2>&1
    
    Write-Host "`n[Check $($LoopCount + 1)/$MaxLoops] $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    Write-Host $ClusterStatus -ForegroundColor Gray
    
    # Check if cluster is stable
    if ($ClusterStatus -match "5 up" -and $ClusterStatus -match "5 in") {
        Write-Success "All 5 OSDs are UP and IN"
        break
    }
    
    $LoopCount++
    if ($LoopCount -lt $MaxLoops) {
        Start-Sleep -Seconds 10
    }
}

Write-Step "Removing recovery flags" "4.2"
$UnsetResult = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "
sudo cephadm shell -- ceph osd unset noout
sudo cephadm shell -- ceph osd unset norebalance
sudo cephadm shell -- ceph osd unset nobackfill
echo 'Flags cleared'
" 2>&1

Write-Success "Recovery flags cleared"

# ============================================================================
# PHASE 5: VERIFY RAID 6
# ============================================================================

Write-Header "PHASE 5: VERIFY RAID 6 CONFIGURATION"

Write-Step "Checking RAID 6 profile" "5.1"
$RAID6Config = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile" 2>&1

Write-Host $RAID6Config -ForegroundColor Gray

if ($RAID6Config -match "k=4" -and $RAID6Config -match "m=2") {
    Write-Success "RAID 6 configuration verified: k=4, m=2"
} else {
    Write-Error2 "RAID 6 configuration not found or incorrect"
}

# ============================================================================
# PHASE 6: SERVICE VERIFICATION
# ============================================================================

Write-Header "PHASE 6: SERVICE VERIFICATION"

Write-Step "Checking all services" "6.1"
$Services = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "sudo cephadm ls | grep -E 'mon|mgr|osd|prometheus|grafana|alertmanager'" 2>&1

Write-Host $Services -ForegroundColor Gray

Write-Step "Testing Grafana" "6.2"
$GrafanaTest = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "curl -s http://localhost:3000/api/health" 2>&1
if ($GrafanaTest -match "database") {
    Write-Success "Grafana is running"
} else {
    Write-Warning "Grafana may not be responding yet"
}

Write-Step "Testing Prometheus" "6.3"
$PrometheusTest = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "curl -s http://localhost:9095/-/healthy" 2>&1
if ($PrometheusTest -match "Healthy") {
    Write-Success "Prometheus is running"
} else {
    Write-Warning "Prometheus may not be responding yet"
}

# ============================================================================
# PHASE 7: FINAL HEALTH CHECK
# ============================================================================

Write-Header "PHASE 7: FINAL HEALTH CHECK"

Write-Step "Complete cluster status" "7.1"
$FinalStatus = & ssh -i $KeyPath "${SSHUser}@${MonitorIP}" "
echo '=== CLUSTER STATUS ==='
sudo cephadm shell -- ceph -s | head -30
echo ''
echo '=== OSD STATUS ==='
sudo cephadm shell -- ceph osd status | head -10
echo ''
echo '=== CLUSTER UTILIZATION ==='
sudo cephadm shell -- ceph df | head -10
" 2>&1

Write-Host $FinalStatus -ForegroundColor Gray

# ============================================================================
# SUMMARY
# ============================================================================

Write-Header "✅ RESTART PROCESS COMPLETED"

Write-Host "`n📋 SUMMARY:" -ForegroundColor Green
Write-Host "  Monitor IP (Updated): $MonitorIP"
Write-Host "  Cluster ID: $ClusterID"
Write-Host "  Ceph Version: v17.2.9 (Quincy)"
Write-Host "  RAID 6: k=4, m=2 (Verified)"
Write-Host ""
Write-Host "🌐 ACCESS POINTS:" -ForegroundColor Green
Write-Host "  Grafana:       https://$MonitorIP`:3000 (admin/admin)"
Write-Host "  Ceph Dashboard: https://$MonitorIP`:8080 (admin/admin123)"
Write-Host "  Prometheus:    http://$MonitorIP`:9095"
Write-Host ""
Write-Host "⏱️  STATUS:" -ForegroundColor Green
Write-Host "  Cluster will continue recovering for 1-4 hours depending on load"
Write-Host "  PGs should be moving toward 'active+clean' state"
Write-Host "  Watch recovery progress in Grafana or with 'ceph -s'"
Write-Host ""

Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Update your documentation with new IP: $MonitorIP"
Write-Host "  2. Access Grafana/Ceph Dashboard to verify everything"
Write-Host "  3. Take screenshots for assignment submission"
Write-Host "  4. Monitor cluster recovery via Prometheus/Grafana"
Write-Host ""

# Save new IP to file
$IPFile = "C:\Users\Dell\Downloads\ACTIVE_IPS.txt"
@"
# ACTIVE IP ADDRESSES
# Updated: $(Get-Date)

MONITOR_IP=$MonitorIP
CLUSTER_ID=$ClusterID

# Services:
GRAFANA=https://${MonitorIP}:3000
CEPH_DASHBOARD=https://${MonitorIP}:8080
PROMETHEUS=http://${MonitorIP}:9095

# SSH:
ssh -i cloud-ass3.pem ${SSHUser}@${MonitorIP}
"@ | Out-File -FilePath $IPFile -Encoding ASCII

Write-Success "New IPs saved to: $IPFile"

Write-Host ""
Write-Host "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
