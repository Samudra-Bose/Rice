#!/bin/bash
set -u
# Resolve absolute path to project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH_DIR="${PROJECT_ROOT}/scratch"

# Source external helper libraries
COREDUMP_LIB="${PROJECT_ROOT}/scripts/lib/coredump-logic.sh"
if [[ ! -r "${COREDUMP_LIB}" ]]; then
    echo "ERROR: Required helper library is missing or unreadable: ${COREDUMP_LIB}" >&2
    exit 1
fi
if ! source "${COREDUMP_LIB}"; then
    echo "ERROR: Failed to source helper library: ${COREDUMP_LIB}" >&2
    exit 1
fi
# Ensure scratch directory exists
if ! mkdir -p "${SCRATCH_DIR}"; then
    echo "ERROR: Failed to create scratch directory ${SCRATCH_DIR}" >&2
    exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
if ! LOG_FILE="$(mktemp "${SCRATCH_DIR}/audit_${TIMESTAMP}_XXXXXX.log")"; then
    echo "ERROR: Failed to create audit log file in ${SCRATCH_DIR}" >&2
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
    
    local out
    local rc=0
    out=$("$@" 2>&1) || rc=$?
    
    if [[ -n "$out" ]]; then
        echo "$out"
    fi
    
    if [[ $rc -ne 0 ]]; then
        echo "WARN: Check '${name}' failed with exit code $rc."
    elif [[ -z "$out" ]]; then
        echo "INFO: Check '${name}' returned no output."
    fi
    echo ""
}

run_check "System Architecture & Kernel" uname -a
run_check "Key Package Versions" pacman -Q linux-lts hyprland caelestia-shell quickshell-git qt6-base qt6-declarative nvidia-open-lts nvidia-utils
run_check "Active Quickshell Processes" pgrep -a qs
run_check "System Performance Snapshot" bash -c 'out=$(top -b -n 1 -w 512 2>&1); rc=$?; echo "$out" | head -n 20; exit $rc'
run_check "Recent System Errors (Current Boot)" journalctl -b -p 3 --no-pager --lines=50

check_coredumps() {
    local label="$1"
    shift
    echo "=== Core Dumps (${label}) ==="
    local out
    local rc=0
    out=$(coredumpctl list "$@" --no-pager 2>&1) || rc=$?
    _evaluate_coredump_result "$rc" "$out"
    echo ""
}

check_coredumps "Quickshell: /usr/bin/quickshell" /usr/bin/quickshell
check_coredumps "Quickshell: qs" qs
check_coredumps "Hyprland" /usr/bin/Hyprland
check_coredumps "XDG Portal: /usr/lib/xdg-desktop-portal-hyprland" /usr/lib/xdg-desktop-portal-hyprland
check_coredumps "XDG Portal: xdg-desktop-portal-hyprland" xdg-desktop-portal-hyprland

run_check "Sleep Mode Configuration" cat /sys/power/mem_sleep
run_check "NVIDIA Power Parameters" grep -H "" /sys/module/nvidia/parameters/NVreg_PreserveVideoMemoryAllocations /sys/module/nvidia/parameters/NVreg_UseKernelSuspendNotifiers
run_check "NVIDIA Systemd Drop-in Ownership" pacman -Qo /usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf
run_check "NVIDIA Systemd Drop-in Contents" cat /usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf
run_check "Qt Wayland Plugin Ownership" pacman -Qo /usr/lib/qt6/plugins/platforms/libqwayland.so
run_check "Environment Qt Variables (env.lua)" grep -H "QT" ~/.config/hypr/hyprland/env.lua

echo "=================================================="
echo " Audit script completed."
