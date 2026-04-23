# Contributing Guidelines

**This repository is maintained by Sharaz Soni.**

---

## 📋 Branch Protection Policy

This repository uses **branch protection** to ensure code quality and proper authorization.

### Main Branch Protection Rules

```
Branch: main
├─ Require pull request reviews: YES (minimum 1)
├─ Require status checks to pass: YES
├─ Require authorized push: YES (sharazsony only)
├─ Dismiss stale reviews: YES
└─ Require branches up-to-date: YES
```

### What This Means

```
✅ ALLOWED:
   └─ Only sharazsony can directly push to main

❌ NOT ALLOWED:
   ├─ Direct commits to main
   ├─ Force pushes
   ├─ Merging without review
   └─ Other users pushing to main
```

---

## 🔄 Contribution Workflow

### For Authorized Contributors (sharazsony)

```
1. Create feature branch:
   git checkout -b feature/your-feature

2. Make changes:
   ├─ Edit files
   ├─ Test changes
   └─ Commit with clear messages

3. Push to GitHub:
   git push origin feature/your-feature

4. Create pull request:
   ├─ Click "New Pull Request" on GitHub
   ├─ Base: main
   ├─ Compare: feature/your-feature
   ├─ Add description
   └─ Create PR

5. Review and merge:
   ├─ Self-review code
   ├─ Check status checks pass
   ├─ Merge to main
   └─ Delete feature branch
```

### For Other Contributors

```
This repository accepts limited contributions.

To contribute:
1. Create a GitHub issue describing your suggestion
2. Wait for approval from maintainer (sharazsony)
3. If approved, you can submit a pull request
4. PR will be reviewed before merging

Note: Only authorized contributors can merge to main.
```

---

## 📝 Commit Message Guidelines

Use clear, descriptive commit messages:

```
GOOD EXAMPLES:
✅ "Add RAID 6 configuration documentation"
✅ "Fix OSD creation script for new Ceph version"
✅ "Update prerequisites with AWS pricing"
✅ "Add Grafana dashboard setup"

BAD EXAMPLES:
❌ "Fix stuff"
❌ "Update"
❌ "asdfgh"
❌ "Lots of changes"
```

**Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation update
- `scripts:` Script improvements
- `config:` Configuration changes
- `refactor:` Code restructuring

**Example:**
```
feat: Add failure recovery test script

Added comprehensive test for RAID 6 failure
scenarios including OSD recovery and data
integrity verification.

Fixes #12
```

---

## 🧪 Testing Guidelines

Before submitting pull request:

```
☑ Read entire ZERO_TO_HERO.md
☑ Test all steps manually
☑ Verify command outputs
☑ Check for formatting errors
☑ Validate all links work
☑ Test on actual AWS environment
```

---

## 📄 File Organization

When adding files, follow this structure:

```
ceph-raid6-deployment/
├── README.md              # Always keep updated
├── docs/                  # Documentation folder
│   ├── ZERO_TO_HERO.md   # Main guide
│   ├── PREREQUISITES.md  # Requirements
│   └── [other-docs].md   # Other guides
├── scripts/              # Automation scripts
│   ├── *.sh             # Bash scripts
│   └── *.ps1            # PowerShell scripts
├── config/              # Configuration files
│   └── *.yaml           # Config templates
└── aws/                 # AWS resources
    ├── terraform/       # IaC templates
    └── cloudformation/  # CF templates
```

---

## 🚀 Pull Request Checklist

Before submitting PR:

```
Title:
☑ Clear and descriptive
☑ Follows type: description format
☑ Includes issue number if fixing

Description:
☑ Explains what changed and why
☑ References any related issues (#number)
☑ Lists any breaking changes
☑ Includes testing notes

Code/Docs:
☑ Follows style guidelines
☑ No spelling/grammar errors
☑ Links are functional
☑ Code blocks are valid
☑ Formatting is consistent

Testing:
☑ Changes have been tested
☑ No new errors introduced
☑ Documentation is accurate
☑ All steps verified
```

---

## 📊 Code Review Process

### For Maintainer

```
1. Receive Pull Request
2. Review changes:
   ├─ Check against guidelines
   ├─ Verify technical accuracy
   ├─ Test if needed
   ├─ Check for conflicts
   └─ Review status checks

3. Approve or request changes:
   ├─ Request changes (if needed)
   ├─ Suggest improvements
   └─ Approve (if ready)

4. Merge to main:
   ├─ All checks pass
   ├─ Approved
   └─ Click "Merge"

5. Delete feature branch
```

### Status Checks

```
All status checks must pass:
☑ GitHub Actions (if configured)
☑ Code quality checks
☑ Link validation
☑ Markdown linting
```

---

## 🔒 Access Control

### Repository Access Levels

```
sharazsony (Maintainer):
├─ Can push directly to main
├─ Can merge pull requests
├─ Can manage issues and PRs
├─ Can modify branch protection
└─ Can delete branches

Other Collaborators:
├─ Can create feature branches
├─ Can submit pull requests
├─ Can comment on issues
└─ Cannot directly push to main
```

### How to Request Access

```
If you need elevated access:
1. Open an issue on GitHub
2. Explain your role/requirements
3. Wait for maintainer approval
4. Access will be granted
```

---

## 🐛 Issue Reporting

To report an issue:

```
1. Click "Issues" tab
2. Click "New Issue"
3. Title: Brief description
4. Description:
   ├─ What did you expect?
   ├─ What actually happened?
   ├─ Steps to reproduce
   ├─ Environment (OS, AWS region, etc.)
   └─ Screenshots if applicable
5. Click "Submit new issue"
```

**Issue Template:**
```markdown
## Description
[Clear description of issue]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happened]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [Final step]

## Environment
- OS: [Windows/Mac/Linux]
- AWS Region: [us-east-1]
- Ceph Version: [17.x]

## Screenshots
[If applicable]
```

---

## 📜 License

By contributing to this repository, you agree that your contributions
will be licensed under the MIT License (see LICENSE file).

---

## ❓ Questions or Support?

```
For help with contributions:
1. Review the README.md
2. Check existing issues
3. Read ZERO_TO_HERO.md
4. Open new issue if needed
```

---

**Last Updated:** April 23, 2026  
**Maintainer:** Sharaz Soni  
**Status:** Active
