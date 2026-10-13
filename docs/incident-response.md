# Incident response: compute node unreachable after storage latency spike

## Scenario

One powered-on compute host with 300 VMs becomes unreachable. Storage latency rose for several minutes first. Prioritize customer impact, preserve evidence, and prevent a second writer. Do not assume the network is the root cause merely because the host is unreachable.

## First 15 minutes

### 0–3 minutes — declare and scope

1. Acknowledge the page, open an incident channel/record, assign incident lead and technical lead, and freeze unrelated host/storage changes.
2. Confirm the host identity, region/rack, 300-VM inventory, affected customer count, and whether monitoring/control-plane loss is isolated to one node.
3. Test management and customer-facing paths from two independent probes; check BMC/IPMI power/console and switch-port/link status. Record timestamps and dashboards.
4. Notify on-call operations immediately. Send a short customer status update once impact is confirmed; do not promise an ETA before diagnosis.

### 3–8 minutes — discriminate storage, kernel, network and hardware

- **Out-of-band/hardware:** BMC sensor/event log, PSU/temperature, PCIe/NVMe health, NIC link, ECC/MCE, and switch counters. Preserve console output.
- **Storage first (given the latency lead):** inspect Prometheus disk latency/queue depth, `journalctl -k`, NVMe SMART/error log, `nvme list`, `mdadm --detail`, `lsblk`, device-mapper/thin-pool status, filesystem errors and dirty/writeback pressure. Do not run repairs or force a resync blindly.
- **Kernel/resource:** check hung tasks, blocked D-state tasks, OOM records, CPU soft lockups, I/O scheduler and kernel panic/watchdog messages via BMC or remote logging.
- **Network independently:** compare BMC console reachability, switch port/link/CRC/drop counters, NIC driver reset/watchdog logs and a second management path. A storage-induced kernel stall can delay networking, but NIC errors may also be a separate fault.
- Snapshot/export logs and metrics before reboot. Record last-known-good time and the order of events.

### 8–15 minutes — contain and decide

1. Determine whether VM disks are local or shared/replicated and whether the storage quorum is healthy. Check fencing status and confirm whether the old host can still issue writes.
2. **Do not reboot yet** if storage is degraded, the thin pool is read-only, RAID redundancy is uncertain, or a second host could start the same disk. Preserve evidence and avoid making damage worse.
3. Reboot only when BMC confirms the host is wedged, storage state is understood, and either shared storage has safe exclusive ownership or the host is fenced. Prefer controlled fencing/power-cycle through the cluster runbook; record approval and timestamp.
4. Recover guests only after fencing and storage checks. With healthy shared RBD and quorum, restart eligible VMs on spare hosts in priority order, watching storage latency and cluster capacity. With local-only NVMe, do not claim transparent recovery: restore from replica/backup and disclose the likely data-loss window.
5. Reconcile the control plane and guest states after recovery; avoid an uncontrolled “start all 300” thundering herd.

## Communication cadence

- Internal: immediate page/incident bridge; update every 10–15 minutes or when the diagnosis changes. Keep a timeline and clearly separate confirmed facts from hypotheses.
- Customers: acknowledge impact promptly through the status page/support channel; update at a predictable cadence (for example every 15 minutes) with scope, mitigation and next update time. No unsupported ETA or root-cause claim.
- After service stabilizes: publish an interim summary, then a blameless postmortem with timeline, customer impact, root cause, contributing factors, detection gaps and owners/dates for actions.

## Prevention actions

- Alert on NVMe latency/timeouts, SMART media errors, RAID degradation, thin-pool metadata pressure, filesystem remount-read-only, OOM, NIC resets and lost blackbox probes.
- Validate BMC access, fencing, spare capacity, backups and restore drills; test failure scenarios in staging.
- Ensure backup/snapshot jobs are rate-limited and observable; correlate them with storage latency before labeling them harmless.
- Keep replicated storage and backups in independent failure domains; tune recovery/backfill to customer latency SLOs.
