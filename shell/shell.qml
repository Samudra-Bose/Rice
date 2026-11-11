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

        function status(): string {
            return JSON.stringify({
                manualOverride: topBar.manualOverride,
                leftVisible: topBar.leftVisible,
                centerVisible: topBar.centerVisible,
                rightVisible: topBar.rightVisible,
                leftCollided: topBar.leftCollided,
                centerCollided: topBar.centerCollided,
                rightCollided: topBar.rightCollided
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
            Region {
                item: topBar.leftVisible ? topBar.leftIsland : null
                radius: Theme.radiusPill
            }

            Region {
                item: topBar.centerVisible ? topBar.centerIsland : null
                radius: Theme.radiusPill
            }

            Region {
                item: topBar.rightVisible ? topBar.rightIsland : null
                radius: Theme.radiusPill
            }
        }

        TopBar {
            id: topBar
            anchors.fill: parent
        }
    }
}
