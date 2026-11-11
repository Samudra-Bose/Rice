import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../core"
import "common"

Item {
    id: root

    implicitHeight: Theme.panelHeight + Theme.spacingMedium

    // Read-only visual island references for surgical Wayland input masking
    readonly property Item leftIsland: navCard
    readonly property Item centerIsland: clockCard
    readonly property Item rightIsland: statusCard

    // Adaptive collision & manual override states
    property bool manualOverride: false
    property bool leftCollided: false
    property bool centerCollided: false
    property bool rightCollided: false

    readonly property bool leftVisible: manualOverride || !leftCollided
    readonly property bool centerVisible: manualOverride || !centerCollided
    readonly property bool rightVisible: manualOverride || !rightCollided

    // Active workspace state (interactive)
    property int activeWorkspace: 1

    // Real-time clock and date properties
    property string currentDateText: "WED, OCT 14"
    property string currentTimeText: "12:00"
    property string currentAmPmText: "PM"

    // =========================================================================
    // Collision-Aware Adaptive Navigation Engine
    // =========================================================================
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (["openwindow", "closewindow", "movewindow", "windowtitle",
                 "workspace", "moveworkspace", "activespecial", "focusedmon",
                 "fullscreen", "changefloatingmode", "pin", "minimize"].includes(n) ||
                n.includes("window") || n.includes("workspace")) {
                debounceTimer.restart();
            }
        }

        function onFocusedWorkspaceChanged() {
            debounceTimer.restart();
        }
    }

    Timer {
        id: debounceTimer
        interval: 35
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels();
            postRefreshTimer.restart();
        }
    }

    Timer {
        id: postRefreshTimer
        interval: 35
        repeat: false
        onTriggered: {
            root.updateCollisions();
        }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        debounceTimer.restart();
    }

    onWidthChanged: updateCollisions()
    onManualOverrideChanged: updateCollisions()

    function updateCollisions() {
        const mon = Hyprland.focusedMonitor;
        const activeWs = Hyprland.focusedWorkspace;
        if (!mon || !activeWs) {
            root.leftCollided = false;
            root.centerCollided = false;
            root.rightCollided = false;
            return;
        }

        const activeWsId = activeWs.id;

        // Rule 1: Fullscreen application on active workspace hides all islands
        if (activeWs.hasFullscreen) {
            root.leftCollided = true;
            root.centerCollided = true;
            root.rightCollided = true;
            return;
        }

        const monIpc = mon.lastIpcObject;
        const resLeft = (monIpc && monIpc.reserved && monIpc.reserved.length > 0) ? monIpc.reserved[0] : 60;
        const resTop = (monIpc && monIpc.reserved && monIpc.reserved.length > 1) ? monIpc.reserved[1] : 10;
        const panelScreenX = mon.x + resLeft;
        const panelScreenY = mon.y + resTop;

        const restY = panelScreenY + Math.round((root.height - 36) / 2);
        const cardH = 36;

        const rLeft = {
            x: panelScreenX + leftRegion.x + navCard.x,
            y: restY,
            w: navCard.width,
            h: cardH
        };
        const rCenter = {
            x: panelScreenX + centerRegion.x + clockCard.x,
            y: restY,
            w: clockCard.width,
            h: cardH
        };
        const rRight = {
            x: panelScreenX + rightRegion.x + statusCard.x,
            y: restY,
            w: statusCard.width,
            h: cardH
        };

        function rectsIntersect(r1, r2) {
            return r1.x < r2.x + r2.w &&
                   r1.x + r1.w > r2.x &&
                   r1.y < r2.y + r2.h &&
                   r1.y + r1.h > r2.y;
        }

        let collL = false;
        let collC = false;
        let collR = false;

        const toplevels = Hyprland.toplevels.values;
        for (let i = 0; i < toplevels.length; ++i) {
            const tl = toplevels[i];
            const ipc = tl.lastIpcObject;
            if (!ipc || !ipc.mapped || ipc.hidden)
                continue;

            const ws = ipc.workspace;
            if (!ws || ws.id !== activeWsId)
                continue;

            if (ipc.fullscreen > 0) {
                collL = collC = collR = true;
                break;
            }

            const at = ipc.at;
            const size = ipc.size;
            if (!at || !size || at.length < 2 || size.length < 2)
                continue;

            const winRect = {
                x: at[0],
                y: at[1],
                w: size[0],
                h: size[1]
            };

            if (!collL && rectsIntersect(rLeft, winRect)) collL = true;
            if (!collC && rectsIntersect(rCenter, winRect)) collC = true;
            if (!collR && rectsIntersect(rRight, winRect)) collR = true;

            if (collL && collC && collR) break;
        }

        root.leftCollided = collL;
        root.centerCollided = collC;
        root.rightCollided = collR;
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            const days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
            const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

            root.currentDateText = days[now.getDay()] + ", " + months[now.getMonth()] + " " + now.getDate();

            let hours = now.getHours();
            root.currentAmPmText = hours >= 12 ? "PM" : "AM";
            hours = hours % 12;
            hours = hours ? hours : 12;
            const minutes = ("0" + now.getMinutes()).slice(-2);
            root.currentTimeText = hours + ":" + minutes;
        }
    }

    // =========================================================================
    // CENTER REGION: Mathematically Centered Floating Glass Clock Capsule
    // =========================================================================
    Item {
        id: centerRegion
        anchors.centerIn: parent
        width: clockCard.width
        height: parent.height

        SurfaceCard {
            id: clockCard
            anchors.centerIn: parent
            height: 36
            width: clockRow.implicitWidth + Theme.spacingLarge * 2
            radius: Theme.radiusPill
            hoverEnabled: true
            contentPadding: 0

            opacity: root.centerVisible ? 1.0 : 0.0
            transform: Translate {
                y: root.centerVisible ? 0 : -44
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: Theme.spacingMedium + 2

                // Refined date label
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentDateText
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.0
                    color: Theme.textMuted
                }

                // Accent separator dot
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.accent

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                }

                // Prominent time display
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        id: clockLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentTimeText
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 1
                        text: root.currentAmPmText
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }

    // =========================================================================
    // LEFT REGION: Floating Brand Identity & Workspace Selector Island
    // =========================================================================
    Item {
        id: leftRegion
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingLarge
        anchors.right: centerRegion.left
        anchors.rightMargin: Theme.spacingMedium
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        SurfaceCard {
            id: navCard
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 36
            width: navRow.implicitWidth + Theme.spacingMedium * 2
            radius: Theme.radiusPill
            hoverEnabled: false
            contentPadding: 0

            opacity: root.leftVisible ? 1.0 : 0.0
            transform: Translate {
                y: root.leftVisible ? 0 : -44
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: navRow
                anchors.centerIn: parent
                spacing: Theme.spacingMedium

                // --- Brand Section ---
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: brandRow.implicitWidth + Theme.spacingSmall * 2
                    height: 28

                    Rectangle {
                        id: brandPill
                        anchors.fill: parent
                        radius: Theme.radiusPill
                        color: brandMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        border.color: brandMouse.containsMouse ? Theme.borderHighlight : "transparent"
                        border.width: 1
                        scale: brandMouse.pressed ? 0.94 : 1.0

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                        }

                        Row {
                            id: brandRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingSmall + 2

                            // Geometric Accent Diamond Mark
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 2
                                rotation: 45
                                color: Theme.accent
                                scale: brandMouse.containsMouse ? 1.15 : 1.0

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                                }
                                Behavior on scale {
                                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "RICE"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 2.0
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: brandMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                // Vertical hairline separator
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 14
                    color: Theme.borderSubtle

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                }

                // --- Workspace Indicators ---
                Row {
                    id: wsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: [1, 2, 3, 4]

                        Rectangle {
                            id: wsPill
                            readonly property bool isCurrent: modelData === root.activeWorkspace

                            anchors.verticalCenter: parent.verticalCenter
                            width: isCurrent ? 30 : 24
                            height: 24
                            radius: Theme.radiusPill

                            color: isCurrent
                                ? Theme.accent
                                : (wsMouse.containsMouse ? Theme.surfaceHover : "transparent")

                            border.color: isCurrent
                                ? "transparent"
                                : (wsMouse.containsMouse ? Theme.borderHighlight : Theme.borderSubtle)
                            border.width: isCurrent ? 0 : 1

                            scale: wsMouse.pressed ? 0.90 : 1.0

                            Behavior on color {
                                ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                            }
                            Behavior on width {
                                NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.toString()
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: wsPill.isCurrent
                                color: wsPill.isCurrent
                                    ? Theme.onAccent
                                    : (wsMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeWorkspace = modelData
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // RIGHT REGION: Floating Glass System Status Island
    // =========================================================================
    Item {
        id: rightRegion
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingLarge
        anchors.left: centerRegion.right
        anchors.leftMargin: Theme.spacingMedium
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        SurfaceCard {
            id: statusCard
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 36
            width: statusRow.implicitWidth + Theme.spacingMedium * 2
            radius: Theme.radiusPill
            hoverEnabled: false
            contentPadding: 0

            opacity: root.rightVisible ? 1.0 : 0.0
            transform: Translate {
                y: root.rightVisible ? 0 : -44
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: Theme.spacingSmall

                // --- Network Cell ---
                Rectangle {
                    id: netCell
                    anchors.verticalCenter: parent.verticalCenter
                    width: netRow.implicitWidth + Theme.spacingSmall * 2
                    height: 26
                    radius: Theme.radiusPill
                    color: netMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: netMouse.containsMouse ? Theme.borderHighlight : "transparent"
                    border.width: 1
                    scale: netMouse.pressed ? 0.94 : 1.0

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }

                    Row {
                        id: netRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰤨"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: Theme.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "NET"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.5
                            color: Theme.textMuted
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "100%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Vertical hairline separator
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 12
                    color: Theme.borderSubtle

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                }

                // --- Volume Cell ---
                Rectangle {
                    id: volCell
                    anchors.verticalCenter: parent.verticalCenter
                    width: volRow.implicitWidth + Theme.spacingSmall * 2
                    height: 26
                    radius: Theme.radiusPill
                    color: volMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: volMouse.containsMouse ? Theme.borderHighlight : "transparent"
                    border.width: 1
                    scale: volMouse.pressed ? 0.94 : 1.0

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }

                    Row {
                        id: volRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰕾"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: Theme.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "VOL"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.5
                            color: Theme.textMuted
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "80%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: volMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Vertical hairline separator
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 12
                    color: Theme.borderSubtle

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                }

                // --- Battery Cell ---
                Rectangle {
                    id: batCell
                    anchors.verticalCenter: parent.verticalCenter
                    width: batRow.implicitWidth + Theme.spacingSmall * 2
                    height: 26
                    radius: Theme.radiusPill
                    color: batMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: batMouse.containsMouse ? Theme.borderHighlight : "transparent"
                    border.width: 1
                    scale: batMouse.pressed ? 0.94 : 1.0

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
                    }

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰁹"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: Theme.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "BAT"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.5
                            color: Theme.textMuted
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "95%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: batMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}
