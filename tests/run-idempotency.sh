#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${1:-}" ]]; then
  case "$1" in
    /*) INV="$1" ;;
    *) INV="$(cd "$ROOT" && cd "$(dirname "$1")" && pwd)/$(basename "$1")" ;;
  esac
else
  INV="$ROOT/ansible/inventory.ini"
fi
ASK_BECOME=()
if [[ "${ANSIBLE_ASK_BECOME_PASS:-0}" == "1" ]]; then
  ASK_BECOME=(-K)
fi
mkdir -p "$ROOT/tests/evidence"
cd "$ROOT/ansible"
ansible-playbook -i "$INV" site.yml "${ASK_BECOME[@]}" | tee "$ROOT/tests/evidence/ansible-first-run.txt"
ansible-playbook -i "$INV" site.yml "${ASK_BECOME[@]}" | tee "$ROOT/tests/evidence/ansible-second-run.txt"
awk '
  /PLAY RECAP/ { recap=1; next }
  recap && NF {
    seen++
    if ($0 ~ /changed=[1-9]/ || $0 ~ /failed=[1-9]/ || $0 ~ /unreachable=[1-9]/) bad=1
  }
  END { if (!seen || bad) exit 1 }
' "$ROOT/tests/evidence/ansible-second-run.txt"
echo 'PASS: second Ansible run has zero changes, failures and unreachable hosts.'
