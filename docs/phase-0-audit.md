# Phase 0: System and Caelestia Health Audit

**Date:** October 10, 2026
**Status:** Diagnostic Only - No changes applied.

## 1. System Baseline

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

### 2.1 Quickshell and Hyprland Stability
*   **Historical Quickshell Crashes:** `coredumpctl` shows two crashes for `/usr/bin/quickshell` on Oct 2, 2026, terminating with `SIGABRT`. 
*   **Historical Hyprland Crashes:** Multiple `SIGABRT` and `SIGSEGV` core dumps for `/usr/bin/Hyprland` between Oct 1 and Oct 5, 2026.
*   **Assessment:** Both sets of crashes occurred **before** the October 9 upgrades to `qt6-base 6.12.0`, `hyprland 0.56.2-4`, and other related packages. 
*   **Classification:** Unresolved hypothesis (Pending reproduction on current package versions).

### 2.2 Suspend / Resume Black Screen Issue
*   **Symptoms:** Waking from sleep results in a black screen (keyboard backlight remains on).
*   **Sleep Mode:** Confirmed as `s2idle` via `/sys/power/mem_sleep`.
*   **NVIDIA Settings:** 
    *   `NVreg_PreserveVideoMemoryAllocations=1`
    *   `NVreg_UseKernelSuspendNotifiers=1`
*   **Systemd Services:** `nvidia-suspend.service`, `nvidia-resume.service`, and `nvidia-hibernate.service` are currently **disabled** and inactive.
*   **Session Freeze Drop-in:** `/usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf` is owned by `nvidia-utils 615.71.09-1` and intentionally sets `SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false`.
*   **Classification:** Unresolved problem. For NVIDIA driver 615.71.09 (which is >595) using open kernel modules, memory preservation is handled automatically by kernel suspend notifiers (`NVreg_UseKernelSuspendNotifiers=1`). According to the Arch Wiki and NVIDIA upstream documentation, the systemd services (`nvidia-suspend`, `nvidia-resume`) are explicitly unnecessary and correctly disabled by default. The disabled services are **not** the cause of the black screen. The actual root cause of the `s2idle` black screen remains unknown and requires further driver-level or firmware-level investigation.

### 2.3 Quickshell Log Warnings
*   **Missing icon warnings:** Qt cannot find requested icon assets in the current icon theme. *Classification: Cosmetic issue.*
*   **Missing `/home/samudra/.face`:** Expected avatar image is absent. *Classification: Cosmetic issue.*
*   **QML incubation messages:** Asynchronous loading of QML components is delayed or stalling. *Classification: Unresolved hypothesis. We do not yet know if this merely causes a visual delay or indicates a deeper component initialization failure.*
*   **PipeWire `ENOENT`:** An audio node or socket was not found. *Classification: Unresolved hypothesis. The actual impact on the system's audio or volume widgets is currently unverified and must be tested before classifying it as a defect.*
*   **Qt Wayland text-input messages:** Standard Wayland input method protocol negotiation messages. *Classification: Benign warning.*

### 2.4 Environment and Platform Variables
*   **Qt Wayland Plugin:** `/usr/lib/qt6/plugins/platforms/libqwayland.so` is correctly owned by `qt6-base 6.12.0-2`.
*   **`QT_QPA_PLATFORM`:** `~/.config/hypr/hyprland/env.lua` exports `QT_QPA_PLATFORM="wayland;xcb"`. This is a valid fallback chain in Qt6. *Classification: Benign / Correct.*

## 3. Risks & Recommendations

1.  **Do not attempt to fix historical crashes** unless they reproduce on the current software stack (post-Oct 9).
2.  **Suspend/Resume:** Our initial hypothesis regarding disabled systemd services was incorrect. For this driver version, the kernel suspend notifiers handle VRAM preservation natively. We must **not** enable the systemd services. The next step is to investigate alternative causes for the black screen, such as GSP firmware issues, kernel ACPI warnings, or `s2idle` incompatibility with this specific laptop hardware.
3.  **UI Warnings:** We cannot assume the QML incubation and PipeWire warnings are harmless. Their actual functional impact must be verified through targeted testing before they are dismissed.
