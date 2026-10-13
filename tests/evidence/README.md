# Test evidence

Evidence files in this directory were collected from the single Debian 11 lab VM.
The Ansible logs below are from the already-provisioned lab host; they demonstrate
repeat-run idempotency on that host, **not** a clean-VM acceptance test.

## Ansible

- `ansible-first-run.txt`: recorded run against the existing lab host.
- `ansible-second-run.txt`: subsequent run against that same host.
- `ansible-idempotency-recheck.txt`: additional repeat run against that host.
- Each recorded recap reports `changed=0`, `failed=0`, and `unreachable=0`.
- **Outstanding:** the task's explicit clean-VM two-run test has not yet been
  established by these files. Do not treat them as evidence of a pristine baseline.

## Monitoring validation

- `monitoring-config-validation.txt`: successful Prometheus configuration,
  nine alert-rule, and Alertmanager configuration validation.

## Synthetic alert test

- `demo-alerts-during-test.json`: Alertmanager API response containing both
  `DemoStorageFailure` and `DemoVmFailure`.
- `demo-alerts-after-cleanup.json`: final Alertmanager API response; the verified
  response is an empty JSON array (`[]`).
- The temporary demo rule file was removed, and the demo rules were confirmed
  absent from Prometheus.
- All three Prometheus scrape targets were reported `up` after the test.

## Limitations

- The synthetic test verifies alert visibility through Alertmanager's API, not
  delivery to an external paging or notification service.
- The lab is a single nested-virtualization VM; it does not demonstrate multi-rack
  HA, physical fencing, or production-scale recovery.
- The clean-VM test remains pending; the VM evidence above is from the existing
  lab host.
- Delivery status applies to a specific commit; verify the remote branch before
  treating this evidence as published.
