# System Architecture Documentation

**Complete technical architecture for Ceph RAID 6 cluster deployment**

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   AWS US-EAST-1 Region                      │
│                   (Virtual Private Cloud)                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Security Group: ceph-cluster              │   │
│  │  Ports: 22, 3000, 3300, 6789, 6800-7300, 8080, 9095 │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                       │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │         MONITOR NODE (vm1)                  │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Ceph Monitor Daemon                 │   │     │   │
│  │  │  │ - Maintains cluster state            │   │     │   │
│  │  │  │ - Port 6789, 3300                   │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Ceph Manager Daemon                 │   │     │   │
│  │  │  │ - Orchestrates cluster              │   │     │   │
│  │  │  │ - Manages OSD placement             │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Ceph OSD Daemon (osd.3)             │   │     │   │
│  │  │  │ - Stores data (30GB disk)           │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Prometheus                           │   │     │   │
│  │  │  │ - Collects metrics (port 9095)      │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Grafana                              │   │     │   │
│  │  │  │ - Visualizes metrics (port 3000)    │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Ceph Dashboard                       │   │     │   │
│  │  │  │ - Web UI (port 8080)                 │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │ Node Exporter                        │   │     │   │
│  │  │  │ - System metrics                    │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  │                                                       │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │  OSD Node   │ │  OSD Node   │ │  OSD Node   │   │   │
│  │  │   (vm2)     │ │   (vm3)     │ │   (vm4)     │   │   │
│  │  │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │   │   │
│  │  │ │OSD.0   │ │ │ │OSD.1   │ │ │ │OSD.2   │ │   │   │
│  │  │ │30GB    │ │ │ │30GB    │ │ │ │30GB    │ │   │   │
│  │  │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │   │   │
│  │  │ Node       │ │ │ Node       │ │ │ Node       │   │   │
│  │  │ Exporter   │ │ │ Exporter   │ │ │ Exporter   │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  │          ↓               ↓               ↓           │   │
│  │      Ceph Network (Port 6789+)                      │   │
│  │                                                       │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │ Spare VMs (vm5, vm6)                       │     │   │
│  │  │ - Not used in active cluster               │     │   │
│  │  │ - Available for expansion                  │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  │                                                       │   │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         ↓                                      ↑
     SSH Port 22                          SSH Access
    (From Local PC)                    (Your Computer)
```

---

## 📊 RAID 6 Architecture (Erasure Coding)

### Data Distribution: k=4, m=2

```
┌──────────────────────────────────────────────────────────┐
│              RAID 6 Data Placement (k=4, m=2)            │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Original Data Block:                                    │
│  ┌────────────────────────────┐                         │
│  │   100 MB User Data         │                         │
│  └────────────────────────────┘                         │
│           ↓ (Encode with EC)                            │
│                                                           │
│  ┌────┬────┬────┬────┬────┬────┐                       │
│  │ D1 │ D2 │ D3 │ D4 │ P1 │ P2 │                       │
│  ├────┼────┼────┼────┼────┼────┤                       │
│  │ 25 │ 25 │ 25 │ 25 │ 25 │ 25 │ MB                    │
│  └────┴────┴────┴────┴────┴────┘                       │
│                                                           │
│  D1-D4: Data chunks (MUST have all 4 to read)           │
│  P1-P2: Parity chunks (for recovery)                    │
│                                                           │
│  Distribution across 5 OSDs:                            │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐
│  │   OSD.0  │   OSD.1  │   OSD.2  │   OSD.3  │   OSD.4  │
│  ├──────────┼──────────┼──────────┼──────────┼──────────┤
│  │    D1    │    D2    │    D3    │    D4    │   P1/P2  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘
│
│  Redundancy:
│  ✓ Can lose D1 → Reconstruct from D2,D3,D4,P1,P2
│  ✓ Can lose D2 → Reconstruct from D1,D3,D4,P1,P2
│  ✓ Can lose both OSD.0 AND OSD.1 → Still functional!
│  ✗ Can lose 3+ chunks → DATA LOST
```

### Failure Scenarios

```
┌─────────────────────────────────────────────────────────┐
│ SCENARIO 1: Single OSD Failure (Expected - OK)          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Before: [D1] [D2] [D3] [D4] [P1] [P2]                 │
│         [✓]  [✓]  [✓]  [✓]  [✓]  [✓]                 │
│                                                          │
│ After OSD.0 down:                                       │
│         [D1] [D2] [D3] [D4] [P1] [P2]                 │
│         [✗]  [✓]  [✓]  [✓]  [✓]  [✓]                 │
│                                                          │
│ System Status: DEGRADED (still operational)             │
│ Ceph automatically recovers D1 using P1,P2,D2,D3,D4    │
│ Recovery time: ~5-10 minutes for 30GB                   │
│ ✓ DATA SAFE - No data loss                             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ SCENARIO 2: Two OSD Failures (RAID 6 protects!)        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ After OSD.0 AND OSD.1 down:                            │
│         [D1] [D2] [D3] [D4] [P1] [P2]                 │
│         [✗]  [✗]  [✓]  [✓]  [✓]  [✓]                 │
│                                                          │
│ System Status: DEGRADED UNCLEAN (still operational)    │
│ Ceph recovers both D1 AND D2 simultaneously            │
│ Recovery time: ~15-20 minutes for 30GB                  │
│ ✓ DATA SAFE - RAID 6 protection working!              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ SCENARIO 3: Three OSD Failures (RAID 6 FAILS!)         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ After OSD.0, OSD.1 AND OSD.2 down:                     │
│         [D1] [D2] [D3] [D4] [P1] [P2]                 │
│         [✗]  [✗]  [✗]  [✓]  [✓]  [✓]                 │
│                                                          │
│ System Status: HEALTH_ERR (data potentially lost)      │
│ Cannot recover without all 4 data chunks               │
│ ❌ POSSIBLE DATA LOSS                                  │
│                                                          │
│ PREVENTION: Don't run 3+ OSDs on same hardware!       │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Architecture

