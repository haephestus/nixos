import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    // Theme
    property color colBg: "#1a1b26"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property string fontFamily: "DaddyTimeMono Nerd Font"
    property int fontSize: 14

    // Floating geometry
    property int barMargin: 8    // gap from screen edges
    property int barHeight: 40
    property int barRadius: 12

    // System data
    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // Follow the focused monitor: park the bar on whichever output currently
    // has focus. Verified live on Quickshell 0.3.0 — runtime setScreen works.
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // Passive overlay: never take keyboard focus (fixes the bar eating keys)
    focusable: false

    // Disable hot reload: 0.3.0 segfaults when a window with an explicit
    // `screen` is reloaded (confirmed: reload -> stack trace -> crash handler
    // relaunch). NOTE: this must live in a component file, NOT shell.qml —
    // the root entry file's Component.onCompleted fails to compile with
    // "Non-existent attached object" on 0.3.0. Restart quickshell manually
    // after changing config files.
    Component.onCompleted: {
        Quickshell.watchFiles = false
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Window itself spans full width but is transparent,
    // reserve space for the floating bar + margin
    implicitHeight: barHeight + barMargin
    color: "transparent"

    // exclusive zone so windows don't overlap the bar's reserved space
    exclusiveZone: barHeight + barMargin

    Rectangle {
        id: pill

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: bar.barMargin
        anchors.leftMargin: bar.barMargin
        anchors.rightMargin: bar.barMargin

        height: bar.barHeight
        radius: bar.barRadius
        color: bar.colBg

        border.color: bar.colMuted
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            // Workspaces
            Repeater {
                model: 7
                Text {
                    property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    text: index + 1
                    color: isActive ? bar.colCyan : (ws ? bar.colBlue : bar.colMuted)
                    font { family: bar.fontFamily; pixelSize: bar.fontSize; bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Clock
            Text {
                id: clock
                color: bar.colBlue
                font { family: bar.fontFamily; pixelSize: bar.fontSize; bold: true }
                text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                }
            }

            Item { Layout.fillWidth: true }

            // CPU
            Text {
                text: "CPU: " + cpuUsage + "%"
                color: bar.colYellow
                font { family: bar.fontFamily; pixelSize: bar.fontSize; bold: true }
            }
            Rectangle { width: 1; height: 16; color: bar.colMuted }

            // Memory
            Text {
                text: "Mem: " + memUsage + "%"
                color: bar.colCyan
                font { family: bar.fontFamily; pixelSize: bar.fontSize; bold: true }
            }
            Rectangle { width: 1; height: 16; color: bar.colMuted }
          }
    }
}
