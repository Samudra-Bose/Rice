import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../core"

Item {
    id: root

    implicitHeight: Theme.panelHeight + Theme.spacingMedium

    // =========================================================================
    // Read-only visual item references for surgical Wayland input masking
    // =========================================================================
    readonly property Item leftCornerItem: leftCornerSensor
    readonly property Item rightCornerItem: rightCornerSensor
    readonly property Item navRailItem: navRail

    // =========================================================================
    // State & Visibility Policy Engine
    // =========================================================================
    property bool manualOverride: false
    property bool desktopHasWindows: false
    property bool cornerTriggered: false
    property int autoHideDelayMs: Theme.autoHideDelayMs

    // Navbar is revealed if:
    // - State A: Desktop is empty (!desktopHasWindows)
    // - State C/D: User triggered reveal via corner (cornerTriggered)
    // - Manual override active via shortcut/IPC (manualOverride)
    readonly property bool isRevealed: (!desktopHasWindows) || manualOverride || cornerTriggered

    // Pointer hover tracking
    readonly property bool anyCornerHovered: leftCornerHover.hovered || rightCornerHover.hovered
    readonly property bool railHovered: railHover.hovered

    // Active workspace state
    property int activeWorkspace: 1

    // Real-time clock and date
    property string currentDateText: "WED, OCT 14"
    property string currentTimeText: "12:00"
    property string currentAmPmText: "PM"

    // =========================================================================
    // Hyprland Event Coordination & Desktop Window Tracking
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
            // When workspace changes, reset corner trigger so windowed workspaces default to hidden
            root.cornerTriggered = false;
            hideTimer.stop();
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
            root.updateDesktopState();
        }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        debounceTimer.restart();
    }

    onManualOverrideChanged: updateDesktopState()

    function updateDesktopState() {
        const mon = Hyprland.focusedMonitor;
        const activeWs = Hyprland.focusedWorkspace;
        if (!mon || !activeWs) {
            root.desktopHasWindows = false;
            return;
        }

        root.activeWorkspace = activeWs.id;

        // If fullscreen window exists on active workspace, desktop definitely has windows
        if (activeWs.hasFullscreen) {
            root.desktopHasWindows = true;
            return;
        }

        const activeWsId = activeWs.id;
        const toplevels = Hyprland.toplevels.values;
        let foundApp = false;

        for (let i = 0; i < toplevels.length; ++i) {
            const tl = toplevels[i];
            const ipc = tl.lastIpcObject;
            if (!ipc || !ipc.mapped || ipc.hidden)
                continue;

            const ws = ipc.workspace;
            if (!ws || ws.id !== activeWsId)
                continue;

            // Check monitor scope
            if (ipc.monitor !== undefined && ipc.monitor !== mon.id)
                continue;

            // Exclude zero-size or ghost surfaces
            const sz = ipc.size;
            if (!sz || sz.length < 2 || sz[0] < 20 || sz[1] < 20)
                continue;

            foundApp = true;
            break;
        }

        root.desktopHasWindows = foundApp;
    }

    // =========================================================================
    // Pointer Retention & Delayed Hiding (State D)
    // =========================================================================
    Timer {
        id: hideTimer
        interval: root.autoHideDelayMs
        repeat: false
        onTriggered: {
            root.cornerTriggered = false;
        }
    }

    onAnyCornerHoveredChanged: {
        if (root.anyCornerHovered) {
            if (root.desktopHasWindows) {
                root.cornerTriggered = true;
            }
            hideTimer.stop();
        } else {
            if (root.desktopHasWindows && root.cornerTriggered && !root.railHovered) {
                hideTimer.restart();
            }
        }
    }

    onRailHoveredChanged: {
        if (root.railHovered) {
            // Keep visible while pointer is over revealed rail
            if (root.cornerTriggered) {
                hideTimer.stop();
            }
        } else {
            // Pointer left rail: start hide delay countdown if outside corner
            if (root.desktopHasWindows && root.cornerTriggered && !root.anyCornerHovered) {
                hideTimer.restart();
            }
        }
    }

    function triggerCornerFromIpc(side) {
        if (root.desktopHasWindows) {
            root.cornerTriggered = true;
            hideTimer.restart();
        }
    }

    function switchWorkspace(wsId) {
        if (Hyprland.usingLua) {
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsId + '" })');
        } else {
            Hyprland.dispatch('workspace ' + wsId);
        }
    }

    // =========================================================================
    // Real-Time Clock Engine
    // =========================================================================
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

            let h = now.getHours();
            const m = String(now.getMinutes()).padStart(2, "0");
            root.currentAmPmText = h >= 12 ? "PM" : "AM";
            h = h % 12;
            if (h === 0)
                h = 12;
            root.currentTimeText = String(h) + ":" + m;
        }
    }

    // =========================================================================
    // Corner Activation Sensors (State C)
    // Small, invisible activation zones positioned at Rice panel corners
    // =========================================================================
    Item {
        id: leftCornerSensor
        anchors.left: parent.left
        anchors.top: parent.top
        width: 28
        height: 20

        HoverHandler {
            id: leftCornerHover
        }
    }

    Item {
        id: rightCornerSensor
        anchors.right: parent.right
        anchors.top: parent.top
        width: 28
        height: 20

        HoverHandler {
            id: rightCornerHover
        }
    }

    // =========================================================================
    // Cohesive Precision Control Rail Component (Choreographed Motion)
    // =========================================================================
    Item {
        id: railContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: navRail.width
        height: Theme.railHeight

        // Coordinated animation target properties
        property real yOffset: 0.0
        property real railOpacity: 1.0
        property real railScale: 1.0

        transform: [
            Translate {
                y: railContainer.yOffset
            },
            Scale {
                origin.x: navRail.width / 2
                origin.y: Theme.railHeight / 2
                xScale: railContainer.railScale
                yScale: railContainer.railScale
            }
        ]

        opacity: railContainer.railOpacity

        state: root.isRevealed ? "revealed" : "hidden"

        states: [
            State {
                name: "revealed"
                PropertyChanges {
                    target: railContainer
                    yOffset: 0.0
                    railOpacity: 1.0
                    railScale: 1.0
                }
            },
            State {
                name: "hidden"
                PropertyChanges {
                    target: railContainer
                    yOffset: Theme.hiddenYOffset
                    railOpacity: 0.0
                    railScale: Theme.hiddenScale
                }
            }
        ]

        transitions: [
            Transition {
                to: "revealed"
                ParallelAnimation {
                    NumberAnimation {
                        target: railContainer
                        properties: "yOffset,railScale"
                        duration: Theme.revealDuration
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: railContainer
                        property: "railOpacity"
                        duration: Math.round(Theme.revealDuration * 0.88)
                        easing.type: Easing.OutQuad
                    }
                }
            },
            Transition {
                to: "hidden"
                ParallelAnimation {
                    NumberAnimation {
                        target: railContainer
                        properties: "yOffset,railScale"
                        duration: Theme.retractDuration
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        target: railContainer
                        property: "railOpacity"
                        duration: Math.round(Theme.retractDuration * 0.88)
                        easing.type: Easing.InQuad
                    }
                }
            }
        ]

        Rectangle {
            id: navRail
            height: Theme.railHeight
            width: railRow.implicitWidth + Theme.spacingMedium * 2 + Theme.spacingLarge * 2
            radius: Theme.railRadius
            color: Theme.railBg
            border.color: Theme.railBorder
            border.width: 1

            HoverHandler {
                id: railHover
            }

            // Subtle dark ambient drop shadow for physical elevation
            Rectangle {
                id: outerShadow
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: -2
                radius: parent.radius
                color: Qt.rgba(0.0, 0.0, 0.0, 0.35)
                z: -1
            }

            // Subtle optical depth gradient across the surface
            Rectangle {
                id: opticalSheen
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1.0, 1.0, 1.0, 0.05) }
                    GradientStop { position: 0.45; color: Qt.rgba(1.0, 1.0, 1.0, 0.01) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.0, 0.0, 0.12) }
                }
            }

            // Inner specular bevel for physical precision glass depth
            Rectangle {
                id: innerBevel
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, parent.radius - 1)
                color: "transparent"
                border.width: 1
                border.color: Theme.railHighlight
            }

            // Top-edge light refraction sheen along the upper crown
            Rectangle {
                id: topSheen
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: parent.radius
                anchors.rightMargin: parent.radius
                height: 1
                color: Qt.rgba(1.0, 1.0, 1.0, 0.18)
            }

            Row {
                id: railRow
                anchors.centerIn: parent
                spacing: Theme.spacingMedium

                // -------------------------------------------------------------
                // SECTION 1: Brand Identity Glyph & Title
                // -------------------------------------------------------------
                Row {
                    id: brandGroup
                    spacing: 7
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: 10
                        height: 10
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                        }

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.centerIn: parent
                            color: Theme.accent
                        }
                    }

                    Text {
                        text: "RICE"
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                        color: Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Vertical Hairline Separator
                Rectangle {
                    width: 1
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.borderSubtle
                }

                // -------------------------------------------------------------
                // SECTION 2: Interactive Hyprland Workspace Selector
                // -------------------------------------------------------------
                Row {
                    id: wsRow
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: [1, 2, 3, 4, 5]

                        Item {
                            id: wsPill
                            width: 24
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter

                            readonly property int wsId: modelData
                            readonly property bool isActive: root.activeWorkspace === wsPill.wsId
                            readonly property bool isHovered: wsMouse.containsMouse

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: wsPill.isActive ? Theme.accent : (wsPill.isHovered ? Theme.surfaceHover : "transparent")

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.animDuration
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                scale: wsMouse.pressed ? 0.94 : (wsPill.isHovered ? 1.06 : 1.0)
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Theme.animDuration
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: wsPill.wsId
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.weight: wsPill.isActive ? Font.Bold : Font.Normal
                                    color: wsPill.isActive ? Theme.onAccent : (wsPill.isHovered ? Theme.textPrimary : Theme.textMuted)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.animDuration
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    root.switchWorkspace(wsPill.wsId);
                                }
                            }
                        }
                    }
                }

                // Vertical Hairline Separator
                Rectangle {
                    width: 1
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.borderSubtle
                }

                // -------------------------------------------------------------
                // SECTION 3: Refined Date & Clock Treatment
                // -------------------------------------------------------------
                Row {
                    id: clockGroup
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: root.currentDateText
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 0.5
                        font.capitalization: Font.AllUppercase
                        color: Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "•"
                        font.pixelSize: 9
                        color: Theme.textMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.currentTimeText + " " + root.currentAmPmText
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Vertical Hairline Separator
                Rectangle {
                    width: 1
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.borderSubtle
                }

                // -------------------------------------------------------------
                // SECTION 4: Truthful System Status Indicators
                // Clean iconography with hover feedback and no fake percentages
                // -------------------------------------------------------------
                Row {
                    id: statusGroup
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    // Network Status Icon
                    Item {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: netMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            scale: netMouse.pressed ? 0.94 : (netMouse.containsMouse ? 1.05 : 1.0)

                            Behavior on color {
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

                            Text {
                                anchors.centerIn: parent
                                text: "󰖩"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: netMouse.containsMouse ? Theme.accent : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Volume Status Icon
                    Item {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: volMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            scale: volMouse.pressed ? 0.94 : (volMouse.containsMouse ? 1.05 : 1.0)

                            Behavior on color {
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

                            Text {
                                anchors.centerIn: parent
                                text: "󰕾"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: volMouse.containsMouse ? Theme.accent : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: volMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Battery / Power Status Icon
                    Item {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: batMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            scale: batMouse.pressed ? 0.94 : (batMouse.containsMouse ? 1.05 : 1.0)

                            Behavior on color {
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

                            Text {
                                anchors.centerIn: parent
                                text: "󰁹"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: batMouse.containsMouse ? Theme.accent : Theme.textSecondary
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
}
