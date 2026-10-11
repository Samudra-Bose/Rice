import QtQuick
import Quickshell
import Quickshell.Wayland

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

        implicitHeight: 40
        color: "#2E3440"

        Text {
            anchors.centerIn: parent
            text: "Rice is alive"
            color: "#ECEFF4"
            font.pixelSize: 16
        }
    }
}
