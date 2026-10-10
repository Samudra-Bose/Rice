# Phase 0: System and Caelestia Health Audit

**Date:** October 10, 2026
**Status:** Diagnostic Only - No changes applied.

## 1. System Baseline (Observations)

*   **OS:** Arch Linux (x86_64)
*   **Kernel:** `6.18.55-1-lts`
*   **Compositor:** Hyprland `0.56.2-4`
*   **Shell:** Caelestia Shell `2.5.0-1`
*   **Quickshell:** `0.3.1.r18.g41651d7-1` (package: `quickshell-git`)
*   **Qt:** `qt6-base 6.12.0-2`, `qt6-declarative 6.12.0-1`
*   **Graphics:** NVIDIA GeForce RTX 3050 6 GB Laptop GPU
*   **NVIDIA Driver:** `nvidia-open-lts 1:615.71.09-7`, `nvidia-utils 615.71.09-1`
*   **Sleep Mode:** `s2idle`

## 2. Investigation Findings

### 2.1 Suspend / Resume Black Screen Issue
*   **Observation:** Waking from sleep results in a black screen (keyboard backlight remains on). Sleep mode is confirmed as `s2idle` via `/sys/power/mem_sleep`.
*   **Observation:** NVIDIA Settings report `NVreg_PreserveVideoMemoryAllocations=1` and `NVreg_UseKernelSuspendNotifiers=1`. The systemd services (`nvidia-suspend.service`, `nvidia-resume.service`, `nvidia-hibernate.service`) are disabled and inactive.
*   **Observation:** Session Freeze Drop-in at `/usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf` intentionally sets `SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false`.
*   **Unresolved Problem / Hypothesis:** For NVIDIA driver 615.71.09 (which is >595) using open kernel modules, memory preservation is handled automatically by kernel suspend notifiers (`NVreg_UseKernelSuspendNotifiers=1`). According to the [Arch Wiki](https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Preserve_video_memory_after_suspend) and [NVIDIA upstream documentation](https://download.nvidia.com/XFree86/Linux-x86_64/615.71.09/README/powermanagement.html), the systemd services are explicitly unnecessary and correctly disabled by default. Thus, the disabled services are **not** the cause of the black screen. The actual root cause of the `s2idle` black screen remains unknown and requires further driver-level or firmware-level investigation.

### 2.2 Quickshell Log Warnings
*   **Observation:** Missing icon warnings and missing `/home/samudra/.face`.
    *   **Hypothesis:** Likely cosmetic issues due to missing assets, but exact visual impact is pending test.
*   **Observation:** QML incubation messages (Asynchronous loading of QML components is delayed or stalling).
    *   **Unresolved Hypothesis:** We do not yet know if this merely causes a visual delay or indicates a deeper component initialization failure. Pending test to correlate logs with actual shell behavior.
*   **Observation:** PipeWire `ENOENT`.
    *   **Unresolved Hypothesis:** An audio node or socket was not found. The actual impact on the system's audio or volume widgets is currently unverified and must be tested before classifying it as a defect or a harmless warning.
*   **Observation:** Qt Wayland text-input messages.
    *   **Hypothesis:** Likely standard Wayland input method protocol negotiation messages, but pending verification of input functionality.

### 2.3 Quickshell and Hyprland Stability
*   **Observation:** `coredumpctl` shows two crashes for `/usr/bin/quickshell` on Oct 2, 2026, terminating with `SIGABRT`. 
*   **Observation:** Multiple `SIGABRT` and `SIGSEGV` core dumps for `/usr/bin/Hyprland` between Oct 1 and Oct 5, 2026.
*   **Observation:** Multiple `SIGSEGV` core dumps for `/usr/lib/xdg-desktop-portal-hyprland` between Oct 2 and Oct 5, 2026.
*   **Hypothesis:** All sets of crashes occurred **before** the October 9 upgrades to `qt6-base 6.12.0`, `hyprland 0.56.2-4`, and other related packages. They may no longer be relevant.
*   **Pending Test:** Monitor current package versions for reproduction of these crashes.

### 2.4 Environment and Platform Variables
*   **Observation:** `QT_QPA_PLATFORM="wayland;xcb"` is exported in `~/.config/hypr/hyprland/env.lua`.
*   **Confirmed Defect/Correctness:** This is a valid fallback chain in Qt6. `/usr/lib/qt6/plugins/platforms/libqwayland.so` is correctly owned by `qt6-base 6.12.0-2`. No defect.

## 3. Pending Tests & Recommended Next Steps

1.  **Suspend/Resume:** The next step is to investigate alternative causes for the black screen, such as GSP firmware issues, kernel ACPI warnings, or `s2idle` incompatibility with this specific laptop hardware.
2.  **UI Warnings:** Their actual functional impact must be verified through targeted testing before they are dismissed as harmless. We need to test volume controls and UI component rendering.
3.  **Crash Monitoring:** Do not attempt to fix historical crashes unless they reproduce on the current software stack. Monitor system logs moving forward.
