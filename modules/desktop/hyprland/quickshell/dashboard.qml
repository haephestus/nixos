
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool shown: false
    property real volume: 0.4
    property bool muted: false
    property string defaultSink: ""
    property var sinks: []

    function run(cmd) {
        runner.command = ["sh", "-c", cmd]
        runner.running = true
    }

    function refresh() {
        volProc.running = true
        sinksAll.running = true
    }

    Process {
        id: volProc

        command: [
            "sh", "-c",
            "echo VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@); " +
            "echo SINK=$(pactl get-default-sink 2>/dev/null)"
        ]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("VOL=")) {
                    root.muted = data.includes("MUTED")

                    const v = parseFloat(
                        data.slice(4)
                            .replace("[MUTED]", "")
                            .replace("Volume:", "")
                            .trim()
                    )

                    if (!isNaN(v)) {
                        root.volume = v
                        slider.value = v
                    }
                } else if (data.startsWith("SINK=")) {
                    root.defaultSink = data.slice(5).trim()
                }
            }
        }
    }

    Process {
        id: sinksAll

        command: [
            "sh", "-c",
            "pactl -f json list sinks 2>/dev/null || true"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(this.text)

                    root.sinks = arr.map(s => ({
                        name: s.name,
                        desc: s.description || s.name,
                        active: s.name === root.defaultSink
                    }))
                } catch (e) {
                    root.sinks = []
                }
            }
        }
    }

    Process {
        id: runner

        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }

    Timer {
        interval: 2000
        running: root.shown
        repeat: true
        onTriggered: root.refresh()
    }

    onShownChanged: {
        if (root.shown)
            root.refresh()
    }

    PanelWindow {
        visible: root.shown

        anchors {
            right: true
            top: true
            bottom: true
        }

        width: 360
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.margins: 8

            radius: 12
            color: "#ee1a1b26"
            border.color: "#557aa2f7"

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Text {
                    color: "#c0caf5"
                    font.pixelSize: 16
                    font.bold: true
                    text: "dashboard"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#337aa2f7"
                }

                Text {
                    color: "#565f89"
                    text: "OUTPUT — " + root.defaultSink
                }

                Slider {
                    id: slider

                    width: parent.width

                    from: 0
                    to: 1

                    background: Rectangle {
                        x: slider.leftPadding
                        y: slider.topPadding
                           + slider.availableHeight / 2
                           - height / 2

                        width: slider.availableWidth
                        height: 6
                        radius: 3

                        color: "#33242036"

                        Rectangle {
                            width: slider.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: "#ff7aa2f7"
                        }
                    }

                    handle: Rectangle {
                        x: slider.leftPadding
                           + slider.visualPosition
                           * (slider.availableWidth - width)

                        y: slider.topPadding
                           + slider.availableHeight / 2
                           - height / 2

                        width: 16
                        height: 16
                        radius: 8

                        color: "#ee7aa2f7"
                        border.color: "#1a1b26"
                        border.width: 2
                    }

                    onMoved: root.run(
                        "wpctl set-volume @DEFAULT_AUDIO_SINK@ "
                        + value.toFixed(2)
                    )
                }

                Row {
                    spacing: 10

                    Repeater {
                        model: [
                            {
                                t: root.muted ? "unmute" : "mute",
                                a: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                            },
                            {
                                t: "−",
                                a: "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                            },
                            {
                                t: "+",
                                a: "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                            }
                        ]

                        delegate: Rectangle {
                            width: btnText.width + 24
                            height: 30
                            radius: 6

                            color: ma.pressed
                                ? "#557aa2f7"
                                : "#22242036"

                            border.color: "#447aa2f7"

                            Text {
                                id: btnText
                                anchors.centerIn: parent

                                color: "#c0caf5"
                                text: modelData.t
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent

                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                    root.run(modelData.a)
                            }
                        }
                    }
                }

                Text {
                    color: root.muted
                        ? "#f7768e"
                        : "#c0caf5"

                    text:
                        "volume "
                        + Math.round(root.volume * 100)
                        + "%"
                        + (root.muted ? "  [MUTED]" : "")
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#337aa2f7"
                }

                Text {
                    color: "#565f89"
                    text: "DEVICES"
                }

                Repeater {
                    model: root.sinks

                    delegate: Rectangle {
                        width: parent.width
                        height: 34
                        radius: 6

                        color: modelData.active
                            ? "#333473a5"
                            : "#22242036"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10

                            spacing: 8

                            Text {
                                color: modelData.active
                                    ? "#7dcfff"
                                    : "#565f89"

                                text: modelData.active ? "▸" : " "
                            }

                            Text {
                                width: 280

                                elide: Text.ElideRight

                                color: modelData.active
                                    ? "#c0caf5"
                                    : "#a9b1d6"

                                text: modelData.desc
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked:
                                root.run(
                                    "pactl set-default-sink "
                                    + modelData.name
                                )
                        }
                    }
                }

                Item {
                    height: 1
                    width: 1
                }

                Text {
                    color: "#565f89"
                    font.pixelSize: 11
                    text: "Super+D to close"
                }
            }
        }
    }
}
