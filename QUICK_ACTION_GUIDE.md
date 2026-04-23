# CS-4075 Assignment 3 - QUICK ACTION GUIDE
## Immediate Tasks to Complete (35% Remaining)

**Report Date:** April 20, 2026  
**Completion Status:** 65% Done → Target: 100% Complete  
**Time Estimate:** 4-6 hours

---

## 📋 TASK BREAKDOWN

### ✅ ALREADY COMPLETED (65%)

| Component | Status | Details |
|-----------|--------|---------|
| **AWS Infrastructure** | ✅ Done | 6 VMs running (vm1-vm6) |
| **Ceph Cluster** | ✅ Done | v17.2.9 with 5 OSDs UP |
| **RAID 6 Setup** | ✅ Done | Erasure coding k=4 m=2 configured |
| **Prometheus** | ✅ Done | Running on port 9283 |
| **Grafana** | ✅ Done | Running on port 3000 |
| **Ceph Dashboard** | ✅ Done | Running on port 8080 |

---

## 🚀 REMAINING TASKS (35%)

### **TASK 1: CREATE 5 GRAFANA DASHBOARDS** ⏱️ 2-3 hours
**Priority:** 🔴 CRITICAL

#### Dashboard #1: Cluster Overview
**What to show:**
- Total storage capacity (GB)
- Used storage (GB)
- Available space (GB)
- Number of active OSDs
- Cluster health status (HEALTH_OK)

**How to create:**
1. Login to Grafana: https://172.31.45.113:3000
   - Username: `admin`
   - Password: `admin`

2. Click **"+"** button → Select **"Dashboard"**

3. Click **"Add new panel"**

4. For each panel, add these queries:

**Panel 1: Total Capacity (Gauge)**
```
Query: ceph_cluster_total_bytes / 1024 / 1024 / 1024
Title: Total Capacity (GB)
Visualization: Gauge
```

**Panel 2: Used Storage (Gauge)**
```
Query: ceph_cluster_total_used_bytes / 1024 / 1024 / 1024
Title: Used Storage (GB)
Visualization: Gauge
```

**Panel 3: Available Space (Gauge)**
```
Query: (ceph_cluster_total_bytes - ceph_cluster_total_used_bytes) / 1024 / 1024 / 1024
Title: Available (GB)
Visualization: Gauge
```

**Panel 4: Active OSDs (Stat)**
```
Query: count(ceph_osd_stat_up == 1)
Title: Active OSDs
Visualization: Stat
```

**Panel 5: Cluster Health (Table)**
```
Query: ceph_health_status
Title: Cluster Health
Visualization: Table
```

5. Click **"Save"** → Name it **"Cluster Overview"**

---

#### Dashboard #2: Performance Metrics
**What to show:**
- Read operations per second (IOPS)
- Write operations per second (IOPS)
- Read latency (ms)
- Write latency (ms)

**How to create:**

1. Create new Dashboard: **"+"** → **"Dashboard"**

2. Add 4 panels:

**Panel 1: Read IOPS (Graph)**
```
Query: rate(ceph_osd_op_r[1m])
Title: Read IOPS
Visualization: Time series graph
Y-axis label: Operations/sec
```

**Panel 2: Write IOPS (Graph)**
```
Query: rate(ceph_osd_op_w[1m])
Title: Write IOPS
Visualization: Time series graph
Y-axis label: Operations/sec
```

**Panel 3: Operation Latency (Graph)**
```
Query: ceph_osd_op_rw_latency_total
Title: Operation Latency
Visualization: Time series graph
Y-axis label: Milliseconds
```

**Panel 4: Throughput (Graph)**
```
Query: rate(ceph_osd_bytes[1m])
Title: Throughput
Visualization: Time series graph
Y-axis label: Bytes/sec
```

3. Click **"Save"** → Name it **"Performance Metrics"**

---

#### Dashboard #3: Reliability & Fault Tolerance
**What to show:**
- Number of degraded placement groups (PGs)
- Number of misplaced PGs
- Recovery progress
- Failed nodes count

