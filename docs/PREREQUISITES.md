# Prerequisites: Ceph RAID 6 Cluster Deployment

**Before starting this guide, ensure you have all requirements met.**

---

## ✅ Checklist: Do You Have Everything?

### 1. AWS Account & Credentials

```
☑ AWS account created
☑ Access to EC2 service
☑ us-east-1 region selected
☑ AWS IAM credentials configured (optional but helpful)
☑ ~$20-30 budget for 3-hour deployment
```

**Estimated Cost Breakdown:**
```
t3.medium (Monitor):     $0.0416/hour × 3 hours = $0.12
t3.medium (OSD1-3):      $0.0416/hour × 3 × 3  = $0.37
t3.micro (Spare 2):      $0.0104/hour × 3 × 2  = $0.06
EBS Storage (6 × 50GB):  ~$3 (data transfer)
Total: ~$3-5 for 3 hours
```

### 2. SSH & Networking

```
☑ SSH client installed on your computer
☑ OpenSSH available (Windows 10+)
☑ PEM key file saved locally
☑ Network access to SSH ports (usually open)
☑ Stable internet connection (minimum 5 Mbps)
```

**Windows Check:**
```powershell
# Verify SSH installed
ssh -V

# Verify key file exists
Test-Path "C:\Users\Dell\Downloads\cloud-ass3.pem"
```

**Mac/Linux Check:**
```bash
# Verify SSH installed
ssh -V

# Verify key file exists
ls -la ~/cloud-ass3.pem
```

### 3. Knowledge Prerequisites

```
☑ Basic understanding of Linux/Ubuntu
☑ Familiarity with SSH and remote connections
☑ Basic understanding of networking (IP addresses, ports)
☑ Awareness of cloud infrastructure concepts
☑ 90 minutes of uninterrupted time
```

### 4. System Requirements

| Component | Requirement | Your System |
|-----------|-------------|------------|
| OS | Windows/Mac/Linux | ✅ |
| SSH Client | OpenSSH 7.4+ | ✅ |
| Terminal | PowerShell/Bash | ✅ |
| Internet | Stable, 5+ Mbps | ✅ |
| Time | 90 minutes | ✅ |
| PEM Key | Saved locally | ✅ |

---

## 📋 Pre-Deployment Verification

### Step 1: Verify AWS Account Access

```bash
# If you have AWS CLI configured
aws ec2 describe-regions --region us-east-1

# Or use AWS Console:
# 1. Go to https://console.aws.amazon.com
# 2. Login with credentials
# 3. Select "EC2" from services
# 4. Verify region is "us-east-1" (top-right corner)
```

### Step 2: Verify SSH Key

```powershell
# Windows PowerShell
$key_path = "C:\Users\Dell\Downloads\cloud-ass3.pem"
if (Test-Path $key_path) {
    Get-Item $key_path | Select-Object Name, Length
    Write-Host "✅ Key file found"
} else {
    Write-Host "❌ Key file NOT found"
}
```

```bash
# Mac/Linux Terminal
ls -lh ~/cloud-ass3.pem
# Should show: (example)
# -rw-r--r-- 1 user group 1.7K Jan 1 12:00 cloud-ass3.pem
```

### Step 3: Verify SSH Access

```bash
# Test SSH is available
ssh -V
# Should show: OpenSSH_X.X version

# Verify key permissions (Mac/Linux)
chmod 400 ~/cloud-ass3.pem
ls -la ~/cloud-ass3.pem
# Should show: -r--------
```

### Step 4: Download Required Files

```
Download these files (save to ~/Downloads/):
├─ cloud-ass3.pem (SSH key)
└─ ZERO_TO_HERO.md (this guide)
```

---

## 🔧 Software to Install (Optional)

These are helpful but not required:

```
Optional Installation:
├─ Git (version control)
├─ VS Code (editor for reviewing files)
├─ AWS CLI (for command-line AWS access)
└─ Terraform (for infrastructure as code)
```

**Windows Installation:**
```powershell
# Using Chocolatey (if installed)
choco install git vscode awscli -y

# Or download manually:
# Git: https://git-scm.com/download/win
# VS Code: https://code.visualstudio.com/
# AWS CLI: https://aws.amazon.com/cli/
```

**Mac Installation:**
```bash
# Using Homebrew
brew install git awscli terraform

# Or download VS Code:
# https://code.visualstudio.com/
```

**Linux Installation:**
```bash
# Ubuntu/Debian
sudo apt-get install -y git awscli terraform

# Or use snap for VS Code:
sudo snap install code --classic
```

---

## ⏰ Time Breakdown

```
Planning & Setup:         5 minutes
├─ Read prerequisites
└─ Verify AWS access

AWS Infrastructure:       20 minutes
├─ Create 6 VMs           (15 min)
├─ Configure security     (5 min)
└─ Wait for boot

VM Configuration:         20 minutes
├─ SSH to each VM         (5 min)
├─ Update packages        (10 min)
└─ Configure hostnames    (5 min)

Ceph Installation:        15 minutes
├─ Install Ceph           (5 min)
├─ Bootstrap cluster      (10 min)
└─ Distribute config      (5 min)

OSD & RAID 6 Setup:       20 minutes
├─ Add OSD nodes          (5 min)
├─ Create OSDs            (10 min)
└─ Configure RAID 6       (5 min)

Monitoring Setup:         10 minutes
├─ Enable services        (3 min)
├─ Deploy Grafana         (5 min)
└─ Verify access          (2 min)

Testing & Validation:     10 minutes
├─ Data write/read test   (5 min)
├─ Failure test           (3 min)
└─ Dashboard check        (2 min)

TOTAL: 90-100 minutes
```

---

## 🚨 Critical Prerequisites Summary

**You CANNOT proceed without:**

```
MUST HAVE:
├─ ✅ AWS account with EC2 access
├─ ✅ PEM SSH key file
├─ ✅ SSH client on your computer
├─ ✅ Internet connection
└─ ✅ 90 minutes of time

MUST NOT:
├─ ❌ Interrupt setup once started
├─ ❌ Close SSH sessions mid-process
├─ ❌ Use old Ubuntu versions
└─ ❌ Skip any verification steps
```

---

## 📞 Support Resources

| Resource | Purpose | URL |
|----------|---------|-----|
| AWS Docs | Infrastructure help | https://aws.amazon.com/docs/ |
| Ceph Docs | Cluster help | https://docs.ceph.com/ |
| Ubuntu Docs | OS help | https://help.ubuntu.com/ |
| This Guide | Deployment help | See ZERO_TO_HERO.md |

---

**Status:** ✅ Verified  
**Last Updated:** April 23, 2026
