#!/usr/bin/env node

const assert = require("node:assert/strict")
const fs = require("node:fs")
const vm = require("node:vm")
const path = require("node:path")

const source = fs.readFileSync(path.join(__dirname, "..", "js", "Life.js"), "utf8")
  .replace(/^\.pragma library\s*/, "")
const life = { Math, Date, String, Number, isFinite }
vm.createContext(life)
vm.runInContext(source, life)

assert.equal(life.randomMaxAge(0), 95)
assert.equal(life.randomMaxAge(0.999999), 120)

assert.deepEqual(
  JSON.parse(JSON.stringify(life.parseIsoDate("1995-08-20"))),
  { year: 1995, month: 8, day: 20 }
)
assert.equal(life.parseIsoDate("2025-02-29"), null)
assert.equal(life.parseIsoDate("not-a-date"), null)

const birthDay = new Date(2025, 7, 20, 12)
const atBirth = life.metrics("2025-08-20", 95, birthDay)
assert.equal(atBirth.livedDays, 0)
assert.equal(atBirth.endDate, "2120-08-20")
assert.equal(atBirth.remainingDays, atBirth.totalDays)

const leapScale = life.metrics("2000-02-29", 95, new Date(2001, 1, 28, 12))
assert.equal(leapScale.endDate, "2095-02-28")
assert.equal(leapScale.livedDays, 365)

const beyond = life.metrics("1900-01-01", 95, new Date(2000, 0, 1, 12))
assert.equal(beyond.beyond, true)
assert.equal(beyond.remainingDays, 0)
assert.ok(beyond.beyondDays > 0)
assert.ok(beyond.progress > 1)
assert.equal(beyond.visualProgress, 1)

const valid = life.validateInput("  Midas   Truth  ", "1995-08-20", new Date(2026, 0, 1, 12))
assert.equal(valid.ok, true)
assert.equal(valid.name, "Midas Truth")
assert.equal(valid.birthday, "1995-08-20")
assert.equal(life.validateInput("Midas", "2099-01-01", new Date(2026, 0, 1, 12)).ok, false)

const normalized = life.normalizeProfile({
  initialized: true,
  name: "Midas",
  birthday: "1995-08-20",
  maxAge: 107,
  dailyDisplay: false,
  showRemaining: false,
  lastShownDate: "2026-09-12"
})
assert.equal(normalized.initialized, true)
assert.equal(normalized.maxAge, 107)
assert.equal(normalized.dailyDisplay, false)
assert.equal(normalized.showRemaining, false)

console.log("Life.js: all tests passed")
