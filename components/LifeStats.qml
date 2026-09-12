pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons

Column {
  id: root

  property var rows: []
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  spacing: Style.space(10)

  Repeater {
    model: root.rows

    delegate: Item {
      id: row
      required property var modelData
      width: root.width
      height: Math.max(label.implicitHeight, value.implicitHeight)

      Text {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: String(row.modelData.label || "")
        color: Qt.darker(root.foreground, 1.55)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: value
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: String(row.modelData.value || "")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: row.modelData.emphasis === true
      }
    }
  }
}
