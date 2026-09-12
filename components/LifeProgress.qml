import QtQuick
import qs.Commons

Item {
  id: root

  property real progress: 0
  property color foreground: Color.foreground
  property color accent: Color.accent
  property int trackHeight: Style.space(8)

  readonly property real clampedProgress: Math.max(0, Math.min(1, Number(progress) || 0))

  implicitWidth: Style.space(280)
  implicitHeight: trackHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius > 0 ? height / 2 : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

    Rectangle {
      width: Math.round(parent.width * root.clampedProgress)
      height: parent.height
      radius: parent.radius
      color: Style.selectedStateColor(root.foreground, root.accent)

      Behavior on width {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }
    }
  }
}
