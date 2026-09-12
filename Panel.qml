import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "components"
import "js/Life.js" as Life

Panel {
  id: root

  moduleName: "io.github.midastruth.omalive"
  ipcTarget: "omalive"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property bool settingsOpen: false
  property bool resetArmed: false
  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.barForeground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    if (!service || !service.initialized) return
    controller.show()
    Qt.callLater(function() {
      keyCatcher.forceActiveFocus()
      if (service.viewMode === "grid") panelLifeGrid.revealPresent()
    })
  }

  function close() {
    settingsOpen = false
    resetArmed = false
    controller.hide()
  }

  function openSettings() {
    if (!service) return
    nameField.text = service.name
    birthdayField.text = service.birthday
    service.validationError = ""
    settingsOpen = true
    Qt.callLater(function() { nameField.forceActiveFocus() })
  }

  function closeSettings() {
    settingsOpen = false
    resetArmed = false
    if (service) service.validationError = ""
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function saveIdentity() {
    if (service && service.updateIdentity(nameField.text, birthdayField.text)) closeSettings()
  }

  function unitLabel(unit) {
    if (unit === "days") return "days"
    if (unit === "months") return "months"
    if (unit === "years") return "years"
    return "weeks"
  }

  function requestReset() {
    if (!resetArmed) {
      resetArmed = true
      disarmReset.restart()
      return
    }
    root.close()
    service.reset()
  }

  Timer {
    id: disarmReset
    interval: 3000
    repeat: false
    onTriggered: root.resetArmed = false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(contentRoot.height)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: nameField.activeFocus || birthdayField.activeFocus
      onCloseRequested: root.settingsOpen ? root.closeSettings() : root.close()

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentRoot.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
          id: contentRoot
          width: parent.width
          height: root.settingsOpen ? settingsColumn.implicitHeight
            : root.service && root.service.viewMode === "grid"
              ? gridColumn.implicitHeight : summaryColumn.implicitHeight

          Column {
            id: summaryColumn
            visible: !root.settingsOpen && (!root.service || root.service.viewMode !== "grid")
            width: parent.width
            spacing: Style.space(16)

            Item {
              width: parent.width
              height: Math.max(title.implicitHeight, settingsButton.implicitHeight)

              Text {
                id: title
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "OMALIVE"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                font.letterSpacing: 1.5
              }

              Button {
                id: settingsButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰒓"
                tooltipText: "Omalive settings"
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.openSettings()
              }
            }

            Column {
              width: parent.width
              spacing: Style.space(2)

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.service ? root.service.name : ""
                color: Qt.darker(root.contentForeground, 1.35)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.service ? Life.formatNumber(root.service.livedDays) : "0"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: 48
                font.bold: true
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "DAYS ALIVE"
                color: Qt.darker(root.contentForeground, 1.55)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.letterSpacing: 1.8
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(12)

              LifeProgress {
                width: parent.width - percentLabel.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                progress: root.service ? root.service.visualProgress : 0
                foreground: root.contentForeground
              }

              Text {
                id: percentLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.service ? root.service.progressText : "0.00%"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }

            Text {
              visible: !!root.service && (root.service.showRemaining || root.service.beyondScale)
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: {
                if (!root.service) return ""
                if (root.service.beyondScale)
                  return "+" + Life.formatNumber(root.service.beyondDays) + " days beyond your life scale"
                return Life.formatNumber(root.service.remainingDays) + " days remaining"
              }
              color: root.service && root.service.beyondScale
                ? Color.accent : Qt.darker(root.contentForeground, 1.3)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
            }

            LifeStats {
              width: parent.width
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              rows: root.service ? [
                { label: "Day", value: Life.formatNumber(root.service.livedDays) + " / " + Life.formatNumber(root.service.totalDays), emphasis: true },
                { label: "Life scale", value: root.service.maxAge + " years" },
                { label: "Birthday", value: root.service.birthday },
                { label: "Scale endpoint", value: root.service.endDate }
              ] : []
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              horizontalAlignment: Text.AlignHCenter
              text: "A randomly generated scale — not a prediction of your lifespan."
              color: Qt.darker(root.contentForeground, 1.8)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Column {
            id: gridColumn
            visible: !root.settingsOpen && !!root.service && root.service.viewMode === "grid"
            width: parent.width
            spacing: Style.space(14)

            Item {
              width: parent.width
              height: Math.max(gridTitle.implicitHeight, gridSettingsButton.implicitHeight)

              Text {
                id: gridTitle
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "LIFE GRID"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                font.letterSpacing: 1.5
              }

              Button {
                id: gridSettingsButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰒓"
                tooltipText: "Omalive settings"
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.openSettings()
              }
            }

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: root.service
                ? Life.formatNumber(root.service.gridElapsed) + " / "
                  + Life.formatNumber(root.service.gridTotal) + " "
                  + root.unitLabel(root.service.gridUnit)
                : ""
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            LifeGrid {
              id: panelLifeGrid
              width: parent.width
              height: Style.space(310)
              totalUnits: root.service ? root.service.gridTotal : 0
              elapsedUnits: root.service ? root.service.gridElapsed : 0
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(16)

              Text {
                text: "■ lived"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
              }

              Text {
                text: "■ now"
                color: Color.accent
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
              }

              Text {
                text: "□ remaining"
                color: Qt.darker(root.contentForeground, 1.45)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          Column {
            id: settingsColumn
            visible: root.settingsOpen
            width: parent.width
            spacing: Style.space(14)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Button {
                iconText: "󰅁"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.closeSettings()
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "SETTINGS"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                font.letterSpacing: 1.5
              }
            }

            Text {
              text: "Name"
              color: Qt.darker(root.contentForeground, 1.45)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            TextField {
              id: nameField
              width: parent.width
              foreground: root.contentForeground
              placeholderText: "Your name"
              maximumLength: 60
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) { root.closeSettings(); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  birthdayField.forceActiveFocus(); event.accepted = true
                }
              }
            }

            Text {
              text: "Birthday"
              color: Qt.darker(root.contentForeground, 1.45)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            TextField {
              id: birthdayField
              width: parent.width
              foreground: root.contentForeground
              placeholderText: "YYYY-MM-DD"
              maximumLength: 10
              inputMethodHints: Qt.ImhDigitsOnly
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) { root.closeSettings(); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.saveIdentity(); event.accepted = true
                }
              }
            }

            Text {
              visible: !!root.service && root.service.validationError !== ""
              width: parent.width
              wrapMode: Text.WordWrap
              text: root.service ? root.service.validationError : ""
              color: Color.urgent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            LifeStats {
              width: parent.width
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              rows: root.service ? [
                { label: "Life scale", value: root.service.maxAge + " years", emphasis: true }
              ] : []
            }

            Text {
              text: "View"
              color: Qt.darker(root.contentForeground, 1.45)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            ButtonGroup {
              options: [
                { value: "summary", label: "Summary" },
                { value: "grid", label: "Life grid" }
              ]
              value: root.service ? root.service.viewMode : "summary"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              fontSize: Style.font.bodySmall
              onChanged: function(value) { if (root.service) root.service.setViewMode(value) }
            }

            Text {
              text: "Grid unit"
              color: Qt.darker(root.contentForeground, 1.45)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            ButtonGroup {
              options: [
                { value: "days", label: "Days" },
                { value: "weeks", label: "Weeks" },
                { value: "months", label: "Months" },
                { value: "years", label: "Years" }
              ]
              value: root.service ? root.service.gridUnit : "weeks"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              fontSize: Style.font.caption
              onChanged: function(value) { if (root.service) root.service.setGridUnit(value) }
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              text: root.service
                ? Life.formatNumber(root.service.gridTotal) + " cells at the selected unit."
                : ""
              color: Qt.darker(root.contentForeground, 1.65)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Item {
              width: parent.width
              height: dailyLabel.implicitHeight + Style.space(8)

              Text {
                id: dailyLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Daily display"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
              }

              ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: !!root.service && root.service.dailyDisplay
                foreground: root.contentForeground
                onToggled: if (root.service) root.service.setDailyDisplay(!checked)
              }
            }

            Item {
              width: parent.width
              height: remainingLabel.implicitHeight + Style.space(8)

              Text {
                id: remainingLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Show remaining days"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
              }

              ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: !!root.service && root.service.showRemaining
                foreground: root.contentForeground
                onToggled: if (root.service) root.service.setShowRemaining(!checked)
              }
            }

            Button {
              width: parent.width
              text: "Save profile"
              bordered: true
              focusable: true
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.saveIdentity()
            }

            Button {
              width: parent.width
              text: root.resetArmed ? "Click again to reset Omalive" : "Reset Omalive"
              bordered: true
              foreground: root.resetArmed ? Color.urgent : root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.requestReset()
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              text: "Resetting erases the profile and generates a new 95–120 year scale after setup."
              color: Qt.darker(root.contentForeground, 1.75)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}
