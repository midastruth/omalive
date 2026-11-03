pragma Singleton
import QtQuick

// Deterministic palette for headless component tests; no running shell needed.
QtObject {
  readonly property color foreground: "#e0e0e0"
  readonly property color accent: "#00aaff"
}