**How to create:**

1. Create new Dashboard: **"+"** → **"Dashboard"**

2. Add 4 panels:

**Panel 1: Degraded PGs (Stat)**
```
Query: ceph_pg_degraded
Title: Degraded PGs
Visualization: Stat
Color if > 0: Red (warning)
```

**Panel 2: Misplaced PGs (Stat)**
```
Query: ceph_pg_misplaced
Title: Misplaced PGs
Visualization: Stat
Color if > 0: Yellow (warning)
```

**Panel 3: Recovering PGs (Graph)**
```
Query: ceph_pg_recovering
Title: PGs in Recovery
Visualization: Time series graph
```

**Panel 4: Failed Nodes (Stat)**
```
Query: count(ceph_osd_stat_down)
Title: Failed OSDs
Visualization: Stat
Color if > 0: Red (critical)
```

3. Click **"Save"** → Name it **"Reliability & Fault Tolerance"**

---

#### Dashboard #4: Resource Utilization
**What to show:**
- CPU usage per node
- Memory usage per node
- Disk usage per node
- Network utilization

**How to create:**

1. Create new Dashboard: **"+"** → **"Dashboard"**

2. Add panels for resource metrics:

**Panel 1: OSD CPU Usage (Graph)**
```
Query: rate(ceph_osd_cpuacct[5m])
Title: CPU Usage (%)
Visualization: Time series graph
```

**Panel 2: OSD Memory (Graph)**
```
Query: ceph_osd_memory_per_osd_bytes / 1024 / 1024 / 1024
Title: Memory per OSD (GB)
Visualization: Time series graph
```

**Panel 3: Disk Usage per OSD (Graph)**
```
Query: ceph_osd_stat_bytes_used / ceph_osd_stat_bytes_total * 100
Title: Disk Usage (%)
Visualization: Time series graph
```

**Panel 4: Network I/O (Graph)**
```
Query: rate(ceph_osd_bytes[1m])
Title: Network Throughput
Visualization: Time series graph
```

3. Click **"Save"** → Name it **"Resource Utilization"**

---

#### Dashboard #5: Alerts & Events
**What to show:**
- Current alerts and their status
- Failed node alerts
- Disk space warnings (>80%, >90%)
- Recent Ceph events

**How to create:**

1. Create new Dashboard: **"+"** → **"Dashboard"**

2. Add 3 panels:

**Panel 1: Alert Status (Table)**
```
Query: ALERTS{alertstate="firing"}
Title: Active Alerts
Visualization: Table
```

**Panel 2: Disk Space Warning Indicator (Gauge)**
```
Query: max(ceph_osd_stat_bytes_used / ceph_osd_stat_bytes_total * 100)
Title: Max Disk Usage (%)
Visualization: Gauge
Thresholds: 
  - Yellow: >80%
  - Red: >90%
```

**Panel 3: Event Timeline (Graph)**
```
Query: ceph_crash_count
Title: Crash Events
Visualization: Time series graph
```

3. Click **"Save"** → Name it **"Alerts & Events"**

---

### **TASK 2: PERFORM FAULT TOLERANCE TESTING** ⏱️ 1-2 hours
**Priority:** 🔴 CRITICAL

#### Test 1: Single OSD Failure Recovery
```bash
# SSH into monitor node
ssh -i cloud-ass3.pem ubuntu@54.89.62.36

# Stop one OSD (e.g., OSD.4 on vm6)
sudo cephadm shell -- ceph osd down osd.4
sudo cephadm shell -- ceph osd out osd.4

# Monitor recovery in another terminal
watch 'ceph -s'

# Check recovery progress
sudo cephadm shell -- ceph pg stat

# Document:
# - Time when OSD went down
# - Time to start recovery
# - Recovery completion time
# - Total recovery duration
# - Data integrity verified

# Bring OSD back up
sudo cephadm shell -- ceph osd in osd.4
sudo cephadm shell -- ceph osd up osd.4
```

