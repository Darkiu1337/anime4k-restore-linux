import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    objectName: "mainWindow"
    title: "Anime4K Launcher"
    width: 1100
    height: 700
    visible: true
    color: theme.bg
    property string gid: ""

    function refreshDetails() {
        detailText.text = root.gid === "" ? "Select a game." : backend.gameDetails(root.gid)
        detailIcon.source = root.gid === "" ? "" : backend.iconFor(root.gid)
        logView.clear()
        if (root.gid !== "")
            logView.append("— launch to populate logs —\n")
    }

    function selectIndex(i) {
        root.gid = (i >= 0 && i < gameList.count) ? gamesModel.gidAt(i) : ""
        refreshDetails()
    }

    function ensureSelection() {
        if (gameList.count === 0) {
            selectIndex(-1)
        } else if (gameList.currentIndex < 0) {
            gameList.currentIndex = 0
        } else {
            selectIndex(gameList.currentIndex)
        }
    }

    function err(text) {
        promptDlg.ask("Notice", text, ["OK"], "local")
    }

    Component.onCompleted: ensureSelection()

    menuBar: MenuBar {
        Menu {
            title: "File"
            Action {
                text: "Settings…"
                onTriggered: { settingsDlg.load(); settingsDlg.open() }
            }
            Action {
                text: "Quit"
                onTriggered: root.close()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        ColumnLayout {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            spacing: 6
            Label { text: "Games"; color: theme.text; font.bold: true }
            ListView {
                id: gameList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: gamesModel
                highlight: Rectangle { color: theme.hover; radius: 4 }
                onCurrentIndexChanged: root.selectIndex(currentIndex)
                onCountChanged: root.ensureSelection()
                delegate: ItemDelegate {
                    width: gameList.width
                    onClicked: gameList.currentIndex = index
                    contentItem: RowLayout {
                        spacing: 8
                        Image {
                            source: model.icon
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            fillMode: Image.PreserveAspectFit
                            visible: model.icon !== ""
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Label { text: model.name; color: theme.text; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: model.info; color: theme.subtext; font.pointSize: 8; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
            RowLayout {
                Btn { text: "Add…"; Layout.fillWidth: true; onClicked: wizard.open("") }
                Btn {
                    text: "Edit…"
                    Layout.fillWidth: true
                    enabled: root.gid !== ""
                    onClicked: wizard.open(root.gid)
                }
                Btn {
                    text: "Remove"
                    Layout.fillWidth: true
                    enabled: root.gid !== ""
                    onClicked: promptDlg.ask("Remove game", "Remove this game from the library?", ["Remove", "Cancel"], "delete")
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Image {
                    id: detailIcon
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                }
                Text {
                    id: detailText
                    text: "Select a game."
                    color: theme.text
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    Layout.fillWidth: true
                }
            }

            GridLayout {
                columns: 4
                Btn {
                    text: "Launch"
                    enabled: root.gid !== "" && !backend.running
                    onClicked: {
                        var r = backend.launchGame(root.gid, false)
                        if (r !== "" && r !== "pending")
                            err(r)
                    }
                }
                Btn {
                    text: "Launch unfiltered (A/B)"
                    enabled: root.gid !== "" && !backend.running
                    onClicked: {
                        var r = backend.launchGame(root.gid, true)
                        if (r !== "" && r !== "pending")
                            err(r)
                    }
                }
                Btn {
                    text: "Translate"
                    enabled: root.gid !== "" && !backend.running
                    onClicked: {
                        var r = backend.translateGame(root.gid, false)
                        if (r !== "" && r !== "pending")
                            err(r)
                    }
                }
                Btn {
                    text: "Setup…"
                    enabled: root.gid !== "" && !backend.running
                    onClicked: {
                        var r = backend.translateGame(root.gid, true)
                        if (r !== "" && r !== "pending")
                            err(r)
                    }
                }
                Btn {
                    text: "Pick thread…"
                    enabled: root.gid !== ""
                    onClicked: pickThreadDlg.start(root.gid)
                }
                Btn {
                    text: "Textbox"
                    onClicked: backend.openTextbox(root.gid)
                }
                Btn {
                    text: "Stop"
                    enabled: backend.running
                    onClicked: backend.stopGame()
                }
                Btn {
                    text: "Preview command"
                    enabled: root.gid !== ""
                    onClicked: {
                        previewLabel.text = backend.previewCommand(root.gid)
                        previewDlg.open()
                    }
                }
            }

            Label { text: backend.statusText; color: theme.text }
            Label { text: backend.bridgeText; color: theme.subtext }

            TextArea {
                id: logView
                objectName: "logView"
                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                wrapMode: TextEdit.Wrap
                placeholderText: "Launch output appears here…"
                color: theme.text
                background: Rectangle { color: theme.field; radius: 6; border.color: theme.border }
            }
        }
    }

    Wizard { id: wizard }
    SettingsDlg { id: settingsDlg }
    PickThreadDlg { id: pickThreadDlg }
    PromptDlg { id: promptDlg }

    Dialog {
        id: previewDlg
        title: "Resolved command"
        modal: true
        width: 640
        standardButtons: Dialog.Ok
        palette.windowText: theme.text
        Label {
            id: previewLabel
            width: parent ? parent.width : 0
            color: theme.text
            wrapMode: Text.Wrap
        }
        background: Rectangle { color: theme.panel; radius: 8; border.color: theme.border }
    }

    Connections {
        target: backend
        function onLogAppended(line) { logView.append(line); logView.cursorPosition = logView.length }
        function onLogCleared() { logView.clear() }
        function onPrompt(title, text, buttons) { promptDlg.ask(title, text, JSON.parse(buttons)) }
        function onGamesChanged() { root.ensureSelection() }
    }

    Connections {
        target: promptDlg
        function onDone(result) {
            if (promptDlg.tag === "delete" && result === 0 && root.gid !== "")
                backend.removeGame(root.gid)
        }
    }

    background: Rectangle { color: theme.bg }
}
