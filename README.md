# Ceph RAID 6 Cluster Deployment Guide
## CS-4075 Cloud Computing Assignment 3

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Production Ready](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)]()
[![Author: Sharaz Soni](https://img.shields.io/badge/Author-Sharaz%20Soni-blue)]()
[![Last Updated: April 23, 2026](https://img.shields.io/badge/Updated-April%2023%2C%202026-blue)]()

## 📋 Project Overview

This repository contains a **complete, production-tested guide** for deploying a **Ceph RAID 6 cluster on AWS** with monitoring and high availability. It includes:

- ✅ **Step-by-step manual** with 10 major phases
- ✅ **Architecture diagrams** for each stage
- ✅ **Common pitfalls & fixes** for every step
- ✅ **Troubleshooting guide** with real solutions
- ✅ **Automation scripts** (Bash, PowerShell)
- ✅ **Testing procedures** & validation checklists

## 🎯 What You'll Learn

By following this guide, you will:

1. **Deploy 6 AWS EC2 instances** with proper networking
2. **Install & configure Ceph** in a distributed manner
3. **Set up RAID 6 erasure coding** (k=4, m=2 configuration)
4. **Deploy monitoring** with Grafana, Prometheus, and Ceph Dashboard
5. **Test failure scenarios** and verify recovery
6. **Troubleshoot common issues** with proven solutions

## 📊 Project Architecture

```
┌─────────────────────────────────────────────────────┐
│         AWS Cloud Environment (US-EAST-1)           │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────┐    ┌──────────┐                    │
│  │   Monitor   │    │   OSD1   │                    │
│  │  (vm1)      │    │  (vm2)   │                    │
│  │ t3.medium   │    │ t3.medium│                    │
│  │ 2vCPU/4GB   │    │ 2vCPU/4GB│                    │
│  │ 20GB + 30GB │    │ 20GB+30GB│                    │
│  └─────────────┘    └──────────┘                    │
│         │                  │                         │
│         └──────────────────┘                         │
│              Ceph Network                            │
│              (6789 ports)                            │
│         ┌──────────────────────┐                    │
│         │                      │                     │
│  ┌──────┴────┐          ┌──────┴────┐              │
│  │   OSD2    │          │   OSD3    │              │
│  │  (vm3)    │          │  (vm4)    │              │
│  │ t3.medium │          │ t3.medium │              │
│  │ 20GB+30GB │          │ 20GB+30GB │              │
│  └───────────┘          └───────────┘              │
│                                                       │
│  ┌──────────────┐      ┌──────────────┐            │
│  │  Spare VM5   │      │  Spare VM6   │            │
│  │  t3.micro    │      │  t3.micro    │            │
│  └──────────────┘      └──────────────┘            │
│                                                       │
└─────────────────────────────────────────────────────┘

RAID 6 Configuration: k=4 (data), m=2 (parity)
→ Can survive simultaneous failure of 2 OSDs
```

## 📁 Repository Structure

```
ceph-raid6-deployment/
├── README.md                           # This file
├── CONTRIBUTING.md                     # Contribution guidelines
├── LICENSE                             # MIT License
├── .gitignore                          # Git ignore patterns
│
├── docs/
│   ├── ZERO_TO_HERO.md                # Complete step-by-step guide
│   ├── ARCHITECTURE.md                # Detailed architecture docs
│   ├── TROUBLESHOOTING.md             # Common issues & solutions
│   ├── PREREQUISITES.md               # Requirements checklist
│   └── images/
│       ├── architecture.png           # System architecture
│       ├── deployment-flow.png        # Deployment flowchart
│       └── raid6-diagram.png          # RAID 6 explanation
│
├── scripts/
│   ├── bootstrap-monitor.sh           # Monitor node setup
│   ├── bootstrap-osd.sh               # OSD node setup
│   ├── add-osd-nodes.sh               # Add nodes to cluster
│   ├── create-raid6-pool.sh           # RAID 6 pool creation
│   ├── health-check.sh                # Cluster health script
│   └── cleanup.sh                     # Cleanup & teardown
│
├── config/
│   ├── security-group.json            # AWS security group rules
│   ├── ceph.conf.template             # Ceph config template
│   └── monitoring-config.yaml         # Monitoring setup
│
├── aws/
│   ├── terraform/
│   │   └── main.tf                    # IaC for AWS resources
│   └── cloudformation/
│       └── ceph-stack.yaml            # CloudFormation template
│
├── tests/
│   ├── test-raid6-protection.sh       # RAID 6 failure test
│   ├── test-data-integrity.sh         # Data integrity test
│   └── test-recovery.sh               # Recovery procedure test
│
└── .github/
    └── CODEOWNERS                      # Code ownership rules
```

## 🚀 Quick Start

### Prerequisites
- AWS account with EC2 access
- SSH client (Windows: use PowerShell with OpenSSH)
- PEM key file for SSH authentication
- Understanding of cloud infrastructure basics

### Minimal Setup (5 steps)

```bash
# 1. Clone repository
git clone https://github.com/sharazsony/ceph-raid6-deployment.git
cd ceph-raid6-deployment

# 2. Read prerequisites
cat docs/PREREQUISITES.md

# 3. Follow Zero to Hero guide
cat docs/ZERO_TO_HERO.md

# 4. Run bootstrap scripts
chmod +x scripts/*.sh
./scripts/bootstrap-monitor.sh

# 5. Verify deployment
./scripts/health-check.sh
```

## 📖 Documentation

| Document | Purpose | Time |
|----------|---------|------|
| [ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md) | Complete deployment guide with diagrams | 60-90 min |
| [PREREQUISITES.md](docs/PREREQUISITES.md) | System requirements & checklist | 5 min |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Detailed technical architecture | 15 min |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues & solutions | 20 min |

## 🔐 Repository Access Control

This repository is configured with:
- ✅ **Branch protection** on `main` branch
- ✅ **Authorized pushers**: Only `sharazsony` can push to main
- ✅ **Pull request required** for all changes
- ✅ **Code review** enforced before merge
- ✅ **Status checks** must pass

### How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

**Quick version:**
1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test thoroughly
3. Create pull request to `main`
4. Wait for code review and approval
5. Author merges after approval

## 📊 Key Metrics

| Metric | Value |
|--------|-------|
| **Total VMs** | 6 (4 active, 2 spare) |
| **Active Nodes** | 1 Monitor + 3 OSD + 1 OSD on Monitor |
| **Total OSDs** | 5 |
| **RAID Level** | RAID 6 (k=4, m=2) |
| **Fault Tolerance** | Can survive 2 simultaneous OSD failures |
| **Total Storage** | ~45 GiB raw, ~43 GiB usable |
| **Deployment Time** | 60-90 minutes |
| **Monitoring** | Grafana + Prometheus + Ceph Dashboard |

## ⚠️ Critical Mistakes to Avoid

1. **❌ Not adding extra storage to OSD nodes** → OSD creation fails
2. **❌ Using t3.micro for monitor** → Cluster becomes unstable
3. **❌ Wrong security group ports** → Cannot access dashboards
4. **❌ Interrupting bootstrap process** → Cluster corrupted
5. **❌ Wrong k/m values in RAID 6** → Insufficient redundancy
6. **❌ Forgetting to copy ceph.conf to OSD nodes** → Connection errors
7. **❌ Using old Ubuntu versions** → Tool incompatibilities
8. **❌ Not verifying disk attachment** → OSDs won't create

→ See [ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md) for detailed fixes

## 📊 Expected Final State

After following this guide:

```
CEPH CLUSTER STATUS:
  Health: HEALTH_OK
  Monitor: 1 daemon
  Manager: 1 active
  OSDs: 5 (all up and in)
  
RAID 6 PROTECTION:
  Profile: k=4, m=2
  Redundancy: Can lose any 2 OSDs
  
STORAGE:
  Total Capacity: ~45 GiB
  Usable Capacity: ~43 GiB
  Metadata Usage: ~1-2 GiB
  
MONITORING:
  Grafana Dashboard: http://[MONITOR_IP]:3000
  Ceph Dashboard: https://[MONITOR_IP]:8080
  Prometheus: http://[MONITOR_IP]:9095
```

## 🧪 Testing & Validation

This guide includes:

- ✅ **Pre-deployment checklist** (Prerequisites)
- ✅ **Step-by-step verification** at each phase
- ✅ **Health check procedures** after each major step
- ✅ **Failure scenario tests** (OSD failures, recovery)
- ✅ **Data integrity verification** (write/read/compare)
- ✅ **Final validation checklist** before submission

## 🔧 Automation & Scripting

The `scripts/` directory contains:

- **bootstrap-monitor.sh** - Automates monitor node setup
- **bootstrap-osd.sh** - Automates OSD node setup
- **create-raid6-pool.sh** - Creates RAID 6 pool automatically
- **health-check.sh** - Verifies cluster health
- **cleanup.sh** - Safe teardown and cleanup

Usage:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run bootstrap
./scripts/bootstrap-monitor.sh

# Check health
./scripts/health-check.sh
```

## 🛠️ Infrastructure as Code

Optional IaC templates available:

- **Terraform** (`aws/terraform/main.tf`) - For AWS resources
- **CloudFormation** (`aws/cloudformation/ceph-stack.yaml`) - Alternative to Terraform

## 📝 Assignment Checklist

Before submitting, verify:

- [ ] All 6 VMs created and running
- [ ] Security group configured with all ports
- [ ] OSD nodes have 30GB extra storage
- [ ] Ceph cluster bootstrapped successfully
- [ ] All 4 OSD nodes added to cluster
- [ ] 5 OSDs created and UP/IN
- [ ] RAID 6 profile created (k=4, m=2)
- [ ] RAID 6 pool created and functional
- [ ] Grafana running and accessible
- [ ] Prometheus running and collecting metrics
- [ ] Ceph Dashboard operational
- [ ] Health status is HEALTH_OK or HEALTH_WARN (no errors)
- [ ] Data written, read, and verified
- [ ] Failure scenarios tested
- [ ] Screenshots taken for submission

## 🐛 Troubleshooting

**Quick links to common issues:**

- [Cannot connect to cluster](docs/TROUBLESHOOTING.md#cannot-connect-to-cluster)
- [OSDs are DOWN](docs/TROUBLESHOOTING.md#osds-are-down)
- [HEALTH_ERR status](docs/TROUBLESHOOTING.md#health_err)
- [Grafana won't connect](docs/TROUBLESHOOTING.md#grafana-wont-connect)
- [No space left](docs/TROUBLESHOOTING.md#no-space-left)

See full troubleshooting guide: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 📜 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) file for details.

## 👤 Author

**Sharaz Soni**
- Email: sharaz.soni@university.edu
- GitHub: [@sharazsony](https://github.com/sharazsony)
- Course: CS-4075 Cloud Computing
- Institution: [Your University]

## 📞 Support

For issues or questions:

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review [ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md) for that specific step
3. Create an issue on GitHub (if public)
4. Contact author directly

## 🎓 Educational Value

This project demonstrates:

- **Infrastructure as Code** (IaC)
- **Distributed systems** concepts
- **RAID & erasure coding** principles
- **Cloud deployment** procedures
- **Monitoring & observability**
- **High availability** design
- **Disaster recovery** planning

## 📈 Version History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 1.0 | Apr 20, 2026 | Production | Initial release |
| 1.1 | Apr 23, 2026 | Current | Enhanced docs & diagrams |

---

**Last Updated:** April 23, 2026  
**Status:** ✅ Production Ready  
**Maintained by:** Sharaz Soni
