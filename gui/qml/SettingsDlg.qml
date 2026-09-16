import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: "Settings"
    modal: true
    width: Math.min(560, root.parent ? root.parent.width - 48 : 560)
    padding: 16
    anchors.centerIn: parent
    standardButtons: Dialog.Save | Dialog.Cancel
    property string prefix: ""
    property string proton: ""
    property string layerDir: ""

    function load() {
        var cfg = JSON.parse(backend.loadSettings())
        root.prefix = cfg["prefix"] || ""
        root.proton = cfg["proton"] || ""
        root.layerDir = cfg["layer_dir"] || ""
        prefixField.text = root.prefix
        protonField.text = root.proton
        layerField.text = root.layerDir
    }

    onAccepted: {
        backend.saveSettings(JSON.stringify({
            "prefix": prefixField.text.trim(),
            "proton": protonField.text.trim(),
            "layer_dir": layerField.text.trim()
        }))
    }

    GridLayout {
        columns: 2
        width: availableWidth
        columnSpacing: 12
        rowSpacing: 10

        Label { text: "Wine prefix default:" }
        TextField {
            id: prefixField
            Layout.fillWidth: true
            placeholderText: "(project shared prefix)"
        }
        Label { text: "Proton default:" }
        TextField {
            id: protonField
            Layout.fillWidth: true
            placeholderText: "(umu-managed — leave empty)"
        }
        Label { text: "vkBasalt layer dir:" }
        TextField {
            id: layerField
            Layout.fillWidth: true
            placeholderText: "empty = system layer"
        }
        Label {
            text: "Saved prefix/Proton/layer changes apply to the next launch. " +
                  "The window follows your desktop colour scheme."
            opacity: 0.7
            font.pointSize: 8
            wrapMode: Text.Wrap
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }
    }
}
