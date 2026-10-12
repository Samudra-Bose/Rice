import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"

PanelWindow {
    id: root

    property string panelNamespace: "rice-panel"
    default property alias content: root.data

    WlrLayershell.namespace: root.panelNamespace
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        left: true
        right: true
        bottom: false
    }

    implicitHeight: Theme.panelHeight
    color: Theme.backgroundColor
}
