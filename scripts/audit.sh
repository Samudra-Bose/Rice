#!/bin/bash
set -u

# Resolve absolute path to project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH_DIR="${PROJECT_ROOT}/scratch"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRATCH_DIR}/audit_${TIMESTAMP}.log"

# Ensure scratch directory exists
if ! mkdir -p "${SCRATCH_DIR}"; then
    echo "ERROR: Failed to create scratch directory ${SCRATCH_DIR}" >&2
    exit 1
fi

# Set up logging: output to terminal AND log file
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=================================================="
echo " Rice - System Audit Snapshot"
echo " Date: $(date)"
echo " Log File: ${LOG_FILE}"
echo "=================================================="
echo ""

run_check() {
    local name="$1"
    shift
    echo "--- CHECK: ${name} ---"
    if ! "$@"; then
        echo "WARN: Check '${name}' failed or returned no results."
    fi
    echo ""
}

run_check "System Architecture & Kernel" uname -a
run_check "Key Package Versions" pacman -Q linux-lts hyprland caelestia-shell quickshell-git qt6-base qt6-declarative nvidia-open-lts nvidia-utils
run_check "Active Quickshell Processes" pgrep -a qs
run_check "System Performance Snapshot" bash -c 'top -b -n 1 -w 512 | head -n 20'
run_check "Recent System Errors (Current Boot)" journalctl -b -p 3 --no-pager --lines=50

echo "=== Core Dumps (Quickshell) ==="
coredumpctl list /usr/bin/quickshell --no-pager 2>/dev/null || echo "No Quickshell core dumps found."
coredumpctl list qs --no-pager 2>/dev/null || echo "No 'qs' core dumps found."
echo ""

echo "=== Core Dumps (Hyprland) ==="
coredumpctl list /usr/bin/Hyprland --no-pager 2>/dev/null || echo "No Hyprland core dumps found."
echo ""

echo "=== Core Dumps (XDG Desktop Portal Hyprland) ==="
coredumpctl list /usr/lib/xdg-desktop-portal-hyprland --no-pager 2>/dev/null || coredumpctl list xdg-desktop-portal-hyprland --no-pager 2>/dev/null || echo "No portal core dumps found."
echo ""

run_check "Sleep Mode Configuration" cat /sys/power/mem_sleep
run_check "NVIDIA Power Parameters" grep -H "" /sys/module/nvidia/parameters/NVreg_PreserveVideoMemoryAllocations /sys/module/nvidia/parameters/NVreg_UseKernelSuspendNotifiers
run_check "NVIDIA Systemd Drop-in Ownership" pacman -Qo /usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf
run_check "NVIDIA Systemd Drop-in Contents" cat /usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf
run_check "Qt Wayland Plugin Ownership" pacman -Qo /usr/lib/qt6/plugins/platforms/libqwayland.so
run_check "Environment Qt Variables (env.lua)" grep -H "QT" ~/.config/hypr/hyprland/env.lua

echo "=================================================="
echo " Audit script completed."