### Write Operation

```
┌────────────────────────────────────────────────────┐
│                CLIENT APPLICATION                   │
│                   (Write Data)                      │
└────────────────────┬─────────────────────────────────┘
                     │
                     │ "Write 100 MB file"
                     ↓
        ┌────────────────────────────┐
        │   CEPH CLIENT LIBRARY      │
        │ ├─ Librados               │
        │ ├─ libcephfs              │
        │ └─ RGW Client             │
        └────────────────┬───────────┘
                         │
                 ┌───────┴────────┐
                 │                │
                 ↓                ↓
        ┌──────────────────┐  ┌──────────────────┐
        │ Monitor (Port 6789)   │  Manager (Port 6789)
        │ ├─ Cluster state   │  │ ├─ Decide OSD  │
        │ ├─ OSD map        │  │ │   placement    │
        │ └─ Authentication │  │ └─ Rebalance    │
        └────────┬──────────┘  └────────┬─────────┘
                 │                      │
                 └──────────────┬───────┘
                                │
                     ┌──────────┴────────┐
                     │                   │
                     ↓                   ↓
            ┌─────────────────┐  ┌─────────────────┐
            │ CRUSH ALGORITHM │  │ EC: Reed-Solomon│
            │ ├─ Distribute   │  │ ├─ k=4 Data    │
            │ │   chunks      │  │ ├─ m=2 Parity  │
            │ └─ Host-aware   │  │ └─ Total: 6    │
            └────────┬────────┘  └────────┬────────┘
                     │                    │
        ┌────────────┼───────────────────┼──────────┐
        │            │                   │          │
        ↓            ↓                   ↓          ↓
    ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
    │ OSD.0  │  │ OSD.1  │  │ OSD.2  │  │ OSD.3  │  │ OSD.4  │
    │ ┌────┐ │  │ ┌────┐ │  │ ┌────┐ │  │ ┌────┐ │  │ ┌────┐ │
    │ │ D1 │ │  │ │ D2 │ │  │ │ D3 │ │  │ │ D4 │ │  │ │P1P2│ │
    │ └────┘ │  │ └────┘ │  │ └────┘ │  │ └────┘ │  │ └────┘ │
    │ Data   │  │ Data   │  │ Data   │  │ Data   │  │ Parity │
    │ Block  │  │ Block  │  │ Block  │  │ Block  │  │ Blocks │
    └────────┘  └────────┘  └────────┘  └────────┘  └────────┘
        │            │          │          │           │
        │ Disk IO    │          │          │           │
        ↓            ↓          ↓          ↓           ↓
    [ 30GB ] [ 30GB ] [ 30GB ] [ 30GB ] [ 30GB ]

Stored data across cluster (distributed, redundant)
```

### Read Operation

```
CLIENT REQUEST
    │ "Get 100 MB file"
    ↓
CEPH CLIENT
    │
    ↓ (Lookup placement)
MONITOR/CRUSHMAP
    │
    ↓ (Find fastest copies)
OBJECT LOCATION
    │
    ├─ OSD.0 (Chunk D1) ✓ UP
    ├─ OSD.1 (Chunk D2) ✓ UP
    ├─ OSD.2 (Chunk D3) ✗ DOWN
    ├─ OSD.3 (Chunk D4) ✓ UP
    └─ OSD.4 (Parity P1P2) ✓ UP

READ STRATEGY
    │
    ├─ If 4 data chunks available → Read D1,D2,D3,D4 (fastest)
    │
    └─ If 1+ data chunks missing:
       ├─ Read 4 available chunks (mix of D + P)
       └─ Decode to recover missing data

CLIENT RECEIVES: Complete 100 MB file ✓
```

