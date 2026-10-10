pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons

// Life Day: the whole life scale drawn as one arc. Birth is first light
// on the left horizon, death is the day's end on the right. The arc is split
// into dawn, day, dusk, and darkness; a marker shows today.
Item {
  id: root

  property real progress: 0
  property var phases: []
  property int phaseIndex: 0
  property string countText: "0"
  property string countLabel: "DAYS LEFT"
  property string phaseText: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property int strokeWidth: Style.space(9)
  // Owners set this to false while hidden; the gauge self-test replays on reopen.
  property bool active: true

  // Fixed sky palette: the meaning of each phase depends on its hue.
  readonly property var phaseColors: ({
    dawn: "#e8a07a",
    day: "#f2cc6b",
    dusk: "#c8607a",
    darkness: "#6a78b8"
  })

  // Colour stops along the life arc (fraction of the scale → colour).
  readonly property var arcStops: [
    [0, "#e8907a"], [2 / 19, "#f0b870"], [7 / 19, "#f2cc6b"], [12 / 19, "#e8875f"],
    [13 / 19, "#c8607a"], [14 / 19, "#7a5a9a"], [1, "#3a4580"]
  ]
  // Sky behind the arc: [fraction, zenith, horizon, opacity].
  readonly property var skyStops: [
    [0, "#3a4a7a", "#f0a080", 0.20], [2 / 19, "#5a8ac8", "#f2d8a0", 0.18],
    [7 / 19, "#4a90d8", "#bcdcf0", 0.16], [12 / 19, "#5a6aa8", "#f0a070", 0.22],
    [13 / 19, "#3a3a70", "#d06070", 0.30], [14 / 19, "#141830", "#3a2a50", 0.45],
    [1, "#05060c", "#10121c", 0.60]
  ]
  readonly property real clampedProgress: Math.max(0, Math.min(1, Number(progress) || 0))
  property real displayedProgress: clampedProgress

  // Geometry shared by the canvases and the positioned labels.
  readonly property real line: Math.max(2, Math.min(strokeWidth, width / 18))
  readonly property real radius: Math.max(0, Math.min(width / 2 - line - Style.space(18),
    height - line - Style.space(26)))
  readonly property real centerX: width / 2
  readonly property real centerY: line / 2 + Style.space(10) + radius
  readonly property real markerX: centerX - radius * Math.cos(Math.PI * displayedProgress)
  readonly property real markerY: centerY - radius * Math.sin(Math.PI * displayedProgress)

  implicitWidth: Style.space(320)
  implicitHeight: Style.space(190)

  // Gauge self-test: sweep the whole arc from start to end, hold, then
  // settle back on today — like a car dashboard when the ignition turns on.
  function replay() {
    selfTest.stop()
    displayedProgress = 0
    settle.to = clampedProgress
    selfTest.start()
  }

  function phaseColor(key) {
    return phaseColors[key] || foreground
  }

  function clamp01(v) { return Math.max(0, Math.min(1, v)) }

  function smoothstep(a, b, v) {
    var t = clamp01((v - a) / (b - a))
    return t * t * (3 - 2 * t)
  }

  function rgbOf(value) {
    var c = Qt.color(value)
    return [c.r, c.g, c.b]
  }

  function mixRgb(a, b, t) {
    if (typeof a === "string") a = rgbOf(a)
    if (typeof b === "string") b = rgbOf(b)
    return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]
  }

  // Interpolates column `column` of a stop table at fraction t.
  function stopAt(stops, t, column) {
    var col = column || 1
    if (t <= stops[0][0]) return stops[0][col]
    for (var i = 1; i < stops.length; i++) {
      if (t <= stops[i][0]) {
        var k = (t - stops[i - 1][0]) / (stops[i][0] - stops[i - 1][0])
        var lo = stops[i - 1][col]
        var hi = stops[i][col]
        if (typeof lo === "number") return lo + (hi - lo) * k
        return mixRgb(rgbOf(lo), rgbOf(hi), k)
      }
    }
    return stops[stops.length - 1][col]
  }

  function css(c, alpha) {
    var v = typeof c === "string" ? rgbOf(c) : c
    return "rgba(" + Math.round(v[0] * 255) + "," + Math.round(v[1] * 255) + ","
      + Math.round(v[2] * 255) + "," + Math.max(0, Math.min(1, alpha)) + ")"
  }

  function rgba(value, alpha) { return css(rgbOf(value), alpha) }

  function angleFor(fraction) {
    return Math.PI + Math.PI * fraction
  }

  // Deterministic pseudo-random in [0, 1) for star placement.
  function hash(n) {
    var x = Math.sin(n * 12.9898 + 78.233) * 43758.5453
    return x - Math.floor(x)
  }

  onClampedProgressChanged: {
    if (selfTest.running) {
      settle.to = clampedProgress
    } else {
      displayedProgress = clampedProgress
    }
  }
  onVisibleChanged: if (visible && active) replay()
  onActiveChanged: if (visible && active) replay()
  onDisplayedProgressChanged: { skyCanvas.requestPaint(); markerCanvas.requestPaint() }
  onPhasesChanged: skyCanvas.requestPaint()
  onForegroundChanged: skyCanvas.requestPaint()
  onWidthChanged: skyCanvas.requestPaint()
  onHeightChanged: skyCanvas.requestPaint()

  SequentialAnimation {
    id: selfTest
    NumberAnimation {
      target: root
      property: "displayedProgress"
      from: 0
      to: 1
      duration: 1100
      easing.type: Easing.InOutCubic
    }
    PauseAnimation { duration: 260 }
    NumberAnimation {
      id: settle
      target: root
      property: "displayedProgress"
      from: 1
      duration: 1000
      easing.type: Easing.OutCubic
    }
    onStopped: root.displayedProgress = root.clampedProgress
  }

  // Sky, horizon, and the life arc. Repaints only when the marker moves.
  Canvas {
    id: skyCanvas
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (root.radius <= 0) return

      var cx = root.centerX
      var cy = root.centerY
      var r = root.radius
      var p = root.displayedProgress
      var inner = r - root.line / 2

      // 1. Sky inside the arc, tinted by the current phase.
      ctx.save()
      ctx.beginPath()
      ctx.moveTo(cx - inner, cy)
      ctx.arc(cx, cy, inner, Math.PI, Math.PI * 2, false)
      ctx.closePath()
      ctx.clip()

      var skyAlpha = root.stopAt(root.skyStops, p, 3)
      var sky = ctx.createLinearGradient(0, cy - inner, 0, cy)
      sky.addColorStop(0, root.css(root.stopAt(root.skyStops, p, 1), skyAlpha))
      sky.addColorStop(1, root.css(root.stopAt(root.skyStops, p, 2), skyAlpha * 1.1))
      ctx.fillStyle = sky
      ctx.fillRect(cx - inner, cy - inner, inner * 2, inner)

      // Stars appear from late dusk onwards.
      var starLight = root.smoothstep(12.5 / 19, 15 / 19, p)
      if (starLight > 0) {
        for (var s = 0; s < 34; s++) {
          var sr = Math.sqrt(root.hash(s)) * inner * 0.92
          var sa = Math.PI + root.hash(s + 101) * Math.PI
          var px = cx + Math.cos(sa) * sr
          var py = cy + Math.sin(sa) * sr
          if (py > cy - root.line) continue
          var size = 0.6 + root.hash(s + 203) * 1.1
          ctx.fillStyle = root.rgba(root.foreground, starLight * (0.25 + root.hash(s + 307) * 0.6))
          ctx.beginPath()
          ctx.arc(px, py, size, 0, Math.PI * 2, false)
          ctx.fill()
        }
      }
      ctx.restore()

      // 2. Horizon, fading out at both ends.
      var horizon = ctx.createLinearGradient(cx - r - root.line * 3, 0, cx + r + root.line * 3, 0)
      horizon.addColorStop(0, root.rgba(root.foreground, 0))
      horizon.addColorStop(0.15, root.rgba(root.foreground, 0.22))
      horizon.addColorStop(0.85, root.rgba(root.foreground, 0.22))
      horizon.addColorStop(1, root.rgba(root.foreground, 0))
      ctx.lineWidth = 1
      ctx.strokeStyle = horizon
      ctx.beginPath()
      ctx.moveTo(cx - r - root.line * 3, cy)
      ctx.lineTo(cx + r + root.line * 3, cy)
      ctx.stroke()

      // 3. Life arc as a continuous sky gradient: faint ahead, solid behind.
      // On a semicircle x maps monotonically to the arc fraction, so a
      // horizontal gradient sampled at arc positions colours it exactly.
      function arcGradient(alpha) {
        var g = ctx.createLinearGradient(cx - r, 0, cx + r, 0)
        var samples = 48
        for (var k = 0; k <= samples; k++) {
          var t = k / samples
          var x = (1 - Math.cos(Math.PI * t)) / 2
          g.addColorStop(x, root.css(root.stopAt(root.arcStops, t, 1), alpha))
        }
        return g
      }

      ctx.lineCap = "butt"
      ctx.lineWidth = root.line
      if (p < 1) {
        ctx.strokeStyle = arcGradient(0.16)
        ctx.beginPath()
        ctx.arc(cx, cy, r, root.angleFor(p), root.angleFor(1), false)
        ctx.stroke()
      }
      if (p > 0) {
        ctx.strokeStyle = arcGradient(0.95)
        ctx.beginPath()
        ctx.arc(cx, cy, r, root.angleFor(0), root.angleFor(p), false)
        ctx.stroke()
      }

      // Rounded ends.
      ctx.fillStyle = root.css(root.stopAt(root.arcStops, 0, 1), p > 0 ? 0.95 : 0.16)
      ctx.beginPath()
      ctx.arc(cx - r, cy, root.line / 2, 0, Math.PI * 2, false)
      ctx.fill()
      ctx.fillStyle = root.css(root.stopAt(root.arcStops, 1, 1), p >= 1 ? 0.95 : 0.16)
      ctx.beginPath()
      ctx.arc(cx + r, cy, root.line / 2, 0, Math.PI * 2, false)
      ctx.fill()

      // Tiny dots just outside the arc mark the phase boundaries.
      var list = root.phases || []
      for (var i = 1; i < list.length; i++) {
        var a = root.angleFor(list[i].start)
        var dr = r + root.line * 1.15
        ctx.fillStyle = root.rgba(root.foreground, 0.4)
        ctx.beginPath()
        ctx.arc(cx + Math.cos(a) * dr, cy + Math.sin(a) * dr, Math.max(1, root.line * 0.16), 0, Math.PI * 2, false)
        ctx.fill()
      }
    }
  }

  // Today: a marker on the arc, coloured like the arc at that point, with a
  // soft, steady glow. No rays, no animation of its brightness.
  Canvas {
    id: markerCanvas
    width: Math.ceil(root.line * 7)
    height: width
    x: root.markerX - width / 2
    y: root.markerY - height / 2
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var c = width / 2
      var body = root.line * 0.85
      var color = root.stopAt(root.arcStops, root.displayedProgress, 1)

      var glowR = c
      var glow = ctx.createRadialGradient(c, c, body * 0.8, c, c, glowR)
      glow.addColorStop(0, root.css(color, 0.45))
      glow.addColorStop(0.45, root.css(color, 0.14))
      glow.addColorStop(1, root.css(color, 0))
      ctx.fillStyle = glow
      ctx.beginPath()
      ctx.arc(c, c, glowR, 0, Math.PI * 2, false)
      ctx.fill()

      ctx.fillStyle = root.css(color, 1)
      ctx.beginPath()
      ctx.arc(c, c, body, 0, Math.PI * 2, false)
      ctx.fill()
      ctx.lineWidth = Math.max(1.5, root.line * 0.3)
      ctx.strokeStyle = root.rgba(root.foreground, 0.95)
      ctx.stroke()
    }
  }

  Text {
    x: Math.max(0, root.centerX - root.radius - implicitWidth / 2)
    y: root.centerY + Style.space(4)
    text: "Dawn"
    color: Qt.darker(root.foreground, 1.7)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  Text {
    x: Math.min(root.width - implicitWidth, root.centerX + root.radius - implicitWidth / 2)
    y: root.centerY + Style.space(4)
    text: "Darkness"
    color: Qt.darker(root.foreground, 1.7)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.centerY - height - Style.space(6)
    spacing: Style.space(2)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.countText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Math.max(Style.font.body, Math.round(root.radius * 0.3))
      font.bold: true
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.countLabel
      color: Qt.darker(root.foreground, 1.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1.8
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.phaseText.toUpperCase()
      color: root.phases && root.phases.length > 0
        ? root.phaseColor(root.phases[Math.max(0, Math.min(root.phases.length - 1, root.phaseIndex))].key)
        : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1.8
      font.bold: true
    }
  }
}
