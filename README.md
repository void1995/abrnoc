# AbrNOC Senior DevOps — KVM Virtualization Host

Implementation and written deliverables for `AbrNOC_DevOpsTask_Senior_VirtHost.pdf`.

## Lab facts

The connected lab is Debian 11.7 (`5.10.0-22-amd64`) inside VMware Workstation. It exposes nested virtualization (`vmx`, `/dev/kvm`, `kvm_intel.nested=Y`) and has 4 vCPU, 3.8 GiB RAM, and a 19 GiB root disk. It is one modest VM, not production hardware or a multi-rack cluster.

## Repository layout

- `ansible/`: idempotent host role, inventory examples and repeatability helper.
- `monitoring/`: Prometheus, Alertmanager, blackbox and alert-rule configuration, plus opt-in demo alerts.
- `docs/`: HA architecture, first-15-minute incident response, Appendix A analysis, alert policy and trade-offs.
- `tests/`: idempotency and Alertmanager checks; `tests/evidence/` contains only outputs from tests actually run.

## Run from a control node

Install Ansible, copy `ansible/inventory.ini.example` to `ansible/inventory.ini`, set the real host address and user, then copy `ansible/group_vars/virtualization_hosts.yml.example` to `ansible/group_vars/virtualization_hosts.yml` and set real VM/probe targets. Do not put passwords or webhook secrets in inventory; use interactive prompts or Ansible Vault.

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml --syntax-check
ansible-playbook -i inventory.ini site.yml -K
ansible-playbook -i inventory.ini site.yml -K
```

The second run should report `changed=0`. The role preserves password authentication by default to avoid locking out this lab; only set `virt_host_ssh_password_authentication: false` after a separate key-only login is verified. Firewall configuration is opt-in on an existing host and uses a dedicated nftables table rather than flushing libvirt's rules.

## Monitoring and tests

The role installs Debian packages for Prometheus, Alertmanager, node exporter and blackbox exporter, plus a lightweight `virsh` textfile exporter. Services bind to loopback by default; Prometheus retention is limited to 3 days/1 GiB. Set `network_probe_targets` and `virt_host_expected_vms` after checking actual targets. Real paging requires a secret-backed receiver; no webhook credentials are included.

Run `tests/run-demo-alerts.sh` on the Debian host after deployment. It temporarily installs two always-firing synthetic rules, confirms both appear through Alertmanager's API, then removes the rules. Do not leave demo alerts installed.

## Limits and trade-offs

The single 4-vCPU/3.8-GiB VM cannot demonstrate Ceph across independent racks, split-brain fencing, or safe recovery of 300 production guests. Those are documented design/runbook deliverables, not claimed deployment results. Bullseye package sources in this VM were installed from the DVD initially; the lab source was changed to the official Bullseye mirror to enable tests. Validate current package security lifecycle before production use. Do not conduct destructive storage or power-failure tests on the user's live VM. GitHub push is not performed by this local deliverable.
