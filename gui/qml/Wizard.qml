import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Dialog {
    id: root
    modal: true
    width: Math.min(680, root.parent ? root.parent.width - 48 : 680)
    height: Math.min(540, root.parent ? root.parent.height - 48 : 540)
    padding: 16
    anchors.centerIn: parent
    standardButtons: Dialog.NoButton
    property string gid: ""
    property var runnerKeys: ["proton", "rpgmaker", "native"]
    property var runnerDescs: []
    property var variantNames: []
    property string runner: "proton"

    function start(gid) {
        root.gid = gid
        root.title = gid === "" ? "Add game" : "Edit game"
        var descs = JSON.parse(backend.runnersJson())
        root.runnerDescs = root.runnerKeys.map(function(k) { return k + " — " + descs[k] })
        root.variantNames = backend.listVariants()
        variantCombo.model = root.variantNames.map(function(v) {
            var n = backend.variantNote(v)
            return n !== "" ? v + " — " + n : v
        })
        gpuCombo.model = backend.listGpus()
        if (gid === "") {
            root.runner = "proton"
            runnerRepeater.itemAt(0).checked = true
            pathField.text = ""
            detectLabel.text = "Tip: Detect fills in the runner from the previous page."
            variantCombo.currentIndex = Math.max(0, root.variantNames.indexOf("L"))
            gpuCombo.currentIndex = 0
            fpsSpin.value = 60
            hudCheck.checked = false
            langCombo.currentIndex = 0
            prefixCheck.checked = false
            nameField.text = ""
            trEnable.checked = false
            trHook.text = ""
        } else {
            var g = JSON.parse(backend.gameData(gid))
            root.runner = g.runner || "proton"
            for (var i = 0; i < root.runnerKeys.length; i++)
                runnerRepeater.itemAt(i).checked = (root.runnerKeys[i] === root.runner)
            pathField.text = g.path || ""
            variantCombo.currentIndex = Math.max(0, root.variantNames.indexOf(g.variant || "L"))
            var gi = gpuCombo.find(g.gpu || "")
            gpuCombo.currentIndex = gi >= 0 ? gi : 0
            fpsSpin.value = g.fps === "off" ? 0 : (parseInt(g.fps) || 60)
            hudCheck.checked = g.hud === "1"
            var li = langCombo.find(g.lang || "")
            if (li >= 0)
                langCombo.currentIndex = li
            else { langCombo.currentIndex = -1; langCombo.editText = g.lang || "" }
            prefixCheck.checked = g.prefix_mode === "game"
            nameField.text = g.name || ""
            var tr = g.translate || {}
            trEnable.checked = tr.enabled === "1"
            trHook.text = tr.hook_code || ""
        }
        errLabel.text = ""
        pages.currentIndex = 0
        root.open()
    }

    function collect() {
        var lang = langCombo.editText.trim()
        if (langCombo.currentIndex === 0)
            lang = ""
        return JSON.stringify({
            name: nameField.text.trim(),
            runner: root.runner,
            path: pathField.text.trim(),
            variant: variantCombo.currentText.split(" ")[0],
            gpu: gpuCombo.currentText,
            fps: fpsSpin.value === 0 ? "off" : String(fpsSpin.value),
            hud: hudCheck.checked ? "1" : "0",
            lang: lang,
            prefix_mode: prefixCheck.checked ? "game" : "shared",
            translate: {
                enabled: (trEnable.checked && root.runner === "proton") ? "1" : "0",
                hook_code: trHook.text.trim()
            }
        })
    }

    function finish() {
        var data = collect()
        if (JSON.parse(data).name === "")
            data = JSON.stringify(Object.assign(JSON.parse(data),
                {name: pathField.text.trim().split("/").pop()}))
        var err = backend.validateGame(data)
        if (err !== "") {
            errLabel.text = err
            return
        }
        err = backend.saveGame(root.gid, data)
        if (err !== "") {
            errLabel.text = err
            return
        }
        root.close()
    }

    FileDialog {
        id: exePicker
        title: "Select Windows game executable"
        nameFilters: ["Windows executables (*.exe *.EXE)", "All files (*)"]
        onAccepted: {
            var p = backend.fileUrlToPath(exePicker.selectedFile)
            if (p !== "") {
                pathField.text = p
                backend.rememberDir(p)
            }
        }
    }

    FolderDialog {
        id: dirPicker
        title: "Select RPGMaker game folder"
        onAccepted: {
            var p = backend.fileUrlToPath(dirPicker.selectedFile)
            if (p !== "") {
                pathField.text = p
                backend.rememberDir(p)
            }
        }
    }

    footer: RowLayout {
        spacing: 8
        Btn { text: "Cancel"; onClicked: root.close() }
        Item { Layout.fillWidth: true }
        Btn {
            text: "Back"
            enabled: pages.currentIndex > 0
            onClicked: pages.currentIndex--
        }
        Btn {
            text: pages.currentIndex === pages.count - 1 ? "Finish" : "Next"
            onClicked: {
                if (pages.currentIndex === pages.count - 1)
                    finish()
                else
                    pages.currentIndex++
            }
        }
    }

    ColumnLayout {
        spacing: 8
        width: availableWidth
        height: availableHeight

        StackLayout {
            id: pages
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: 0

            Item {
                ScrollView {
                    id: sv1
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: sv1.availableWidth
                        spacing: 8
                        Label { text: "Runner" + (root.gid !== "" ? " (locked: runner changes mean re-adding)" : ""); font.bold: true }
                        Repeater {
                            id: runnerRepeater
                            model: root.runnerDescs
                            RadioButton {
                                text: modelData
                                checked: index === 0
                                enabled: root.gid === ""
                                onCheckedChanged: if (checked) root.runner = root.runnerKeys[index]
                            }
                        }
                    }
                }
            }

            Item {
                ScrollView {
                    id: sv2
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: sv2.availableWidth
                        spacing: 8
                        Label { text: "Game location"; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                placeholderText: "/path/to/game"
                            }
                            Btn {
                                text: "Browse…"
                                onClicked: {
                                    if (root.runner === "rpgmaker") {
                                        dirPicker.currentFolder = backend.pathToFileUrl(backend.lastDir())
                                        dirPicker.open()
                                    } else {
                                        exePicker.currentFolder = backend.pathToFileUrl(backend.lastDir())
                                        exePicker.open()
                                    }
                                }
                            }
                            Btn {
                                text: "Detect"
                                onClicked: {
                                    var res = backend.detect(pathField.text)
                                    if (res === "") {
                                        detectLabel.text = "Detection failed to run."
                                        return
                                    }
                                    var parts = res.split("|")
                                    var r = parts[1], conf = parts[2], rroot = parts[3], detail = parts[4]
                                    if ((conf === "high" || conf === "medium") && root.runnerKeys.indexOf(r) >= 0) {
                                        root.runner = r
                                        for (var i = 0; i < root.runnerKeys.length; i++)
                                            runnerRepeater.itemAt(i).checked = (root.runnerKeys[i] === r)
                                        if (r === "rpgmaker" && !backend.isDir(pathField.text) && backend.isDir(rroot)) {
                                            pathField.text = rroot
                                            detectLabel.text = "Detected: " + detail + " → runner '" + r + "' (" + conf + "). Path set to game folder."
                                        } else {
                                            detectLabel.text = "Detected: " + detail + " → runner '" + r + "' (" + conf + " confidence)."
                                        }
                                    } else {
                                        detectLabel.text = "Detected: " + detail + " (confidence: " + conf + ") — pick the runner manually."
                                    }
                                }
                            }
                        }
                        Label {
                            id: detectLabel
                            text: "Tip: Detect fills in the runner from the previous page."
                            opacity: 0.7
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Item {
                ScrollView {
                    id: sv3
                    anchors.fill: parent
                    clip: true
                    GridLayout {
                        width: sv3.availableWidth
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 10
                        Label { text: "Filter and performance"; font.bold: true; Layout.columnSpan: 2 }
                        Label { text: "Variant:" }
                        ComboBox {
                            id: variantCombo
                            Layout.fillWidth: true
                        }
                        Label { text: "Game GPU:" }
                        ComboBox {
                            id: gpuCombo
                            Layout.fillWidth: true
                        }
                        Label { text: "FPS cap (0 = off):" }
                        SpinBox {
                            id: fpsSpin
                            from: 0
                            to: 480
                            value: 60
                            Layout.fillWidth: true
                        }
                        CheckBox {
                            id: hudCheck
                            text: "Show fps overlay while playing"
                            Layout.columnSpan: 2
                        }
                        Label { text: "Language:" }
                        ComboBox {
                            id: langCombo
                            objectName: "langCombo"
                            editable: true
                            Layout.fillWidth: true
                            model: backend.locales()
                        }
                        CheckBox {
                            id: prefixCheck
                            text: "Separate Wine prefix for this game (Proton only)"
                            Layout.columnSpan: 2
                        }
                    }
                }
            }

            Item {
                ScrollView {
                    id: sv4
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: sv4.availableWidth
                        spacing: 8
                        Label { text: "Name"; font.bold: true }
                        TextField {
                            id: nameField
                            Layout.fillWidth: true
                            placeholderText: "Display name"
                        }
                    }
                }
            }

            Item {
                ScrollView {
                    id: sv5
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: sv5.availableWidth
                        spacing: 8
                        Label { text: "Translation (Japanese VNs)"; font.bold: true }
                        CheckBox {
                            id: trEnable
                            text: "Translate Japanese dialogue via DeepL"
                        }
                        Label { text: "Hook code:" }
                        TextField {
                            id: trHook
                            Layout.fillWidth: true
                            placeholderText: "hook code, e.g. HSX10@54DC0:game.exe (optional)"
                        }
                        Label {
                            text: "Proton/Windows games only. Filter and translation compose in one launch. First run: enable, launch with Translate, pick the text hook in Textractor (Setup shows its window), paste its code here."
                            opacity: 0.7
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        Label {
            id: errLabel
            visible: text !== ""
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
