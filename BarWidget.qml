import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// A mug that keeps the system awake. Bar widgets do not get Omarchy's
// first-party services, so it goes through the public interface instead:
// `omarchy toggle idle` to change state, and the state file the idle service
// itself watches to read it. That keeps it in step with the built-in
// indicator. A timed preset adds a deadline, kept in a state file of its own
// so a shell reload does not lose it.
BarWidget {
  id: root
  moduleName: "elvisgastelum.stay-awake"

  readonly property string icon: "\uef59"
  readonly property string indicatorDir: Quickshell.env("HOME") + "/.local/state/omarchy/indicators"
  property bool serviceReady: false
  property bool stayAwake: false

  readonly property var presets: Model.parsePresets(setting("presets", "30,60,120"))
  readonly property bool showCountdown: {
    var v = setting("showCountdown", true)
    return v !== false && v !== "false"
  }

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/elvisgastelum.stay-awake"
  property var timer: null          // { deadline: epochMs, minutes: preset } or null
  property bool stateLoaded: false
  property real now: Date.now()

  readonly property bool timed: stayAwake && timer !== null
  readonly property var remaining: Model.splitRemaining(timed ? timer.deadline - now : 0)
  readonly property int nextMinutes: Model.nextPreset(presets, timed ? timer.minutes : 0)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  function durationText(minutes) {
    if (minutes < 60) return strings.tn("duration.minutes", minutes).arg(Commons.I18n.formatNumber(minutes))
    var h = Math.floor(minutes / 60)
    var m = minutes % 60
    if (m === 0) return strings.tn("duration.hours", h).arg(Commons.I18n.formatNumber(h))
    return strings.t("duration.hoursMinutes").arg(Commons.I18n.formatNumber(h)).arg(Commons.I18n.formatNumber(m))
  }

  function countdownText() {
    if (remaining.hours > 0)
      return strings.t("countdown.hoursMinutes").arg(Commons.I18n.formatNumber(remaining.hours)).arg(Commons.I18n.formatNumber(remaining.minutes))
    return strings.t("countdown.minutes").arg(Commons.I18n.formatNumber(remaining.minutes))
  }

  function setStayAwake(enabled) {
    root.stayAwake = enabled   // optimistic; the watcher confirms it
    toggleProc.command = ["omarchy-toggle-idle", enabled ? "stay-awake" : "allow-idle"]
    toggleProc.running = true
  }

  function probe() {
    if (!probeProc.running) probeProc.running = true
  }

  function writeTimer(value) {
    root.timer = value
    timerFile.setText(value ? Model.formatState(value.deadline, value.minutes) : "")
  }

  function stayAwakeFor(minutes) {
    root.now = Date.now()
    writeTimer({ deadline: root.now + minutes * 60000, minutes: minutes })
    setStayAwake(true)
  }

  function allowIdle() {
    writeTimer(null)
    setStayAwake(false)
  }

  function toggle() {
    if (root.stayAwake) {
      allowIdle()
    } else {
      writeTimer(null)
      setStayAwake(true)
    }
  }

  function cyclePreset() {
    if (root.nextMinutes > 0) stayAwakeFor(root.nextMinutes)
    else allowIdle()
  }

  // Ends an expired timer, and drops a stale one when stay-awake was turned
  // off somewhere else (the built-in indicator, `omarchy toggle idle`).
  function reconcile() {
    if (!root.serviceReady || !root.stateLoaded || root.timer === null) return
    if (!root.stayAwake) {
      writeTimer(null)
      return
    }
    root.now = Date.now()
    if (root.timer.deadline <= root.now) allowIdle()
  }

  onServiceReadyChanged: reconcile()
  onStayAwakeChanged: reconcile()
  onStateLoadedChanged: reconcile()
  Component.onCompleted: probe()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    running: true
    command: ["mkdir", "-p", root.stateDir, root.indicatorDir]
  }

  Process {
    id: toggleProc
    onExited: root.probe()
  }

  // Same source of truth as `omarchy toggle idle status`: the flag file.
  Process {
    id: probeProc
    command: ["test", "-f", root.indicatorDir + "/stay-awake"]
    onExited: function(exitCode) {
      if (toggleProc.running) return   // stale read; toggleProc re-probes when done
      root.stayAwake = exitCode === 0
      root.serviceReady = true
      root.reconcile()
    }
  }

  // The idle service watches this directory the same way.
  FileView {
    path: root.indicatorDir
    printErrors: false
    watchChanges: true
    onFileChanged: root.probe()
  }

  // Backstop in case a directory event is missed.
  Timer { interval: 30000; running: true; repeat: true; onTriggered: root.probe() }

  FileView {
    id: timerFile
    path: root.stateDir + "/timer"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      root.timer = Model.parseState(text())
      root.stateLoaded = true
    }
    onLoadFailed: function() {
      root.timer = null
      root.stateLoaded = true
    }
  }

  // Ticks only while a timed preset runs; minute resolution is enough.
  Timer {
    interval: 5000
    running: root.timed
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      root.now = Date.now()
      root.reconcile()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.timed && root.showCountdown && !root.vertical
      ? root.icon + " " + root.countdownText() : root.icon
    fontSize: root.vertical || !root.timed ? Style.bar.iconFont : Style.font.body
    active: root.stayAwake
    dimmed: !root.stayAwake
    tooltipText: root.timed
        ? strings.t("tooltip.timed").arg(root.durationText(root.remaining.total))
            .arg(root.nextMinutes > 0 ? strings.t("tooltip.next").arg(root.durationText(root.nextMinutes)) : strings.t("tooltip.nextOff"))
        : strings.t(root.stayAwake ? "tooltip.on" : "tooltip.off").arg(root.durationText(root.presets[0]))
    onPressed: function(b) {
      if (b === Qt.RightButton) root.cyclePreset()
      else if (b === Qt.LeftButton) root.toggle()
    }
  }
}
