# Assumptions and trade-offs

The assessment gives a 3–4 hour budget and says depth beats shallow coverage. The lab VM is Debian 11.7 with 4 vCPU, 3.8 GiB RAM and 19 GiB disk; it exposes nested KVM, but it is not a clean spare node with physical disks, BMC, or independent failure domains.

| Decision | Assumption / trade-off |
|---|---|
| Debian version | Debian 11 is retained because that is the supplied lab. Package availability and service names are validated against the actual APT repository before claiming a successful run. |
| SSH | Password authentication remains enabled by default in the lab to avoid lockout. Production should disable it only after a separate key-only login is verified. Root login and empty passwords are disabled. |
| Firewall | nftables is opt-in by default on an existing host. The dedicated table avoids a global ruleset flush that could delete libvirt's runtime rules. Review allowed management paths before enabling. |
| Monitoring | Prometheus and exporters bind to loopback; the VM has modest resources, so retention is limited to 3 days/1 GiB. Real page delivery needs a separate secret-backed receiver. |
| VM exporter | A small `virsh` state exporter writes Prometheus textfile metrics, avoiding an additional heavyweight service. Only inventory-declared expected VMs are evaluated for “not running.” |
| Network loss | Blackbox ICMP probes provide end-to-end reachability, not a precise packet-loss percentage. Probe several independent targets and correlate interface/switch counters. |
| HA | Ceph/cluster HA is designed on paper because this single-VM lab cannot represent three independent racks or test split brain safely. |
| Failure tests | Do not remove the live VM's storage device, simulate host power loss, or force RAID/thin-pool corruption. Use disposable nested guests or a separate staging cluster. |
| GitHub | The local repository is built and validated here. No public or private remote is configured and no push is performed without the user's explicit destination/authorization. |
