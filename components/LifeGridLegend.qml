pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons

// Legend for LifeGrid. Colours come from the grid itself so the swatches
// always match the painted cells, whatever the theme's selected colour is.
Row {
  id: root

  property var grid: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  spacing: Style.space(16)

  Repeater {
    model: [
      { label: "lived", kind: "lived" },
      { label: "now", kind: "now" },
      { label: "remaining", kind: "remaining" }
    ]

    Row {
      id: entry
      required property var modelData
      spacing: Style.space(5)

      Rectangle {
        readonly property real swatch: Math.max(6, Math.round(Style.font.caption * 0.7))
        anchors.verticalCenter: parent.verticalCenter
        width: swatch
        height: swatch
        color: entry.modelData.kind === "lived" && root.grid ? root.grid.livedColor
          : entry.modelData.kind === "now" && root.grid ? root.grid.presentColor
          : "transparent"
        border.width: entry.modelData.kind === "remaining" ? 1 : 0
        border.color: root.grid ? root.grid.emptyColor : root.foreground
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: entry.modelData.label
        color: entry.modelData.kind === "remaining"
          ? Qt.darker(root.foreground, 1.45) : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
