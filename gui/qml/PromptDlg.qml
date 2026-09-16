import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    modal: true
    width: 440
    height: contentItem.implicitHeight + topPadding + bottomPadding
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

    contentItem: Column {
        width: availableWidth
        spacing: 12
        Label {
            text: root.body
            width: parent.width
            wrapMode: Text.Wrap
        }
        Repeater {
            model: root.options
            Btn {
                text: modelData
                width: parent.width
                onClicked: { root.choice = index; root.close() }
            }
        }
    }
}
