pragma Singleton
import QtQuick

QtObject {
  readonly property QtObject font: QtObject {
    readonly property string family: "Sans Serif"
    readonly property int caption: 10
  }

  function space(value) { return value }
  function selectedStateColor(foreground, accent) { return foreground }
}
