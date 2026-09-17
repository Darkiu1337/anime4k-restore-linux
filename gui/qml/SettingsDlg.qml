import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: "Settings"
    modal: true
    width: Math.min(600, root.parent ? root.parent.width - 48 : 600)
    padding: 16
    anchors.centerIn: parent
    standardButtons: Dialog.Save | Dialog.Cancel
    property string prefix: ""
    property string proton: ""
    property string layerDir: ""
    property string guiFont: ""
    property int guiFontSize: 0
    property var protonChoices: []

    function load() {
        var cfg = JSON.parse(backend.loadSettings())
        root.prefix = cfg["prefix"] || ""
        root.proton = cfg["proton"] || ""
        root.layerDir = cfg["layer_dir"] || ""
        root.guiFont = cfg["gui.font"] || ""
        root.guiFontSize = parseInt(cfg["gui.font_size"] || 0, 10) || 0
        prefixField.text = root.prefix
        layerField.text = root.layerDir
        refreshProtons()
        fontCombo.currentIndex = root.guiFont === "" ? 0
            : Math.max(0, fontCombo.find(root.guiFont))
        fontSize.value = root.guiFontSize > 0 ? root.guiFontSize : 0
    }

    function refreshProtons() {
        var list = JSON.parse(backend.protonsJson())
        var idx = -1
        for (var i = 0; i < list.length; i++) {
            if (list[i].value === root.proton) { idx = i; break }
        }
        if (idx < 0 && root.proton !== "") {
            // Keep a configured value the scan did not find (e.g. a bare name).
            list = list.concat([{ "label": root.proton + "  (not detected)",
                                  "value": root.proton, "wow64": true }])
            idx = list.length - 1
        }
        root.protonChoices = list
        protonCombo.model = list
        protonCombo.currentIndex = idx >= 0 ? idx : 0
    }

    function selectedProton() {
        return (protonCombo.currentIndex >= 0 && protonCombo.currentIndex < root.protonChoices.length)
            ? root.protonChoices[protonCombo.currentIndex].value : ""
    }

    onAccepted: {
        backend.saveSettings(JSON.stringify({
            "prefix": prefixField.text.trim(),
            "proton": selectedProton(),
            "layer_dir": layerField.text.trim(),
            "gui.font": fontCombo.currentIndex <= 0 ? "" : fontCombo.currentText,
            "gui.font_size": fontSize.value
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
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ComboBox {
                id: protonCombo
                objectName: "protonCombo"
                Layout.fillWidth: true
                textRole: "label"
            }
            Btn {
                text: "Refresh"
                onClicked: {
                    root.proton = selectedProton()
                    root.refreshProtons()
                }
            }
        }
        Label {
            text: "Detected from common Proton folders; some builds may not work. " +
                  "UMU-Proton (umu-managed) is the safe default."
            opacity: 0.7
            font.pointSize: 8
            wrapMode: Text.Wrap
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }
        Label {
            visible: protonCombo.currentIndex >= 0
                     && protonCombo.currentIndex < root.protonChoices.length
                     && !root.protonChoices[protonCombo.currentIndex].wow64
            text: "This build has no new WoW64 support — launching falls back to UMU-Proton."
            color: "#d9534f"
            font.pointSize: 8
            wrapMode: Text.Wrap
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }

        Label { text: "Font (this app):" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ComboBox {
                id: fontCombo
                objectName: "guiFontCombo"
                Layout.fillWidth: true
                model: ["Default (system)"].concat(
                           typeof fontFamilies !== "undefined" ? fontFamilies : [])
            }
            SpinBox {
                id: fontSize
                from: 0
                to: 72
                editable: true
                textFromValue: function (value) { return value === 0 ? "Default" : value }
                valueFromText: function (text) { return parseInt(text, 10) || 0 }
            }
        }

        Label { text: "vkBasalt layer dir:" }
        TextField {
            id: layerField
            Layout.fillWidth: true
            placeholderText: "empty = system layer"
        }

        Label {
            text: "Font applies immediately; prefix/Proton/layer changes apply to the " +
                  "next launch. The window follows your desktop colour scheme."
            opacity: 0.7
            font.pointSize: 8
            wrapMode: Text.Wrap
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }
    }
}
