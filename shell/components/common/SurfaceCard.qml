import QtQuick
import "../../core"

Rectangle {
    id: root

    property bool hoverEnabled: false
    readonly property bool isHovered: hoverArea.containsMouse
    readonly property bool isPressed: hoverArea.pressed
    property color baseColor: Theme.surfaceContainer
    property real baseOpacity: 0.85
    property real hoverOpacity: 0.94
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

    // Subtle optical top-edge sheen for glass depth
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.radius / 2
        anchors.rightMargin: root.radius / 2
        height: 1
        color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, (root.hoverEnabled && root.isHovered) ? 0.22 : 0.08)

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
