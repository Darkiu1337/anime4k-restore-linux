import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    modal: true
    width: 440
    padding: 16
    anchors.centerIn: parent
    standardButtons: Dialog.NoButton
    property string body: ""
    property var options: []
    property int choice: -1
    property string tag: "backend"
    signal done(int result)

    function ask(title, text, buttons, tag) {
        root.title = title
        root.body = text
        root.options = buttons
        root.tag = tag || "backend"
        root.choice = -1
        root.open()
    }

    onClosed: {
        if (root.tag === "backend") {
            backend.resolvePrompt(root.choice >= 0 ? root.choice : -1)
        } else {
            root.done(root.choice)
        }
    }

    ColumnLayout {
        spacing: 12
        width: availableWidth
        Label {
            text: root.body
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Repeater {
            model: root.options
            Btn {
                text: modelData
                Layout.fillWidth: true
                onClicked: { root.choice = index; root.close() }
            }
        }
    }
}