**What to document:**
- Recovery start time
- Recovery end time
- Total recovery time (minutes)
- Data integrity status
- No data loss confirmation

#### Test 2: Dual OSD Failure (RAID 6 Capability Test)
```bash
# Stop TWO OSDs simultaneously (e.g., OSD.3 and OSD.4)
sudo cephadm shell -- ceph osd down osd.3
sudo cephadm shell -- ceph osd down osd.4

# Monitor recovery
watch 'sudo cephadm shell -- ceph -s'

# Check if cluster remains operational
sudo cephadm shell -- ceph rados ls

# Verify data integrity
sudo cephadm shell -- ceph pg ls-by-pool storage-pool

# Document:
# - Cluster status (should be HEALTH_WARN, not HEALTH_ERR)
# - Data accessibility
# - Recovery ability
# - Time to recover

# Bring OSDs back
sudo cephadm shell -- ceph osd in osd.3
sudo cephadm shell -- ceph osd in osd.4
```

**What to document:**
- Cluster remained healthy (RAID 6 protection)
- Data was still accessible
- Recovery time
- No data loss

#### Test 3: Verify RAID 6 Parity
```bash
# Check pool configuration
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile

# Verify placement groups
sudo cephadm shell -- ceph pg stat

# Expected output should show:
# - k=4 (4 data chunks)
# - m=2 (2 parity chunks)
# - Total 6 chunks per object
```

---

### **TASK 3: DOCUMENT RESULTS** ⏱️ 1 hour
**Priority:** 🟡 MEDIUM

**Create file: `TESTING_RESULTS.md` with:**

```markdown
# Fault Tolerance Testing Results

## Single OSD Failure Test
- Time Started: [timestamp]
- Time Completed: [timestamp]
- Recovery Duration: [X minutes]
- Cluster Status: HEALTH_OK
- Data Integrity: ✅ Verified
- Result: ✅ PASS

## Dual OSD Failure Test
- OSDs Failed: OSD.3, OSD.4
- Cluster Status During Failure: HEALTH_WARN
- Data Remained Accessible: ✅ YES
- Recovery Duration: [X minutes]
- Data Integrity: ✅ Verified
- Result: ✅ PASS (RAID 6 protection confirmed)

## Performance Impact
- Read throughput degraded: [X%]
- Write throughput degraded: [X%]
- Latency increase: [X ms]

## Conclusion
- Fault tolerance: ✅ VERIFIED
- RAID 6 protection: ✅ WORKING
- Data safety: ✅ CONFIRMED
```

---

### **TASK 4: CREATE DEMO SETUP** ⏱️ 0.5 hours
**Priority:** 🟡 MEDIUM

**What to prepare for demo:**

1. **Access credentials document:**
```
System Access Details:
- Ceph Monitor: ubuntu@54.89.62.36
- Grafana: https://172.31.45.113:3000 (admin/admin)
- Ceph Dashboard: https://172.31.45.113:8080 (admin/admin123)
- Prometheus: http://172.31.45.113:9283
- Private IP for internal access: 172.31.45.113
```

2. **Screenshot all 5 dashboards:**
   - Cluster Overview dashboard
   - Performance Metrics dashboard
   - Reliability dashboard
   - Resource Utilization dashboard
   - Alerts & Events dashboard

3. **Demo script:**
```
Step 1: Show Grafana dashboards (2 min)
Step 2: Show Ceph Dashboard (1 min)
Step 3: Show cluster status (ceph -s) (1 min)
Step 4: Discuss fault tolerance (1 min)
Step 5: Show test results (1 min)
Total: ~6 minutes
```

---

### **TASK 5: SETUP ALERTING (OPTIONAL)** ⏱️ 0.5 hours
**Priority:** 🟢 LOW (BONUS)

**Create alert rules in Prometheus:**

