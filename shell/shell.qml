import QtQuick
import Quickshell
import "core"
import "components"

ShellRoot {
    BasePanel {
        id: panel
        panelNamespace: "rice-prototype"

        mask: Region {
            Region {
                item: topBar.leftIsland
                radius: Theme.radiusPill
            }

            Region {
                item: topBar.centerIsland
                radius: Theme.radiusPill
            }

            Region {
                item: topBar.rightIsland
                radius: Theme.radiusPill
            }
        }

        TopBar {
            id: topBar
            anchors.fill: parent
        }
    }
}
