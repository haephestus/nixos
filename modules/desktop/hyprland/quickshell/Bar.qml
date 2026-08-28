import Quickshell
import Quickshell

PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 35
  Rectangle {
    anchors.fill: parent
    color: "#1e1e2e"

    Text {
      anchors.centerIn: parent
      text: "Hello World"
      color: "#cdd6f4"
    }
  }
}
