# ✅ COMPLETE VM RESTART & RECOVERY GUIDE
## CS-4075 Assignment 3 - Zero to Full Operation

**Last Updated:** April 20, 2026  
**Cluster ID:** 1512292e-3cde-11f1-ab7e-3748aba09780

---

## 📋 TABLE OF CONTENTS
1. [Pre-Restart Checklist](#pre-restart-checklist)
2. [Stop All VMs (Phase 1)](#phase-1-stop-all-vms)
3. [Start All VMs (Phase 2)](#phase-2-start-all-vms)
4. [Verify Network Connectivity (Phase 3)](#phase-3-verify-network-connectivity)
5. [Ceph Cluster Recovery (Phase 4)](#phase-4-ceph-cluster-recovery)
6. [Service Verification (Phase 5)](#phase-5-service-verification)
7. [Update Public IPs (Phase 6)](#phase-6-update-public-ips)
8. [Final Health Check (Phase 7)](#phase-7-final-health-check)
9. [Troubleshooting](#troubleshooting)

---

## PRE-RESTART CHECKLIST

### Step 1: Document Current Public IPs
**Before stopping any VMs, save these current IPs:**

```bash
VM1 (ceph-mon):     54.89.62.36
VM2 (ceph-osd1):    3.88.142.38
VM3 (ceph-osd2):    54.221.32.236
VM4 (ceph-osd3):    54.227.35.69
VM5 (spare):        3.88.29.137
VM6 (spare):        3.90.184.140
```

### Step 2: Take Final Cluster Snapshot
Run this **BEFORE restarting**:

```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@54.89.62.36 "
echo '=== FINAL CLUSTER STATE PRE-RESTART ==='
sudo cephadm shell -- ceph -s
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
sudo cephadm shell -- ceph df
"
```

---

## PHASE 1: STOP ALL VMs

### Step 1.1: Gracefully Shutdown Ceph Services
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@54.89.62.36 "
echo '=== STOPPING CEPH SERVICES ==='
echo 'Time: '$(date '+%H:%M:%S')

# Set to noout to prevent rebalancing during shutdown
sudo cephadm shell -- ceph osd set noout
sudo cephadm shell -- ceph osd set norebalance
sudo cephadm shell -- ceph osd set nobackfill

echo 'OSDs marked no-out, no-rebalance, no-backfill'
sleep 5

# Stop monitoring services
sudo docker stop prometheus grafana-server alertmanager 2>/dev/null || echo 'Docker containers not found (may be in Ceph)'

echo '=== READY FOR VM SHUTDOWN ==='
"
```

### Step 2.2: Stop VMs via AWS CLI or Console
**Option A: Using AWS Console**
1. Go to EC2 Dashboard
2. Select all 6 VMs (vm1 through vm6)
3. Right-click → Instance State → Stop
4. Wait for all to show "Stopped"

**Option B: Using AWS CLI**
```bash
# Get VM Instance IDs first, then run:
aws ec2 stop-instances --instance-ids i-xxxxx i-xxxxx i-xxxxx --region us-east-1
```

### Step 2.3: Wait for Complete Shutdown
- Wait **2 minutes** for all VMs to fully stop
- Verify in AWS Console: All show "Stopped" status
- Do NOT proceed until all are fully stopped

---

## PHASE 2: START ALL VMs

### Step 3.1: Start All VMs Simultaneously
**Via AWS Console:**
1. Select all 6 stopped VMs
2. Right-click → Instance State → Start
3. Click "Start instances"

**Via AWS CLI:**
```bash
aws ec2 start-instances --instance-ids i-xxxxx i-xxxxx i-xxxxx --region us-east-1
```

### Step 3.2: Wait for VMs to Boot
- **Initial boot:** ~30-60 seconds per VM
- Watch AWS Console Status Checks
- ✅ All should show "Running" with green status checks

### Step 3.3: Document NEW Public IPs
Once all VMs show "Running":

Go to EC2 Console → Instances → Record the **NEW** Public IPs:

```
VM1 (Monitor):  [NEW_IP_1]
VM2 (OSD1):     [NEW_IP_2]
VM3 (OSD2):     [NEW_IP_3]
VM4 (OSD3):     [NEW_IP_4]
VM5 (Spare):    [NEW_IP_5]
VM6 (Spare):    [NEW_IP_6]
```

⚠️ **IMPORTANT:** The public IPs WILL CHANGE. Use the new ones for all following steps.

---

## PHASE 3: VERIFY NETWORK CONNECTIVITY

### Step 4.1: Test SSH to Monitor VM
```bash
# Replace NEW_IP_1 with actual new public IP
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "echo 'SSH Connection OK'"
```

Expected: `SSH Connection OK`

### Step 4.2: Verify All VMs Responsive
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo 'Testing all VM connectivity...'
ping -c 1 172.31.45.113 2>/dev/null && echo 'VM1 (Monitor) - OK' || echo 'VM1 - FAILED'
ping -c 1 172.31.19.240 2>/dev/null && echo 'VM2 (OSD1) - OK' || echo 'VM2 - FAILED'
ping -c 1 172.31.22.12 2>/dev/null && echo 'VM4 (OSD3) - OK' || echo 'VM4 - FAILED'
"
```

All should show "OK"

---

## PHASE 4: CEPH CLUSTER RECOVERY

### Step 5.1: Initial Cluster Status Check
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo '=== INITIAL CLUSTER STATUS (Post-Boot) ==='
echo 'Time: '$(date '+%H:%M:%S')
sudo cephadm shell -- ceph -s | head -40
"
```

**Expected states:**
- `health: HEALTH_WARN` or `HEALTH_OK` (not HEALTH_ERR yet)
- Some OSDs may show "down" initially
- PGs may be "inactive"

### Step 5.2: Wait for Cluster to Stabilize
```bash
# Run every 10 seconds, watch for stability
for i in {1..30}; do
  echo "=== Check $i ($(date '+%H:%M:%S')) ==="
  ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "sudo cephadm shell -- ceph -s | grep -E 'health|osd:|pg'" 
  sleep 10
done
```

**Wait for:**
- ✅ All 5 OSDs show "up"
- ✅ All 5 OSDs show "in"  
- ✅ PGs moving toward "active+clean"

### Step 5.3: Unset Recovery Flags
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo '=== REMOVING NO-OUT/NO-REBALANCE FLAGS ==='
sudo cephadm shell -- ceph osd unset noout
sudo cephadm shell -- ceph osd unset norebalance
sudo cephadm shell -- ceph osd unset nobackfill

echo 'Recovery flags cleared. Cluster can now rebalance.'
sleep 5

echo ''
echo '=== CLUSTER STATUS AFTER RECOVERY ==='
sudo cephadm shell -- ceph -s
"
```

### Step 5.4: Verify RAID 6 Still Configured
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo '=== VERIFYING RAID 6 CONFIGURATION ==='
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
"
```

**Must show:**
```
k=4
m=2
plugin=jerasure
```

---

## PHASE 5: SERVICE VERIFICATION

### Step 6.1: Verify Ceph Services Running
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo '=== CEPH SERVICE STATUS ==='
sudo cephadm ls | grep -E 'mon|mgr|osd|prometheus|grafana'
"
```

**Expected output:**
```
ceph-mon - running
ceph-mgr - running
ceph-osd.0 - running
ceph-osd.1 - running
... (5 total)
prometheus - running
grafana - running
```

### Step 6.2: Check Grafana Status
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
curl -s http://localhost:3000/api/health | jq .
"
```

Expected: `{"database":"ok"}`

### Step 6.3: Check Prometheus Status
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
curl -s http://localhost:9095/-/healthy
"
```

Expected: `Prometheus is Healthy.`

---

## PHASE 6: UPDATE PUBLIC IPs

### Step 7.1: Update Configuration Files

**Create a new reference file with updated IPs:**

```bash
cat > C:\Users\Dell\Downloads\ACTIVE_IPS.txt << 'EOF'
# ACTIVE IP ADDRESSES (Updated: $(date))
# Use these IPs for all future connections

MONITOR_IP=NEW_IP_1
OSD1_IP=NEW_IP_2
OSD2_IP=NEW_IP_3
OSD3_IP=NEW_IP_4

# Services Accessible At:
GRAFANA=https://${MONITOR_IP}:3000
CEPH_DASHBOARD=https://${MONITOR_IP}:8080
PROMETHEUS=http://${MONITOR_IP}:9095

# SSH Access:
ssh -i cloud-ass3.pem ubuntu@${MONITOR_IP}
EOF
```

### Step 7.2: Update Documentation
Replace old IPs in all files:
- Update `PROJECT_COMPLETION_SUMMARY.md`
- Update `ASSIGNMENT_3_COMPLETION_REPORT.md`
- Update any notes with new public IPs

---

## PHASE 7: FINAL HEALTH CHECK

### Step 8.1: Complete Cluster Verification
```bash
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo '╔════════════════════════════════════════════════════════════╗'
echo '║           FINAL CLUSTER HEALTH CHECK (POST-RESTART)         ║'
echo '╚════════════════════════════════════════════════════════════╝'
echo ''

echo '[1] CLUSTER STATUS'
sudo cephadm shell -- ceph -s

echo ''
echo '[2] OSD STATUS'
sudo cephadm shell -- ceph osd status

echo ''
echo '[3] PLACEMENT GROUPS'
sudo cephadm shell -- ceph pg stat

echo ''
echo '[4] RAID 6 CONFIGURATION'
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile

echo ''
echo '[5] CLUSTER UTILIZATION'
sudo cephadm shell -- ceph df

echo ''
echo '[6] RUNNING SERVICES'
sudo cephadm ls | tail -20

echo ''
echo '✅ POST-RESTART VERIFICATION COMPLETE'
"
```

### Step 8.2: Test Monitoring Systems
```powershell
# Test Grafana (use NEW_IP_1)
$MONITOR_IP = "NEW_IP_1"
Invoke-WebRequest -Uri "https://$MONITOR_IP:3000" -SkipCertificateCheck

# Test Ceph Dashboard
Invoke-WebRequest -Uri "https://$MONITOR_IP:8080" -SkipCertificateCheck

# Test Prometheus
Invoke-WebRequest -Uri "http://$MONITOR_IP:9095" -SkipCertificateCheck
```

---

## TROUBLESHOOTING

### Issue: OSDs Not Coming Up

**Problem:** Some OSDs show "down"

```bash
# Check OSD status
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
sudo cephadm shell -- ceph osd tree
sudo cephadm shell -- ceph osd down <osd-id>
sudo cephadm shell -- ceph osd in <osd-id>
"

# Wait 30 seconds and check again
sleep 30
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "sudo cephadm shell -- ceph -s"
```

### Issue: Ceph Cluster Health is HEALTH_ERR

**Problem:** Cluster shows many warnings

```bash
# This is NORMAL immediately after restart
# Check what the actual errors are:
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
sudo cephadm shell -- ceph health detail
"
```

**Common post-restart warnings (harmless):**
- "Failed to place X daemon(s)" - will resolve when recovery completes
- "Degraded data redundancy" - expected during PG recovery
- "too many PGs per OSD" - resolves after ~1-2 hours

### Issue: Services Not Responding

**Problem:** Grafana/Prometheus timeouts

```bash
# Restart the services
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
echo 'Restarting monitoring services...'
sudo cephadm shell --type fstype -- systemctl restart grafana-server
sleep 10
curl -s http://localhost:3000/api/health
"
```

### Issue: Network Connectivity Lost

**Problem:** Can't SSH to VMs

```bash
# Verify security groups allow SSH (port 22)
# Verify VMs are actually running in AWS Console
# Verify new public IP is correct
# Try connecting with explicit key:
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem -v ubuntu@NEW_IP_1
```

### Issue: Data Recovery Too Slow

**Problem:** Recovery shows ETA > 4 hours

```bash
# This is NORMAL after extended downtime
# Let recovery proceed naturally
# Monitor progress:
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP_1 "
watch -n 10 'sudo cephadm shell -- ceph -s | grep -E \"recovery|remaining|io\"'
"
```

---

## QUICK REFERENCE: START-TO-FINISH COMMANDS

### All-in-One Quick Start (After VMs Running)
```powershell
# 1. SET NEW PUBLIC IP
$NEW_IP = "NEW_IP_1"  # Replace with actual new IP

# 2. VERIFY CONNECTIVITY
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$NEW_IP "echo 'Connected'"

# 3. WAIT FOR CLUSTER
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$NEW_IP "
for i in {1..40}; do
  status=$(sudo cephadm shell -- ceph -s | grep 'health:' | awk '{print $2}')
  osds=$(sudo cephadm shell -- ceph -s | grep 'osd:' | grep -oP '\d+(?= up)')
  echo \"[$i] Health: $status | OSDs UP: $osds/5\"
  [ \"$osds\" = \"5\" ] && [ \"$status\" != \"HEALTH_ERR\" ] && break
  sleep 10
done
"

# 4. UNSET RECOVERY FLAGS
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$NEW_IP "
sudo cephadm shell -- ceph osd unset noout
sudo cephadm shell -- ceph osd unset norebalance
"

# 5. VERIFY RAID 6
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$NEW_IP "
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
"

# 6. FINAL STATUS
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$NEW_IP "
sudo cephadm shell -- ceph -s
echo ''
echo 'Grafana:   https://'$NEW_IP':3000'
echo 'Ceph:      https://'$NEW_IP':8080'
echo 'Prometheus: http://'$NEW_IP':9095'
"
```

---

## ✅ SUCCESS CHECKLIST

After completing all phases, verify:

- [ ] All 6 VMs show "Running" in AWS Console
- [ ] SSH to monitor VM works with new IP
- [ ] Ceph cluster shows "up" OSDs (at least 4/5)
- [ ] RAID 6 profile confirmed (k=4, m=2)
- [ ] Grafana accessible at https://NEW_IP:3000
- [ ] Ceph Dashboard accessible at https://NEW_IP:8080
- [ ] Prometheus accessible at http://NEW_IP:9095
- [ ] Cluster health improving (moving toward HEALTH_OK)
- [ ] PGs mostly "active+clean" or recovering
- [ ] No data loss reported
- [ ] Documentation updated with new IPs

---

## ESTIMATED TIMELINE

| Phase | Duration | Notes |
|-------|----------|-------|
| Stop VMs | 2-3 min | Wait for graceful shutdown |
| Start VMs | 1-2 min | Starting in parallel |
| Boot to Ready | 1-2 min | Waiting for services to start |
| Cluster Stabilization | 10-15 min | OSDs coming up, PGs activating |
| Recovery (if needed) | 1-4 hours | Depends on failure scenario |
| **Total (without recovery)** | **~20 minutes** | |

---

**Document Updated:** April 20, 2026  
**Assignment:** CS-4075 Cloud Computing - Distributed Storage with RAID 6
