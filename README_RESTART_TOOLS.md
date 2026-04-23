# 📚 MASTER GUIDE: VM RESTART & RECOVERY TOOLS INDEX
## CS-4075 Assignment 3 - Complete Resource Library

**Created:** April 20, 2026  
**Assignment:** Distributed Cloud Storage with RAID 6  
**Cluster ID:** 1512292e-3cde-11f1-ab7e-3748aba09780

---

## 📁 FILES IN THIS PACKAGE

### 1. **QUICK_RESTART_REFERENCE.md** ⚡
**When to use:** Print this and keep it on your screen during restart  
**What it does:** Step-by-step visual guide with checklist  
**Time to complete:** 20 minutes (without recovery wait)  
**Best for:** First-time users, quick reference

**Contains:**
- 8 simple steps with copy-paste commands
- Checkboxes for tracking progress
- Quick troubleshooting table
- Expected timeline

**How to use:**
1. Print it out or keep open in second monitor
2. Follow steps 1-8 sequentially
3. Check off each step as completed
4. Use troubleshooting table if issues occur

---

### 2. **VM_RESTART_GUIDE.md** 📋
**When to use:** Detailed step-by-step walkthrough  
**What it does:** Comprehensive guide with explanations  
**Best for:** Understanding what's happening at each stage

**Contains:**
- 7 detailed phases with sub-steps
- Expected outputs for each command
- Troubleshooting section with solutions
- Pre-restart snapshot procedure

**How to use:**
1. Read through entire document first (10 min)
2. Follow each phase in order
3. Verify expected output at each step
4. Use troubleshooting if needed

**Key sections:**
- Phase 1: Pre-restart checklist
- Phase 2: Stop VMs
- Phase 3: Start VMs & verify connectivity
- Phase 4: Ceph cluster recovery
- Phase 5: Service verification
- Phase 6: Update public IPs
- Phase 7: Final health check

---

### 3. **VM_RESTART_AUTO.ps1** 🤖
**When to use:** Automated restart process (Recommended)  
**What it does:** PowerShell script automates most of the restart  
**Requirements:** PowerShell on Windows, SSH, AWS VMs  
**Best for:** Experienced users, repeatable automation

**How to use:**

```powershell
# Option 1: Run with default settings (will prompt for IP)
cd C:\Users\Dell\Downloads
.\VM_RESTART_AUTO.ps1

# Option 2: Provide IP directly
.\VM_RESTART_AUTO.ps1 -MonitorIP "54.89.62.36"

# Option 3: Specify custom key path
.\VM_RESTART_AUTO.ps1 -MonitorIP "54.89.62.36" -KeyPath "C:\path\to\key.pem"
```

**What it automates:**
- ✅ SSH connectivity testing
- ✅ Pre-restart snapshot capture
- ✅ New IP collection
- ✅ Cluster recovery monitoring (5 min)
- ✅ RAID 6 verification
- ✅ Service health checks
- ✅ Generates ACTIVE_IPs.txt with new IPs

**Output:**
- Colored console output with status
- ACTIVE_IPs.txt file with new public IPs
- Real-time cluster status updates

**Advantages:**
- Hands-off automation
- Captures all outputs
- No manual IP updates needed
- Saves new IP to file automatically

---

### 4. **ceph_recovery.sh** 🔧
**When to use:** Run on the Monitor VM itself  
**What it does:** Server-side automation of recovery process  
**Best for:** Ensuring proper recovery from VM perspective

**How to use:**

```bash
# Copy script to Monitor VM
scp -i cloud-ass3.pem ceph_recovery.sh ubuntu@NEW_IP:/tmp/

# SSH to Monitor and run
ssh -i cloud-ass3.pem ubuntu@NEW_IP
bash /tmp/ceph_recovery.sh

# Or run directly
ssh -i cloud-ass3.pem ubuntu@NEW_IP "bash -s" < ceph_recovery.sh
```

**What it does:**
1. Verifies sudo access
2. Checks Ceph installation
3. Monitors OSD startup
4. Clears recovery flags
5. Verifies RAID 6
6. Checks service status
7. Captures logs

**Output:**
- Real-time progress with colors
- Log file saved to /tmp/ceph_recovery_*.log
- Service health summary

---

## 🎯 RECOMMENDED WORKFLOW

### Scenario 1: First Time / Learning
**Goal:** Understand the process  
**Tools to use:**
1. Read **VM_RESTART_GUIDE.md** completely
2. Use **QUICK_RESTART_REFERENCE.md** as checklist
3. Follow steps manually
4. Total time: 30-40 minutes

---

### Scenario 2: Quick Restart (Experienced)
**Goal:** Get back up and running fast  
**Tools to use:**
1. Print **QUICK_RESTART_REFERENCE.md**
2. Run **VM_RESTART_AUTO.ps1**
3. Monitor in Grafana
4. Total time: 20 minutes + recovery

---

### Scenario 3: Fully Automated
**Goal:** Completely hands-off  
**Tools to use:**
1. Run **VM_RESTART_AUTO.ps1** (client side)
2. Optionally: **ceph_recovery.sh** (server side)
3. Automated logs saved
4. Total time: 15 minutes + recovery

---

## 📊 COMPARISON TABLE

| Guide | Time | Automation | Best For | Level |
|-------|------|-----------|----------|-------|
| QUICK_RESTART_REFERENCE | 20 min | None | Quick reference | Beginner |
| VM_RESTART_GUIDE | 30-40 min | None | Learning | Beginner |
| VM_RESTART_AUTO.ps1 | 15 min | 80% | Regular use | Intermediate |
| ceph_recovery.sh | 10 min | 100% | Server-side | Advanced |

---

