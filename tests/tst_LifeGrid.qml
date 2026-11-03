import QtQuick
import QtTest
import qs.Commons as Commons
import "../components"

TestCase {
  id: testCase
  name: "LifeGrid"
  when: windowShown

  Component {
    id: gridComponent
    LifeGrid {
      width: 420
      height: 420
      columns: 210
      totalUnits: 35064
      elapsedUnits: 5000
      foreground: "#e0e0e0"
      accent: "#00aaff"
    }
  }

  Component {
    id: legendComponent
    LifeGridLegend { foreground: Commons.Color.foreground }
  }

  function test_paletteMatchesCanvas_data() {
    return [
      { tag: "days", columns: 210, total: 35064, alpha: 0.34 },
      { tag: "weeks", columns: 78, total: 5010, alpha: 0.42 },
      { tag: "months", columns: 36, total: 1152, alpha: 0.42 },
      { tag: "years", columns: 10, total: 96, alpha: 0.42 }
    ]
  }

  function test_paletteMatchesCanvas(data) {
    const grid = createTemporaryObject(gridComponent, testCase, {
      columns: data.columns, totalUnits: data.total
    })
    verify(grid)
    compare(grid.cellSize, Math.min(grid.width / grid.fittedColumns,
      grid.height / grid.fittedRows))
    fuzzyCompare(grid.emptyColor.a, data.alpha, 0.005)
    const legend = createTemporaryObject(legendComponent, testCase, { grid: grid })
    verify(legend)
    const repeater = Array.from(legend.children).find(child => typeof child.itemAt === "function")
    verify(repeater)
    compare(repeater.count, 3)
    compare(repeater.itemAt(0).children[0].color, grid.livedColor)
    compare(repeater.itemAt(1).children[0].color, grid.presentColor)
    compare(repeater.itemAt(2).children[0].border.color, grid.emptyColor)

    // Resizing can switch the dense-cell alpha without changing the unit.
    grid.width = 100
    grid.height = 100
    if (grid.cellSize < 4) fuzzyCompare(grid.emptyColor.a, 0.34, 0.005)
    compare(repeater.itemAt(2).children[0].border.color, grid.emptyColor)
  }

  function test_elapsedClamped() {
    const grid = createTemporaryObject(gridComponent, testCase)
    verify(grid)
    grid.elapsedUnits = -1
    compare(grid.safeElapsed, 0)
    grid.elapsedUnits = grid.totalUnits + 1
    compare(grid.safeElapsed, grid.totalUnits)
  }
}
