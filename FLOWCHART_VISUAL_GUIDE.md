# 🗺️ VISUAL FLOWCHART GUIDE: CEPH RAID 6 DEPLOYMENT
## Step-by-Step Visual Flow Chart

---

## PHASE 1: AWS SETUP FLOW

```
START
  ↓
[1] Open AWS EC2 Console
  ↓
[2] Create 6 VMs
  ├─ VM1 (Monitor):    t3.medium + 20GB OS
  ├─ VM2 (OSD1):       t3.medium + 20GB OS + 30GB OSD
  ├─ VM3 (OSD2):       t3.medium + 20GB OS + 30GB OSD
  ├─ VM4 (OSD3):       t3.medium + 20GB OS + 30GB OSD
  ├─ VM5 (Spare):      t3.micro + 20GB OS
  └─ VM6 (Spare):      t3.micro + 20GB OS
  ↓
[3] Create Security Group "ceph-cluster"
  ├─ Port 22 (SSH)
  ├─ Port 3000 (Grafana)
  ├─ Port 8080 (Ceph Dashboard)
  ├─ Port 9095 (Prometheus)
  ├─ Port 3300 (Ceph Mon)
  ├─ Port 6789 (Ceph Mon)
  ├─ Port 6800-7300 (Ceph OSD)
  └─ Port 443 (HTTPS)
  ↓
[4] Wait for all VMs to show "Running"
  ↓
[5] Copy all Public IPs to a text file
  ↓
AWS SETUP COMPLETE ✅
```

---

## PHASE 2: INITIAL VM SETUP FLOW

```
FOR EACH VM (VM1, VM2, VM3, VM4):
  ↓
[1] SSH to VM
  ssh -i key.pem ubuntu@[PUBLIC_IP]
  ↓
[2] Update System
  sudo apt-get update
  sudo apt-get upgrade -y
  ↓
[3] Install Tools
  sudo apt-get install -y curl wget git vim
  ↓
[4] Set Hostname
  sudo hostnamectl set-hostname ceph-mon  (VM1)
  sudo hostnamectl set-hostname ceph-osd1 (VM2)
  sudo hostnamectl set-hostname ceph-osd2 (VM3)
  sudo hostnamectl set-hostname ceph-osd3 (VM4)
  ↓
NEXT VM
(Repeat for VM2, VM3, VM4)
```

---

## PHASE 3: CEPH INSTALLATION FLOW

```
ON MONITOR NODE (VM1):
  ↓
[1] Install Cephadm
  curl -fsSL https://download.ceph.com/keys/release.asc | sudo apt-key add -
  sudo apt-add-repository "deb https://download.ceph.com/debian-octopus ..."
  sudo apt-get update
  sudo apt-get install -y cephadm
  ↓
[2] Bootstrap Cluster
  sudo cephadm bootstrap \
    --mon-ip 0.0.0.0 \
    --skip-firewall \
    --allow-fqdn-hostname
  ⏱️  WAIT 5 MINUTES - DON'T INTERRUPT! ⏱️
  ↓
[3] Verify Bootstrap Success
  sudo cephadm shell -- ceph -s
  Expected: Shows "cluster id", "health:", "mon: 1 daemons"
  ↓
[4] Copy Configuration to Local Directory
  sudo cp /etc/ceph/ceph.conf .
  sudo cp /etc/ceph/ceph.client.admin.keyring .
  ↓
ON EACH OSD NODE (VM2, VM3, VM4):
  ↓
[1] Install Cephadm
  curl -fsSL https://download.ceph.com/keys/release.asc | sudo apt-key add -
  sudo apt-add-repository "deb https://download.ceph.com/debian-octopus ..."
  sudo apt-get update
  sudo apt-get install -y cephadm
  ↓
[2] Copy Config from Monitor
  (FROM MONITOR) scp ceph.conf ubuntu@[OSD_IP]:/home/ubuntu/
  (FROM MONITOR) scp ceph.client.admin.keyring ubuntu@[OSD_IP]:/home/ubuntu/
  ↓
[3] Setup Config Directory
  mkdir -p ~/.ceph
  mv ~/ceph.conf ~/.ceph/
  mv ~/ceph.client.admin.keyring ~/.ceph/
  ↓
(Repeat for VM2, VM3, VM4)
```

