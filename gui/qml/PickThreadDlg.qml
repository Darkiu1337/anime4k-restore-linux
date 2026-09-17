import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: "Pick Text Hooker"
    modal: true
    width: Math.min(560, root.parent ? root.parent.width - 48 : 560)
    height: Math.min(460, root.parent ? root.parent.height - 48 : 460)
    padding: 16
    anchors.centerIn: parent
    standardButtons: Dialog.Ok | Dialog.Cancel
    property string gid: ""
    property var threads: []
    property bool sampling: false
    property string selectedKey: ""

    // waitForBridge: keep retrying until the game/bridge comes up (used by
    // Setup, which launches the game just before opening this). Searching is
    // continuous and only ends when a thread is accepted or the dialog closes.
    function start(gid, waitForBridge) {
        root.gid = gid
        root.threads = []
        root.selectedKey = ""
        root.open()
        var r = backend.pickThread(gid)
        if (r === "nobridge") {
            if (waitForBridge) {
                statusLabel.text = "Waiting for the game and the text bridge…"
                root.sampling = false
                bridgeWait.restart()
            } else {
                statusLabel.text = "No live translation session (bridge :6677 silent).\nLaunch Setup Text Hooker for translation first."
                root.sampling = false
            }
        } else if (r !== "") {
            statusLabel.text = r
            root.sampling = false
        } else {
            statusLabel.text = "Searching for text threads… (advance the game text)"
            root.sampling = true
        }
    }

    function selectKey(key) {
        if (key === "")
            return
        for (var i = 0; i < root.threads.length; ++i) {
            var t = root.threads[i]
            if ((t.follow ? "*" : t.name) === key) {
                threadList.currentIndex = i
                return
            }
        }
    }

    Timer {
        id: bridgeWait
        interval: 2000
        repeat: true
        onTriggered: {
            var r = backend.pickThread(root.gid)
            if (r === "") {
                stop()
                statusLabel.text = "Searching for text threads… (advance the game text)"
                root.sampling = true
            } else if (r !== "nobridge") {
                stop()
                statusLabel.text = r
                root.sampling = false
            }
        }
    }

    onClosed: {
        bridgeWait.stop()
        backend.cancelPick()
    }

    Connections {
        target: backend
        function onThreadResults(payload) {
            if (!root.visible)
                return
            var data = JSON.parse(payload)
            if (data.error) {
                statusLabel.text = "Waiting for the text bridge…"
                root.sampling = true
                return
            }
            if (!data.threads || data.threads.length === 0)
                return
            var keep = root.selectedKey
            var rows = data.threads.slice()
            rows.push({num: "*", name: "", addr: "", n: 0,
                       last: "Follow Textractor's own selection (fallback; needs Textractor shown)",
                       current: false, follow: true})
            root.threads = rows
            root.sampling = false
            if (keep !== "")
                root.selectKey(keep)
            statusLabel.text = data.threads.length + " thread(s) — pick the text hook"
                + " (list keeps updating as you advance)"
        }
    }

    onAccepted: {
        backend.cancelPick()
        var t = root.threads[threadList.currentIndex]
        if (t)
            backend.saveThread(root.gid, t.follow ? "" : t.name)
    }

    ColumnLayout {
        spacing: 10
        width: availableWidth
        height: availableHeight

        // Underline below the dialog title (matches the top bar divider).
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.palette.windowText
            opacity: 0.25
        }

        Label {
            id: statusLabel
            objectName: "threadStatus"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ListView {
            id: threadList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.threads
            onCurrentIndexChanged: {
                var ok = root.standardButton(Dialog.Ok)
                if (ok)
                    ok.enabled = currentIndex >= 0
            }
            delegate: ItemDelegate {
                width: threadList.width
                onClicked: {
                    threadList.currentIndex = index
                    root.selectedKey = modelData.follow ? "*" : modelData.name
                }
                contentItem: ColumnLayout {
                    spacing: 2
                    Label {
                        text: modelData.follow ? modelData.last
                              : modelData.name + "  (#" + modelData.num
                                + (modelData.addr ? ", @" + modelData.addr : "")
                                + ", " + modelData.n + " lines)"
                                + (modelData.current ? "  ← current" : "")
                        font.bold: !modelData.follow
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Label {
                        text: modelData.follow ? "" : modelData.last
                        opacity: 0.7
                        font.pointSize: 8
                        elide: Text.ElideRight
                        visible: text !== ""
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
