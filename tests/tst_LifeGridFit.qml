import QtQuick
import QtTest
import "../components"
import "../js/Life.js" as Life

// The whole grid must be visible at a glance: owners cap its height, and the
// cells shrink instead of the grid scrolling or overflowing its box.
TestCase {
  id: testCase
  name: "LifeGridFit"
  when: windowShown

  Component {
    id: cardComponent
    Item {
      id: card
      width: 430
      height: 650
      property string unit: "weeks"
      property int scaleAge: 120
      property alias grid: grid
      property alias footer: footer

      Column {
        width: parent.width
        spacing: 12

        Rectangle { id: header; width: parent.width; height: 100 }

        LifeGrid {
          id: grid
          width: parent.width
          height: Math.min(naturalHeight, Math.max(80,
            card.height - header.height - footer.height - parent.spacing * 2))
          columns: Life.gridColumns(card.unit)
          totalUnits: Life.unitMetrics("2000-01-01", card.scaleAge,
            new Date(2026, 0, 1, 12), card.unit).total
          foreground: "#e0e0e0"
          accent: "#00aaff"
        }

        Rectangle { id: footer; width: parent.width; height: 70 }
      }
    }
  }

  function test_wholeGridVisible_data() {
    const rows = []
    for (const unit of ["days", "weeks", "months", "years"])
      for (const age of [95, 120])
        for (const size of [[430, 650], [452, 650], [430, 400]])
          rows.push({ tag: unit + "-" + age + "-" + size.join("x"),
            unit: unit, age: age, width: size[0], height: size[1] })
    return rows
  }

  function test_wholeGridVisible(data) {
    const card = createTemporaryObject(cardComponent, testCase, {
      unit: data.unit, scaleAge: data.age, width: data.width, height: data.height
    })
    verify(card)
    const grid = card.grid
    verify(grid.totalUnits > 0)
    verify(grid.fittedColumns * grid.cellSize <= grid.width + 0.001)
    verify(grid.fittedRows * grid.cellSize <= grid.height + 0.001)
    verify(card.footer.mapToItem(card, 0, card.footer.height).y <= data.height + 0.001)
  }

  function test_weeksUseEighteenMonthRows() {
    // A tall screen shows 78-week rows at full width; a short one shrinks the
    // cells but still shows every row.
    const tall = createTemporaryObject(cardComponent, testCase, { height: 1000, scaleAge: 95 })
    verify(tall)
    compare(tall.grid.columns, 78)
    compare(tall.grid.height, tall.grid.naturalHeight)
    fuzzyCompare(tall.grid.cellSize, tall.width / 78, 0.001)

    const short = createTemporaryObject(cardComponent, testCase, { height: 450, scaleAge: 120 })
    verify(short)
    verify(short.grid.height < short.grid.naturalHeight)
    verify(short.grid.fittedRows * short.grid.cellSize <= short.grid.height + 0.001)
  }
}
