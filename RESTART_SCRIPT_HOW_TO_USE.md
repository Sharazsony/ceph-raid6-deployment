# 🔄 RESTART SCRIPT GUIDE: When VMs Stop & Start Again

**Issue:** When you stop AWS VMs and restart them, they get **NEW PUBLIC IPs**. All your connection strings break.

**Solution:** Use the **VM_RESTART_AUTO.ps1** script to automatically detect new IPs and update everything.

---

## 📍 WHERE THE SCRIPT IS

```
Location: C:\Users\Dell\Downloads\VM_RESTART_AUTO.ps1

Also available:
- QUICK_RESTART_REFERENCE.md ........ (Printable checklist)
- VM_RESTART_GUIDE.md ............... (Step-by-step walkthrough)
- ceph_recovery.sh .................. (Server-side automation)
- README_RESTART_TOOLS.md .......... (Which tool to use)
```

---

## 🚀 WHAT HAPPENS WHEN YOU STOP/START VMs

### Before (All Working):
```
VM1 Public IP:  54.89.62.36
VM2 Public IP:  98.80.76.110
VM3 Public IP:  52.72.91.187
VM4 Public IP:  23.22.31.47
↓
You connect to: ssh ubuntu@54.89.62.36
Grafana: https://54.89.62.36:3000
Ceph: https://54.89.62.36:8080
```

### After You Stop & Start VMs:
```
VM1 Public IP:  3.208.XX.XX (NEW!)
VM2 Public IP:  50.19.XX.XX (NEW!)
VM3 Public IP:  45.XX.XX.XX (NEW!)
VM4 Public IP:  100.XX.XX.XX (NEW!)
↗️
Old URLs now BROKEN:
❌ ssh ubuntu@54.89.62.36 (Won't work!)
❌ https://54.89.62.36:3000 (Won't work!)
```

### The Script Fixes This:
```
1. Detects all NEW public IPs automatically
2. Updates ACTIVE_IPS.txt with new IPs
3. Tests SSH connection to each VM
4. Shows you which commands to run
5. Ready to go!
```

---

## 🎯 HOW TO USE THE RESTART SCRIPT

### Step 1: Stop All VMs in AWS Console

```
1. Go to AWS EC2 Console
2. Select all 6 VMs
3. Click Instance State → Stop
4. Wait for all to show "Stopped"
5. ✅ All VMs stopped
```

### Step 2: Start All VMs Again

```
1. Select all 6 VMs in AWS Console
2. Click Instance State → Start
3. Wait 2-3 minutes for them to boot
4. Status shows "Running"
5. ✅ All VMs started (but with NEW IPs)
```

### Step 3: Run the PowerShell Script (Windows)

```powershell
# Open PowerShell on your Windows machine

# Navigate to downloads
cd C:\Users\Dell\Downloads

# Run the script (choose ONE option):

# Option A: Run normally (shows everything)
.\VM_RESTART_AUTO.ps1

# Option B: Run and don't show details (cleaner)
.\VM_RESTART_AUTO.ps1 -Silent

# Wait for it to complete (2-3 minutes)
# It will show: ✅ "All VMs detected successfully!"
```

### Step 4: Check the Results

```powershell
# The script creates: ACTIVE_IPS.txt

# Open it to see new IPs:
cat ACTIVE_IPS.txt

# Output looks like:
# NEW PUBLIC IPs (after restart):
# VM1:  3.208.45.67
# VM2:  50.19.82.12
# VM3:  45.33.15.88
# VM4:  100.26.44.55
# VM5:  2.50.32.15
# VM6:  200.15.44.88
```

---

## 📊 WHAT THE SCRIPT DOES STEP-BY-STEP

### Phase 1: Detect New IPs (30 seconds)
```
┌─────────────────────────────────┐
│ AWS Metadata Query              │
│ "What are the new public IPs?"  │
└──────────┬──────────────────────┘
           ↓
    ✅ Found 6 IPs
           ↓
    Writes to: ACTIVE_IPS.txt
```

### Phase 2: Test SSH Connections (1-2 minutes)
```
For each VM:
  VM1 (3.208.45.67)
    ├─ Try SSH connection
    ├─ Test if it responds
    └─ ✅ Connected!
  
  VM2 (50.19.82.12)
    ├─ Try SSH connection
    ├─ Test if it responds
    └─ ✅ Connected!
  
  ... (repeat for all 6)
```

### Phase 3: Verify Services (1-2 minutes)
```
For each VM:
  ├─ Check if Ceph running
  ├─ Check if services started
  ├─ Verify cluster status
  └─ ✅ All good!
```

### Phase 4: Display Results
```
┌──────────────────────────────┐
│ RESULTS                      │
├──────────────────────────────┤
│ ✅ 6/6 VMs found             │
│ ✅ All SSH working           │
│ ✅ Cluster healthy           │
│ ✅ New IPs saved             │
│                              │
│ New Grafana URL:             │
│ https://3.208.45.67:3000     │
│                              │
│ New Ceph URL:                │
│ https://3.208.45.67:8080     │
└──────────────────────────────┘
```

