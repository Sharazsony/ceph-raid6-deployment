# ⚡ RESTART SCRIPT - QUICK VISUAL GUIDE

## 🎯 THE PROBLEM (Why You Need This)

```
CURRENT STATE (Working):
┌─────────────────────────────────────────┐
│ VM1 (Monitor)                           │
│ Public IP: 54.89.62.36                  │
│ Access: ssh ubuntu@54.89.62.36          │
│         https://54.89.62.36:3000        │
└─────────────────────────────────────────┘

YOU STOP ALL VMs IN AWS CONSOLE
            ↓↓↓
WHAT HAPPENS:
AWS deallocates old public IPs
AWS randomly assigns NEW public IPs on restart

NEW STATE (Everything Broken):
┌─────────────────────────────────────────┐
│ VM1 (Monitor)                           │
│ Old IP: 54.89.62.36          ❌ GONE!  │
│ New IP: 3.208.45.67          ✅ NEW    │
│ Access: ssh ubuntu@54.89.62.36 ❌ FAIL  │
│         https://54.89.62.36:3000 ❌ FAIL│
│                                         │
│ Need new: 3.208.45.67                   │
└─────────────────────────────────────────┘

SOLUTION: Use VM_RESTART_AUTO.ps1
  ↓ Detects all new IPs automatically
  ↓ Saves them to ACTIVE_IPS.txt
  ↓ You copy and use new IPs
  ↓ Everything works again! ✅
```

---

## 📍 WHERE IS THE SCRIPT?

```
C:\Users\Dell\Downloads\
├─ VM_RESTART_AUTO.ps1 ................... ← THIS ONE!
├─ cloud-ass3.pem ........................ Needed (SSH key)
└─ ACTIVE_IPS.txt ........................ Output (created by script)
```

---

## 🚀 HOW TO USE (5 Simple Steps)

### STEP 1: Stop All VMs
```
1. Open AWS EC2 Console
2. Select all 6 VMs
3. Instance State → Stop
4. Wait for status: "Stopped"
   
Time: 2 minutes
```

### STEP 2: Start All VMs
```
1. In AWS EC2 Console, select all VMs again
2. Instance State → Start
3. Status changes to "Running"
4. Wait 3 minutes for full boot

Time: 5 minutes (3 min waiting)
```

### STEP 3: Open PowerShell
```
On your Windows machine:

1. Press: Windows Key + R
2. Type: powershell
3. Press: Enter
4. You should see: PS C:\...>

Or click: Start Menu → PowerShell
```

### STEP 4: Run the Script
```
Copy and paste exactly:

cd C:\Users\Dell\Downloads ; .\VM_RESTART_AUTO.ps1

(This changes to Downloads folder AND runs the script)

Wait 2-3 minutes...
You'll see output like:
  ✅ Finding VMs...
  ✅ VM1 found: 3.208.45.67
  ✅ VM2 found: 50.19.82.12
  ... (all 6)
  ✅ All systems ready!
```

### STEP 5: Use New IPs
```
1. Open: C:\Users\Dell\Downloads\ACTIVE_IPS.txt
2. Find new IP (e.g., 3.208.45.67)
3. Copy it
4. Use new IP for everything:
   
   OLD: ssh -i cloud-ass3.pem ubuntu@54.89.62.36
   NEW: ssh -i cloud-ass3.pem ubuntu@3.208.45.67
   
   OLD: https://54.89.62.36:3000
   NEW: https://3.208.45.67:3000
```

---

## 📊 WHAT THE SCRIPT SHOWS YOU

```
When you run the script, you see:

═══════════════════════════════════════════════
    VM RESTART AUTOMATION IN PROGRESS
═══════════════════════════════════════════════

[1/3] Detecting new public IPs...
  ✅ VM1: 3.208.45.67
  ✅ VM2: 50.19.82.12
  ✅ VM3: 45.33.15.88
  ✅ VM4: 100.26.44.55
  ✅ VM5: 2.50.32.15
  ✅ VM6: 200.15.44.88

[2/3] Testing SSH connections...
  ✅ VM1 (3.208.45.67): SSH OK
  ✅ VM2 (50.19.82.12): SSH OK
  ✅ VM3 (45.33.15.88): SSH OK
  ✅ VM4 (100.26.44.55): SSH OK
  ✅ VM5 (2.50.32.15): SSH OK
  ✅ VM6 (200.15.44.88): SSH OK

[3/3] Verifying services...
  ✅ Ceph Cluster: HEALTH_OK
  ✅ Grafana: Running on :3000
  ✅ Prometheus: Running on :9095
  ✅ All services operational

═══════════════════════════════════════════════
              ✅ ALL SYSTEMS READY!
═══════════════════════════════════════════════

New IPs saved to: ACTIVE_IPS.txt

New connection strings:
  SSH: ssh -i cloud-ass3.pem ubuntu@3.208.45.67
  Grafana: https://3.208.45.67:3000
  Ceph: https://3.208.45.67:8080
  Prometheus: http://3.208.45.67:9095

═══════════════════════════════════════════════
```

---

## 📝 WHAT GETS SAVED

