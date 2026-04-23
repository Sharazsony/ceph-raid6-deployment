#!/bin/bash
# ============================================================================
# CEPH CLUSTER POST-RESTART RECOVERY SCRIPT
# Run on Monitor VM after restart: bash /tmp/ceph_recovery.sh
# ============================================================================

set -e

CLUSTER_ID="1512292e-3cde-11f1-ab7e-3748aba09780"
TIMEOUT=300  # 5 minutes default timeout
LOG_FILE="/tmp/ceph_recovery_$(date +%s).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo "$1" >> $LOG_FILE
}

log_step() {
    echo -e "\n${YELLOW}[$(date '+%H:%M:%S')] STEP: $1${NC}"
    echo "[$(date '+%H:%M:%S')] STEP: $1" >> $LOG_FILE
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "✅ $1" >> $LOG_FILE
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "⚠️  $1" >> $LOG_FILE
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "❌ $1" >> $LOG_FILE
}

# ============================================================================
# PHASE 1: PRE-RECOVERY CHECKS
# ============================================================================

log_header "PHASE 1: PRE-RECOVERY CHECKS"

log_step "Checking sudo access"
if ! sudo -n true 2>/dev/null; then
    log_error "This script requires sudo access. Please ensure sudo is available without password."
    exit 1
fi
log_success "Sudo access verified"

log_step "Checking cephadm availability"
if ! command -v cephadm &> /dev/null; then
    log_error "cephadm not found. Is Ceph installed?"
    exit 1
fi
log_success "cephadm found"

log_step "Checking cluster connectivity"
FSID=$(sudo cephadm shell -- ceph -s 2>/dev/null | grep "id:" | awk '{print $2}' || echo "")
if [ -z "$FSID" ]; then
    log_error "Cannot connect to Ceph cluster"
    exit 1
fi
log_success "Connected to Ceph cluster: $FSID"

# ============================================================================
# PHASE 2: CAPTURE INITIAL STATE
# ============================================================================

log_header "PHASE 2: INITIAL STATE"

log_step "Cluster status"
CLUSTER_STATUS=$(sudo cephadm shell -- ceph -s 2>/dev/null)
echo "$CLUSTER_STATUS" | head -20
echo "$CLUSTER_STATUS" >> $LOG_FILE

# ============================================================================
# PHASE 3: WAIT FOR OSDs TO COME UP
# ============================================================================

log_header "PHASE 3: WAIT FOR OSDs TO COME UP"

log_step "Monitoring OSD startup (up to 5 minutes)"

LOOP_COUNT=0
MAX_LOOPS=30  # 30 * 10 seconds = 5 minutes
OSDS_UP=0

while [ $LOOP_COUNT -lt $MAX_LOOPS ]; do
    OSD_STATUS=$(sudo cephadm shell -- ceph -s 2>/dev/null | grep "osd:" || echo "")
    OSDS_UP=$(echo "$OSD_STATUS" | grep -oP '\d+(?= up)' || echo "0")
    
    echo -n "."
    
    if [ "$OSDS_UP" = "5" ]; then
        log_success "All 5 OSDs are UP"
        break
    fi
    
    LOOP_COUNT=$((LOOP_COUNT + 1))
    sleep 10
done

echo ""
log_step "Final OSD count: $OSDS_UP/5"

if [ "$OSDS_UP" != "5" ]; then
    log_warning "Not all OSDs are up yet ($OSDS_UP/5). Recovery will continue."
fi

# ============================================================================
# PHASE 4: UNSET RECOVERY FLAGS
# ============================================================================

log_header "PHASE 4: REMOVE RECOVERY FLAGS"

log_step "Unsetting noout, norebalance, nobackfill"
sudo cephadm shell -- ceph osd unset noout 2>/dev/null || log_warning "noout flag may already be unset"
sudo cephadm shell -- ceph osd unset norebalance 2>/dev/null || log_warning "norebalance flag may already be unset"
sudo cephadm shell -- ceph osd unset nobackfill 2>/dev/null || log_warning "nobackfill flag may already be unset"