---

## 💻 SCRIPT DETAILS

### What You Need:
```
✅ cloud-ass3.pem .... SSH key (in Downloads)
✅ PowerShell ........ Already on Windows
✅ AWS EC2 Console .. Browser access
✅ VMs must be running
```

### What It Outputs:
```
1. Console display:
   - Status of each VM
   - Cluster health
   - New IPs

2. File: ACTIVE_IPS.txt
   - All 6 new public IPs
   - All private IPs
   - SSH command examples

3. File: RESTART_LOG.txt
   - Complete log of everything
   - Timestamps
   - All operations performed
```

### Time Required:
```
Total time: ~3-5 minutes

Breaking down:
├─ AWS boot-up: 2 minutes (done before script)
├─ IP detection: 30 seconds
├─ SSH testing: 1-2 minutes
├─ Service verify: 1-2 minutes
└─ Display results: 10 seconds
```

---

## 🔗 WHAT TO DO AFTER SCRIPT FINISHES

### After Script Completes, Do This:

```
1. Open ACTIVE_IPS.txt
   Location: C:\Users\Dell\Downloads\ACTIVE_IPS.txt
   
   Contains:
   ├─ NEW Public IP for VM1
   ├─ All SSH commands to use
   └─ All URLs to visit

2. Update Your Bookmarks/Notes:
   OLD:  https://54.89.62.36:3000
   NEW:  https://[NEW_IP]:3000
   
   OLD:  ssh -i cloud-ass3.pem ubuntu@54.89.62.36
   NEW:  ssh -i cloud-ass3.pem ubuntu@[NEW_IP]

3. Test SSH Connection:
   ssh -i cloud-ass3.pem ubuntu@[NEW_IP] "ceph -s"
   
   Should show: HEALTH_OK or HEALTH_ERR (but responsive)

4. Access Grafana:
   https://[NEW_IP]:3000
   Username: admin
   Password: admin

5. Access Ceph Dashboard:
   https://[NEW_IP]:8080
   Username: admin
   Password: admin123
```

---

## 🛠️ ALTERNATIVE METHODS

### Method 1: Automated Script (RECOMMENDED) ✅
```
Use: VM_RESTART_AUTO.ps1
Time: 3-5 minutes
Effort: Run 1 command
Good for: When you want automation

Command:
  .\VM_RESTART_AUTO.ps1
```

### Method 2: Manual Checklist ✓
```
Use: QUICK_RESTART_REFERENCE.md
Time: 10-15 minutes
Effort: 8 steps manually
Good for: Learning what happens

Steps:
  1. Get new IPs from AWS console
  2. Test SSH to each
  3. Update ACTIVE_IPS.txt
  4. Update Grafana URL
  5. Update Ceph URL
  ... (see checklist)
```

### Method 3: Server-Side Script 🚀
```
Use: ceph_recovery.sh
Time: Hands-free on server
Effort: 1 command from Windows
Good for: Advanced users

How:
  1. SSH to new VM IP
  2. Run: bash ceph_recovery.sh
  3. Server handles everything
```

---

## 🚨 TROUBLESHOOTING

### Problem: Script Can't Find Cloud-ass3.pem
```
Error: "cloud-ass3.pem not found"

Solution:
  1. Ensure file is in: C:\Users\Dell\Downloads\
  2. Check filename exactly: cloud-ass3.pem (not .pem.txt)
  3. Try: ls cloud-ass3.pem
```

### Problem: SSH Timeouts
```
Error: "ssh timed out"

Solution:
  1. Check VMs really started in AWS console
  2. Wait another 2 minutes for full boot
  3. Check security group has port 22 open
  4. Try manual SSH: ssh -i cloud-ass3.pem ubuntu@[NEW_IP]
```

### Problem: Can't Connect to Grafana/Ceph After Restart
```
Error: "Connection refused"

Solution:
  1. Services take 1-2 min to start after boot
  2. Wait another minute then try
  3. SSH in and check: 
     sudo docker ps
     (should show containers running)
  4. If not running, start manually:
     sudo cephadm bootstrap ...
```

### Problem: Script Says "Some VMs Not Responding"
```
Error: "3 VMs found, 3 missing"

Solution:
  1. Check AWS console - are all 6 running?
  2. Check security group allows SSH from your IP
  3. Wait longer for boot
  4. Manually check: ping [IP]
  5. Try SSH: ssh -i cloud-ass3.pem ubuntu@[IP]
```

---

## ⏰ TIMELINE: What Happens

### t=0min: You Stop All VMs
```
AWS Console → All 6 instances "Stopped"
```