---

## PHASE 4: CLUSTER EXPANSION FLOW

```
ON MONITOR NODE (VM1):
  ↓
[1] Add OSD Hosts to Cluster
  sudo cephadm shell -- ceph orch host add ceph-osd1 [IP_2]
  sudo cephadm shell -- ceph orch host add ceph-osd2 [IP_3]
  sudo cephadm shell -- ceph orch host add ceph-osd3 [IP_4]
  ↓
[2] Verify Hosts Added
  sudo cephadm shell -- ceph orch host ls
  Expected: Shows 4 hosts (1 monitor + 3 OSDs)
  ↓
[3] Discover Available Disks
  sudo cephadm shell -- ceph orch device ls
  
  ⚠️ CHECK: Do you see /dev/sdf entries (30GB disks)?
  ├─ YES → Continue to next step
  └─ NO  → OSD VMs missing 30GB storage volumes!
           Go back to AWS and add EBS volumes
           Then retry this step
  ↓
[4] Create OSDs on Discovered Disks
  sudo cephadm shell -- ceph orch apply osd --all-available-devices
  ⏱️  WAIT 2-3 MINUTES - Monitor with: watch -n 2 'cephadm shell -- ceph osd tree'
  ↓
[5] Verify All 5 OSDs are UP and IN
  sudo cephadm shell -- ceph osd tree
  
  Expected output:
  ├─ osd.0  up  in (ceph-mon)
  ├─ osd.1  up  in (ceph-osd1)
  ├─ osd.2  up  in (ceph-osd2)
  ├─ osd.3  up  in (ceph-osd3)
  └─ osd.4  up  in (one of the above)
  
  ⚠️ If any show "down" or "out":
     └─ Run: sudo cephadm shell -- ceph osd in [OSD_ID]
  ↓
CEPH CLUSTER READY ✅
```

---

## PHASE 5: RAID 6 CONFIGURATION FLOW

```
ON MONITOR NODE (VM1):
  ↓
[1] Create RAID 6 Erasure Code Profile
  sudo cephadm shell -- ceph osd erasure-code-profile set raid6-profile \
    k=4 m=2 plugin=jerasure technique=reed_sol_van
  
  ⚠️ CRITICAL: k=4 and m=2 MUST be these exact values!
  ↓
[2] Verify Profile Created Correctly
  sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
  
  Check for: k=4, m=2, plugin=jerasure, technique=reed_sol_van
  ↓
[3] Create Pool Using RAID 6 Profile
  sudo cephadm shell -- ceph osd pool create raid6-pool 64 64 erasure raid6-profile
  ↓
[4] Enable Overwrites on Pool
  sudo cephadm shell -- ceph osd pool set raid6-pool allow_ec_overwrites true
  ↓
[5] Verify Pool Created
  sudo cephadm shell -- ceph osd pool ls detail
  
  Expected: Shows raid6-pool with type=erasure
  ↓
RAID 6 CONFIGURED ✅
(System can now survive 2 simultaneous OSD failures)
```

---

## PHASE 6: MONITORING SETUP FLOW

```
ON MONITOR NODE (VM1):
  ↓
[1] Enable Dashboard Module
  sudo cephadm shell -- ceph mgr module enable dashboard
  ↓
[2] Enable Prometheus Module
  sudo cephadm shell -- ceph mgr module enable prometheus
  ↓
[3] Deploy Node Exporter
  sudo cephadm shell -- ceph orch apply node-exporter '*'
  ↓
[4] Deploy Grafana
  sudo cephadm orch apply grafana
  ⏱️  WAIT 30 seconds
  ↓
[5] Verify Services Running
  sudo cephadm ls | grep -E "dashboard|prometheus|grafana|node-exporter"
  
  Expected: All show "running"
  ↓
[6] Test Dashboard Access
  Browser: https://[PUBLIC_IP]:8080
  User: admin
  Pass: admin123
  ↓
[7] Test Grafana Access
  Browser: http://[PUBLIC_IP]:3000
  User: admin
  Pass: admin
  ↓
[8] Test Prometheus Access
  Browser: http://[PUBLIC_IP]:9095
  ↓
MONITORING CONFIGURED ✅
```

