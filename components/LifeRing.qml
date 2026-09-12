import QtQuick
import qs.Commons

Item {
  id: root

  property real progress: 0
  property string percentText: "0.00%"
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property int strokeWidth: Style.space(10)

  readonly property real clampedProgress: Math.max(0, Math.min(1, Number(progress) || 0))
  readonly property color progressColor: Style.selectedStateColor(foreground, accent)
  property real displayedProgress: clampedProgress

  implicitWidth: Style.space(220)
  implicitHeight: implicitWidth

  function rgba(value, alpha) {
    return "rgba(" + Math.round(value.r * 255) + ","
      + Math.round(value.g * 255) + ","
      + Math.round(value.b * 255) + "," + alpha + ")"
  }

  onDisplayedProgressChanged: ringCanvas.requestPaint()
  onForegroundChanged: ringCanvas.requestPaint()
  onProgressColorChanged: ringCanvas.requestPaint()
  onStrokeWidthChanged: ringCanvas.requestPaint()

  Behavior on displayedProgress {
    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
  }

  Canvas {
    id: ringCanvas
    anchors.fill: parent
    antialiasing: true

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (width <= 0 || height <= 0) return

      var line = Math.max(1, Math.min(root.strokeWidth, Math.min(width, height) / 4))
      var radius = Math.max(0, (Math.min(width, height) - line) / 2)
      var centerX = width / 2
      var centerY = height / 2
      var start = -Math.PI / 2

      ctx.lineWidth = line
      ctx.lineCap = "round"
      ctx.beginPath()
      ctx.strokeStyle = root.rgba(root.foreground, 0.12)
      ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false)
      ctx.stroke()

      if (root.displayedProgress > 0) {
        ctx.beginPath()
        ctx.strokeStyle = root.rgba(root.progressColor, 1)
        ctx.arc(centerX, centerY, radius, start,
          start + Math.PI * 2 * root.displayedProgress, false)
        ctx.stroke()
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.percentText
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Math.max(Style.font.body, Math.round(Math.min(root.width, root.height) * 0.16))
    font.bold: true
  }
}