## ⚠️ CRITICAL STEPS (DO NOT SKIP)

1. **Document public IPs BEFORE restarting**
2. **Wait for all VMs to show "Running" status**
3. **Record NEW public IPs after restart**
4. **Test SSH connectivity to new IP**
5. **Monitor cluster recovery for 5-15 minutes**
6. **Verify RAID 6 profile (k=4, m=2)**
7. **Check all services responding**

---

## 🔄 THE RESTART PROCESS AT A GLANCE

```
PHASE 1: PREPARATION
  └─ Record current IPs
  └─ Take pre-restart snapshot

PHASE 2: SHUTDOWN
  └─ Stop all VMs (2-3 min)

PHASE 3: STARTUP
  └─ Start all VMs (1-2 min)
  └─ Get new public IPs

PHASE 4: VERIFICATION
  └─ SSH connectivity (1-2 min)
  └─ Cluster stabilization (5-15 min)
  └─ Clear recovery flags (1 min)
  └─ Verify RAID 6 (1 min)
  └─ Check services (2 min)

TOTAL: ~20 minutes to working state
Recovery continues: 1-4 hours in background
```

---

## 🆘 TROUBLESHOOTING QUICK REFERENCE

### "SSH Connection Refused"
```
Cause: VM still booting
Solution: Wait 1-2 minutes and retry
```

### "All OSDs not UP after 15 min"
```
Cause: Some OSDs may be slow to start
Solution: Run: sudo cephadm shell -- ceph osd in <id>
```

### "HEALTH_ERR with many warnings"
```
Cause: Normal post-restart
Solution: Wait 10-15 minutes, should improve to HEALTH_OK/WARN
```

### "Grafana/Prometheus not responding"
```
Cause: Services starting up
Solution: Wait 2-5 minutes, containers may still be initializing
```

### "RAID 6 profile not found"
```
Cause: Profile may have been lost
Solution: See VM_RESTART_GUIDE.md Phase 5 for recreation
```

---

## 📝 DOCUMENTATION TO UPDATE AFTER RESTART

After completing restart, update these files:

1. **ACTIVE_IPS.txt** 
   - Update with new public IP for Monitor
   - Update service URLs

2. **ASSIGNMENT_3_COMPLETION_REPORT.md**
   - Add section on "Restart Procedure"
   - Include screenshots of recovery
   - Document timeline

3. **PROJECT_COMPLETION_SUMMARY.md**
   - Note restart date/time
   - Document recovery success
   - Update system access section

---

## 🎓 TIPS FOR ASSIGNMENT SUBMISSION

1. **Take screenshots of:**
   - Cluster status before restart
   - Cluster status during recovery (showing PG recovery)
   - Cluster status after recovery (all OSDs UP)
   - Grafana dashboard with recovery metrics
   - Ceph Dashboard showing RAID 6 configuration
   - Prometheus showing metrics

2. **Include in documentation:**
   - Steps you followed
   - Timeline of restart process
   - Any issues encountered and solutions
   - Final cluster health status
   - Proof that RAID 6 is configured and working

3. **Highlight:**
   - Zero data loss during restart
   - Automatic recovery of cluster
   - All monitoring systems working post-restart
   - RAID 6 protection verified

---

## 📞 GETTING HELP

### For SSH Issues
Check security groups allow port 22 from your IP

### For Cluster Recovery Issues
Check: `sudo cephadm shell -- ceph health detail`

### For Service Issues
Check logs:
```bash
sudo cephadm logs [service-name]  # e.g., grafana, prometheus
```

### For RAID 6 Issues
Verify profile:
```bash
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
```

---

## ✅ SUCCESS CRITERIA

After complete restart, you should have:

- [ ] All 6 VMs running in AWS
- [ ] New public IPs documented
- [ ] SSH connectivity verified
- [ ] Ceph cluster with 5 OSDs UP/IN
- [ ] RAID 6 configuration verified (k=4, m=2)
- [ ] Grafana accessible (port 3000)
- [ ] Ceph Dashboard accessible (port 8080)
- [ ] Prometheus accessible (port 9095)
- [ ] Cluster health improving toward HEALTH_OK
- [ ] No data loss reported
- [ ] PGs recovering toward active+clean
- [ ] All documentation updated with new IPs

---

## 📅 RECOMMENDED SCHEDULE

- **5 minutes before restart:** Read QUICK_RESTART_REFERENCE.md
- **During restart:** Follow one of the 4 guides
- **During recovery:** Monitor in Grafana
- **After recovery:** Take screenshots, update documentation

---

## 🔐 SECURITY NOTES

- Keep cloud-ass3.pem safe (SSH key)
- Security groups must allow ports 22, 3000, 8080, 9095
- Default credentials (admin/admin) should be changed for production
- Public IPs change on restart - update them in all systems

---

## 📈 EXPECTED CLUSTER RECOVERY TIMELINE

```
T+0min:    VMs Start → Ceph services starting
T+5min:    OSDs coming online, PGs activating
T+15min:   All OSDs UP, most PGs active+clean
T+30min:   Cluster health improving
T+60min:   Most recovery complete
T+4h:      Full recovery with all data verified
```

Recovery speed depends on:
- Number of failed OSDs
- Amount of data stored
- Number of PGs
- Server CPU/disk speed

---

## 🎯 NEXT STEPS AFTER SUCCESSFUL RESTART

1. Take assignment screenshots
2. Document restart procedure
3. Update all configuration files with new IPs
4. Verify all test suites still pass
5. Prepare final submission with evidence

---

**Document Version:** 1.0  
**Last Updated:** April 20, 2026  
**Status:** Ready for production use

For questions or issues, refer to the detailed guides above.