---

## 📈 Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│           CEPH MONITORING STACK                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  CEPH CLUSTER (MGR Module: Prometheus)         │    │
│  │  ├─ Collects internal metrics                  │    │
│  │  ├─ Exposes via port 9283                      │    │
│  │  └─ ~50 different metrics                      │    │
│  └────────────────────┬───────────────────────────┘    │
│                       │                                  │
│  ┌────────────────────┴───────────────────────────┐    │
│  │ NODE EXPORTER (on each node)                   │    │
│  │ ├─ CPU usage                                   │    │
│  │ ├─ Memory usage                                │    │
│  │ ├─ Disk I/O                                    │    │
│  │ └─ Network metrics                             │    │
│  └────────────────────┬───────────────────────────┘    │
│                       │                                  │
│                       ↓                                  │
│  ┌────────────────────────────────────────────────┐    │
│  │    PROMETHEUS (Port 9095)                       │    │
│  │    ├─ Scrapes all metric endpoints             │    │
│  │    ├─ Stores time-series data                  │    │
│  │    ├─ 15-second collection interval            │    │
│  │    └─ 15GB storage (365 days)                  │    │
│  └────────────────────┬───────────────────────────┘    │
│                       │                                  │
│          ┌────────────┴───────────────┐                │
│          │                            │                │
│          ↓                            ↓                │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │  GRAFANA        │      │ CEPH DASHBOARD   │       │
│  │  (Port 3000)    │      │ (Port 8080)      │       │
│  │                 │      │                  │       │
│  │ Dashboards:     │      │ Features:        │       │
│  │ ├─ Cluster      │      │ ├─ Cluster      │       │
│  │ │   Overview    │      │ │   Health      │       │
│  │ ├─ OSD Health   │      │ ├─ Pool Mgmt    │       │
│  │ ├─ Performance  │      │ ├─ OSD Control  │       │
│  │ ├─ Capacity     │      │ └─ Config       │       │
│  │ └─ Alerts       │      │                 │       │
│  └──────────────────┘      └──────────────────┘       │
│          ↓                            ↓                │
│     (JSON API)                    (REST API)           │
│          │                            │                │
│          └────────────────┬───────────┘                │
│                           │                            │
│                           ↓                            │
│        ┌──────────────────────────────────┐            │
│        │  YOUR BROWSER / MONITORING TOOLS │            │
│        │                                  │            │
│        │ https://[IP]:8080 (Dashboard)    │            │
│        │ http://[IP]:3000 (Grafana)       │            │
│        │ http://[IP]:9095 (Prometheus)    │            │
│        └──────────────────────────────────┘            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Metrics Collected

```
CEPH CLUSTER METRICS:
├─ Health Status (HEALTH_OK, HEALTH_WARN, HEALTH_ERR)
├─ OSD Metrics:
│  ├─ Total OSDs
│  ├─ Up/Down status
│  ├─ In/Out status
│  └─ Read/Write ops/sec
├─ Pool Metrics:
│  ├─ Capacity
│  ├─ Usage
│  ├─ PG count
│  └─ IOPS
├─ Data Metrics:
│  ├─ Total objects
│  ├─ Data written
│  ├─ Data read
│  └─ Recovery rate
└─ Network:
   ├─ Client traffic
   ├─ Cluster traffic
   └─ Recovery traffic

NODE-LEVEL METRICS:
├─ CPU
│  ├─ Usage %
│  ├─ System vs User
│  └─ Load average
├─ Memory
│  ├─ Used vs Available
│  ├─ Cache
│  └─ Swap
├─ Disk
│  ├─ I/O ops
│  ├─ Read/Write throughput
│  └─ Utilization %
└─ Network
   ├─ Bytes in/out
   ├─ Errors
   └─ Dropped packets
```

---

## 🔐 Security Architecture

