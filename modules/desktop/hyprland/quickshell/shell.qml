
//@ pragma UseQApplication

import Quickshell

ShellRoot {
    id: root

    property bool shown: false
    property bool bindsShown: false

    Bar {}

    Dashboard {
        shown: root.shown
    }

    Keybinds {
        shown: root.bindsShown
    }

    IpcHandler {
        target: "dashboard"

        function toggle() {
            root.shown = !root.shown
        }
    }

    IpcHandler {
        target: "keybinds"

        function toggle() {
            root.bindsShown = !root.bindsShown
        }
    }
}
