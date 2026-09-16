import QtQuick
import QtQuick.Controls

Button {
    id: root
    palette.buttonText: theme.buttonText
    contentItem: Text {
        text: root.text
        color: theme.buttonText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 6
        color: !root.enabled ? theme.panelAlt : root.pressed ? theme.pressed : root.hovered ? theme.hover : theme.panel
        border.color: theme.border
        border.width: 1
    }
}
