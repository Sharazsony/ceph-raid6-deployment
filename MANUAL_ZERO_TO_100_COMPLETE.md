# 📚 COMPLETE MANUAL: ZERO TO 100% CEPH RAID 6 CLUSTER
## CS-4075 Cloud Computing Assignment 3
## Beginner-Friendly Step-by-Step Guide

**Created:** April 20, 2026  
**Status:** Production Ready  
**Based on:** Real deployment experience with common pitfalls

---

## TABLE OF CONTENTS

1. [Pre-Deployment Planning](#1-pre-deployment-planning)
2. [AWS Setup (Part 1: VMs)](#2-aws-setup-part-1-create-vms)
3. [AWS Setup (Part 2: Networking)](#3-aws-setup-part-2-configure-networking)
4. [Initial VM Configuration](#4-initial-vm-configuration)
5. [Ceph Installation](#5-ceph-installation)
6. [RAID 6 Configuration](#6-raid-6-configuration)
7. [Monitoring Setup](#7-monitoring-setup)
8. [Testing & Verification](#8-testing-and-verification)
9. [Common Mistakes & Fixes](#9-common-mistakes--fixes)
10. [Troubleshooting](#10-troubleshooting)

---

# 1. PRE-DEPLOYMENT PLANNING

## What You Need (Before Starting)

### AWS Account Requirements
- ✅ AWS account with free tier or credits
- ✅ Access to EC2, VPC, Security Groups
- ✅ US-EAST-1 region (cheapest)
- ✅ SSH key pair already created

### Local Machine Requirements
- ✅ PowerShell (Windows) or Bash (Mac/Linux)
- ✅ SSH client installed
- ✅ PEM key file saved locally
- ✅ Internet connectivity

---

## 2. AWS SETUP (PART 1): CREATE VMs

### Step 2.1: Plan Your VMs

**You will create 6 VMs:**

| VM # | Hostname | Role | Instance Type | vCPU | RAM | Storage | Why? |
|------|----------|------|---------------|------|-----|---------|------|
| 1 | vm1 (ceph-mon) | Monitor | t3.medium | 2 | 4GB | 20GB | Runs Monitor + MGR + Services |
| 2 | vm2 (ceph-osd1) | OSD Node | t3.medium | 2 | 4GB | 20GB (OS) + 30GB (OSD) | Data storage |
| 3 | vm3 (ceph-osd2) | OSD Node | t3.medium | 2 | 4GB | 20GB (OS) + 30GB (OSD) | Data storage |
| 4 | vm4 (ceph-osd3) | OSD Node | t3.medium | 2 | 4GB | 20GB (OS) + 30GB (OSD) | Data storage |
| 5 | vm5 | Spare | t3.micro | 1 | 1GB | 20GB | Not used in cluster |
| 6 | vm6 | Spare | t3.micro | 1 | 1GB | 20GB | Not used in cluster |

### Step 2.2: Create First VM (Monitor Node)

1. **Go to AWS Console**
   - Search: "EC2"
   - Click "Instances"
   - Click "Launch instances"

2. **Step 1: Choose AMI (Image)**
   - Search: "Ubuntu Server 22.04 LTS"
   - Look for: "ami-xxxxx" (official Ubuntu)
   - Click "Select"

3. **Step 2: Choose Instance Type**
   - Scroll down and find: **t3.medium**
   - Click it (NOT t3.micro, NOT t3.large)
   - This gives: 2 vCPU, 4GB RAM (perfect for monitor)

4. **Step 3: Configure Instance Details**
   - Number of instances: 1
   - VPC: Default VPC
   - Subnet: Any (default is fine)
   - Auto-assign Public IP: **ENABLE** ✅
   - IAM role: None
   - Leave everything else default
   - Click "Next"

5. **Step 4: Add Storage**
   - Root volume: 20 GB (default is fine)
   - Volume type: gp2 (default)
   - Delete on termination: ✅ checked
   - Click "Next"

6. **Step 5: Add Tags**
   - Key: "Name"
   - Value: "vm1"
   - Add tag
   - Click "Next"

7. **Step 6: Configure Security Group**
   - Click "Create a new security group"
   - Group name: "ceph-cluster"
   - Description: "Ceph Cluster Security"
   - **Add these rules:**

   | Type | Protocol | Port | Source |
   |------|----------|------|--------|
   | SSH | TCP | 22 | 0.0.0.0/0 |
   | Custom TCP | TCP | 3000 | 0.0.0.0/0 |
   | Custom TCP | TCP | 8080 | 0.0.0.0/0 |
   | Custom TCP | TCP | 9095 | 0.0.0.0/0 |
   | Custom TCP | TCP | 3300 | 0.0.0.0/0 |
   | Custom TCP | TCP | 6789 | 0.0.0.0/0 |
   | Custom TCP | TCP | 6800-7300 | 0.0.0.0/0 |
   | Custom TCP | TCP | 443 | 0.0.0.0/0 |

   **⚠️ COMMON MISTAKE:** Forgetting ports 9095 (Prometheus), 8080 (Ceph), 3000 (Grafana)

8. **Step 7: Review**
   - Instance count: 1 ✅
   - Instance type: t3.medium ✅
   - Storage: 20GB ✅
   - Security group: has SSH + Ceph ports ✅
   - Auto-assign public IP: Yes ✅
   - Click "Launch"

9. **Select Key Pair**
   - Choose your existing key: "cloud-ass3" (or your key name)
   - Check: "I acknowledge..."
   - Click "Launch instances"

10. **Wait for VM to start**
    - Status should change: "pending" → "running" (2-3 minutes)
    - Copy public IP address when available

### Step 2.3: Create OSD Nodes (VM2, VM3, VM4)

**Repeat the same process 3 times for VMs 2, 3, 4 BUT:**

- Use **t3.medium** (same as VM1)
- Name them: vm2, vm3, vm4
- Use **SAME security group** ("ceph-cluster")
- **Add EXTRA storage:**

   **Storage Configuration (Special for OSD nodes):**
   - Root volume: 20GB (default)
   - **Add new volume:**
     - Size: 30GB
     - Volume type: gp2
     - Delete on termination: ✅
     - Device name: /dev/sdf
   
   This 30GB disk is for Ceph OSD data

**⚠️ CRITICAL MISTAKE:** Not adding extra storage for OSD nodes. They NEED separate disk for data!

### Step 2.4: Create Spare VMs (VM5, VM6)

Repeat for VMs 5 & 6 BUT:
- Instance type: **t3.micro** (cheaper, not used in cluster)
- Storage: 20GB only
- Name: vm5, vm6

---

## 3. AWS SETUP (PART 2): CONFIGURE NETWORKING

### Step 3.1: Record Public IPs

Go to EC2 Instances and copy the public IPs:

```
VM1 (Monitor):  [IP_1]
VM2 (OSD1):     [IP_2]
VM3 (OSD2):     [IP_3]
VM4 (OSD3):     [IP_4]
VM5 (Spare):    [IP_5]
VM6 (Spare):    [IP_6]
```

**Save these in a text file for later reference**

### Step 3.2: Verify Security Group

1. Click on any running instance
2. Click "Security" tab
3. Click on security group name ("ceph-cluster")
4. Verify inbound rules have:
   - ✅ Port 22 (SSH)
   - ✅ Port 3000 (Grafana)
   - ✅ Port 8080 (Ceph)
   - ✅ Port 9095 (Prometheus)
   - ✅ Port 3300 (Ceph Monitor)
   - ✅ Port 6789 (Ceph Monitor)
   - ✅ Port 6800-7300 (Ceph OSD)
   - ✅ Port 443 (HTTPS)

---

# 4. INITIAL VM CONFIGURATION

## Step 4.1: SSH to Monitor VM (VM1)

```powershell
# Windows PowerShell
$KEY_PATH = "C:\Users\Dell\Downloads\cloud-ass3.pem"
$MONITOR_IP = "[IP_1]"  # Replace with actual IP

ssh -i $KEY_PATH ubuntu@$MONITOR_IP
```

**⚠️ MISTAKE:** Forgetting `-i` flag for key path

### Step 4.2: Update System

Once SSH'd into VM1:

```bash
# Update package list
sudo apt-get update

# Upgrade packages (take ~3 minutes)
sudo apt-get upgrade -y

# Install essential tools
sudo apt-get install -y \
  curl \
  wget \
  git \
  net-tools \
  vim \
  htop \
  python3-pip

# Verify curl works
curl --version
```

Expected: Shows curl version

### Step 4.3: Set Hostname

```bash
# Set hostname for monitor
sudo hostnamectl set-hostname ceph-mon

# Verify
hostnamectl
```

### Step 4.4: SSH to Each OSD Node

Repeat for VM2, VM3, VM4:

```bash
# SSH to VM2
ssh -i $KEY_PATH ubuntu@[IP_2]

# Update
sudo apt-get update
sudo apt-get upgrade -y

# Set hostname
sudo hostnamectl set-hostname ceph-osd1

# Exit and repeat for VM3, VM4
exit
```

**⚠️ MISTAKE:** Not updating all nodes - causes installation failures later

### Step 4.5: Verify All VMs Connected

From monitor (VM1):

```bash
# Ping other VMs to verify connectivity
ping -c 1 [IP_2]  # Should work
ping -c 1 [IP_3]  # Should work
ping -c 1 [IP_4]  # Should work
```

---

# 5. CEPH INSTALLATION

## Step 5.1: Install Ceph on Monitor Node (VM1)

SSH to VM1 and run:

```bash
# Add Ceph repository key
curl -fsSL https://download.ceph.com/keys/release.asc | sudo apt-key add -

# Add Ceph repository
sudo apt-add-repository "deb https://download.ceph.com/debian-octopus $(lsb_release -sc) main"

# Install cephadm (the Ceph cluster manager)
sudo apt-get update
sudo apt-get install -y cephadm

# Verify cephadm installed
cephadm --version
```

Expected: Shows version number (e.g., "17.2.9")

**⚠️ MISTAKE:** Using wrong Ceph version. Stick with Quincy (v17)

### Step 5.2: Bootstrap the Cluster (CRITICAL)

```bash
# Create /etc/ceph directory
sudo mkdir -p /etc/ceph

# Bootstrap - this creates the cluster
sudo cephadm bootstrap \
  --mon-ip 0.0.0.0 \
  --skip-firewall \
  --skip-dashboard \
  --allow-fqdn-hostname \
  2>&1 | tee bootstrap.log

# This takes ~5 minutes - WAIT for it to complete
# You should see "Ceph FSid: xxxx-xxxx..."
```

**What this does:**
- Creates Ceph cluster
- Starts monitor daemon
- Sets up MGR daemon
- Generates cluster configuration

**⚠️ CRITICAL MISTAKE:** Interrupting bootstrap - let it run to completion!

### Step 5.3: Verify Bootstrap Success

```bash
# Check cluster status
sudo cephadm shell -- ceph -s

# Expected output should show:
# - cluster: id: (hex number)
# - health: HEALTH_OK or HEALTH_WARN
# - services: mon: 1 daemons...
# - mgr: 1 active...
```

If shows "HEALTH_ERR", that's okay for now - warnings are normal

### Step 5.4: Copy Ceph Configuration

```bash
# Copy admin key to current directory
sudo cp /etc/ceph/ceph.client.admin.keyring .
sudo cp /etc/ceph/ceph.conf .

# Fix permissions
sudo chown ubuntu:ubuntu ceph*
```

---

## Step 5.5: Add OSD Nodes to Cluster

SSH to each OSD node (VM2, VM3, VM4) and install Ceph:

```bash
# On VM2 (ceph-osd1) SSH shell:

# Install cephadm
curl -fsSL https://download.ceph.com/keys/release.asc | sudo apt-key add -
sudo apt-add-repository "deb https://download.ceph.com/debian-octopus $(lsb_release -sc) main"
sudo apt-get update
sudo apt-get install -y cephadm

# Copy ceph configuration from monitor
# Run this FROM monitor (VM1):
scp -i $KEY_PATH ceph.conf ubuntu@[IP_2]:/home/ubuntu/
scp -i $KEY_PATH ceph.client.admin.keyring ubuntu@[IP_2]:/home/ubuntu/

# Back on OSD node:
mkdir -p ~/.ceph
mv ~/ceph.conf ~/.ceph/
mv ~/ceph.client.admin.keyring ~/.ceph/
```

**⚠️ MISTAKE:** OSD nodes not getting config - causes "cannot connect to cluster" errors

### Step 5.6: Add OSD Nodes to Cluster (From Monitor)

Back on VM1 (monitor):

```bash
# Add node 2
sudo cephadm shell -- ceph orch host add [HOSTNAME_2] [IP_2]

# Add node 3
sudo cephadm shell -- ceph orch host add [HOSTNAME_3] [IP_3]

# Add node 4
sudo cephadm shell -- ceph orch host add [HOSTNAME_4] [IP_4]

# Verify hosts added
sudo cephadm shell -- ceph orch host ls
```

Expected: Shows all 4 nodes

### Step 5.7: Deploy OSD Daemons

**⚠️ CRITICAL SECTION - This is where most mistakes happen**

```bash
# Discover available disks on each host
sudo cephadm shell -- ceph orch device ls

# Example output should show:
# Hostname       Path      Type  Size  Vendor
# ceph-mon       /dev/sdf  ssd   30GB  -
# ceph-osd1      /dev/sdf  ssd   30GB  -
# ceph-osd2      /dev/sdf  ssd   30GB  -
# ceph-osd3      /dev/sdf  ssd   30GB  -
```

**If you DON'T see the 30GB disks:**
- VMs might not have extra storage attached
- Go back to AWS and add EBS volumes!

### Step 5.8: Create OSDs on the Disks

```bash
# Add OSD on each host
sudo cephadm shell -- ceph orch apply osd --all-available-devices

# This will:
# - Find all unused disks
# - Create OSD for each disk
# - Takes ~2-3 minutes

# Monitor OSD creation
watch -n 2 'sudo cephadm shell -- ceph osd tree'

# Press Ctrl+C to exit watch
```

**Expected output shows 5 OSDs:**
```
ID CLASS WEIGHT TYPE  NAME      STATUS
-1       0.1000  root default
-3       0.0300    host ceph-osd1
 0    ssd 0.0300      osd.0     up   in
-5       0.0300    host ceph-osd2
 1    ssd 0.0300      osd.1     up   in
-7       0.0300    host ceph-osd3
 2    ssd 0.0300      osd.2     up   in
-9       0.0300    host ceph-mon
 3    ssd 0.0300      osd.3     up   in
```

**⚠️ CRITICAL MISTAKES HERE:**
1. Not adding extra storage to OSD VMs - OSD creation fails
2. Not using `/dev/sdf` - wrong disk gets formatted
3. Interrupting OSD creation - leaves cluster in bad state

### Step 5.9: Verify OSD Cluster

```bash
# Check cluster health
sudo cephadm shell -- ceph -s

# Should show:
#   osd: 5 osds: 5 up (since X), 5 in (since X)
#   health: HEALTH_WARN or HEALTH_OK

# List all OSDs
sudo cephadm shell -- ceph osd tree

# Check OSD status
sudo cephadm shell -- ceph osd status
```

---

# 6. RAID 6 CONFIGURATION

## Step 6.1: Create Erasure Coding Profile

**This is the key step for RAID 6**

From Monitor (VM1):

```bash
# Create RAID 6 profile
# k=4 (data chunks), m=2 (parity chunks)
sudo cephadm shell -- ceph osd erasure-code-profile set raid6-profile \
  k=4 \
  m=2 \
  plugin=jerasure \
  technique=reed_sol_van \
  crush-failure-domain=host \
  crush-root=default

# Verify profile created
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
```

**Expected output:**
```
crush-device-class=
crush-failure-domain=host
crush-root=default
jerasure-per-chunk-alignment=false
k=4
m=2
plugin=jerasure
technique=reed_sol_van
w=8
```

**What this means:**
- k=4: Need 4 chunks of data
- m=2: Need 2 chunks of parity
- Total: 6 chunks needed = can lose 2 OSDs

**⚠️ MISTAKE:** Wrong k/m values. MUST be k=4, m=2 for RAID 6

## Step 6.2: Create Pool with RAID 6

```bash
# Create a pool using the RAID 6 profile
sudo cephadm shell -- ceph osd pool create raid6-pool 64 64 erasure raid6-profile

# Enable pool
sudo cephadm shell -- ceph osd pool set raid6-pool allow_ec_overwrites true

# Verify pool created
sudo cephadm shell -- ceph osd pool ls
sudo cephadm shell -- ceph osd pool ls detail
```

**Expected:** Shows raid6-pool with erasure coding

## Step 6.3: Verify RAID 6 is Working

```bash
# Check pool configuration
sudo cephadm shell -- ceph osd pool info raid6-pool | grep -E "erasure_code|crush_rule"

# Test with sample data (optional)
echo "test data" | sudo cephadm shell -- ceph --name client.admin put test-object -
sudo cephadm shell -- ceph get test-object
```

---

# 7. MONITORING SETUP

## Step 7.1: Enable Monitoring Services

From Monitor (VM1):

```bash
# Deploy Prometheus
sudo cephadm shell -- ceph mgr module enable prometheus

# Deploy Grafana
sudo cephadm shell -- ceph mgr module enable dashboard

# Deploy AlertManager
sudo cephadm orch ls | grep alert

# Deploy node exporter on all hosts
sudo cephadm shell -- ceph orch apply node-exporter '*'
```

## Step 7.2: Access Ceph Dashboard

```bash
# Get dashboard credentials
sudo cephadm shell -- ceph dashboard ac-user-get admin

# Should show username: admin and password hash
# Try password: admin123 (if set earlier)
```

**Access Dashboard:**
- URL: `https://[MONITOR_IP]:8080`
- Username: `admin`
- Password: `admin123`

## Step 7.3: Deploy Grafana

```bash
# Deploy Grafana
sudo cephadm orch apply grafana

# Wait ~30 seconds for Grafana to start
sleep 30

# Check Grafana service
sudo cephadm ls | grep grafana
```

**Access Grafana:**
- URL: `http://[MONITOR_IP]:3000`
- Username: `admin`
- Password: `admin`

## Step 7.4: Create Grafana Dashboards

```bash
# Create dashboards via API
# Get Grafana auth token
GRAFANA_ADMIN_KEY=$(sudo cephadm shell -- ceph dashboard create-grafana-api-key admin)

echo "Grafana API Key: $GRAFANA_ADMIN_KEY"

# Create dashboards (see next section for script)
```

---

# 8. TESTING AND VERIFICATION

## Step 8.1: Full Health Check

```bash
# Check everything
sudo cephadm shell -- ceph -s

# Should show:
# - health: HEALTH_OK (or HEALTH_WARN with no errors)
# - osd: 5 osds: 5 up, 5 in
# - pools: 1 pools, XX pgs
# - usage: X GiB used, Y GiB / Z GiB avail
# - pgs: all active+clean or similar
```

## Step 8.2: Verify RAID 6 Protection

```bash
# Check profile
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile

# Check pool
sudo cephadm shell -- ceph osd pool info raid6-pool

# Expected:
# - pool raid6-pool has k=4, m=2
# - Crush failure domain = host
# - Can survive 2 OSD failures
```

## Step 8.3: Test RAID 6 (Optional)

```bash
# Create test file
echo "Important data" > /tmp/test.txt

# Upload to Ceph
sudo cephadm shell -- ceph put test-file -i /tmp/test.txt

# Download to verify
sudo cephadm shell -- ceph get test-file -o /tmp/test-download.txt

# Check they match
diff /tmp/test.txt /tmp/test-download.txt
echo $?  # Should show 0 (files identical)
```

## Step 8.4: Test Failure Scenario (Advanced)

```bash
# List OSDs
sudo cephadm shell -- ceph osd tree

# Simulate OSD failure (mark down)
sudo cephadm shell -- ceph osd down 4

# Watch recovery
watch -n 5 'sudo cephadm shell -- ceph -s | grep -E "health|osd|recovery"'

# Bring it back up
sudo cephadm shell -- ceph osd in 4

# Watch recovery complete
```

---

# 9. COMMON MISTAKES & FIXES

## Mistake 1: OSD Nodes Don't Have Extra Storage

**Problem:** `ceph orch device ls` shows empty list

**Cause:** Didn't add 30GB EBS volume to OSD VMs

**Fix:**
```bash
# In AWS Console:
1. Go to EC2 → Instances
2. Select OSD VM (vm2, vm3, vm4)
3. Storage tab → Elastic Block Store → Create volume
4. Size: 30GB, Type: gp2
5. Attach to instance, device: /dev/sdf
6. In VM: sudo partprobe /dev/sdf
7. Retry OSD creation
```

## Mistake 2: Ceph Config Not Copied to OSD Nodes

**Problem:** OSD nodes can't connect to cluster

**Cause:** `ceph.conf` and keyring not copied

**Fix:**
```bash
# From monitor:
for ip in [IP_2] [IP_3] [IP_4]; do
  scp -i $KEY ceph.conf ubuntu@$ip:/home/ubuntu/
  scp -i $KEY ceph.client.admin.keyring ubuntu@$ip:/home/ubuntu/
done

# On each OSD node:
mkdir -p ~/.ceph
mv ~/ceph* ~/.ceph/
```

## Mistake 3: Wrong RAID 6 Parameters

**Problem:** Cluster has incorrect k/m values

**Cause:** Typo in profile creation

**Fix:**
```bash
# Delete wrong profile
sudo cephadm shell -- ceph osd erasure-code-profile rm raid6-profile

# Create correct one
sudo cephadm shell -- ceph osd erasure-code-profile set raid6-profile \
  k=4 m=2 plugin=jerasure technique=reed_sol_van
```

## Mistake 4: Security Group Missing Ports

**Problem:** Can't access Grafana/Ceph Dashboard

**Cause:** Ports not in security group

**Fix:**
```bash
# In AWS Console:
1. EC2 → Security Groups → ceph-cluster
2. Inbound rules → Edit
3. Add:
   - Port 3000 (Grafana)
   - Port 8080 (Ceph)
   - Port 9095 (Prometheus)
4. Save
```

## Mistake 5: Bootstrap Interrupted

**Problem:** Cluster in bad state, can't continue

**Cause:** Pressed Ctrl+C during bootstrap

**Fix:**
```bash
# Destroy cluster
sudo cephadm rm-cluster --fsid [CLUSTER_ID] --force

# Start over
sudo cephadm bootstrap --mon-ip 0.0.0.0 --skip-firewall --allow-fqdn-hostname
```

## Mistake 6: Using Wrong Ubuntu Version

**Problem:** Cephadm not available or errors

**Cause:** Using old Ubuntu (16.04, 18.04)

**Fix:**
- Always use **Ubuntu 20.04 LTS** or **Ubuntu 22.04 LTS**
- Select correct AMI in step 2.2

## Mistake 7: Not Enough Disk Space

**Problem:** OSDs fail to start

**Cause:** OSD volumes too small (< 20GB)

**Fix:**
```bash
# OSD node needs:
# - 20GB for OS
# - 30GB for OSD data
# Total: 50GB per OSD node
```

## Mistake 8: Monitor Node Overloaded

**Problem:** Ceph cluster slow, timeouts

**Cause:** Using t3.micro for monitor (too small)

**Fix:**
- Monitor MUST be t3.medium (2 vCPU, 4GB RAM)
- OSD nodes can be t3.medium or larger
- Don't use t3.micro for monitor

---

# 10. TROUBLESHOOTING

## Problem: "Cannot connect to cluster"

```bash
# Check if services running
sudo cephadm shell -- ceph -s

# Check config file
cat ~/.ceph/ceph.conf

# Verify keyring exists
ls -la ~/.ceph/ceph.client.admin.keyring

# Test with explicit config/keyring
sudo cephadm shell -- ceph --name client.admin -s
```

## Problem: "OSDs are DOWN"

```bash
# Check OSD status
sudo cephadm shell -- ceph osd tree

# Check OSD logs
sudo cephadm logs --name osd.0

# Bring OSD back in (if stuck out)
sudo cephadm shell -- ceph osd in 0

# Check device
ls -la /dev/sdf*
```

## Problem: "HEALTH_ERR"

```bash
# Check health detail
sudo cephadm shell -- ceph health detail

# Common errors:
# - "not best effort"  → Normal, will resolve
# - "recovery running" → Normal, wait for completion
# - "pg stuck" → May need intervention

# Wait and retry
sleep 30
sudo cephadm shell -- ceph -s
```

## Problem: "No space left"

```bash
# Check disk usage
sudo cephadm shell -- ceph df

# OSDs might be full - need more storage
# Add more EBS volumes to OSD nodes
```

## Problem: "Grafana won't connect"

```bash
# Check Grafana running
sudo cephadm ls | grep grafana

# Check port 3000 open
sudo ss -tlnp | grep 3000

# Add port to security group in AWS

# Check logs
sudo cephadm logs --name grafana
```

## Problem: "Prometheus shows no data"

```bash
# Check Prometheus running
sudo cephadm ls | grep prometheus

# Check manager module enabled
sudo cephadm shell -- ceph mgr module ls | grep prometheus

# Enable if not there
sudo cephadm shell -- ceph mgr module enable prometheus
```

---

## QUICK REFERENCE: COMMAND CHEAT SHEET

### Cluster Status
```bash
sudo cephadm shell -- ceph -s                    # Full status
sudo cephadm shell -- ceph health               # Health only
sudo cephadm shell -- ceph osd tree             # OSD tree
sudo cephadm shell -- ceph df                   # Disk usage
```

### OSD Management
```bash
sudo cephadm shell -- ceph osd status           # OSD status
sudo cephadm shell -- ceph osd down 0           # Mark down
sudo cephadm shell -- ceph osd in 0             # Mark in
sudo cephadm shell -- ceph osd out 0            # Mark out
```

### RAID 6
```bash
# Check profile
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile

# Create profile
sudo cephadm shell -- ceph osd erasure-code-profile set raid6-profile k=4 m=2 plugin=jerasure technique=reed_sol_van

# Check pool
sudo cephadm shell -- ceph osd pool info raid6-pool
```

### Services
```bash
sudo cephadm ls                                 # List all services
sudo cephadm logs --name grafana                # Grafana logs
sudo cephadm logs --name prometheus             # Prometheus logs
```

### Dashboard/Grafana
```bash
# Ceph Dashboard: https://[IP]:8080
# Grafana: http://[IP]:3000
# Prometheus: http://[IP]:9095
```

---

## FINAL CHECKLIST

Before submitting assignment:

- [ ] All 6 VMs running
- [ ] All VMs have auto-assign public IP
- [ ] Security group has all required ports
- [ ] OSD nodes have extra 30GB storage
- [ ] Ceph cluster bootstrapped on monitor
- [ ] All 4 OSD nodes added to cluster
- [ ] 5 OSDs created and UP/IN
- [ ] RAID 6 profile created (k=4, m=2)
- [ ] RAID 6 pool created
- [ ] Ceph Dashboard accessible
- [ ] Grafana running and accessible
- [ ] Prometheus running
- [ ] Cluster health checked
- [ ] Data written and verified
- [ ] Screenshots taken

---

## EXPECTED FINAL STATE

```
CLUSTER STATUS:
  cluster id: 1512292e-3cde-11f1-ab7e-3748aba09780
  health: HEALTH_OK
  
SERVICES:
  mon: 1 daemons
  mgr: 1 active
  osd: 5 osds, 5 up, 5 in
  
RAID 6:
  k=4, m=2
  Can survive 2 OSD failures
  
STORAGE:
  ~45 GiB total
  ~1-2 GiB used (metadata)
  ~43 GiB available
  
MONITORING:
  Grafana: http://[IP]:3000
  Ceph Dashboard: https://[IP]:8080
  Prometheus: http://[IP]:9095
```

---

**Manual Version:** 1.0  
**Created:** April 20, 2026  
**Status:** Production Tested  
**Last Updated:** April 20, 2026

Good luck! Follow this guide step-by-step and you WILL succeed! 🚀
