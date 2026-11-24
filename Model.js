.pragma library

// Pure helpers, kept free of QML so tests/model.test.mjs can run them in node.

var MAX_MINUTES = 24 * 60

// "30, 60,abc,120" -> [30, 60, 120]; sorted, deduped, each 1..1440.
function parsePresets(value) {
  var parts = String(value === undefined || value === null ? "" : value).split(",")
  var seen = {}
  var out = []
  for (var i = 0; i < parts.length && out.length < 12; i++) {
    var trimmed = parts[i].trim()
    if (!/^\d{1,4}$/.test(trimmed)) continue
    var n = parseInt(trimmed, 10)
    if (n < 1 || n > MAX_MINUTES || seen[n]) continue
    seen[n] = true
    out.push(n)
  }
  out.sort(function(a, b) { return a - b })
  return out.length ? out : [30, 60, 120]
}

// The preset after the one currently running, or 0 (= turn off) after the last.
// currentMinutes is the preset that started the running timer, 0 if none.
function nextPreset(presets, currentMinutes) {
  if (!currentMinutes) return presets[0]
  for (var i = 0; i < presets.length; i++) {
    if (presets[i] > currentMinutes) return presets[i]
  }
  return 0
}

// State file: "<deadlineEpochMs> <presetMinutes>". Anything else -> null.
function parseState(text) {
  var m = /^\s*(\d{10,14})\s+(\d{1,4})\s*$/.exec(String(text || ""))
  if (!m) return null
  var deadline = parseInt(m[1], 10)
  var minutes = parseInt(m[2], 10)
  if (minutes < 1 || minutes > MAX_MINUTES) return null
  return { deadline: deadline, minutes: minutes }
}

function formatState(deadline, minutes) {
  return Math.round(deadline) + " " + Math.round(minutes) + "\n"
}

// Split remaining milliseconds into whole hours and minutes, rounding up so
// the countdown never reads 0m while time is left.
function splitRemaining(ms) {
  var totalMinutes = Math.max(0, Math.ceil(ms / 60000))
  return { hours: Math.floor(totalMinutes / 60), minutes: totalMinutes % 60, total: totalMinutes }
}
