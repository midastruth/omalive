import QtQuick

// Keep a column's natural height independent of the available viewport height.
// Short cards stay compact; tall content remains reachable without painting
// outside the card's padded content area.
Flickable {
  id: root

  default property alias contents: column.data
  property alias spacing: column.spacing

  implicitHeight: contentHeight
  contentWidth: width
  contentHeight: column.implicitHeight
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  flickableDirection: Flickable.VerticalFlick

  Column {
    id: column
    width: root.width
  }
}
