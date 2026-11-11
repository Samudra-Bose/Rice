import QtQuick
import "../../core"

Rectangle {
    id: root

    property bool hoverEnabled: false
    readonly property bool isHovered: hoverArea.containsMouse
    readonly property bool isPressed: hoverArea.pressed
    property color baseColor: Theme.surfaceContainer
    property real baseOpacity: 0.68
    property real hoverOpacity: 0.82
    property color borderColor: (hoverEnabled && isHovered) ? Theme.borderHighlight : Theme.borderSubtle
    property int contentPadding: Theme.spacingSmall

    default property alias content: contentContainer.data

    radius: Theme.radiusPill
    color: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, (hoverEnabled && isHovered) ? hoverOpacity : baseOpacity)
    border.color: borderColor
    border.width: 1

    scale: (hoverEnabled && isPressed) ? 0.985 : 1.0

    Behavior on color {
        ColorAnimation {
            duration: Theme.animDuration
            easing.type: Easing.OutQuad
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animDuration
            easing.type: Easing.OutQuad
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Easing.OutQuad
        }
    }

    // Inner highlight ring: 1px specular bevel for physical glass refraction
    Rectangle {
        id: innerBevel
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, (root.hoverEnabled && root.isHovered) ? 0.08 : 0.035)

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutQuad
            }
        }
    }

    // Subtle optical top-edge sheen for directional ambient light reflection
    Rectangle {
        id: topSheen
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Math.max(root.radius / 2, 8)
        anchors.rightMargin: Math.max(root.radius / 2, 8)
        height: 1
        color: Qt.rgba(1.0, 1.0, 1.0, (root.hoverEnabled && root.isHovered) ? 0.26 : 0.12)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: root.hoverEnabled
        hoverEnabled: root.hoverEnabled
        cursorShape: root.hoverEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
