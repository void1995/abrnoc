# Alert policy

## Page immediately (24×7)

- `RaidDegraded`: redundancy loss can turn a second device failure into data loss.
- `HostDiskLatencyHigh`: sustained storage latency on a virtualization host threatens many guests; correlate with I/O errors and customer SLOs.
- `ExpectedVmNotRunning`: inventory-declared production VM unavailable for 2 minutes.
- `NetworkProbeFailed`: management/control-plane reachability probe unavailable for 2 minutes; verify from an independent vantage point before declaring host failure.

## Business hours by default

- `HostLoadHigh`: sustained load alone can reflect normal scheduled work; page sooner only when customer latency/errors are affected.
- `HostMemoryPressure`: investigate capacity/overcommit during business hours, but escalate immediately if OOM or guest impact begins.
- `NetworkInterfaceDrops`: sustained local NIC drop counters merit investigation during business hours; page sooner when customer impact or probe failures correlate.
- `VmExporterUnavailable` and `NodeExporterDown`: investigate the exporter/telemetry path during business hours unless independent probes or customer impact confirm a host outage.

The network probe is an ICMP reachability test, **not a measured end-to-end packet-loss percentage**. `NetworkInterfaceDrops` uses NIC counters; correlate it with switch counters and external probes.

Critical alerts route to the `on-call` Alertmanager receiver; warnings route to `business-hours`. **The included receivers are notification placeholders**, so configure a real secret-backed webhook/PagerDuty/email integration before claiming pages are delivered. Without it, alerts are visible in Prometheus/Alertmanager UI/API only.
