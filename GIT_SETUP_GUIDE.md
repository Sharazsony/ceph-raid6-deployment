# Git Repository Setup Guide

**Initialize and push this project to GitHub with proper access control**

---

## 🚀 Quick Start: Push to GitHub

### Step 1: Create Repository on GitHub

```bash
# Go to https://github.com/new
# Fill in:
# Repository name: ceph-raid6-deployment
# Description: Ceph RAID 6 Cluster Deployment Guide for CS-4075
# Visibility: Public (or Private)
# Initialize: NO (don't create README, we have one)
# Click "Create repository"
```

### Step 2: Initialize Local Git Repository

From `c:\Users\Dell\Downloads\cloud_complete_ass3\`:

```powershell
# Windows PowerShell

# Navigate to project
cd "C:\Users\Dell\Downloads\cloud_complete_ass3"

# Initialize git
git init

# Add all files
git add .

# Verify files added
git status
# Should show: Changes to be committed (lots of files)
```

Or on Mac/Linux:

```bash
cd ~/Downloads/cloud_complete_ass3
git init
git add .
git status
```

### Step 3: Create Initial Commit

```bash
git config user.name "Sharaz Soni"
git config user.email "sharaz.soni@university.edu"

git commit -m "Initial commit: Ceph RAID 6 deployment guide

- Complete deployment documentation
- Zero to Hero step-by-step guide
- Architecture documentation
- Troubleshooting guide
- Prerequisites checklist
- Contributing guidelines
- Professional repository structure"
```

### Step 4: Connect to GitHub

```powershell
# Add remote repository (replace with your GitHub URL)
git remote add origin https://github.com/sharazsony/ceph-raid6-deployment.git

# Verify remote added
git remote -v
# Should show: origin pointing to your GitHub URL

# Rename branch to main (if on master)
git branch -M main

# Push to GitHub
git push -u origin main
# First push might ask for credentials
```

### Step 5: Configure Branch Protection

```
On GitHub:

1. Go to repository settings
2. Settings → Branches
3. Add rule for "main" branch:
   ├─ Require pull request reviews: ✓
   ├─ Require status checks: ✓
   ├─ Require branches up to date: ✓
   ├─ Require code review from: 1
   ├─ Require admin approval: ✓
   └─ Restrict who can push: Add "sharazsony"
4. Save rule
```

---

## 📋 Repository Structure Verification

After pushing, verify this structure on GitHub:

```
ceph-raid6-deployment/
├── README.md                      ✅ Main project doc
├── CONTRIBUTING.md               ✅ Contribution rules
├── LICENSE                        ✅ MIT License
├── .gitignore                     ✅ Git ignore rules
├── .gitattributes                 ✅ Line ending rules
├── .github/
│   └── CODEOWNERS                 ✅ Code ownership
├── docs/
│   ├── ZERO_TO_HERO.md           ✅ Main guide
│   ├── PREREQUISITES.md           ✅ Requirements
│   ├── ARCHITECTURE.md            ✅ Technical docs
│   └── TROUBLESHOOTING.md         ✅ Fixes & help
├── scripts/                       ✅ (if created)
├── config/                        ✅ (if created)
└── aws/                          ✅ (if created)
```

---

## 🔄 Daily Workflow (After Setup)

### Making Changes

```bash
# Create feature branch
git checkout -b feature/add-ansible-playbooks

# Make changes to files
# Edit some files...

# Stage changes
git add .

# Commit with message
git commit -m "feat: Add Ansible playbooks for automation

Includes playbooks for:
- OSD node configuration
- RAID 6 pool creation
- Monitoring deployment

Fixes #1"

# Push to GitHub
git push origin feature/add-ansible-playbooks
```

### Creating Pull Request

```
On GitHub:

1. Push feature branch (as shown above)
2. GitHub shows "Compare & Pull Request" button
3. Click the button
4. Add PR title and description
5. Set base: main
6. Set compare: feature/your-feature
7. Request review from sharazsony (if different user)
8. Create pull request
```

### Merging Changes

```
On GitHub:

1. Wait for review (auto-requests from CODEOWNERS)
2. Address any comments
3. Once approved, click "Merge pull request"
4. Delete feature branch
5. Celebrate! 🎉
```

---

## ✅ Best Practices

### Commit Messages

```
Good format:
type: subject

body

footer

Example:
feat: Add recovery test script

Adds automated script for testing
RAID 6 recovery scenarios and OSD
failure handling.

Includes:
- OSD down/up simulation
- Data integrity verification
- Recovery time measurement

Fixes #12
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `scripts:` Script improvements
- `config:` Configuration
- `refactor:` Code restructuring

### Branch Naming

```
Good branch names:
- feature/add-terraform-setup
- fix/osd-creation-issue
- docs/update-architecture
- scripts/add-health-check

Bad branch names:
- fix-stuff
- update
- asdf
- temp-branch-123
```

### File Guidelines

