# Test evidence

Evidence files contain outputs collected from the Debian lab.

## Ansible
- `ansible-first-run.txt`: recorded first-run output.
- `ansible-second-run.txt`: recorded second-run output.
- `ansible-idempotency-recheck.txt`: additional idempotency check.
- The recorded repeat runs report `changed=0`, `failed=0`, and
  `unreachable=0`.

## Monitoring validation
- `monitoring-config-validation.txt`: successful Prometheus config,
  Prometheus rules, and Alertmanager config validation.

## Synthetic alert test
- `demo-alerts-during-test.json`: Alertmanager API response containing
  both `DemoStorageFailure` and `DemoVmFailure`.
- `demo-alerts-after-cleanup.json`: final Alertmanager API response;
  the verified response is an empty JSON array (`[]`).
- The temporary demo rule file was removed, and the demo rules were
  confirmed absent from Prometheus.
- All three Prometheus scrape targets were reported `up` after the test.

## Limitations
- The synthetic test verifies alert visibility through Alertmanager's API,
  not delivery to an external paging or notification service.
- The lab is a single nested-virtualization VM; it does not demonstrate
  multi-rack HA, physical fencing, or production-scale recovery.
- Delivery status applies to a specific commit; verify the remote branch before treating this evidence as published.
