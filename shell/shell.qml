import QtQuick
import Quickshell
import "core"
import "components"

ShellRoot {
    BasePanel {
        panelNamespace: "rice-prototype"

        Text {
            anchors.centerIn: parent
            text: "Rice is alive"
            color: Theme.textColor
            font.pixelSize: Theme.bodyFontSize
        }
    }
}
