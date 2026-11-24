// node tests/model.test.mjs
import { readFileSync } from "node:fs"
import assert from "node:assert/strict"

const src = readFileSync(new URL("../Model.js", import.meta.url), "utf8").replace(".pragma library", "")
const M = new Function(src + "; return { parsePresets, nextPreset, parseState, formatState, splitRemaining }")()

assert.deepEqual(M.parsePresets("120, 30,abc,60,60,0,9999,<b>5</b>"), [30, 60, 120])
assert.deepEqual(M.parsePresets(""), [30, 60, 120])
assert.deepEqual(M.parsePresets(undefined), [30, 60, 120])
assert.deepEqual(M.parsePresets("15"), [15])

assert.equal(M.nextPreset([30, 60, 120], 0), 30)
assert.equal(M.nextPreset([30, 60, 120], 30), 60)
assert.equal(M.nextPreset([30, 60, 120], 120), 0)
assert.equal(M.nextPreset([30, 60, 120], 45), 60)

const s = M.formatState(1764000000000, 60)
assert.deepEqual(M.parseState(s), { deadline: 1764000000000, minutes: 60 })
assert.equal(M.parseState(""), null)
assert.equal(M.parseState("garbage"), null)
assert.equal(M.parseState("1764000000000 0"), null)
assert.equal(M.parseState("1764000000000 60; rm -rf ~"), null)

assert.deepEqual(M.splitRemaining(0), { hours: 0, minutes: 0, total: 0 })
assert.deepEqual(M.splitRemaining(1), { hours: 0, minutes: 1, total: 1 })
assert.deepEqual(M.splitRemaining(90 * 60000), { hours: 1, minutes: 30, total: 90 })
assert.deepEqual(M.splitRemaining(-5000), { hours: 0, minutes: 0, total: 0 })

console.log("model tests passed")
