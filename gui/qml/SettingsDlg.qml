import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: "Settings"
    modal: true
    width: 520
    standardButtons: Dialog.Save | Dialog.Cancel
    palette.windowText: theme.text
    property string prefix: ""
    property string proton: ""
    property string layerDir: ""
    property string themeName: "System"
    property var themeOptions: ["System", "Omarchy", "dark", "light"]

    function load() {
        var cfg = JSON.parse(backend.loadSettings())
        root.prefix = cfg["prefix"] || ""
        root.proton = cfg["proton"] || ""
        root.layerDir = cfg["layer_dir"] || ""
        root.themeName = cfg["gui.theme"] || "System"
        prefixField.text = root.prefix
        protonField.text = root.proton
        layerField.text = root.layerDir
        var i = themeCombo.find(root.themeName)
        themeCombo.currentIndex = i >= 0 ? i : 0
    }

    onAccepted: {
        backend.saveSettings(JSON.stringify({
            "prefix": prefixField.text.trim(),
            "proton": protonField.text.trim(),
            "layer_dir": layerField.text.trim(),
            "gui.theme": themeCombo.currentText
        }))
    }

    GridLayout {
        columns: 2
        width: parent ? parent.width : 0
        Label { text: "Wine prefix default:"; color: theme.text }
        TextField {
            id: prefixField
            Layout.fillWidth: true
            placeholderText: "(project shared prefix)"
            color: theme.text
            background: Rectangle { color: theme.field; radius: 5; border.color: theme.border }
        }
        Label { text: "Proton default:"; color: theme.text }
        TextField {
            id: protonField
            Layout.fillWidth: true
            placeholderText: "(umu-managed — leave empty)"
            color: theme.text
            background: Rectangle { color: theme.field; radius: 5; border.color: theme.border }
        }
        Label { text: "vkBasalt layer dir:"; color: theme.text }
        TextField {
            id: layerField
            Layout.fillWidth: true
            placeholderText: "empty = system layer"
            color: theme.text
            background: Rectangle { color: theme.field; radius: 5; border.color: theme.border }
        }
        Label { text: "Theme:"; color: theme.text }
        ComboBox {
            id: themeCombo
            Layout.fillWidth: true
            model: root.themeOptions
        }
        Label {
            text: theme.source === "builtin" ? "" : "active: " + theme.source
            color: theme.subtext
            font.pointSize: 8
            Layout.columnSpan: 2
        }
        Label {
            text: "Saved. Prefix/Proton/layer changes apply to the next launch."
            color: theme.subtext
            wrapMode: Text.Wrap
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }
    }

    background: Rectangle {
        color: theme.panel
        radius: 8
        border.color: theme.border
    }
}
