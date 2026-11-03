import QtQuick
import qs.Commons

Item {
  id: root

  property int totalUnits: 0
  property int elapsedUnits: 0
  // Owners pass Life.gridColumns(unit) so every surface draws the same shape.
  // Zero falls back to an aspect-ratio fit.
  property int columns: 0
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property int safeTotal: Math.max(0, totalUnits)
  readonly property int safeElapsed: Math.max(0, Math.min(safeTotal, elapsedUnits))
  // Exposed so legends use exactly the colours painted into the cells.
  readonly property color livedColor: Style.selectedStateColor(foreground, accent)
  readonly property color presentColor: Qt.rgba(accent.r, accent.g, accent.b, 0.78)
  readonly property color emptyColor: Qt.rgba(foreground.r, foreground.g, foreground.b,
    cellSize >= 4 ? 0.42 : 0.34)
  readonly property int fittedColumns: columns > 0 ? columns : Math.max(1,
    Math.ceil(Math.sqrt(safeTotal * Math.max(1, width) / Math.max(1, height))))
  readonly property int fittedRows: Math.max(1, Math.ceil(safeTotal / fittedColumns))
  readonly property real cellSize: Math.min(width / fittedColumns, height / fittedRows)
  // Height at which square cells fill the full width; owners cap it. Only
  // defined for fixed columns, since the fallback fit itself reads height.
  readonly property real naturalHeight: columns > 0
    ? width / columns * Math.max(1, Math.ceil(safeTotal / columns))
    : implicitHeight

  implicitWidth: Style.space(360)
  implicitHeight: Style.space(300)

  // Kept as part of the component API. The complete grid is always visible,
  // so revealing the present only requires repainting its accent cell.
  function revealPresent() {
    canvas.requestPaint()
  }

  onSafeTotalChanged: canvas.requestPaint()
  onSafeElapsedChanged: canvas.requestPaint()
  onForegroundChanged: canvas.requestPaint()
  onAccentChanged: canvas.requestPaint()
  onLivedColorChanged: canvas.requestPaint()
  onPresentColorChanged: canvas.requestPaint()
  onEmptyColorChanged: canvas.requestPaint()
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

      // Square cells: the grid keeps its shape whatever box it is given.
      var size = root.cellSize
      var originX = (width - size * root.fittedColumns) / 2
      var originY = (height - size * root.fittedRows) / 2
      var gap = size >= 12 ? 2 : size >= 6 ? 1.4 : size >= 3 ? 0.75 : 0.3
      var square = Math.max(0.6, size - gap)
      var inset = (size - square) / 2

      ctx.lineWidth = size >= 6 ? 1 : size >= 3 ? 0.65 : 0.4
      for (var index = 0; index < root.safeTotal; index++) {
        var column = index % root.fittedColumns
        var row = Math.floor(index / root.fittedColumns)
        var x = originX + column * size + inset
        var y = originY + row * size + inset

        if (index < root.safeElapsed) {
          ctx.fillStyle = root.livedColor
          ctx.fillRect(x, y, square, square)
        } else if (index === root.safeElapsed && root.safeElapsed < root.safeTotal) {
          ctx.fillStyle = root.presentColor
          ctx.fillRect(x, y, square, square)
        } else {
          ctx.strokeStyle = root.emptyColor
          ctx.strokeRect(x + ctx.lineWidth / 2, y + ctx.lineWidth / 2,
            Math.max(0.2, square - ctx.lineWidth), Math.max(0.2, square - ctx.lineWidth))
        }
      }
    }
  }
}
