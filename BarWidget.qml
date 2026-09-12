import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// The permanent, deliberately quiet part of Omalive. Like omarchy.clock, this
// bar entry owns its anchored panel; the service owns all persistent state.
BarWidget {
  id: root
  moduleName: "io.github.midastruth.omalive"

  readonly property var lifeService: bar && bar.shell
    ? bar.shell.serviceFor(moduleName) : null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property real openPanelIndicatorWidth: button.contentWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property string screenName: {
    var window = button.QsWindow.window
    return window && window.screen ? String(window.screen.name || "") : ""
  }

  function focusedWidget() {
    var items = bar && typeof bar.moduleWidgets === "function"
      ? bar.moduleWidgets(moduleName) : [root]
    var monitor = Hyprland.focusedMonitor
    var wanted = monitor ? String(monitor.name || "") : ""
    for (var i = 0; i < items.length; i++)
      if (items[i] && items[i].screenName === wanted) return items[i]
    for (var j = 0; j < items.length; j++)
      if (items[j] && items[j].screenName !== "") return items[j]
    return root
  }

  function openFocused() {
    var widget = focusedWidget()
    if (widget) widget.open()
  }

  function toggleFocused() {
    var widget = focusedWidget()
    if (widget) widget.togglePanel()
  }

  function injectChildren() {
    var panel = panelLoader.item
    if (panel) {
      if ("bar" in panel) panel.bar = root.bar
      if ("settings" in panel) panel.settings = root.settings
      if ("anchorItem" in panel) panel.anchorItem = button
      if ("hostWidget" in panel) panel.hostWidget = root
      if ("service" in panel) panel.service = root.lifeService
    }

  }

  function open() {
    if (!lifeService) return
    if (!lifeService.initialized) {
      if (bar && bar.shell)
        bar.shell.summon(moduleName, JSON.stringify({ mode: "setup" }))
      return
    }
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (!lifeService || !lifeService.initialized) {
      open()
      return
    }
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectChildren()
  onSettingsChanged: injectChildren()
  onLifeServiceChanged: injectChildren()

  IpcHandler {
    target: "omalive"

    function open(): void { root.openFocused() }
    function close(): void { root.broadcast("close") }
    function toggle(): void { root.toggleFocused() }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectChildren()
      Qt.callLater(root.injectChildren)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    readonly property int displayedDays: root.lifeService && root.lifeService.barShowsRemaining
      ? root.lifeService.remainingDays : (root.lifeService ? root.lifeService.livedDays : 0)
    readonly property string displayText: root.lifeService && root.lifeService.initialized
      ? String(displayedDays) : "Omalive"
    readonly property real iconSize: Math.round(Style.bar.iconCanvas * 0.8)
    readonly property real contentWidth: contentRow.implicitWidth
    text: ""
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? -1 : contentWidth + scaledHorizontalMargin * 2
    fixedHeight: vertical ? Style.bar.iconSlot : -1
    tooltipText: {
      if (!root.lifeService || !root.lifeService.initialized) return "Set up Omalive"
      var count = root.lifeService.barShowsRemaining
        ? root.lifeService.remainingDays + " days remaining"
        : root.lifeService.livedDays + " days alive"
      return count + " · " + root.lifeService.progressText + " · " + root.lifeService.name
    }
    horizontalMargin: 8.75
    verticalPadding: 8.75

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.space(5)

      Item {
        width: button.iconSize
        height: button.iconSize

        Image {
          id: iconMask
          property bool usingFallback: false
          anchors.fill: parent
          visible: false
          source: Qt.resolvedUrl(usingFallback
            ? "assets/omalive-fallback.svg" : "assets/omalive.svg")
          fillMode: Image.PreserveAspectFit
          sourceSize.width: width * 2
          sourceSize.height: height * 2
          cache: true
          onStatusChanged: if (status === Image.Error && !usingFallback) usingFallback = true
        }

        MultiEffect {
          anchors.fill: iconMask
          source: iconMask
          colorization: 1
          colorizationColor: button.active && button.useActiveColor
            ? button.activeColor : button.foreground
        }
      }

      Text {
        visible: !button.vertical && (!root.lifeService || root.lifeService.showBarDays)
        anchors.verticalCenter: parent.verticalCenter
        text: button.displayText
        color: button.active && button.useActiveColor
          ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        renderType: Text.NativeRendering
      }
    }

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.togglePanel()
    }
  }

  Component.onCompleted: injectChildren()
}
