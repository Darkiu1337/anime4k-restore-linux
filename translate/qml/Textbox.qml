import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtQuick.Layouts

// Textbox.qml — Luna-style translation readout (see docs/translate.md).
ApplicationWindow {
    id: root
    objectName: "textboxWindow"
    title: "vn-translate"
    width: 520
    height: 320
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Tool

    function withAlpha(hex, a) {
        var h = ("0" + Math.round(Math.min(1, Math.max(0, a)) * 255).toString(16)).slice(-2)
        return "#" + h + hex.slice(1)
    }

    component BarButton : ToolButton {
        property string tip: ""
        font.pointSize: 9
        palette.buttonText: theme.text
        ToolTip.text: tip
        ToolTip.visible: hovered && tip.length > 0
        ToolTip.delay: 500
        background: Rectangle {
            radius: 5
            color: checked ? theme.accent : (hovered ? theme.hover : "transparent")
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: backend.cornerRadius
        color: withAlpha(theme.panel, backend.panelAlpha)

        HoverHandler {
            onHoveredChanged: backend.pointerAt(-1, -1, hovered)
            onPointChanged: backend.pointerAt(point.position.x, point.position.y, true)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ---- titlebar (drag handle + window buttons) ----
            Rectangle {
                id: titlebarRect
                Layout.fillWidth: true
                Layout.preferredHeight: titleRow.implicitHeight + 4
                visible: backend.chromeVisible
                color: withAlpha(theme.panelAlt, backend.panelAlpha)
                topLeftRadius: backend.cornerRadius
                topRightRadius: backend.cornerRadius
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.radius
                    color: parent.color
                }
                onHeightChanged: backend.setChromeGeometry(height, toolbarRect.height)

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    onPressed: root.startSystemMove()
                    onEntered: backend.setChromeHovered(true)
                    onExited: backend.setChromeHovered(false)
                }

                RowLayout {
                    id: titleRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 4

                    Label {
                        text: "vn-translate"
                        color: theme.text
                        font.pointSize: 9
                        Layout.fillWidth: true
                    }
                    BarButton { text: "Top"; checkable: true; checked: backend.keepOnTop; tip: "Keep on top (Hyprland: also pins the window)"; onClicked: backend.toggleTop() }
                    BarButton { text: "Click"; checkable: true; checked: backend.clickThrough; tip: "Click-through (hover either bar to click)"; onClicked: backend.toggleClickthrough() }
                    BarButton { text: "_"; tip: "Minimize"; onClicked: backend.minimize() }
                    BarButton { text: "x"; tip: "Close"; onClicked: root.close() }
                }
            }

            // ---- scrolling history ----
            ListView {
                id: history
                objectName: "historyView"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: pairModel
                spacing: 6
                ScrollBar.vertical: ScrollBar {}
                // Stick-to-bottom latch (see docs/translate.md).
                property bool stickBottom: true
                property real lastY: 0
                onCountChanged: { stickBottom = atYEnd; if (stickBottom) positionViewAtEnd(); }
                onContentHeightChanged: if (stickBottom && count > 0) positionViewAtEnd()
                onMovementEnded: stickBottom = atYEnd

                onContentYChanged: {
                    if (contentY < lastY - 1) stickBottom = false;
                    else if (atYEnd) stickBottom = true;
                    lastY = contentY;
                }

                delegate: Column {
                    width: ListView.view.width
                    spacing: 2
                    leftPadding: 8
                    rightPadding: 8
                    Item {
                        width: parent.width - 16
                        height: jaEdit.contentHeight
                        visible: backend.showJa
                        TextEdit {
                            id: jaEdit
                            anchors.fill: parent
                            text: ja
                            color: backend.jaColor
                            font.family: backend.fontFamily
                            font.pointSize: Math.max(8, backend.fontSize - 2)
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            readOnly: true
                            selectByMouse: true
                            selectByKeyboard: true
                            cursorVisible: false
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: jaEdit
                            visible: backend.shadowEnabled
                            autoPaddingEnabled: true
                            shadowEnabled: true
                            shadowColor: backend.shadowColor
                            shadowBlur: 0.6
                            shadowOpacity: 0.9
                        }
                    }
                    Item {
                        width: parent.width - 16
                        height: enEdit.contentHeight
                        TextEdit {
                            id: enEdit
                            anchors.fill: parent
                            text: en
                            color: backend.enColor
                            font.family: backend.fontFamily
                            font.pointSize: backend.fontSize
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            readOnly: true
                            selectByMouse: true
                            selectByKeyboard: true
                            cursorVisible: false
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: enEdit
                            visible: backend.shadowEnabled
                            autoPaddingEnabled: true
                            shadowEnabled: true
                            shadowColor: backend.shadowColor
                            shadowBlur: 0.6
                            shadowOpacity: 0.9
                        }
                    }
                }
            }

            // ---- function toolbar ----
            Rectangle {
                id: toolbarRect
                Layout.fillWidth: true
                Layout.preferredHeight: toolRow.implicitHeight + 6
                visible: backend.chromeVisible
                color: withAlpha(theme.panelAlt, backend.panelAlpha)
                bottomLeftRadius: backend.cornerRadius
                bottomRightRadius: backend.cornerRadius
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.radius
                    color: parent.color
                }
                onHeightChanged: backend.setChromeGeometry(titlebarRect.height, height)

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    onEntered: backend.setChromeHovered(true)
                    onExited: backend.setChromeHovered(false)
                }

                RowLayout {
                    id: toolRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 2

                    BarButton { text: backend.showJa ? "JA+EN" : "EN-only"; tip: "Toggle: translation only / original + translation"; onClicked: backend.toggleMode() }
                    BarButton { text: "Re"; tip: "Re-translate last line"; onClicked: backend.retranslate() }
                    BarButton { text: "Copy"; tip: "Copy last translation"; onClicked: backend.copyCurrent() }
                    BarButton { text: "Auto"; checkable: true; checked: backend.autoHide; tip: "Auto-disappear after delay, reappear on new text"; onClicked: backend.toggleAutohide() }
                    BarButton { text: "A-"; tip: "Smaller font"; onClicked: backend.bumpFont(-1) }
                    BarButton { text: "A+"; tip: "Larger font"; onClicked: backend.bumpFont(1) }
                    BarButton { text: "Clear"; tip: "Clear history"; onClicked: backend.clearHistory() }
                    BarButton { text: "Style"; tip: "Text and window style"; onClicked: styleDrawer.open() }
                    Label {
                        text: backend.statusText
                        color: theme.subtext
                        font.pointSize: 8
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        cursorShape: Qt.SizeFDiagCursor
                        onPressed: root.startSystemResize(Qt.BottomRightEdge)
                    }
                }
            }
        }
    }

    // ---- style drawer ----
    Drawer {
        id: styleDrawer
        objectName: "styleDrawer"
        width: Math.min(300, root.width * 0.8)
        height: root.height
        edge: Qt.RightEdge
        onVisibleChanged: backend.setDrawerOpen(visible)
        palette.text: theme.text
        palette.buttonText: theme.buttonText
        palette.windowText: theme.subtext
        palette.highlightedText: theme.text

        background: Rectangle {
            color: withAlpha(theme.panel, 0.97)
            radius: backend.cornerRadius
        }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 10
            clip: true

            ColumnLayout {
                objectName: "styleColumn"
                width: styleDrawer.width - 20 - 14
                spacing: 8

                Label { text: "Style"; color: theme.text; font.pointSize: 12; font.bold: true }

                Label { text: "Font"; color: theme.subtext; font.pointSize: 9 }
                ComboBox {
                    objectName: "fontCombo"
                    Layout.fillWidth: true
                    model: ["Default"].concat(fontFamilies)
                    currentIndex: backend.fontFamily === "" ? 0 : Math.max(0, find(backend.fontFamily))
                    onActivated: backend.fontFamily = index === 0 ? "" : currentText
                }

                Label { text: "Size"; color: theme.subtext; font.pointSize: 9 }
                SpinBox {
                    Layout.fillWidth: true
                    from: 8
                    to: 32
                    value: Math.round(backend.fontSize)
                    onValueModified: backend.fontSize = value
                }

                Label { text: "Colors"; color: theme.subtext; font.pointSize: 9 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Button {
                        objectName: "enColorBtn"
                        text: "EN"
                        onClicked: { styleDrawer.colorTarget = "en"; colorDialog.open() }
                        background: Rectangle { radius: 5; color: backend.enColor; border.color: theme.border }
                        contentItem: Text { text: "EN"; color: "#ffffff"; style: Text.Outline; styleColor: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        objectName: "jaColorBtn"
                        text: "JA"
                        onClicked: { styleDrawer.colorTarget = "ja"; colorDialog.open() }
                        background: Rectangle { radius: 5; color: backend.jaColor; border.color: theme.border }
                        contentItem: Text { text: "JA"; color: "#ffffff"; style: Text.Outline; styleColor: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        objectName: "shColorBtn"
                        text: "Sh"
                        onClicked: { styleDrawer.colorTarget = "shadow"; colorDialog.open() }
                        background: Rectangle { radius: 5; color: backend.shadowColor; border.color: theme.border }
                        contentItem: Text { text: "Sh"; color: "#ffffff"; style: Text.Outline; styleColor: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }

                CheckBox {
                    text: "Text shadow"
                    checked: backend.shadowEnabled
                    onToggled: backend.shadowEnabled = checked
                }

                Label { text: "Background opacity: " + Math.round(backend.panelAlpha * 100) + "%"; color: theme.subtext; font.pointSize: 9 }
                Slider {
                    Layout.fillWidth: true
                    from: 0.2
                    to: 1.0
                    stepSize: 0.01
                    value: backend.panelAlpha
                    onMoved: backend.panelAlpha = value
                }

                Label { text: "Corner radius: " + backend.cornerRadius + "px (compositor default)"; color: theme.subtext; font.pointSize: 9 }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 16
                    stepSize: 1
                    value: backend.cornerRadius
                    onMoved: backend.cornerRadius = Math.round(value)
                }

                CheckBox {
                    text: "Auto-hide top/bottom bars"
                    checked: backend.chromeAutoHide
                    onToggled: backend.chromeAutoHide = checked
                }
            }
        }

        property string colorTarget: "en"
    }

    // Popups nested in containers may never overlay; keep dialogs window-level.
    ColorDialog {
        id: colorDialog
        objectName: "colorDialog"
        selectedColor: styleDrawer.colorTarget === "en" ? backend.enColor
                     : styleDrawer.colorTarget === "ja" ? backend.jaColor
                     : backend.shadowColor
        onAccepted: {
            if (styleDrawer.colorTarget === "en") backend.enColor = selectedColor;
            else if (styleDrawer.colorTarget === "ja") backend.jaColor = selectedColor;
            else backend.shadowColor = selectedColor;
        }
    }

    onClosing: backend.saveState()
}
