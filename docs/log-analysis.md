# Appendix A log analysis — `vh-fra-017`

## Conclusion

The strongest primary-cause evidence is a failure of `nvme1` / its controller or path beginning at **03:13:58**. The host's storage subsystem then loses a RAID1 member and the thin pool switches read-only. This sequence explains the later guest I/O failures and VM failures. The log does not prove whether the SSD itself, PCIe path, firmware, power, or controller caused the initial NVMe timeouts; hardware/BMC and SMART evidence are needed to distinguish them.

## Causal timeline

| Time | Evidence | Interpretation |
|---|---|---|
| 03:11:52 | `vm-snapshot-rotate.sh` runs | Scheduled snapshot rotation is context, not proven root cause. Because storage timeouts follow shortly, correlate its I/O with device latency; do not discard it as irrelevant without checking. |
| 03:12:40–47 | Ansible SSH login/session opens and closes | Routine management activity in isolation; no evidence it caused the device failure. |
| 03:13:58 | Multiple `nvme1` I/O timeouts | First direct failure signal; investigate NVMe device, controller/PCIe path, firmware, power and kernel logs. |
| 03:14:28–59 | Controller reset fails, device removed, capacity becomes 0, write I/O errors | Confirms the kernel loses the device, not merely a slow application. |
| 03:14:59 | `md/raid1:md0` disables `nvme1n1p2`, continues on one device | RAID1 is degraded; redundancy is gone. Other writes to the missing member fail. |
| 03:14:59 | Device-mapper thin metadata transaction fails; pool goes read-only | Downstream storage protection. Avoid writes/repair attempts until state is understood. |
| 03:15:00 | ext4 journal aborts and VM filesystems remount read-only | Guest filesystems cannot safely continue normal writes. This follows the lower-layer I/O failures. |
| 03:15:02–04 | QEMU block I/O error; one VM crashes, others pause on `werror=stop` | Guest impact from failed storage I/O; not the initiating fault. |
| 03:15:04–14 | Metrics exporter cannot write state DB on read-only FS and restarts | Monitoring symptom; restart loop is not the root cause. |
| 03:15:31 | `jbd2` and a kworker blocked in D state | Kernel tasks waiting on stalled/failed I/O; evidence of host-level impact. |
| 03:16:12 | QEMU invokes OOM killer; one QEMU is killed | Contributing/downstream guest failure. Memory, dirty/writeback and reclaim pressure must also be checked; the log alone cannot prove it was caused exclusively by storage. |
| 03:16:44 onward | `ixgbe` RX ring drops increase | Network degradation appears later. It may be a secondary effect or an independent NIC/driver/switch issue; correlate with switch/BMC counters. |
| 03:17:03 | node_exporter diskstats collector cannot find `nvme1n1` | Expected telemetry symptom after the kernel removes the device. |
| 03:18:02 | NIC TX queue watchdog timeout and adapter reset | Late network failure close to host unreachability; do not mistake it for the first cause. |

## Root cause vs. symptoms

- **Primary fault (high confidence):** NVMe device/controller/path failure on `nvme1`, evidenced by timeout → failed reset → device removal/capacity 0.
- **Storage consequences:** RAID1 degraded; thin-pool metadata errors and read-only pool; ext4 journal abort/remount read-only.
- **VM/customer impact:** QEMU I/O failures, pause/crash, later OOM-killed QEMU. The latter is a separate proximate cause for that one process, but follows the storage incident timeline.
- **Later host/network symptoms:** rising RX ring drops and NIC watchdog/adapter reset. Important to diagnose independently, but they occur after storage failure and do not explain the initial NVMe timeout.
- **Monitoring symptoms:** exporter write failure and diskstats collector failure are consequences of read-only storage/device disappearance.

## Noise and uncertainties

- The Ansible SSH login/session is likely routine and has no direct causal signal in the excerpt.
- The snapshot rotation job is **not automatically noise**: it could create I/O load that exposed a marginal device. Check its run logs, I/O volume and schedule correlation before excluding it.
- The excerpt cannot prove physical media failure vs. controller/PCIe/power/firmware or whether the NIC fault is linked. Check SMART/NVMe error logs, BMC/PCIe events and switch counters.
- The `hung_task_timeout_secs` advisory explains how to suppress a warning; it is not a remediation for stalled storage.
