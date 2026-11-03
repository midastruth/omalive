import QtQuick
import QtTest
import "../components"

TestCase {
  id: testCase
  name: "ScrollableColumn"
  when: windowShown

  Component {
    id: contentComponent
    ScrollableColumn {
      width: 456
      height: 450
      spacing: 12

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: "W".repeat(60)
      }

      Item {
        width: parent.width
        height: 330
      }

      Rectangle {
        width: parent.width
        height: 40
        color: "blue"
      }
    }
  }

  function test_compactContent() {
    const viewport = createTemporaryObject(contentComponent, testCase)
    verify(viewport)
    verify(viewport.contentHeight < viewport.height)
    compare(viewport.implicitHeight, viewport.contentHeight)
    compare(viewport.contentWidth, viewport.width)
    compare(viewport.contentY, 0)
    verify(viewport.clip)
  }

  function test_smallViewportCanReachBottom() {
    const viewport = createTemporaryObject(contentComponent, testCase, { height: 180 })
    verify(viewport)
    verify(viewport.contentHeight > viewport.height)
    const naturalHeight = viewport.contentHeight
    viewport.contentY = viewport.contentHeight - viewport.height
    verify(viewport.atYEnd)

    // Shrinking the viewport must not shrink its content or prevent scrolling.
    viewport.height = 100
    compare(viewport.contentHeight, naturalHeight)
    viewport.contentY = viewport.contentHeight - viewport.height
    verify(viewport.atYEnd)
    const column = viewport.contentItem.children[0]
    const lastChild = column.children[column.children.length - 1]
    const bottom = lastChild.mapToItem(viewport, 0, lastChild.height)
    compare(bottom.y, viewport.height)
  }

  function test_widthTracksViewport() {
    const viewport = createTemporaryObject(contentComponent, testCase)
    verify(viewport)
    viewport.width = 200
    compare(viewport.contentWidth, 200)
    const column = viewport.contentItem.children[0]
    compare(column.width, viewport.width)
    compare(column.children[0].width, viewport.width)
    verify(column.children[0].truncated)
  }
}
