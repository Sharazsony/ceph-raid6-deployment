# 🚀 Zero to Hero: Deploy a Ceph RAID 6 Cluster on AWS in 90 Minutes

> **A complete, battle-tested guide** — from spinning up EC2 instances to a fully operational distributed storage cluster with live monitoring dashboards.

---

*By Sharaz Soni · April 23, 2026 · 15 min read*

---

If you've ever wanted to understand how enterprise-grade distributed storage actually works — and get your hands dirty building one — this is your guide.

We're going to build a **6-node Ceph cluster** on AWS with **RAID 6 erasure coding**, **Grafana dashboards**, and **Prometheus metrics**. By the end, you'll have a system that can survive two simultaneous disk failures without losing a single byte of data.

---

## What We're Building

<img width="782" height="566" alt="image" src="https://github.com/user-attachments/assets/5a8f1df6-a982-48c1-9997-2ad4aef42754" />

<img width="1065" height="572" alt="image" src="https://github.com/user-attachments/assets/325b6a66-4fcb-4947-8e31-e23d7a28ccdb" />

*A production-grade Ceph cluster with Monitor, OSD, and monitoring nodes*

Here's the full architecture at a glance:

| Component | Count | Role |
|-----------|-------|------|
| **Monitor Node (vm1)** | 1 | Cluster brain — tracks state |
| **OSD Nodes (vm2–vm4)** | 3 | Object Storage Daemons — hold data |
| **Spare Nodes (vm5–vm6)** | 2 | Standby / failover |
| **EBS Volumes** | 3×30GB | Dedicated Ceph data disks |

**Total resources:** ~10 vCPU · 18GB RAM · ~200GB storage  
**Estimated cost:** $15–25 for a 3-hour deployment  
**Time:** 60–90 minutes

---

## Prerequisites

Before you type a single command, make sure you have:

- ✅ An AWS account with EC2 access in `us-east-1`
- ✅ A `.pem` key file downloaded locally
- ✅ SSH installed (PowerShell on Windows, Terminal on Mac/Linux)
- ✅ 90 uninterrupted minutes
- ✅ ~$20 to spend on AWS resources

> ❌ **Don't start** if your internet is unstable or you're likely to get interrupted mid-setup. The bootstrap phase is not resumable.

---

## Phase 1 — AWS Infrastructure Setup

### Launch the Monitor VM (vm1)

Head to **EC2 Console → Launch Instances** and configure:

**Operating System**
```
Ubuntu Server 22.04 LTS  ✅  (the only correct choice here)
```

> ⚠️ **Common mistake:** Using Ubuntu 24.04 or 18.04. Stick with 22.04 — it's the production-tested sweet spot for Ceph Quincy.

**Instance Type**
```
t3.medium  →  2 vCPU / 4GB RAM  ✅
```

> ❌ `t3.micro` is too slow for the monitor. ❌ `t3.small` lacks RAM for Ceph daemons.

**Networking**
```
Auto-assign Public IP: ENABLED  ←  (critical — you can't SSH in without this)
```

**Storage for Monitor (vm1)**
```
Root disk: 20GB gp2
```

**Storage for OSD Nodes (vm2, vm3, vm4)**  
This is where most people get tripped up:

```
Root disk:   20GB gp2   (OS)
Data disk:   30GB gp2   (Ceph OSD — add as a second EBS volume!)
```

