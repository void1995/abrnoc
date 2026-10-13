#!/usr/bin/python3
"""Small libvirt state exporter for node_exporter's textfile collector."""
import os
import subprocess
import tempfile

EXPECTED = "/etc/virt-host-exporter/expected-vms.txt"
OUTPUT = "/var/lib/prometheus/node-exporter/virt-host.prom"


def label(value):
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def run(*args):
    return subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout


def main():
    expected = set()
    try:
        with open(EXPECTED, encoding="utf-8") as f:
            expected = {line.strip() for line in f if line.strip() and not line.lstrip().startswith("#")}
    except FileNotFoundError:
        pass

    names = [n.strip() for n in run("/usr/bin/virsh", "-c", "qemu:///system", "list", "--all", "--name").splitlines() if n.strip()]
    known = sorted(set(names) | expected)
    lines = [
        "# HELP virt_domain_info Libvirt domain state (one-hot).",
        "# TYPE virt_domain_info gauge",
        "# HELP virt_expected_domain_running Whether an inventory-declared VM is running.",
        "# TYPE virt_expected_domain_running gauge",
        "# HELP virt_domain_vcpus Configured vCPU count for a domain when available.",
        "# TYPE virt_domain_vcpus gauge",
    ]
    for name in known:
        state = "unknown"
        try:
            state = run("/usr/bin/virsh", "-c", "qemu:///system", "domstate", name).strip().lower()
        except subprocess.CalledProcessError:
            pass
        safe_name = label(name)
        safe_state = label(state or "unknown")
        lines.append(f'virt_domain_info{{domain="{safe_name}",state="{safe_state}"}} 1')
        if name in expected:
            lines.append(f'virt_expected_domain_running{{domain="{safe_name}"}} {1 if state == "running" else 0}')
        try:
            details = run("/usr/bin/virsh", "-c", "qemu:///system", "dominfo", name)
            for row in details.splitlines():
                if row.strip().startswith("CPU(s):"):
                    count = int(row.split(":", 1)[1].strip())
                    lines.append(f'virt_domain_vcpus{{domain="{safe_name}"}} {count}')
                    break
        except (subprocess.CalledProcessError, ValueError):
            pass

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".virt-host-", dir=os.path.dirname(OUTPUT), text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        os.chmod(tmp, 0o644)
        os.replace(tmp, OUTPUT)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


if __name__ == "__main__":
    main()