```
┌──────────────────────────────────────────────────────┐
│         SECURITY LAYERS                               │
├──────────────────────────────────────────────────────┤
│                                                       │
│ LAYER 1: Network Security (AWS Level)               │
│ ├─ Security Group restricts traffic                 │
│ ├─ Only necessary ports open (22, 6789, 8080, etc)  │
│ ├─ Prevents external attacks                        │
│ └─ Port filtering by IP range                       │
│                                                       │
│ LAYER 2: SSH Authentication                         │
│ ├─ PEM key authentication                           │
│ ├─ No password SSH (more secure)                    │
│ ├─ Key stored locally (not transmitted)             │
│ └─ Access control to who can SSH                    │
│                                                       │
│ LAYER 3: Ceph Authentication (Cephx)               │
│ ├─ Admin keyring for cluster access                 │
│ ├─ OSD keys for node communication                  │
│ ├─ Client keys for application access              │
│ ├─ Mutual authentication between daemons            │
│ └─ Default: ceph.client.admin.keyring              │
│                                                       │
│ LAYER 4: Encryption (Optional)                      │
│ ├─ SSL/TLS for Dashboard (HTTPS)                    │
│ ├─ Self-signed certificates                        │
│ ├─ Client-server encryption possible               │
│ └─ Data at rest NOT encrypted (optional feature)   │
│                                                       │
│ LAYER 5: Authorization & Permissions                │
│ ├─ Cluster state protection                        │
│ ├─ OSD management access                           │
│ ├─ Pool creation restrictions                      │
│ └─ User-level access control                       │
│                                                       │
└──────────────────────────────────────────────────────┘
```

---

## 📊 Deployment Timeline

```
0 min: START
│
├─ 5 min: Pre-deployment checks ✓
│
├─ 25 min: AWS Infrastructure
│  ├─ Create 6 VMs (15 min)
│  ├─ Configure security (5 min)
│  └─ VMs booting (5 min)
│
├─ 45 min: VM Configuration
│  ├─ SSH into each VM (5 min)
│  ├─ Update packages (10 min)
│  ├─ Set hostnames (5 min)
│  └─ Verify network (5 min)
│
├─ 65 min: Ceph Installation
│  ├─ Add repositories (3 min)
│  ├─ Install cephadm (2 min)
│  ├─ Bootstrap monitor (10 min)
│  ├─ Add OSD nodes (5 min)
│  └─ Distribute config (3 min)
│
├─ 85 min: OSD & RAID 6
│  ├─ Discover disks (2 min)
│  ├─ Create OSDs (10 min)
│  ├─ Create profile (2 min)
│  ├─ Create pool (2 min)
│  └─ Verify setup (3 min)
│
├─ 95 min: Monitoring
│  ├─ Deploy Prometheus (3 min)
│  ├─ Deploy Grafana (3 min)
│  ├─ Connect Grafana (2 min)
│  └─ Verify dashboards (2 min)
│
├─ 105 min: Testing
│  ├─ Data write/read (5 min)
│  ├─ Health check (2 min)
│  ├─ View dashboards (2 min)
│  └─ Documentation (4 min)
│
└─ 109 min: COMPLETE ✓

Total: 90-110 minutes from start to production-ready cluster
```

---

## 🔧 Component Specifications

### CPU & Memory Requirements

```
┌──────────────┬────────┬──────┬────────────────────┐
│   Role       │ vCPU   │ RAM  │ Why This Much?      │
├──────────────┼────────┼──────┼────────────────────┤
│ Monitor      │ 2      │ 4GB  │ Runs mon+mgr+osd   │
│              │        │      │ Prometheus, Grafana│
│ OSD Node     │ 2      │ 4GB  │ Ceph OSD daemon    │
│              │        │      │ Node exporter      │
│ Spare VM     │ 1      │ 1GB  │ Not used in cluster│
│              │        │      │ Room for growth    │
└──────────────┴────────┴──────┴────────────────────┘
```

### Storage Requirements

```
┌──────────────┬─────────┬────────┬─────────────────┐
│   Role       │ Root    │ OSD    │ Total           │
├──────────────┼─────────┼────────┼─────────────────┤
│ Monitor      │ 20 GB   │ 30 GB  │ 50 GB           │
│ OSD Node     │ 20 GB   │ 30 GB  │ 50 GB           │
│ Spare VM     │ 20 GB   │ --     │ 20 GB           │
├──────────────┼─────────┼────────┼─────────────────┤
│ TOTAL        │ 140 GB  │ 120 GB │ 260 GB          │
│ Usable       │ --      │ 80 GB  │ ~85 GB (RAID 6) │
└──────────────┴─────────┴────────┴─────────────────┘
```

---

## 📚 Related Documentation

- [README.md](../README.md) - Project overview
- [ZERO_TO_HERO.md](ZERO_TO_HERO.md) - Step-by-step guide
- [PREREQUISITES.md](PREREQUISITES.md) - Requirements checklist
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues & fixes

---

**Last Updated:** April 23, 2026  
**Status:** ✅ Complete  
**Author:** Sharaz Soni