### t=0-2min: VMs Boot Up
```
You wait... AWS allocates new IPs...
Instances transitioning to "Running"
```

### t=2min: You Run Script
```
PowerShell: .\VM_RESTART_AUTO.ps1
Script starts detecting...
```

### t=2:30min: Script Finds All IPs
```
Script: ✅ "All 6 IPs detected"
Creates ACTIVE_IPS.txt with new IPs
```

### t=3-5min: SSH Testing
```
Script tests each VM's SSH connection
Verifies services are running
```

### t=5min: Script Done
```
Script: ✅ "All systems ready"
Displays new URLs and commands
Creates RESTART_LOG.txt
```

### t=5+: You're Ready
```
Copy new IP from ACTIVE_IPS.txt
Update your bookmarks
SSH works again! ✅
Grafana works again! ✅
Ceph works again! ✅
```

---

## 📋 QUICK START COMMAND

Just copy and paste this:

```powershell
# Open PowerShell (Win + R, type powershell, Enter)

# Paste this:
cd C:\Users\Dell\Downloads ; .\VM_RESTART_AUTO.ps1

# Wait for "All systems ready!" message
# Done!
```

---

## 📁 FILES YOU'll USE

### Before Restart:
```
cloud-ass3.pem ........................ Have ready
```

### During Restart:
```
VM_RESTART_AUTO.ps1 ................. Run this!
QUICK_RESTART_REFERENCE.md ......... Keep as backup
```

### After Restart:
```
ACTIVE_IPS.txt ...................... New IPs here
RESTART_LOG.txt ..................... What happened
README_RESTART_TOOLS.md ............ Help reference
```

---

## ✅ CHECKLIST: Using Restart Script

```
Before Running Script:
[ ] All 6 VMs started in AWS (not stopped)
[ ] Waited 2-3 minutes for boot
[ ] In correct directory: C:\Users\Dell\Downloads
[ ] cloud-ass3.pem file present

Running Script:
[ ] Open PowerShell
[ ] Run: cd C:\Users\Dell\Downloads
[ ] Run: .\VM_RESTART_AUTO.ps1
[ ] Wait for completion message

After Script:
[ ] Check ACTIVE_IPS.txt exists
[ ] Read new IPs from file
[ ] Test one SSH: ssh -i cloud-ass3.pem ubuntu@[NEW_IP]
[ ] Update Grafana bookmark
[ ] Update Ceph Dashboard bookmark
[ ] All working! ✅
```

---

## 🎓 WHY THIS WORKS

```
Problem Flow:
  Stop VMs
    ↓ (AWS assigns new public IPs)
  Start VMs
    ↓ (All old IPs invalid)
  Can't connect
    ↓
  Need to find and update all new IPs

Solution Flow:
  Stop VMs
    ↓
  Start VMs
    ↓
  Run Script (detects all new IPs)
    ↓
  Script updates everything
    ↓
  All systems working again! ✅
```

---

## 📞 EXAMPLE: Real Restart Scenario

```
Scenario: You need to restart because of AWS maintenance

BEFORE:
├─ VM1: ssh ubuntu@54.89.62.36
├─ Grafana: https://54.89.62.36:3000
├─ Ceph: https://54.89.62.36:8080
└─ All working!

YOU DO THIS:
├─ Stop all VMs in AWS console
├─ Wait 30 seconds
├─ Start all VMs in AWS console
├─ Wait 3 minutes for boot
└─ Run: .\VM_RESTART_AUTO.ps1

SCRIPT DOES THIS:
├─ Detects new IP: 3.208.45.67
├─ Tests SSH connection
├─ Verifies services running
├─ Saves to ACTIVE_IPS.txt
└─ Displays: "All systems ready!"

YOU DO THIS:
├─ Copy new IP from ACTIVE_IPS.txt
├─ Update bookmark
├─ Test: ssh ubuntu@3.208.45.67
├─ Access: https://3.208.45.67:3000
└─ Everything works! ✅

AFTER:
├─ VM1: ssh ubuntu@3.208.45.67
├─ Grafana: https://3.208.45.67:3000
├─ Ceph: https://3.208.45.67:8080
└─ All working again!
```

---

## 🎯 SUMMARY

| Question | Answer |
|----------|--------|
| **Where is script?** | `C:\Users\Dell\Downloads\VM_RESTART_AUTO.ps1` |
| **When do I use it?** | After you stop/start VMs and they get new IPs |
| **How to run?** | `.\VM_RESTART_AUTO.ps1` in PowerShell |
| **How long does it take?** | 3-5 minutes |
| **What does it do?** | Finds new IPs, tests connections, updates everything |
| **What do I do after?** | Copy new IP from ACTIVE_IPS.txt and use it |
| **What if it fails?** | Check troubleshooting section or use manual method |

---

**Status:** ✅ Ready to Use  
**Last Updated:** April 20, 2026  
**Script Type:** PowerShell (Windows)
