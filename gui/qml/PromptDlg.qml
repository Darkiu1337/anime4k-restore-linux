import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    modal: true
    width: 440
    standardButtons: Dialog.NoButton
    palette.windowText: theme.text
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
            if (root.choice >= 0)
                backend.resolvePrompt(root.choice)
            else
                backend.resolvePrompt(-1)
        } else {
            root.done(root.choice)
        }
    }

    ColumnLayout {
        width: parent ? parent.width : 0
        spacing: 10
        Label {
            text: root.body
            color: theme.text
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

    background: Rectangle {
        color: theme.panel
        radius: 8
        border.color: theme.border
    }
}