---

## PHASE 7: VERIFICATION FLOW

```
ON MONITOR NODE (VM1):
  ↓
[1] Check Cluster Health
  sudo cephadm shell -- ceph -s
  
  ✅ Should show:
  ├─ health: HEALTH_OK or HEALTH_WARN (NOT HEALTH_ERR)
  ├─ mon: 1 daemons
  ├─ mgr: 1 active
  ├─ osd: 5 osds, 5 up, 5 in
  ├─ pools: 1 pools, XX pgs
  └─ usage: X GiB used, Y GiB available
  ↓
[2] Check OSD Tree
  sudo cephadm shell -- ceph osd tree
  
  ✅ All 5 OSDs should show "up" and "in"
  ↓
[3] Check RAID 6 Configuration
  sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
  
  ✅ Must show: k=4, m=2
  ↓
[4] Check Disk Utilization
  sudo cephadm shell -- ceph df
  
  ✅ Should show ~45 GiB total available
  ↓
[5] Check Dashboard Access
  https://[PUBLIC_IP]:8080/dashboard
  
  ✅ Should show:
  ├─ Cluster health
  ├─ OSD status
  ├─ Pool info
  └─ Capacity graph
  ↓
[6] Check Grafana Dashboards
  http://[PUBLIC_IP]:3000/dashboards
  
  ✅ Should show:
  ├─ Ceph cluster metrics
  ├─ OSD performance
  └─ Storage utilization
  ↓
[7] Create Test File (Optional)
  echo "test data" | sudo cephadm shell -- ceph put test-file -
  sudo cephadm shell -- ceph get test-file
  
  ✅ Should retrieve same data
  ↓
VERIFICATION COMPLETE ✅
SYSTEM IS PRODUCTION READY ✅
```

---

## TROUBLESHOOTING DECISION TREE

```
PROBLEM: Cluster won't bootstrap
├─ Error: "Cannot create directories"
│ └─ Solution: Run with sudo
├─ Error: "Address already in use"
│ └─ Solution: Stop existing services, then retry
└─ Error: "Timeout"
  └─ Solution: Check firewall, wait longer (5+ min)

PROBLEM: OSDs won't deploy
├─ Error: "No devices found"
│ ├─ Check: ceph orch device ls
│ └─ Solution: Add 30GB EBS volumes to OSD VMs in AWS
├─ Error: "Device in use"
│ └─ Solution: Check if disk was used before, wipe if needed
└─ Error: "OSDs mark down"
  └─ Solution: Check logs: sudo cephadm logs --name osd.X

PROBLEM: Can't SSH to VM
├─ Error: "Connection refused"
│ └─ Solution: Check security group allows port 22
├─ Error: "Permission denied"
│ └─ Solution: Check key file permissions: chmod 400 key.pem
└─ Error: "No route to host"
  └─ Solution: Check public IP is correct

PROBLEM: RAID 6 not working
├─ Error: "Profile not found"
│ └─ Solution: Create it with: ceph osd erasure-code-profile set raid6-profile k=4 m=2 ...
├─ Error: "Wrong k/m values"
│ └─ Solution: Delete and recreate with correct values (k=4, m=2)
└─ Error: "Can't create pool"
  └─ Solution: Check profile exists first

PROBLEM: Dashboard/Grafana not accessible
├─ Error: "Connection refused"
│ └─ Solution: Add ports to security group (3000, 8080, 9095)
├─ Error: "Timeout"
│ └─ Solution: Wait for services to start (2-5 minutes)
└─ Error: "Authentication failed"
  └─ Solution: Use default credentials (admin/admin)

PROBLEM: Cluster shows HEALTH_ERR
├─ Check: sudo cephadm shell -- ceph health detail
├─ If "not best effort": Normal, will resolve in 10 min
├─ If "recovery running": Normal, let it complete
└─ If "pg stuck": Run recovery commands manually
```