```
📝 When adding documentation:
├─ Use Markdown (.md files)
├─ Add to docs/ folder
├─ Keep lines under 80 characters
├─ Use clear headings
├─ Include examples
└─ Update README if needed

🔧 When adding scripts:
├─ Place in scripts/ folder
├─ Add #!/bin/bash or #!/bin/bash at top
├─ Add comments explaining usage
├─ Test on actual system
├─ Make executable: chmod +x script.sh
└─ Document in README

⚙️ When adding config:
├─ Place in config/ folder
├─ Use YAML or JSON format
├─ Add comments explaining each option
├─ Include example values
└─ Document in ARCHITECTURE.md
```

---

## 🔐 Protecting Sensitive Data

### Files NEVER to Commit

```
❌ NEVER add:
├─ *.pem (SSH keys)
├─ *.key (Private keys)
├─ ceph.conf (cluster config)
├─ *.keyring (Ceph keys)
├─ .aws/ (AWS credentials)
├─ .env (Environment variables)
├─ passwords.txt
└─ AWS access keys

✅ Instead:
├─ Add *.pem to .gitignore (already done)
├─ Use templates: ceph.conf.template
├─ Document via CONTRIBUTING.md
├─ Add setup scripts (not credentials)
└─ Use environment variables for secrets
```

### If You Accidentally Committed Secrets

```bash
# 1. Immediately revoke the credentials in AWS/Ceph
# 2. Remove from git history
git filter-branch --tree-filter 'rm -f sensitive-file.pem' HEAD

# 3. Force push (dangerous, use with caution)
git push -f origin main

# 4. Notify all team members
# 5. Have them re-clone

# 6. Create new credentials
```

---

## 📊 GitHub Project Features

### Issues

```
Use for:
├─ Bug reports
├─ Feature requests
├─ Documentation improvements
└─ General discussions

Create issue:
1. GitHub → Issues → New Issue
2. Title: Clear problem/request
3. Description: Details, steps, context
4. Labels: bug, enhancement, docs, etc.
5. Create issue
```

### Projects

```
Use for:
├─ Tracking progress
├─ Sprint planning
├─ Roadmap visualization
└─ Task management

Create project:
1. GitHub → Projects → New Project
2. Add issues to columns
3. Move as work progresses
```

### Discussions

```
Use for:
├─ General questions
├─ Ideas discussion
├─ Community interaction
└─ Non-urgent topics
```

---

## 🚨 Troubleshooting Git Issues

### Push Rejected

```bash
# Error: "The branch 'main' is protected"

# Solution: Use pull request
git push origin feature/your-branch
# Then create PR on GitHub
```

### Changes Not Showing

```bash
# Check what's staged
git status

# Add files
git add .

# Commit
git commit -m "message"

# Push
git push origin main
```

### Wrong Commit Message

```bash
# Fix last commit
git commit --amend -m "Corrected message"

# Then force push (use carefully)
git push -f origin main
```

### Merge Conflict

```bash
# When pulling changes that conflict

# See conflicts
git status

# Edit conflicted files:
# Look for:
# <<<<<<< HEAD
# your changes
# =======
# their changes
# >>>>>>> branch-name

# After fixing, stage and commit
git add .
git commit -m "fix: Resolve merge conflicts"
git push origin main
```

---

## 📚 Git Resources

| Resource | Purpose | Link |
|----------|---------|------|
| Git Basics | Learn Git fundamentals | https://git-scm.com/book |
| GitHub Guides | GitHub-specific help | https://guides.github.com |
| Branching Model | Git workflow | https://nvie.com/posts/a-successful-git-branching-model/ |
| Conventional Commits | Commit message format | https://www.conventionalcommits.org |

---

## ✨ Final Checklist

Before considering repository "done":

```
Repository Setup:
☑ Created on GitHub
☑ Cloned locally
☑ All files committed
☑ Initial push successful

Branch Protection:
☑ Main branch protected
☑ PR reviews required
☑ Status checks enabled
☑ Only sharazsony can push

Documentation:
☑ README complete
☑ CONTRIBUTING clear
☑ CODEOWNERS set
☑ LICENSE included

Files Verified:
☑ No .pem files
☑ No credentials
☑ No .env files
☑ All docs present
☑ All scripts included

Ready for:
☑ Collaboration
☑ Code review
☑ Public submission
☑ Assignment submission
```

---

## 🎯 Next Steps

After pushing to GitHub:

1. **Share Repository Link:**
   ```
   https://github.com/sharazsony/ceph-raid6-deployment
   ```

2. **Add to Resume:**
   ```
   Portfolio Project: Ceph RAID 6 Cluster Deployment
   - Complete deployment guide with architecture
   - 1000+ lines of documentation
   - Automated testing procedures
   - Professional GitHub repository
   - Integrated with best practices
   ```

3. **Add to Course Submission:**
   ```
   Assignment Link: https://github.com/sharazsony/ceph-raid6-deployment
   ```

4. **Future Improvements:**
   ```
   ├─ Add Terraform automation
   ├─ Add Ansible playbooks
   ├─ Add recovery scripts
   ├─ Add monitoring alerts
   └─ Add performance benchmarks
   ```

---

**Status:** ✅ Ready to Push  
**Last Updated:** April 23, 2026  
**Author:** Sharaz Soni
