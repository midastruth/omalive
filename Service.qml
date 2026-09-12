import QtQuick
import Quickshell
import Quickshell.Io
import "js/Life.js" as Life

// Omalive's single source of truth. Every surface reads the same profile and
// date metrics from this long-lived service; UI files never perform life math.
Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateRoot: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string stateDir: stateRoot + "/omalive"
  readonly property string statePath: stateDir + "/state.json"

  // Injected by Omarchy's service host. The scoped API lets this plugin summon
  // only its own overlay.
  property var shell: null
  property var profile: Life.defaultProfile()
  property bool ready: false
  property string validationError: ""
  property date now: new Date()

  property bool startupPrompted: false
  property string lastEvaluatedDate: ""

  readonly property bool initialized: profile.initialized === true
  readonly property string name: initialized ? String(profile.name) : ""
  readonly property string birthday: initialized ? String(profile.birthday) : ""
  readonly property int maxAge: initialized ? Number(profile.maxAge) : 0
  readonly property bool dailyDisplay: profile.dailyDisplay !== false
  readonly property bool showRemaining: profile.showRemaining !== false
  readonly property string viewMode: profile.viewMode === "grid" ? "grid" : "summary"
  readonly property string gridUnit: String(profile.gridUnit || "weeks")
  readonly property string lastShownDate: String(profile.lastShownDate || "")
  readonly property string today: Life.todayKey(now)
  readonly property var life: Life.metrics(birthday, maxAge, now)
  readonly property string endDate: life.endDate
  readonly property int livedDays: life.livedDays
  readonly property int totalDays: life.totalDays
  readonly property int remainingDays: life.remainingDays
  readonly property int beyondDays: life.beyondDays
  readonly property real progress: life.progress
  readonly property real visualProgress: life.visualProgress
  readonly property bool beyondScale: life.beyond
  readonly property string progressText: Life.formatPercent(progress)
  readonly property var unitGrid: Life.unitMetrics(birthday, maxAge, now, gridUnit)
  readonly property int gridTotal: unitGrid.total
  readonly property int gridElapsed: unitGrid.elapsed

  onShellChanged: if (shell && ready) {
    lastEvaluatedDate = ""
    Qt.callLater(evaluateDaily)
  }

  function save(document) {
    profile = Life.normalizeProfile(document)
    stateFile.setText(JSON.stringify(profile, null, 2) + "\n")
  }

  function mutate(change) {
    var draft = JSON.parse(JSON.stringify(profile))
    change(draft)
    save(draft)
  }

  function showOverlay(mode) {
    if (!mode || !shell || typeof shell.summon !== "function") return false
    var shown = shell.summon("io.github.midastruth.omalive", JSON.stringify({ mode: String(mode) }))
    // Persist only after the shell accepted the summon. A reload later today
    // then sees the date and cannot show the daily view a second time.
    if (shown && mode === "daily" && initialized && lastShownDate !== today)
      mutate(function(draft) { draft.lastShownDate = root.today })
    return shown
  }

  function initialize(nameValue, birthdayValue) {
    validationError = ""
    var checked = Life.validateInput(nameValue, birthdayValue, now)
    if (!checked.ok) {
      validationError = checked.error
      return false
    }

    var document = Life.defaultProfile()
    document.initialized = true
    document.name = checked.name
    document.birthday = checked.birthday
    document.maxAge = Life.randomMaxAge()
    // The scale reveal is today's appearance, so setup is not immediately
    // followed by a second, daily overlay.
    document.lastShownDate = today
    save(document)
    return true
  }

  function updateIdentity(nameValue, birthdayValue) {
    validationError = ""
    var checked = Life.validateInput(nameValue, birthdayValue, now)
    if (!checked.ok) {
      validationError = checked.error
      return false
    }
    mutate(function(draft) {
      draft.name = checked.name
      draft.birthday = checked.birthday
      draft.initialized = true
    })
    return true
  }

  function setDailyDisplay(value) {
    mutate(function(draft) { draft.dailyDisplay = value === true })
    if (value === true) Qt.callLater(root.evaluateDaily)
  }

  function setShowRemaining(value) {
    mutate(function(draft) { draft.showRemaining = value === true })
  }

  function setViewMode(value) {
    var selected = value === "grid" ? "grid" : "summary"
    mutate(function(draft) { draft.viewMode = selected })
  }

  function setGridUnit(value) {
    var allowed = ["days", "weeks", "months", "years"]
    var selected = allowed.indexOf(value) >= 0 ? value : "weeks"
    mutate(function(draft) { draft.gridUnit = selected })
  }

  function reset() {
    validationError = ""
    save(Life.defaultProfile())
    startupPrompted = true
    showOverlay("setup")
  }

  function refreshDate() {
    var previous = today
    now = new Date()
    if (today !== previous) {
      lastEvaluatedDate = ""
      Qt.callLater(evaluateDaily)
    }
  }

  function evaluateDaily() {
    if (!ready || lastEvaluatedDate === today) return
    lastEvaluatedDate = today

    if (!initialized) {
      if (!startupPrompted) {
        startupPrompted = showOverlay("setup")
        if (!startupPrompted) lastEvaluatedDate = ""
      }
      return
    }

    if (dailyDisplay && lastShownDate !== today && !showOverlay("daily"))
      lastEvaluatedDate = ""
  }

  function adoptLoaded(text, existed) {
    try {
      profile = Life.normalizeProfile(existed ? JSON.parse(text) : Life.defaultProfile())
    } catch (error) {
      console.warn("omalive: state.json is invalid; keeping the last valid state:", error)
    }
    ready = true
    now = new Date()
    Qt.callLater(evaluateDaily)
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.refreshDate()
  }

  Process {
    id: prepareDirectory
    command: ["mkdir", "-p", root.stateDir]
    onExited: function() { stateFile.reload() }
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    atomicWrites: true
    printErrors: false

    onLoaded: root.adoptLoaded(text(), true)
    onLoadFailed: root.adoptLoaded("", false)
    onFileChanged: reload()
  }

  // FileView may not signal for a path which did not exist at construction.
  Timer {
    interval: 900
    running: !root.ready
    repeat: false
    onTriggered: if (!root.ready) root.adoptLoaded("", false)
  }

  Component.onCompleted: prepareDirectory.running = true
}
