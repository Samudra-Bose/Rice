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

    // Zero workspace reservation: normal windows occupy full work area
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
        bottom: false
    }

    implicitHeight: Theme.panelHeight + Theme.spacingMedium
    color: "transparent"
}