### File: ACTIVE_IPS.txt
```
Created by script automatically
Location: C:\Users\Dell\Downloads\ACTIVE_IPS.txt

Contents:
═══════════════════════════════════════════
NEW PUBLIC IPs (After Restart)
═══════════════════════════════════════════

VM1 (Monitor): 
  Public IP: 3.208.45.67
  Private IP: 172.31.45.113
  SSH: ssh -i cloud-ass3.pem ubuntu@3.208.45.67

VM2 (OSD1):
  Public IP: 50.19.82.12
  Private IP: 172.31.19.240
  SSH: ssh -i cloud-ass3.pem ubuntu@50.19.82.12

VM3 (OSD2):
  Public IP: 45.33.15.88
  SSH: ssh -i cloud-ass3.pem ubuntu@45.33.15.88

VM4 (OSD3):
  Public IP: 100.26.44.55
  SSH: ssh -i cloud-ass3.pem ubuntu@100.26.44.55

VM5 (Spare):
  Public IP: 2.50.32.15
  SSH: ssh -i cloud-ass3.pem ubuntu@2.50.32.15

VM6 (Spare):
  Public IP: 200.15.44.88
  SSH: ssh -i cloud-ass3.pem ubuntu@200.15.44.88

═══════════════════════════════════════════
NEW SERVICE URLs
═══════════════════════════════════════════
Grafana: https://3.208.45.67:3000
Ceph Dashboard: https://3.208.45.67:8080
Prometheus: http://3.208.45.67:9095
═══════════════════════════════════════════
```

---

## 🎬 VISUAL TIMELINE

```
TIME    ACTION                          STATUS

0:00    You: Stop all VMs              📋 AWS Console
        in AWS Console
        
2:00    VMs fully stopped              ✅ All stopped
        
2:00    You: Start all VMs             📋 AWS Console
        in AWS Console
        
2:30    VMs booting up                 ⏳ Initializing
        AWS assigns NEW public IPs
        
5:00    VMs fully started              ✅ All running
        (but with NEW IPs)
        
5:00    You: Open PowerShell           💻 Windows
        
5:05    You: Run script                🚀 Script starts
        .\VM_RESTART_AUTO.ps1
        
5:30    Script: Detect IPs             📍 Finding 6 IPs
        
6:00    Script: Test SSH               🔌 SSH testing
        
6:30    Script: Verify services        ✅ All good
        
7:00    Script: Done!                  ✨ Complete
        Creates ACTIVE_IPS.txt
        
7:05    You: Copy new IP               📋 From file
        
7:10    You: Use new IP                🌐 Working!
        for SSH/Grafana/Ceph

TOTAL TIME FROM STOP TO WORKING: ~7-10 minutes
```

---

## 🔄 BEFORE & AFTER COMPARISON

```
BEFORE RESTART (Working):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH:      ssh -i cloud-ass3.pem ubuntu@54.89.62.36
Grafana:  https://54.89.62.36:3000
Ceph:     https://54.89.62.36:8080
          ✅ All working

WHAT HAPPENS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Stop VMs → Start VMs → AWS assigns NEW IPs
          ❌ All URLs break!

YOU RUN THIS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
.\VM_RESTART_AUTO.ps1
          ↓ Detects new IPs
          ↓ Tests connections
          ↓ Saves to file

AFTER RESTART (Restored):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH:      ssh -i cloud-ass3.pem ubuntu@3.208.45.67
Grafana:  https://3.208.45.67:3000
Ceph:     https://3.208.45.67:8080
          ✅ All working again!
```

---

## ✅ CHECKLIST: Using Script

Before you start:
```
☐ Downloaded VM_RESTART_AUTO.ps1? (It's in Downloads)
☐ Have cloud-ass3.pem? (For SSH access)
☐ All 6 VMs running? (Check AWS console)
☐ Waited 3 minutes after starting? (For boot)
```

Running the script:
```
☐ Opened PowerShell
☐ Navigated to Downloads: cd C:\Users\Dell\Downloads
☐ Ran script: .\VM_RESTART_AUTO.ps1
☐ Waited for "All systems ready!" message
```

After script completes:
```
☐ Opened ACTIVE_IPS.txt
☐ Found new IP for VM1
☐ Updated SSH command with new IP
☐ Tested SSH: ssh -i cloud-ass3.pem ubuntu@[NEW_IP]
☐ Updated Grafana URL
☐ Updated Ceph URL
☐ Verified all systems working
```

---

## 🆘 IF SOMETHING GOES WRONG

```
Script hangs?
  → Check if VMs actually started (AWS console)
  → Wait another 2 minutes
  → Press Ctrl+C and try again

SSH timeout?
  → VMs take time to boot
  → Wait 3-5 minutes before trying
  → Check AWS security group has port 22

Can't find cloud-ass3.pem?
  → File must be in: C:\Users\Dell\Downloads\
  → Check exact name: cloud-ass3.pem (not cloud-ass3.pem.txt)

Services not running?
  → Takes 1-2 min to start after boot
  → Wait and try again
  → SSH in and check: sudo docker ps
```

---

## 🎓 WHAT YOU LEARN

Using this script teaches you:
```
✅ How AWS allocates public IPs
✅ Why IPs change on restart
✅ How to detect and track new IPs
✅ How to automate IP updates
✅ Service startup timing
✅ SSH connection troubleshooting
```

---

## 📞 EXAMPLE COMMAND

Copy this EXACT command:

```powershell
cd C:\Users\Dell\Downloads ; .\VM_RESTART_AUTO.ps1
```

Paste into PowerShell and press Enter.

That's it! The script handles everything else.

---

## 🎯 SUMMARY

| Item | Details |
|------|---------|
| **Script Location** | `C:\Users\Dell\Downloads\VM_RESTART_AUTO.ps1` |
| **When to Use** | After stopping/starting VMs in AWS |
| **How to Run** | `.\VM_RESTART_AUTO.ps1` in PowerShell |
| **What It Does** | Finds new IPs, tests connections, saves to file |
| **Time Required** | 3-5 minutes |
| **Output File** | `ACTIVE_IPS.txt` (contains all new IPs) |
| **Difficulty** | Very Easy (1 command) |

---

**Version:** 1.0  
**Created:** April 20, 2026  
**Status:** Ready to Use ✅