```bash
ssh -i cloud-ass3.pem ubuntu@54.89.62.36

# Create alert rules file
cat > /tmp/ceph_alerts.yaml << 'EOF'
groups:
  - name: ceph_alerts
    rules:
      - alert: HighDiskUsage
        expr: max(ceph_osd_stat_bytes_used / ceph_osd_stat_bytes_total * 100) > 80
        for: 5m
        annotations:
          summary: "High disk usage detected"
          
      - alert: OSDDown
        expr: count(ceph_osd_stat_down) > 0
        for: 1m
        annotations:
          summary: "One or more OSDs are down"
          
      - alert: DegradedPGs
        expr: ceph_pg_degraded > 0
        for: 5m
        annotations:
          summary: "Degraded PGs detected"
          
      - alert: UnhealthyCluster
        expr: ceph_health_status != 1
        for: 1m
        annotations:
          summary: "Ceph cluster is unhealthy"
EOF
```

---

## 📊 COMPLETION TRACKING

| Task | Status | Progress | Est. Time |
|------|--------|----------|-----------|
| Dashboard 1: Cluster Overview | ⬜ TODO | 0% | 30 min |
| Dashboard 2: Performance | ⬜ TODO | 0% | 30 min |
| Dashboard 3: Reliability | ⬜ TODO | 0% | 30 min |
| Dashboard 4: Resources | ⬜ TODO | 0% | 30 min |
| Dashboard 5: Alerts | ⬜ TODO | 0% | 30 min |
| Single OSD Failure Test | ⬜ TODO | 0% | 45 min |
| Dual OSD Failure Test | ⬜ TODO | 0% | 45 min |
| Results Documentation | ⬜ TODO | 0% | 30 min |
| Demo Preparation | ⬜ TODO | 0% | 30 min |
| **TOTAL** | | | **~4-6 hours** |

---

## 🎯 SUCCESS CRITERIA

✅ **All 5 dashboards created and populated with live data**  
✅ **Fault tolerance tests completed and documented**  
✅ **Zero data loss demonstrated**  
✅ **RAID 6 protection verified**  
✅ **Demo ready with evidence**  
✅ **All documentation complete**  

---

## 📞 QUICK REFERENCE

### Ceph Commands
```bash
# Check cluster status
sudo cephadm shell -- ceph -s

# List all OSDs
sudo cephadm shell -- ceph osd tree

# Check pool status
sudo cephadm shell -- ceph df

# Monitor recovery
watch 'sudo cephadm shell -- ceph pg stat'
```

### System Access
```bash
# SSH into monitor node
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@54.89.62.36

# From there, SSH to other nodes
ssh ubuntu@3.88.29.137  (vm5)
ssh ubuntu@3.90.184.140 (vm6)
```

### Grafana API (if needed)
```bash
# Get datasource ID
curl -s -H "Authorization: Bearer <token>" https://172.31.45.113:3000/api/datasources

# List dashboards
curl -s -H "Authorization: Bearer <token>" https://172.31.45.113:3000/api/search
```

---

## ⚠️ IMPORTANT NOTES

1. **All timestamps should be recorded** for accurate duration measurement
2. **Keep cluster healthy** during testing - don't fail >2 OSDs at once
3. **Monitor disk space** - ensure >20% free space during recovery
4. **Document everything** - screenshots and test results
5. **Test during off-peak** - recovery uses network/CPU resources

---

## 🏁 FINAL CHECKLIST

Before submission:
- [ ] All 5 Grafana dashboards created
- [ ] Dashboards showing live Ceph metrics
- [ ] Single OSD failure test completed
- [ ] Dual OSD failure test completed
- [ ] Test results documented
- [ ] Demo script prepared
- [ ] Screenshots taken
- [ ] Access instructions provided
- [ ] No data loss documented
- [ ] RAID 6 protection confirmed

**Ready to submit: ✅ YES** (after above items completed)

---

*Last Updated: April 20, 2026*  
*Project: CS-4075 Assignment 3 - Distributed Cloud Storage System*  
*Target Completion: Week 14 End*
