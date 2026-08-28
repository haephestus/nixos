import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property bool shown: false
    property var bindList: []

    Process {
        id: bindsProc

        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const fmt = m => {
                        let s = []

                        if (m & 64)
                            s.push("SUPER")

                        if (m & 4)
                            s.push("CTRL")

                        if (m & 8)
                            s.push("ALT")

                        if (m & 1)
                            s.push("SHIFT")

                        return s.length ? s.join("+") : ""
                    }

                    root.bindList = JSON.parse(this.text)
                        .filter(b =>
                            b.submap === "" &&
                            b.key !== ""
                        )
                        .map(b => ({
                            keys:
                                fmt(b.modmask)
                                + " + "
                                + b.key,

                            action:
                                (b.dispatcher + " " + b.arg)
                                .trim()
                        }))
                        .sort((a, b) =>
                            a.keys.localeCompare(b.keys)
                        )
                } catch (e) {
                    root.bindList = []
                }
            }
        }
    }

    PanelWindow {
        visible: root.shown

        anchors {
            right: true
            top: true
            bottom: true
        }

        width: 560
        color: "transparent"

        WlrLayershell.keyboardFocus:
            WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (visible) {
                filterField.text = ""
                bindsProc.running = true
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 8

            radius: 12
            color: "#ee1a1b26"
            border.color: "#557aa2f7"

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    color: "#c0caf5"
                    font.pixelSize: 16
                    font.bold: true
                    text: "keybinds"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#337aa2f7"
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6

                    color: "#22242036"
                    border.color: "#447aa2f7"

                    TextInput {
                        id: filterField

                        anchors.fill: parent
                        anchors.margins: 8

                        color: "#c0caf5"
                        focus: root.shown

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            color: "#565f89"

                            visible:
                                filterField.text === ""

                            text: "filter…"
                        }
                    }
                }

                ListView {
                    width: parent.width
                    height: parent.height - 130

                    clip: true
                    spacing: 4

                    model: root.bindList.filter(b =>
                        b.keys.toLowerCase()
                            .includes(
                                filterField.text.toLowerCase()
                            )
                        ||
                        b.action.toLowerCase()
                            .includes(
                                filterField.text.toLowerCase()
                            )
                    )

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 28
                        radius: 5

                        color:
                            index % 2
                            ? "#11242036"
                            : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter

                            color: "#7dcfff"
                            font.pixelSize: 12

                            text: modelData.keys
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter

                            width: 300

                            color: "#a9b1d6"
                            font.pixelSize: 12

                            elide: Text.ElideRight

                            text: modelData.action
                        }
                    }
                }

                Text {
                    color: "#565f89"
                    font.pixelSize: 11

                    text:
                        "type to filter · Super+/ to close"
                }
            }

            Keys.onEscapePressed:
                root.shown = false
        }
    }

    onShownChanged: {
        if (root.shown)
            bindsProc.running = true
    }
}
