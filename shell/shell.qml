import QtQuick
import Quickshell
import Quickshell.Wayland
import "core"

ShellRoot {
    PanelWindow {
        WlrLayershell.namespace: "rice-prototype"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            left: true
            right: true
            bottom: false
        }

        implicitHeight: Theme.panelHeight
        color: Theme.backgroundColor

        Text {
            anchors.centerIn: parent
            text: "Rice is alive"
            color: Theme.textColor
            font.pixelSize: Theme.bodyFontSize
        }
    }
}
