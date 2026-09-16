import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: "Pick thread"
    modal: true
    width: Math.min(560, root.parent ? root.parent.width - 48 : 560)
    height: Math.min(460, root.parent ? root.parent.height - 48 : 460)
    padding: 16
    anchors.centerIn: parent
    standardButtons: Dialog.Ok | Dialog.Cancel
    property string gid: ""
    property var threads: []
    property bool sampling: false

    function start(gid) {
        root.gid = gid
        root.threads = []
        var r = backend.pickThread(gid)
        if (r === "nobridge") {
            statusLabel.text = "No live translation session (bridge :6677 silent).\nLaunch Setup first so threads start flowing."
            root.sampling = false
        } else if (r !== "") {
            statusLabel.text = r
            root.sampling = false
        } else {
            statusLabel.text = "Sampling threads… (advance the game text)"
            root.sampling = true
        }
        root.open()
    }

    Connections {
        target: backend
        function onThreadResults(payload) {
            if (!root.visible)
                return
            var data = JSON.parse(payload)
            root.sampling = false
            if (data.error) {
                statusLabel.text = "Sampling failed: " + data.error
                return
            }
            if (!data.threads || data.threads.length === 0) {
                statusLabel.text = "No tagged threads seen in 20s.\nAdvance the in-game text and retry."
                return
            }
            var rows = data.threads.slice()
            rows.push({num: "*", name: "", addr: "", n: 0,
                       last: "Follow Textractor's own selection (*)", current: false,
                       follow: true})
            root.threads = rows
            statusLabel.text = data.threads.length + " threads — pick the story thread:"
        }
    }

    onAccepted: {
        var t = root.threads[threadList.currentIndex]
        if (t)
            backend.saveThread(root.gid, t.follow ? "" : t.name)
    }

    ColumnLayout {
        spacing: 10
        width: availableWidth
        height: availableHeight

        Label {
            id: statusLabel
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ListView {
            id: threadList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.threads
            delegate: ItemDelegate {
                width: threadList.width
                onClicked: threadList.currentIndex = index
                contentItem: ColumnLayout {
                    spacing: 2
                    Label {
                        text: modelData.follow ? modelData.last
                              : modelData.name + "  (#" + modelData.num + ", " + modelData.n + " lines)"
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