---

## SIMPLE SUCCESS CHECKLIST

Print this and check off as you go:

```
AWS SETUP:
  [ ] 6 VMs created
  [ ] All VMs show "Running"
  [ ] Security group has all ports
  [ ] OSD VMs have 30GB extra storage
  [ ] All public IPs recorded

CEPH INSTALLATION:
  [ ] Cephadm installed on all VMs
  [ ] Bootstrap completed on monitor
  [ ] All 4 OSD nodes added to cluster
  [ ] 5 OSDs created and UP/IN

RAID 6:
  [ ] Erasure code profile created (k=4, m=2)
  [ ] RAID 6 pool created
  [ ] Pool shows erasure coding enabled

MONITORING:
  [ ] Ceph Dashboard accessible (port 8080)
  [ ] Grafana running (port 3000)
  [ ] Prometheus running (port 9095)
  [ ] Dashboard shows all OSDs UP

FINAL:
  [ ] Cluster health is HEALTH_OK or HEALTH_WARN
  [ ] All 5 OSDs showing "up" and "in"
  [ ] RAID 6 verified (k=4, m=2)
  [ ] Can see metrics in Grafana
  [ ] Test data uploaded and retrieved
```

---

## COMMAND QUICK REFERENCE BY PHASE

### Phase 1-2: Setup (copy-paste exactly)
```bash
# Bootstrap (on VM1, WAIT 5 minutes!)
sudo cephadm bootstrap --mon-ip 0.0.0.0 --skip-firewall --allow-fqdn-hostname

# Copy config (on VM1)
sudo cp /etc/ceph/ceph.conf .
sudo cp /etc/ceph/ceph.client.admin.keyring .
```

### Phase 3: OSD Setup (copy-paste exactly)
```bash
# Add hosts (on VM1)
sudo cephadm shell -- ceph orch host add ceph-osd1 [IP_2]
sudo cephadm shell -- ceph orch host add ceph-osd2 [IP_3]
sudo cephadm shell -- ceph orch host add ceph-osd3 [IP_4]

# Create OSDs (on VM1, WAIT 2-3 minutes!)
sudo cephadm shell -- ceph orch apply osd --all-available-devices

# Verify (on VM1)
sudo cephadm shell -- ceph osd tree
```

### Phase 4: RAID 6 (copy-paste exactly)
```bash
# Create profile (on VM1)
sudo cephadm shell -- ceph osd erasure-code-profile set raid6-profile \
  k=4 m=2 plugin=jerasure technique=reed_sol_van

# Create pool (on VM1)
sudo cephadm shell -- ceph osd pool create raid6-pool 64 64 erasure raid6-profile
sudo cephadm shell -- ceph osd pool set raid6-pool allow_ec_overwrites true

# Verify (on VM1)
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
```

### Phase 5: Monitoring (copy-paste exactly)
```bash
# Deploy services (on VM1)
sudo cephadm shell -- ceph mgr module enable dashboard
sudo cephadm shell -- ceph mgr module enable prometheus
sudo cephadm shell -- ceph orch apply node-exporter '*'
sudo cephadm orch apply grafana

# Verify (on VM1)
sudo cephadm ls | grep -E "grafana|prometheus|dashboard"
```

---

## TIME ESTIMATES

| Phase | Time | Critical? |
|-------|------|-----------|
| AWS VM Creation | 5-10 min | Yes |
| Initial Setup | 5-10 min | Yes |
| Cephadm Install | 5 min | Yes |
| Bootstrap | 5 min | YES - DON'T INTERRUPT |
| OSD Discovery | 1 min | Yes |
| OSD Creation | 2-3 min | YES - WAIT FOR COMPLETION |
| RAID 6 Config | 1 min | Yes |
| Monitoring Deploy | 2-3 min | No (can be done later) |
| Verification | 5 min | Yes |
| **TOTAL** | **30-45 min** | |

**Then cluster recovers in background: 1-4 hours**

---

**Flowchart Version:** 1.0  
**Created:** April 20, 2026  
**Use with:** MANUAL_ZERO_TO_100_COMPLETE.md