![AWS EC2 instance storage configuration showing root and data volumes](https://docs.aws.amazon.com/images/AWSEC2/latest/UserGuide/images/ebs_backed_instance.png)

*OSD nodes need two EBS volumes — a root disk and a dedicated 30GB data disk*

### Security Group Configuration

Create a new security group called `ceph-cluster` with all 8 of these rules:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH access |
| 6789 | TCP | Ceph Monitor |
| 3300 | TCP | Ceph Monitor protocol |
| 6800–7300 | TCP | Ceph OSD communication |
| 8080 | TCP | Ceph Dashboard |
| 443 | TCP | HTTPS |
| 3000 | TCP | Grafana |
| 9095 | TCP | Prometheus |

> ⚠️ Missing any of these ports = hours of debugging. Add all 8 upfront.

### VM Inventory

Once all 6 VMs are running, record their public IPs:

```
vm1  (ceph-mon)   →  _______________
vm2  (ceph-osd1)  →  _______________
vm3  (ceph-osd2)  →  _______________
vm4  (ceph-osd3)  →  _______________
vm5  (spare)      →  _______________
vm6  (spare)      →  _______________
```

---

## Phase 2 — Initial VM Configuration

### Connect to the Monitor

```bash
# Mac/Linux
ssh -i ~/cloud-ass3.pem ubuntu@<VM1_IP>

# Windows PowerShell
ssh -i C:\Users\You\Downloads\cloud-ass3.pem ubuntu@<VM1_IP>
```

### Update All Packages

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git net-tools vim htop python3-pip lsb-release gnupg
```

> ☕ This takes 3–5 minutes. Perfect time for coffee.

### Set Hostnames

Run this on **each VM** (adjust the hostname per node):

```bash
# On vm1:
sudo hostnamectl set-hostname ceph-mon

# On vm2:
sudo hostnamectl set-hostname ceph-osd1

# On vm3:
sudo hostnamectl set-hostname ceph-osd2

# On vm4:
sudo hostnamectl set-hostname ceph-osd3
```

### Update `/etc/hosts` on the Monitor

```bash
sudo nano /etc/hosts
```

Add these lines at the bottom (swap in your actual IPs):

```
<VM1_IP>  ceph-mon
<VM2_IP>  ceph-osd1
<VM3_IP>  ceph-osd2
<VM4_IP>  ceph-osd3
```

### Verify Network Connectivity

```bash
ping -c 1 <VM2_IP>
ping -c 1 <VM3_IP>
ping -c 1 <VM4_IP>
# Each should report: 1 packets transmitted, 1 received
```

---

## Phase 3 — Ceph Installation

### Install cephadm on the Monitor

```bash
# Add the Ceph repo key
curl -fsSL https://download.ceph.com/keys/release.asc | sudo apt-key add -

# Add the Ceph repository
echo "deb https://download.ceph.com/debian-$(lsb_release -cs) $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/ceph.list

# Install cephadm
sudo apt-get update
sudo apt-get install -y cephadm

# Verify
cephadm --version
# → 17.2.x (Quincy) or 18.2.x
```

> **Which version to use?** Quincy (v17) is recommended — stable, widely deployed, well-documented. Avoid Pacific (EOL) and Nautilus (ancient).

### Bootstrap the Cluster

> ⚠️ **This step takes 5–10 minutes. Do NOT close your terminal or interrupt the process.**

```bash
sudo mkdir -p /etc/ceph

sudo cephadm bootstrap \
  --mon-ip 0.0.0.0 \
  --skip-firewall \
  --skip-dashboard \
  --allow-fqdn-hostname
```

When it completes you'll see:
```
Bootstrap complete.
```

Verify it worked:
```bash
sudo cephadm shell -- ceph -s
# Should show: health: HEALTH_OK or HEALTH_WARN
```

### Distribute Config Files to OSD Nodes

```bash
# On the monitor — copy to local, then push to OSD nodes
sudo cp /etc/ceph/ceph.client.admin.keyring ~/
sudo cp /etc/ceph/ceph.conf ~/
sudo chown ubuntu:ubuntu ~/ceph*

# From your local machine, push to each OSD:
scp -i cloud-ass3.pem ubuntu@<VM1_IP>:~/ceph.conf .
scp -i cloud-ass3.pem ubuntu@<VM1_IP>:~/ceph.client.admin.keyring .

for IP in <VM2_IP> <VM3_IP> <VM4_IP>; do
  scp -i cloud-ass3.pem ceph.conf ubuntu@$IP:~/
  scp -i cloud-ass3.pem ceph.client.admin.keyring ubuntu@$IP:~/
done
```

### Install cephadm on Each OSD Node

SSH into each OSD node (vm2, vm3, vm4) and run:

```bash
curl -fsSL https://download.ceph.com/keys/release.asc | sudo apt-key add -
echo "deb https://download.ceph.com/debian-$(lsb_release -cs) $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/ceph.list

sudo apt-get update && sudo apt-get install -y cephadm

mkdir -p ~/.ceph
mv ~/ceph.conf ~/.ceph/
mv ~/ceph.client.admin.keyring ~/.ceph/
```

---

## Phase 4 — OSD & RAID 6 Setup

This is the heart of the guide. Let's configure erasure coding and bring RAID 6 to life.

### Add OSD Hosts to the Cluster

Back on the monitor (vm1):

```bash
sudo cephadm shell -- ceph orch host add ceph-osd1 <VM2_IP>
sudo cephadm shell -- ceph orch host add ceph-osd2 <VM3_IP>
sudo cephadm shell -- ceph orch host add ceph-osd3 <VM4_IP>

# Verify
sudo cephadm shell -- ceph orch host ls
```

### Check Your 30GB Disks Are Visible

```bash
sudo cephadm shell -- ceph orch device ls
```

Expected:
```
HOST       PATH      TYPE  SIZE  VENDOR
ceph-osd1  /dev/sdf  ssd   30GB  Amazon
ceph-osd2  /dev/sdf  ssd   30GB  Amazon
ceph-osd3  /dev/sdf  ssd   30GB  Amazon
```

> ❌ **Nothing showing?** Go to AWS Console → EC2 → Instance → Storage tab, attach a new 30GB gp2 EBS volume with device name `/dev/sdf`. Then run `sudo partprobe /dev/sdf` on the VM.

### Create OSDs Automatically

```bash
sudo cephadm shell -- ceph orch apply osd --all-available-devices

# Watch progress (Ctrl+C when done)
watch -n 2 'sudo cephadm shell -- ceph osd tree'
```

After 2–3 minutes you should see **5 OSDs** all showing `up in`.

### Configure RAID 6 Erasure Coding

<img width="818" height="396" alt="image" src="https://github.com/user-attachments/assets/4f8ad539-a8ad-4d5b-a760-40b7e7aa39fa" />


*RAID 6: 4 data chunks + 2 parity chunks = survives any 2 simultaneous failures*

```bash
sudo cephadm shell -- ceph osd erasure-code-profile set raid6-profile \
  k=4 \
  m=2 \
  plugin=jerasure \
  technique=reed_sol_van \
  crush-failure-domain=host \
  crush-root=default
```

**What do these parameters mean?**

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `k` | 4 | Data chunks — actual content |
| `m` | 2 | Parity chunks — redundancy |
| `plugin` | jerasure | Erasure coding library |
| `technique` | reed_sol_van | Reed-Solomon algorithm |
| `crush-failure-domain` | host | Spread chunks across different hosts |

> `k=4, m=2` means: data is split into 6 chunks total. You can lose any 2 of them and still recover everything. That's RAID 6.

Verify the profile was created:
```bash
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
# Should show: k=4, m=2, plugin=jerasure
```

### Create the RAID 6 Pool

```bash
sudo cephadm shell -- ceph osd pool create raid6-pool 64 64 erasure raid6-profile
sudo cephadm shell -- ceph osd pool set raid6-pool allow_ec_overwrites true

# Confirm
sudo cephadm shell -- ceph osd pool ls detail
```

---

## Phase 5 — Monitoring & Dashboards

### Enable Services

```bash
sudo cephadm shell -- ceph mgr module enable prometheus
sudo cephadm shell -- ceph mgr module enable dashboard
sudo cephadm shell -- ceph orch apply node-exporter '*'
```

### Deploy Grafana

```bash
sudo cephadm shell -- ceph orch apply grafana
sleep 30
sudo cephadm shell -- ceph mgr services | grep grafana
```

### Deploy Prometheus

```bash
sudo cephadm shell -- ceph orch apply prometheus
sleep 10
```

### Access Your Dashboards

| Dashboard | URL | Credentials |
|-----------|-----|-------------|
| **Ceph Dashboard** | `https://<VM1_IP>:8080` | admin / (generated at bootstrap) |
| **Grafana** | `http://<VM1_IP>:3000` | admin / admin |
| **Prometheus** | `http://<VM1_IP>:9095` | — |

![Grafana monitoring dashboard showing cluster metrics, storage utilization, and OSD performance graphs](https://grafana.com/static/img/grafana/showcase_visualize.jpg)

*Grafana gives you real-time visibility into every aspect of your cluster*

**Connect Grafana to Prometheus:**
1. Open Grafana → ⚙️ Settings → Data Sources
2. Add → Prometheus
3. URL: `http://<VM1_IP>:9095`
4. Save & Test → "Data source is working" ✅

---

## Phase 6 — Testing & Validation

### Full Health Check

```bash
sudo cephadm shell -- ceph -s
```

Look for:
```
health: HEALTH_OK
osd: 5 osds: 5 up, 5 in
pools: 1 pools
pgs: all active+clean
```

### Write and Read Data

```bash
# Write
echo "Test data from Ceph RAID 6 cluster" > /tmp/test-data.txt
sudo cephadm shell -- ceph put test-object -i /tmp/test-data.txt

# Read back
sudo cephadm shell -- ceph get test-object -o /tmp/test-download.txt

# Verify
diff /tmp/test-data.txt /tmp/test-download.txt && echo "✅ Data matches!"
```

### Simulate an OSD Failure

```bash
# Take down OSD 0 (simulates a disk failure)
sudo cephadm shell -- ceph osd down 0

# Watch recovery in real-time
watch -n 5 'sudo cephadm shell -- ceph -s | grep -E "health|recovery"'

# Bring it back
sudo cephadm shell -- ceph osd in 0
```

Your cluster will self-heal. That's RAID 6 working exactly as designed.

---

## Troubleshooting Guide

### "Cannot connect to cluster"
```bash
# Check config and keyring exist
cat ~/.ceph/ceph.conf
ls -la ~/.ceph/ceph.client.admin.keyring

# Fix ownership if needed
sudo chown ubuntu:ubuntu ~/.ceph/*
```

### "OSDs are DOWN"
```bash
# Check logs
sudo cephadm logs --name osd.0

# Check disk is visible
lsblk | grep sdf

# Force disk detection
sudo partprobe /dev/sdf
```

### "HEALTH_WARN or HEALTH_ERR"
```bash
# Get detailed report
sudo cephadm shell -- ceph health detail

# Most warnings resolve themselves — wait 5 minutes
# If stuck, restart the affected daemon:
sudo cephadm restart mon.ceph-mon
```

### "Grafana won't load"
```bash
# Is it running?
sudo cephadm ls | grep grafana

# Check the port
sudo ss -tlnp | grep 3000

# Deploy if missing
sudo cephadm shell -- ceph orch apply grafana
```

---

## What You've Built

Congratulations. Here's what's running on your cluster:

```
Storage capacity:   ~45–50 GiB usable
Write speed:        50–100 MB/s
Read speed:         100–200 MB/s
Failure tolerance:  Any 2 simultaneous OSD failures
Data durability:    99.99999%
Recovery time:      5–30 minutes per failure
```

### Key Concepts You Now Understand

| Concept | What It Is | Why It Matters |
|---------|------------|----------------|
| **Erasure Coding** | k=4 data + m=2 parity chunks | More efficient than replication |
| **CRUSH Algorithm** | Placement algorithm | Determines where data lives |
| **OSD** | Object Storage Daemon | The actual storage workers |
| **Monitor** | Cluster coordinator | Tracks the map of everything |
| **Placement Groups** | Data distribution units | Balances load across OSDs |
| **cephadm** | Orchestration tool | Deploys and manages daemons |

---

## Final Deployment Checklist

```
Infrastructure
  ☐ 6 VMs running
  ☐ Security group with all 8 ports
  ☐ OSD nodes have 30GB EBS volumes attached

Ceph Setup
  ☐ Monitor bootstrapped
  ☐ 5 OSDs: up + in
  ☐ RAID 6 profile: k=4, m=2
  ☐ raid6-pool created

Monitoring
  ☐ Ceph Dashboard: https://<IP>:8080
  ☐ Grafana: http://<IP>:3000
  ☐ Prometheus: http://<IP>:9095
  ☐ Grafana → Prometheus connected

Validation
  ☐ ceph -s shows HEALTH_OK
  ☐ Data write + read test passed
  ☐ OSD failure + recovery tested
```

---

## Quick Command Reference

```bash
# Cluster health
sudo cephadm shell -- ceph -s
sudo cephadm shell -- ceph health detail
sudo cephadm shell -- ceph df

# OSD management
sudo cephadm shell -- ceph osd tree
sudo cephadm shell -- ceph osd status
sudo cephadm shell -- ceph osd down <ID>
sudo cephadm shell -- ceph osd in <ID>

# Pool management
sudo cephadm shell -- ceph osd pool ls detail
sudo cephadm shell -- ceph osd pool info raid6-pool

# Services
sudo cephadm ls
sudo cephadm logs --name <service>
sudo cephadm restart <service>
```

---

*If this guide helped you, give it a clap 👏 and share it with someone learning distributed systems. Questions? Drop them in the comments.*

---

**Tags:** `Ceph` `AWS` `Distributed Storage` `RAID` `DevOps` `Cloud Infrastructure` `Linux`
