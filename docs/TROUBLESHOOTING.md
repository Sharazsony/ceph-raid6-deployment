# Comprehensive Troubleshooting Guide

**Solutions to 99% of Ceph RAID 6 deployment issues**

---

## 🔧 Quick Fix Index

| Issue | Symptom | Fix Time | Go To |
|-------|---------|----------|-------|
| **No 30GB disks** | `ceph orch device ls` empty | 5 min | [Section 1](#1-no-30gb-disks-showing) |
| **Cannot SSH** | "Permission denied" | 3 min | [Section 2](#2-cannot-ssh-to-vms) |
| **OSDs DOWN** | All OSDs show DOWN | 10 min | [Section 3](#3-osds-are-down) |
| **HEALTH_ERR** | Cluster shows errors | 5 min | [Section 4](#4-health_err-or-health_warn) |
| **Grafana offline** | Can't access :3000 | 5 min | [Section 5](#5-grafana-wont-connect) |
| **No cluster** | Can't run ceph -s | 10 min | [Section 6](#6-cannot-connect-to-cluster) |
| **OSD fails** | OSD creation hangs | 10 min | [Section 7](#7-osd-creation-fails) |
| **Network error** | VMs can't communicate | 5 min | [Section 8](#8-network-and-connectivity) |

---

## 1. No 30GB Disks Showing

### Symptom
```bash
$ sudo cephadm shell -- ceph orch device ls

Scanning disks: (empty, no devices found)
# OR shows only 20GB disk
```

### Diagnosis Checklist

```bash
# Step 1: Check what disks are visible
lsblk
# Should show /dev/sdf (30GB)

# Step 2: Check device list
sudo cephadm shell -- ceph orch device ls --refresh

# Step 3: Check if disk is formatted
sudo fdisk -l /dev/sdf
# Should show device size

# Step 4: Go to AWS and verify
# EC2 → Instance → Storage tab → Check EBS volumes
```

### Solution

#### Option A: Disk Not Attached in AWS

```bash
# AWS Console:
1. EC2 → Instances → Select OSD VM (vm2, vm3, or vm4)
2. Click "Storage" tab
3. Click "Create volume" (if not visible)
4. Configuration:
   ├─ Size: 30 GB (EXACTLY 30)
   ├─ Type: gp2
   ├─ Availability Zone: Same as instance
   └─ Encrypted: No
5. Click "Create volume"
6. Wait for state "available"
7. Right-click volume → "Attach to instances"
8. Select your OSD VM
9. Device name: /dev/sdf ✅ CRITICAL
10. Click "Attach volume"

# Inside VM, refresh disk detection:
ssh -i cloud-ass3.pem ubuntu@[OSD_IP]
sudo partprobe /dev/sdf

# Verify:
lsblk
# Should show /dev/sdf with 30G size
```

#### Option B: Disk Attached but Not Detected

```bash
# Inside OSD VM:

# Force disk rescan
sudo partprobe /dev/sdf
sudo udevadm settle

# Try Ceph refresh
ssh -i cloud-ass3.pem ubuntu@[MONITOR_IP]
sudo cephadm shell -- ceph orch device ls --refresh

# If still not showing, try:
sudo cephadm shell -- ceph orch device zap [HOST] /dev/sdf
# Wait 30 seconds
sudo cephadm shell -- ceph orch device ls --refresh
```

#### Option C: Wrong Device Name

```bash
# Check what disks are available
sudo fdisk -l

# If /dev/sdf doesn't exist but /dev/nvme0n1 does:
# AWS might be using NVMe naming

# Check Ceph device list
sudo cephadm shell -- ceph orch device ls

# If showing /dev/nvme0n1:
# This is normal for newer instance types
# Proceed with OSD creation - it will use the right device
```

---

## 2. Cannot SSH to VMs

### Symptom
```
ssh: Could not resolve hostname
ssh: connect to host [IP] port 22: Connection refused
Permission denied (publickey).
```

### Diagnosis

```powershell
# Windows PowerShell

# Check 1: Key file exists
Test-Path "C:\Users\Dell\Downloads\cloud-ass3.pem"
# Should return True

# Check 2: IP address is valid
[System.Net.Dns]::GetHostByName("[YOUR_IP]") | Select-Object HostName
# Should resolve

# Check 3: Network connectivity
ping [YOUR_IP]
# Should respond (or at least connect attempts)

# Check 4: SSH client works
ssh -V
# Should show OpenSSH version
```

### Solutions

#### Problem: "Permission denied (publickey)"

```powershell
# Windows: Verify key permissions
icacls "C:\Users\Dell\Downloads\cloud-ass3.pem"
# Should show: only your user can read

# Reset permissions if needed:
icacls "C:\Users\Dell\Downloads\cloud-ass3.pem" /inheritance:r
icacls "C:\Users\Dell\Downloads\cloud-ass3.pem" /grant:r "$($env:USERNAME):(F)"

# Try SSH again with full path
ssh -i "C:\Users\Dell\Downloads\cloud-ass3.pem" ubuntu@[YOUR_IP]
```

#### Problem: "Connection refused"

```bash
# Check 1: VM is running
# AWS Console → EC2 → Instances
# Should show: "running" status

# Check 2: Public IP is assigned
# If "Public IPv4 address" shows "—"
# Edit → Instance Settings → Modify Instance Attribute
# Auto-assign Public IP: Enable
# Reboot VM

# Check 3: Security group allows SSH
# AWS Console → EC2 → Security Groups → ceph-cluster
# Inbound rules → Should have:
#   Protocol: TCP
#   Port: 22
#   Source: 0.0.0.0/0

# Check 4: Wait for VM to fully boot
# VMs take 1-2 minutes to fully start
# Try again after waiting
```

#### Problem: "Could not resolve hostname"

```bash
# You're using a hostname instead of IP
# WRONG:
ssh -i key.pem ubuntu@ec2-12-345-678-90.compute-1.amazonaws.com

# CORRECT:
ssh -i key.pem ubuntu@12.345.678.90

# Or use full AWS hostname:
ssh -i key.pem ubuntu@ec2-12-345-678-90.compute-1.amazonaws.com

# Make sure DNS can resolve it
nslookup ec2-12-345-678-90.compute-1.amazonaws.com
```

---

## 3. OSDs Are DOWN

### Symptom
```bash
$ sudo cephadm shell -- ceph osd tree

ID CLASS WEIGHT TYPE NAME        STATUS
-1       0.1200 root default
 0    ssd 0.0300  osd.0        down  out  ← DOWN!
 1    ssd 0.0300  osd.1        down  out  ← DOWN!
```

### Diagnosis

```bash
# Inside OSD VM, check OSD processes
sudo systemctl status ceph-osd@*

# Check OSD logs
sudo cephadm logs --name osd.0 | tail -50

# Check if disk is mounted
df -h | grep sdf
# Should show mounted filesystem

# Check if disk has space
sudo cephadm shell -- ceph df
# Check "avail" column
```

### Solutions

#### Solution 1: Disk Not Mounted

```bash
# Inside OSD VM:

# Check partition
sudo lsblk

# If /dev/sdf has no partition:
sudo fdisk /dev/sdf
# n (new partition)
# p (primary)
# 1 (partition 1)
# Enter, Enter (default size)
# w (write)

# Format
sudo mkfs.ext4 /dev/sdf1

# Mount
sudo mount /dev/sdf1 /mnt/osd
```

#### Solution 2: OSD Daemon Crashed

```bash
# On Monitor VM:

# Bring OSD in
sudo cephadm shell -- ceph osd in 0

# Check again
sudo cephadm shell -- ceph osd tree

# If still down, restart OSD daemon
ssh -i key.pem ubuntu@[OSD_IP]
sudo systemctl restart ceph-osd@0

# Verify from monitor
sudo cephadm shell -- ceph -s
```

#### Solution 3: Device Issues

```bash
# Inside OSD VM:

# Check device health
sudo smartctl -a /dev/sdf
# Look for "PASSED" or failures

# Try reinitializing OSD
sudo cephadm shell -- ceph-disk --help

# Or from monitor, zap and recreate:
sudo cephadm shell -- ceph orch device zap [HOST] /dev/sdf
wait 30 seconds
sudo cephadm shell -- ceph orch apply osd --all-available-devices
```

---

## 4. HEALTH_ERR or HEALTH_WARN

### Symptom
```bash
$ sudo cephadm shell -- ceph -s

health: HEALTH_ERR  ← Shows error

$ sudo cephadm shell -- ceph health detail
HEALTH_ERR: PG_AVAILABILITY
  [ERR PG_AVAILABILITY] 1 pg degraded
  ...more errors...
```

### Common Errors & Fixes

#### Error: "pg stuck stale"

```bash
# DIAGNOSIS
sudo cephadm shell -- ceph health detail | grep "pg stuck"

# FIX: Usually resolves itself
# Wait 2-5 minutes
sleep 120
sudo cephadm shell -- ceph -s

# If still stuck, force recovery:
sudo cephadm shell -- ceph pg dump_stuck stale

# Or restart monitor:
sudo cephadm shell -- ceph mon stat
sudo cephadm restart mon.[name]
```

#### Error: "recovery running"

```bash
# DIAGNOSIS
sudo cephadm shell -- ceph health detail | grep recovery

# This is NORMAL! Ceph is recovering
# WAIT for recovery to complete
watch -n 10 'sudo cephadm shell -- ceph -s | grep -E "recovery|health"'

# Can take 5-30 minutes depending on data size
```

#### Error: "low osd" or "not best effort"

```bash
# DIAGNOSIS
sudo cephadm shell -- ceph health detail

# FIX: These are warnings, not critical errors
# Usually resolve themselves after 1-2 cluster operations

# If persistent:
sudo cephadm shell -- ceph mgr module disable mon_status_check
sudo cephadm shell -- ceph mgr module enable mon_status_check

# Or update thresholds:
sudo cephadm shell -- ceph config set osd osd_backfill_full_ratio 0.95
```

#### Error: "insufficient standby MONs"

```bash
# DIAGNOSIS
sudo cephadm shell -- ceph health detail

# FIX: This is normal for single-monitor setup
# To add standby:
sudo cephadm shell -- ceph orch apply mon "ceph-mon:5"
# Changes number of monitors

# Or just ignore this warning (it's not critical)
```

---

## 5. Grafana Won't Connect

### Symptom
```
Cannot reach http://[IP]:3000
Connection refused or timeout
Grafana not loading
```

### Diagnosis

```bash
# Check 1: Grafana running
sudo cephadm ls | grep grafana

# Check 2: Port open
sudo ss -tlnp | grep 3000
# Should show port 3000 listening

# Check 3: Security group
# AWS Console → Security Groups → ceph-cluster
# Inbound rules → Port 3000 should be present

# Check 4: Network connectivity
# From your computer:
ping [MONITOR_IP]
# Should work
```

### Solutions

#### Solution 1: Grafana Not Running

```bash
# Deploy Grafana
ssh -i key.pem ubuntu@[MONITOR_IP]
sudo cephadm shell -- ceph orch apply grafana

# Wait for startup
sleep 30

# Verify
sudo cephadm ls | grep grafana
# Should show "grafana" service

# Check logs
sudo cephadm logs --name grafana | tail -20
```

#### Solution 2: Port Not in Security Group

```bash
# AWS Console:
1. EC2 → Security Groups
2. Select "ceph-cluster"
3. "Inbound rules" tab
4. "Edit inbound rules"
5. "Add rule"
6. Type: Custom TCP
7. Protocol: TCP
8. Port: 3000
9. Source: 0.0.0.0/0
10. Save

# Wait 30 seconds and try accessing Grafana again
```

#### Solution 3: Port Blocked Locally

```bash
# Windows Firewall might be blocking

# PowerShell (as Administrator):
New-NetFirewallRule -DisplayName "Grafana" `
  -Direction Outbound -Action Allow -RemotePort 3000

# Mac/Linux: Usually no firewall blocks outbound HTTPS
```

---

## 6. Cannot Connect to Cluster

### Symptom
```
Error: couldn't resolve mon
ECONNREFUSED: Cannot connect to cluster
ceph daemon connection failed
```

### Diagnosis

```bash
# Check 1: Cluster exists
sudo cephadm shell -- ceph -s

# Check 2: Config file
cat ~/.ceph/ceph.conf
# Should have [global], [client.admin], [mon], etc.

# Check 3: Keyring exists
ls -la ~/.ceph/ceph.client.admin.keyring
# Should exist with right permissions

# Check 4: Monitor running
sudo cephadm shell -- ceph mon stat
```

### Solutions

#### Solution 1: Config File Missing or Wrong

```bash
# Copy config from monitor
ssh -i key.pem ubuntu@[MONITOR_IP]
scp -i key.pem ubuntu@[MONITOR_IP]:~/ceph.conf ~/.ceph/

# Verify content
cat ~/.ceph/ceph.conf
# Should have [global] section with monitors

# Set permissions
sudo chown ubuntu:ubuntu ~/.ceph/ceph.conf
chmod 644 ~/.ceph/ceph.conf
```

#### Solution 2: Keyring Missing or Wrong

```bash
# Copy keyring from monitor
scp -i key.pem ubuntu@[MONITOR_IP]:~/ceph.client.admin.keyring ~/.ceph/

# Set permissions
sudo chown ubuntu:ubuntu ~/.ceph/ceph.client.admin.keyring
chmod 600 ~/.ceph/ceph.client.admin.keyring

# Test
sudo cephadm shell -- ceph -s
```

#### Solution 3: Monitor Not Running

```bash
# On monitor VM:
sudo systemctl status ceph-mon@*

# If stopped:
sudo systemctl start ceph-mon@ceph-mon
sudo systemctl status ceph-mon@*

# Check monitor status
sudo cephadm shell -- ceph mon stat
```

---

## 7. OSD Creation Fails

### Symptom
```bash
$ sudo cephadm shell -- ceph orch apply osd --all-available-devices
osd.0 creation failed
[error] OSD creation error
```

### Diagnosis

```bash
# Check available devices
sudo cephadm shell -- ceph orch device ls

# Check OSD status
sudo cephadm shell -- ceph osd tree

# Check orchestrator events
sudo cephadm shell -- ceph orch ps | grep osd

# Check logs
sudo cephadm logs --name osd.0 2>&1 | tail -50
```

### Solutions

#### Solution 1: Device Already in Use

```bash
# Zap the device first (CAREFUL - deletes data!)
sudo cephadm shell -- ceph orch device zap [HOSTNAME] /dev/sdf

# Wait 30 seconds
sleep 30

# Try OSD creation again
sudo cephadm shell -- ceph orch apply osd --all-available-devices
```

#### Solution 2: Device Not Ready

```bash
# Ensure device is visible
sudo cephadm shell -- ceph orch device ls --refresh

# If /dev/sdf not showing:
# See Section 1: No 30GB Disks
```

#### Solution 3: Not Enough Space

```bash
# Check available space on each node
df -h

# OSD needs at least 5GB free on root
# If low:
1. Clean up temporary files: sudo apt-get clean
2. Delete unused packages: sudo apt-get autoremove
3. Check disk usage: du -sh /*
4. Retry OSD creation
```

---

## 8. Network and Connectivity

### Symptom
```
Cluster nodes can't communicate
Monitor can't reach OSD nodes
Cluster formation fails
```

### Diagnosis

```bash
# From monitor, test connectivity to each OSD:
ping -c 1 [OSD1_IP]
ping -c 1 [OSD2_IP]
ping -c 1 [OSD3_IP]

# Test specific ports
telnet [OSD_IP] 6789  # Ceph monitor port
telnet [OSD_IP] 6800  # Ceph OSD port

# Check network on OSD node
ip addr show
route -n
```

### Solutions

#### Solution 1: Wrong IP Addresses

```bash
# Verify IPs in /etc/hosts
cat /etc/hosts

# Should show:
# [VM1_IP] ceph-mon
# [VM2_IP] ceph-osd1
# etc.

# Update if wrong:
sudo nano /etc/hosts
# Fix IPs and save
```

#### Solution 2: Security Group Missing Ports

```bash
# AWS Console:
1. EC2 → Security Groups → ceph-cluster
2. Inbound rules should have:
   ├─ Port 22 (SSH)
   ├─ Port 6789 (Ceph Monitor)
   ├─ Port 6800-7300 (Ceph OSD)
   ├─ Port 3300 (Ceph Monitor protocol)
   └─ Port 3000, 8080, 9095 (Dashboard/Grafana)

# Add missing ports:
3. Edit inbound rules
4. Add rule with:
   Type: Custom TCP
   Port: [MISSING_PORT]
   Source: 0.0.0.0/0
5. Save
```

#### Solution 3: Network Configuration

```bash
# Check network interface
ip link show

# Should see "UP" status for eth0/ens0/en0

# Restart network
sudo systemctl restart networking

# Or for newer Ubuntu
sudo netplan apply
```

---

## 9. Prometheus Shows No Data

### Symptom
```
Prometheus empty graph
No metrics collected
Grafana can't connect to Prometheus
```

### Solutions

```bash
# Check Prometheus running
sudo cephadm ls | grep prometheus

# If not running, deploy:
sudo cephadm shell -- ceph orch apply prometheus

# Wait 30 seconds
sleep 30

# Check mgr module enabled
sudo cephadm shell -- ceph mgr module ls | grep prometheus

# If not enabled:
sudo cephadm shell -- ceph mgr module enable prometheus

# Check Prometheus endpoint
sudo cephadm shell -- ceph mgr services | grep prometheus

# Verify data collection
curl -s http://[MONITOR_IP]:9095/api/v1/targets | head -20
```

---

## 10. Dashboard Inaccessible

### Symptom
```
https://[IP]:8080 won't load
Cannot access Ceph Dashboard
```

### Solutions

```bash
# Check dashboard running
sudo cephadm ls | grep dashboard

# If not running, deploy:
sudo cephadm shell -- ceph mgr module enable dashboard

# Wait 30 seconds
sleep 30

# Check URL
sudo cephadm shell -- ceph mgr services | grep dashboard

# Get credentials
sudo cephadm shell -- ceph dashboard ac-user-get admin

# Try accessing HTTPS (note the s)
# https://[IP]:8080/dashboard/
# (NOT http://, must be https://)

# If certificate error, accept self-signed cert
```

---

## ⚠️ CRITICAL ISSUES & RECOVERY

### Cluster Completely Down

```bash
# Last resort: Check service status
sudo cephadm ls

# Restart all services
sudo cephadm shell -- ceph service stat

# Or restart individual services:
sudo cephadm restart mon.[name]
sudo cephadm restart mgr
sudo cephadm restart osd.0
sudo cephadm restart osd.1
# etc.

# Force cluster re-initialization (DESTROYS DATA):
# Only if completely corrupted!
sudo cephadm rm-cluster --force
# Then restart from Phase 3 (Ceph Installation)
```

---

## 🆘 When All Else Fails

1. **Check Status Output:**
   ```bash
   sudo cephadm shell -- ceph -s > /tmp/status.txt
   cat /tmp/status.txt
   ```

2. **Collect Logs:**
   ```bash
   sudo cephadm logs > /tmp/ceph.log
   tail -100 /tmp/ceph.log
   ```

3. **Check System Resources:**
   ```bash
   free -h          # RAM usage
   df -h            # Disk usage
   top -b -n 1      # CPU usage
   ```

4. **Review ZERO_TO_HERO.md:**
   - See if you missed a step
   - Verify all prerequisites met
   - Check command syntax

5. **Contact Support:**
   - Check error messages carefully
   - Provide logs when reporting
   - Include command you ran
   - Include error output

---

**Last Updated:** April 23, 2026  
**Status:** ✅ Comprehensive Coverage  
**Maintainer:** Sharaz Soni
