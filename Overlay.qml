import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "components"
import "js/Life.js" as Life

Item {
  id: root

  // `service` is injected by Omarchy's overlay loader. The focused output is
  // preferred for login/daily summons, with the first screen as a safe fallback.
  property var service: null
  readonly property var targetScreen: {
    var monitor = Hyprland.focusedMonitor
    var wanted = monitor ? String(monitor.name || "") : ""
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++)
      if (String(screens[i].name || "") === wanted) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }
  property bool opened: false
  property string page: "daily"
  readonly property color foreground: Color.foreground
  readonly property string fontFamily: Style.font.family

  function open(payload) {
    var mode = "daily"
    if (payload) {
      try {
        var parsed = JSON.parse(String(payload))
        mode = String(parsed.mode || mode)
      } catch (error) {
        mode = String(payload)
      }
    }
    page = mode === "setup" ? "setup" : "daily"
    if (page === "daily" && (!service || !service.initialized)) page = "setup"
    if (service) service.validationError = ""
    opened = true
    focusTimer.restart()
    if (page === "daily" && service && service.viewMode === "grid")
      Qt.callLater(function() { overlayLifeGrid.revealPresent() })
  }

  function close() {
    opened = false
    if (service) service.validationError = ""
  }

  function unitLabel(unit) {
    if (unit === "days") return "days"
    if (unit === "months") return "months"
    if (unit === "years") return "years"
    return "weeks"
  }

  function birthDate() {
    var year = String(yearField.text || "")
    var month = String(monthField.text || "")
    var day = String(dayField.text || "")
    if (month.length < 2) month = "0" + month
    if (day.length < 2) day = "0" + day
    return year + "-" + month + "-" + day
  }

  function continueSetup() {
    if (!service) return
    if (service.initialize(nameField.text, birthDate())) {
      page = "scale"
      focusTimer.restart()
    }
  }

  function handleFieldKey(event, nextField, submit) {
    if (event.key === Qt.Key_Escape) {
      root.close()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (submit) root.continueSetup()
      else if (nextField) nextField.forceActiveFocus()
      event.accepted = true
    }
  }

  Timer {
    id: focusTimer
    interval: 80
    repeat: false
    onTriggered: {
      if (!root.opened) return
      if (root.page === "setup") nameField.forceActiveFocus()
      else cardFocus.forceActiveFocus()
    }
  }

  PanelWindow {
    id: window
    screen: root.targetScreen
    visible: root.opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.namespace: "omalive-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Color.background
      opacity: 0.82
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      acceptedButtons: Qt.AllButtons
      onClicked: root.close()
    }

    BorderSurface {
      id: card
      width: Math.min(window.width - Style.space(48), Style.space(520))
      height: Math.min(window.height - Style.space(64), contentColumn.implicitHeight + Style.space(64))
      anchors.centerIn: parent
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      padding: Style.space(32)

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
      }

      Item {
        id: cardFocus
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                     && (root.page === "daily" || root.page === "scale")) {
            root.close()
            event.accepted = true
          }
        }
      }

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: card.contentLeftInset
        anchors.rightMargin: card.contentRightInset
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(18)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "OMALIVE"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          font.letterSpacing: 2
        }

        Column {
          visible: root.page === "setup"
          width: parent.width
          spacing: Style.space(12)

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "A life scale for the days you are living"
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Text {
            text: "What is your name?"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          TextField {
            id: nameField
            width: parent.width
            foreground: root.foreground
            placeholderText: "Your name"
            maximumLength: 60
            Keys.onPressed: function(event) { root.handleFieldKey(event, yearField, false) }
          }

          Text {
            text: "When were you born?"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(10)

            TextField {
              id: yearField
              width: Style.space(112)
              foreground: root.foreground
              placeholderText: "YYYY"
              maximumLength: 4
              inputMethodHints: Qt.ImhDigitsOnly
              validator: IntValidator { bottom: 1; top: 9999 }
              Keys.onPressed: function(event) { root.handleFieldKey(event, monthField, false) }
            }

            TextField {
              id: monthField
              width: Style.space(78)
              foreground: root.foreground
              placeholderText: "MM"
              maximumLength: 2
              inputMethodHints: Qt.ImhDigitsOnly
              validator: IntValidator { bottom: 1; top: 12 }
              Keys.onPressed: function(event) { root.handleFieldKey(event, dayField, false) }
            }

            TextField {
              id: dayField
              width: Style.space(78)
              foreground: root.foreground
              placeholderText: "DD"
              maximumLength: 2
              inputMethodHints: Qt.ImhDigitsOnly
              validator: IntValidator { bottom: 1; top: 31 }
              Keys.onPressed: function(event) { root.handleFieldKey(event, null, true) }
            }
          }

          Text {
            visible: !!root.service && root.service.validationError !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.service ? root.service.validationError : ""
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Continue"
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.continueSetup()
          }
        }

        Column {
          visible: root.page === "scale"
          width: parent.width
          spacing: Style.space(12)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "LIFE SCALE"
            color: Qt.darker(root.foreground, 1.5)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1.8
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.service ? root.service.maxAge : "—"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: 76
            font.bold: true
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "YEARS"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.letterSpacing: 2
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "This number was chosen randomly between 95 and 120. It is a fixed scale for reflection — not a prediction of your lifespan."
            color: Qt.darker(root.foreground, 1.45)
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Begin"
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.close()
          }
        }

        Column {
          visible: root.page === "daily" && (!root.service || root.service.viewMode === "summary")
          width: parent.width
          spacing: Style.space(10)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.service ? root.service.name : ""
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
              if (!root.service) return "0"
              return root.service.beyondScale
                ? "+" + Life.formatNumber(root.service.beyondDays)
                : Life.formatNumber(root.service.remainingDays)
            }
            color: root.service && root.service.beyondScale ? Color.accent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: 46
            font.bold: true
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.service && root.service.beyondScale
              ? "DAYS BEYOND SCALE" : "DAYS REMAINING"
            color: Qt.darker(root.foreground, 1.45)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.letterSpacing: 1.8
          }

          LifeProgress {
            width: parent.width
            progress: root.service ? root.service.visualProgress : 0
            foreground: root.foreground
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (root.service ? root.service.progressText : "0.00%") + " elapsed"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Close"
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.close()
          }
        }

        Column {
          visible: root.page === "daily" && !!root.service && root.service.viewMode === "ring"
          width: parent.width
          spacing: Style.space(12)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.service ? root.service.name : ""
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          LifeRing {
            width: Math.min(parent.width, Style.space(240))
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            progress: root.service ? root.service.visualProgress : 0
            percentText: root.service ? root.service.progressText : "0.00%"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: {
              if (!root.service) return ""
              if (root.service.beyondScale)
                return "+" + Life.formatNumber(root.service.beyondDays) + " days beyond your life scale"
              return Life.formatNumber(root.service.remainingDays) + " days remaining"
            }
            color: root.service && root.service.beyondScale ? Color.accent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Close"
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.close()
          }
        }

        Column {
          visible: root.page === "daily" && !!root.service && root.service.viewMode === "grid"
          width: parent.width
          spacing: Style.space(12)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.service ? root.service.name : ""
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: {
              if (!root.service) return ""
              if (root.service.beyondScale)
                return "+" + Life.formatNumber(root.service.beyondDays) + " days beyond your life scale"
              return Life.formatNumber(Math.max(0, root.service.gridTotal - root.service.gridElapsed))
                + " " + root.unitLabel(root.service.gridUnit) + " remaining"
            }
            color: root.service && root.service.beyondScale ? Color.accent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          LifeGrid {
            id: overlayLifeGrid
            width: parent.width
            height: Math.min(Style.space(360), window.height * 0.52)
            totalUnits: root.service ? root.service.gridTotal : 0
            elapsedUnits: root.service ? root.service.gridElapsed : 0
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(16)

            Text {
              text: "■ lived"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              text: "■ now"
              color: Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              text: "□ remaining"
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Close"
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.close()
          }
        }
      }
    }
  }
}
