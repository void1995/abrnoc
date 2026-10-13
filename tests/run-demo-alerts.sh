#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULE=/etc/prometheus/rules/demo-alerts.yml
PROM=http://127.0.0.1:9090
AM=http://127.0.0.1:9093
EVIDENCE="$ROOT/tests/evidence"
installed=0

mkdir -p "$EVIDENCE"

if sudo test -e "$RULE"; then
  echo "ABORT: demo rule file already exists; refusing to overwrite it." >&2
  exit 2
fi

cleanup() {
  rc=$?
  trap - EXIT

  if [[ "$installed" == 1 ]]; then
    if sudo rm -f "$RULE" &&
       sudo curl -fsS -X POST "$PROM/-/reload" >/dev/null; then
      sleep 3

      if curl -fsS "$AM/api/v2/alerts" \
          > "$EVIDENCE/demo-alerts-after-cleanup.json"; then
        if python3 - "$EVIDENCE/demo-alerts-after-cleanup.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    alerts = json.load(f)
names = sorted({
    a.get("labels", {}).get("alertname")
    for a in alerts
    if a.get("labels", {}).get("demo") == "true"
})
print("Remaining demo alerts:", names)
sys.exit(1 if names else 0)
PY
        then
          echo "PASS: demo rules removed and no demo alerts remain."
        else
          echo "FAIL: demo alerts remain after cleanup." >&2
          rc=1
        fi
      else
        echo "FAIL: could not save post-cleanup Alertmanager API response." >&2
        rc=1
      fi
    else
      echo "FAIL: cleanup or Prometheus reload failed." >&2
      rc=1
    fi
  fi

  exit "$rc"
}
trap cleanup EXIT

sudo install -o root -g prometheus -m 0640 \
  "$ROOT/monitoring/demo/demo-alerts.yml" "$RULE"
installed=1

sudo curl -fsS -X POST "$PROM/-/reload" >/dev/null

for _ in $(seq 1 30); do
  if curl -fsS "$AM/api/v2/alerts" \
      > "$EVIDENCE/demo-alerts-during-test.json"; then
    if python3 - "$EVIDENCE/demo-alerts-during-test.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    alerts = json.load(f)
names = sorted({
    a.get("labels", {}).get("alertname")
    for a in alerts
    if a.get("labels", {}).get("demo") == "true"
})
print("Demo alerts:", names)
sys.exit(0 if {"DemoStorageFailure", "DemoVmFailure"} <= set(names) else 1)
PY
    then
      echo "PASS: both synthetic alerts reached Alertmanager."
      exit 0
    fi
  fi
  sleep 2
done

echo "FAIL: expected demo alerts were not visible in Alertmanager." >&2
exit 1
