import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "core"
import "components"

ShellRoot {
    IpcHandler {
        target: "rice"

        function toggle() {
            topBar.manualOverride = !topBar.manualOverride;
        }

        function isOverride(): bool {
            return topBar.manualOverride;
        }

        function triggerCorner(side: string) {
            topBar.triggerCornerFromIpc(side);
        }

        function status(): string {
            return JSON.stringify({
                desktopHasWindows: topBar.desktopHasWindows,
                isRevealed: topBar.isRevealed,
                cornerTriggered: topBar.cornerTriggered,
                manualOverride: topBar.manualOverride,
                activeWorkspace: topBar.activeWorkspace,
                anyCornerHovered: topBar.anyCornerHovered,
                railHovered: topBar.railHovered
            });
        }
    }

    GlobalShortcut {
        appid: "rice"
        name: "toggle"
        description: "Toggle Rice TopBar manual visibility override"
        onPressed: {
            topBar.manualOverride = !topBar.manualOverride;
        }
    }

    BasePanel {
        id: panel
        panelNamespace: "rice-prototype"

        mask: Region {
            // Corner activation zones: always active in input mask to detect pointer enter
            Region {
                item: topBar.leftCornerItem
            }

            Region {
                item: topBar.rightCornerItem
            }

            // Cohesive control rail: ONLY in input mask when revealed!
            Region {
                item: topBar.isRevealed ? topBar.navRailItem : null
                radius: Theme.railRadius
            }
        }

        TopBar {
            id: topBar
            anchors.fill: parent
        }
    }
}