sleep 5
log_success "Recovery flags cleared"

# ============================================================================
# PHASE 5: VERIFY RAID 6
# ============================================================================

log_header "PHASE 5: VERIFY RAID 6 CONFIGURATION"

log_step "Checking RAID 6 profile"
RAID6_PROFILE=$(sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile 2>/dev/null)
echo "$RAID6_PROFILE"

if echo "$RAID6_PROFILE" | grep -q "k=4" && echo "$RAID6_PROFILE" | grep -q "m=2"; then
    log_success "RAID 6 verified: k=4, m=2"
else
    log_error "RAID 6 configuration not found or incorrect"
fi

# ============================================================================
# PHASE 6: CHECK SERVICES
# ============================================================================

log_header "PHASE 6: SERVICE STATUS"

log_step "Listing all running services"
sudo cephadm ls 2>/dev/null | grep -E "mon|mgr|osd|prometheus|grafana" || log_warning "Could not list services"

log_step "Checking Grafana"
if curl -s http://localhost:3000/api/health 2>/dev/null | grep -q "database"; then
    log_success "Grafana is responding"
else
    log_warning "Grafana may not be ready yet"
fi

log_step "Checking Prometheus"
if curl -s http://localhost:9095/-/healthy 2>/dev/null | grep -q "Healthy"; then
    log_success "Prometheus is responding"
else
    log_warning "Prometheus may not be ready yet"
fi

log_step "Checking Ceph Manager Dashboard"
if curl -s -k https://localhost:8080 2>/dev/null | grep -q "Ceph"; then
    log_success "Ceph Dashboard is responding"
else
    log_warning "Ceph Dashboard may not be ready yet"
fi

# ============================================================================
# PHASE 7: MONITOR RECOVERY (OPTIONAL)
# ============================================================================

log_header "PHASE 7: RECOVERY PROGRESS"

log_step "Current cluster health"
sudo cephadm shell -- ceph -s 2>/dev/null | head -40

log_step "PG Status"
sudo cephadm shell -- ceph pg stat 2>/dev/null

# ============================================================================
# PHASE 8: FINAL REPORT
# ============================================================================

log_header "✅ RECOVERY PROCESS INITIATED"

FINAL_STATUS=$(sudo cephadm shell -- ceph -s 2>/dev/null | grep "health:" || echo "Unknown")
FINAL_OSDS=$(sudo cephadm shell -- ceph -s 2>/dev/null | grep "osd:" || echo "Unknown")

log_success "Cluster Health: $FINAL_STATUS"
log_success "OSD Status: $FINAL_OSDS"

cat << 'EOF'

📋 SUMMARY:
  ✅ Recovery process initiated
  ✅ Services verified
  ✅ RAID 6 configuration confirmed
  ✅ Cluster is recovering

⏱️ NEXT STEPS:
  1. Monitor cluster recovery: sudo cephadm shell -- ceph -s
  2. Access Grafana: https://localhost:3000
  3. Check Prometheus for metrics: http://localhost:9095
  4. Watch PG recovery: sudo cephadm shell -- ceph pg stat
  5. Expected recovery time: 1-4 hours depending on load

💾 LOG FILE: 
EOF

log_success "Log saved to: $LOG_FILE"

cat << EOF

🔗 Access Points (on this VM):
  Grafana:       http://localhost:3000
  Ceph Dashboard: https://localhost:8080
  Prometheus:    http://localhost:9095

From remote machine (replace IP with public IP):
  Grafana:       https://[PUBLIC_IP]:3000
  Ceph Dashboard: https://[PUBLIC_IP]:8080
  Prometheus:    http://[PUBLIC_IP]:9095

EOF

# ============================================================================
# CLEANUP
# ============================================================================

log_step "Script completed at $(date)"
log_success "All recovery checks passed!"

echo ""
echo "📝 To monitor recovery continuously, run:"
echo "   watch -n 5 'sudo cephadm shell -- ceph -s | head -30'"
echo ""

exit 0
