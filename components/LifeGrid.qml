import QtQuick
import qs.Commons

Item {
  id: root

  property int totalUnits: 0
  property int elapsedUnits: 0
  property int columns: 0
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property int safeTotal: Math.max(0, totalUnits)
  readonly property int safeElapsed: Math.max(0, Math.min(safeTotal, elapsedUnits))
  readonly property color livedColor: Style.selectedStateColor(foreground, accent)
  readonly property int fittedColumns: columns > 0 ? columns : Math.max(1,
    Math.ceil(Math.sqrt(safeTotal * Math.max(1, width) / Math.max(1, height))))
  readonly property int fittedRows: Math.max(1, Math.ceil(safeTotal / fittedColumns))

  implicitWidth: Style.space(360)
  implicitHeight: Style.space(300)

  // Kept as part of the component API. The complete grid is always visible,
  // so revealing the present only requires repainting its accent cell.
  function revealPresent() {
    canvas.requestPaint()
  }

  function rgba(value, alpha) {
    return "rgba(" + Math.round(value.r * 255) + ","
      + Math.round(value.g * 255) + ","
      + Math.round(value.b * 255) + "," + alpha + ")"
  }

  onSafeTotalChanged: canvas.requestPaint()
  onSafeElapsedChanged: canvas.requestPaint()
  onForegroundChanged: canvas.requestPaint()
  onAccentChanged: canvas.requestPaint()
  onFittedColumnsChanged: canvas.requestPaint()
  onFittedRowsChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (root.safeTotal <= 0 || width <= 0 || height <= 0) return

      var cellWidth = width / root.fittedColumns
      var cellHeight = height / root.fittedRows
      var size = Math.min(cellWidth, cellHeight)
      var gridWidth = cellWidth * root.fittedColumns
      var gridHeight = cellHeight * root.fittedRows
      var originX = (width - gridWidth) / 2
      var originY = (height - gridHeight) / 2
      var gap = size >= 12 ? 2 : size >= 6 ? 1.4 : size >= 3 ? 0.75 : 0.3
      var square = Math.max(0.6, size - gap)
      var insetX = (cellWidth - square) / 2
      var insetY = (cellHeight - square) / 2
      var emptyColor = root.rgba(root.foreground, size >= 4 ? 0.42 : 0.34)
      var presentColor = root.rgba(root.accent, 0.78)

      ctx.lineWidth = size >= 6 ? 1 : size >= 3 ? 0.65 : 0.4
      for (var index = 0; index < root.safeTotal; index++) {
        var column = index % root.fittedColumns
        var row = Math.floor(index / root.fittedColumns)
        var x = originX + column * cellWidth + insetX
        var y = originY + row * cellHeight + insetY

        if (index < root.safeElapsed) {
          ctx.fillStyle = root.livedColor
          ctx.fillRect(x, y, square, square)
        } else if (index === root.safeElapsed && root.safeElapsed < root.safeTotal) {
          ctx.fillStyle = presentColor
          ctx.fillRect(x, y, square, square)
        } else {
          ctx.strokeStyle = emptyColor
          ctx.strokeRect(x + ctx.lineWidth / 2, y + ctx.lineWidth / 2,
            Math.max(0.2, square - ctx.lineWidth), Math.max(0.2, square - ctx.lineWidth))
        }
      }
    }
  }
}
