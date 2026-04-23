# ⚡ QUICK REFERENCE CARD: VM RESTART PROCEDURE
## Print this or keep on screen while restarting

---

## 🔴 BEFORE YOU STOP VMs

```bash
# Record current public IPs
VM1: 54.89.62.36
VM2: 3.88.142.38
VM3: 54.221.32.236
VM4: 54.227.35.69
VM5: 3.88.29.137
VM6: 3.90.184.140
```

---

## 🟠 STEP 1: STOP ALL VMs

### Option A: AWS Console
1. EC2 Dashboard → Instances
2. Select all 6 VMs (checkboxes on left)
3. Right-click → Instance State → Stop
4. Wait 2 minutes for all to show "Stopped"

### Option B: AWS CLI
```bash
aws ec2 stop-instances --instance-ids [instance-ids] --region us-east-1
```

**⏱️ Wait until ALL show "Stopped" status**

---

## 🟡 STEP 2: START ALL VMs

### Option A: AWS Console
1. EC2 Dashboard → Instances
2. Select all 6 stopped VMs
3. Right-click → Instance State → Start
4. Wait for all to show "Running"

### Option B: AWS CLI
```bash
aws ec2 start-instances --instance-ids [instance-ids] --region us-east-1
```

**⏱️ Wait 1-2 minutes for boot + status checks to pass**

---

## 🟢 STEP 3: GET NEW PUBLIC IPs

1. EC2 Dashboard → Instances
2. Copy the NEW public IP for VM1 (top instance)
3. **Write it down:** `___.___.___.___`

⚠️ **IPs WILL CHANGE - Don't use old IPs!**

---

## 🔵 STEP 4: TEST CONNECTIVITY

```powershell
# Replace NEW_IP with actual new public IP
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@NEW_IP "echo 'OK'"
```

**Must see:** `OK`

If fails → VMs may still be booting, wait 1-2 more minutes

---

## 🟣 STEP 5: WATCH CLUSTER RECOVERY (5-15 minutes)

```powershell
# Keep running this every 10 seconds
$IP = "NEW_IP"
for ($i=1; $i -le 30; $i++) {
  ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$IP "sudo cephadm shell -- ceph -s" | grep -E "health|osd|pg"
  Write-Host "Check $i at $(Get-Date -Format 'HH:mm:ss')"
  Start-Sleep -Seconds 10
}
```

**Watch for:**
- `health: HEALTH_OK` or `HEALTH_WARN` (not ERR)
- `5 up, 5 in` ← All OSDs running
- PGs moving to `active+clean`

---

## ⚪ STEP 6: UNSET RECOVERY FLAGS

```powershell
$IP = "NEW_IP"
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$IP "
sudo cephadm shell -- ceph osd unset noout
sudo cephadm shell -- ceph osd unset norebalance
sudo cephadm shell -- ceph osd unset nobackfill
"
```

---

## ✅ STEP 7: VERIFY RAID 6

```powershell
$IP = "NEW_IP"
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@$IP "
sudo cephadm shell -- ceph osd erasure-code-profile get raid6-profile
"
```

**Must see:**
```
k=4
m=2
plugin=jerasure
```

---

## 📊 STEP 8: CHECK SERVICES

```powershell
$IP = "NEW_IP"

# Grafana
Invoke-WebRequest "https://$IP:3000" -SkipCertificateCheck

# Ceph Dashboard
Invoke-WebRequest "https://$IP:8080" -SkipCertificateCheck

# Prometheus
Invoke-WebRequest "http://$IP:9095" -SkipCertificateCheck
```

All should respond (ignore SSL errors)

---

## 🎯 FINAL CHECKLIST

- [ ] All 6 VMs show "Running" in AWS
- [ ] New Monitor IP documented
- [ ] SSH connection works
- [ ] Cluster shows 5 OSDs UP/IN
- [ ] RAID 6 verified (k=4, m=2)
- [ ] Services responding
- [ ] Documentation updated with new IP

---

## 🆘 QUICK TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| SSH: Connection refused | VM still booting, wait 1-2 min |
| SSH: No response | Check new IP is correct |
| OSDs show "down" | Normal, wait 5-10 minutes |
| Health shows HEALTH_ERR | Normal post-restart, resolves in 5-15 min |
| Can't reach Grafana | Port 3000 not in security group |
| Recovery taking hours | Normal if OSDs were offline long |

---

## 📝 PASTE NEW IP HERE:

```
NEW_MONITOR_IP = ___________________________

SSH Command:
ssh -i C:\Users\Dell\Downloads\cloud-ass3.pem ubuntu@___________________________

Services:
Grafana:        https://_____________________:3000
Ceph Dashboard: https://_____________________:8080
Prometheus:     http://_____________________:9095
```

---

## ⏱️ EXPECTED TIMELINE

| Phase | Time |
|-------|------|
| Stop VMs | 2-3 min |
| Start & Boot | 1-2 min |
| Cluster Stabilization | 10-15 min |
| Recovery (if needed) | 1-4 hours |
| **Total to working** | **~20 min** |

---

## 🎓 NOTES FOR ASSIGNMENT

✅ Document the restart procedure you followed  
✅ Save screenshots of Grafana showing recovery  
✅ Include final cluster status showing all OSDs UP  
✅ Verify RAID 6 config in output  
✅ Keep this reference for next class demo

---

**Printed:** ___________  
**Completed at:** ___________  
**Final Status:** ✅ / ⚠️ / ❌
