.pragma library

var DAY_MS = 86400000
var MIN_AGE = 95
var MAX_AGE = 120

function pad2(value) {
  var text = String(Math.floor(Number(value) || 0))
  return text.length < 2 ? "0" + text : text
}

function isoDate(year, month, day) {
  return String(year) + "-" + pad2(month) + "-" + pad2(day)
}

function parseIsoDate(value) {
  var match = String(value || "").match(/^(\d{4})-(\d{2})-(\d{2})$/)
  if (!match) return null

  var year = Number(match[1])
  var month = Number(match[2])
  var day = Number(match[3])
  if (year < 1 || month < 1 || month > 12 || day < 1) return null

  var candidate = new Date(Date.UTC(year, month - 1, day))
  if (candidate.getUTCFullYear() !== year
      || candidate.getUTCMonth() !== month - 1
      || candidate.getUTCDate() !== day) return null

  return { year: year, month: month, day: day }
}

function todayKey(date) {
  var current = date || new Date()
  return isoDate(current.getFullYear(), current.getMonth() + 1, current.getDate())
}

function civilDay(parts) {
  return Math.floor(Date.UTC(parts.year, parts.month - 1, parts.day) / DAY_MS)
}

function daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate()
}

function addYearsClamped(parts, years) {
  var year = parts.year + years
  var day = Math.min(parts.day, daysInMonth(year, parts.month))
  return { year: year, month: parts.month, day: day }
}

function addMonthsClamped(parts, months) {
  var monthIndex = parts.month - 1 + months
  var year = parts.year + Math.floor(monthIndex / 12)
  var month = ((monthIndex % 12) + 12) % 12 + 1
  var day = Math.min(parts.day, daysInMonth(year, month))
  return { year: year, month: month, day: day }
}

function normalizeName(value) {
  return String(value || "").replace(/\s+/g, " ").trim().substring(0, 60)
}

function validateInput(name, birthday, today) {
  var cleanName = normalizeName(name)
  if (!cleanName) return { ok: false, error: "Please enter your name." }

  var born = parseIsoDate(birthday)
  if (!born) return { ok: false, error: "Please enter a valid birth date." }

  var now = parseIsoDate(todayKey(today))
  if (civilDay(born) > civilDay(now))
    return { ok: false, error: "Your birth date cannot be in the future." }

  return { ok: true, name: cleanName, birthday: isoDate(born.year, born.month, born.day) }
}

function randomMaxAge(randomValue) {
  var value = randomValue === undefined ? Math.random() : Number(randomValue)
  if (!isFinite(value)) value = 0
  value = Math.max(0, Math.min(0.999999999, value))
  return MIN_AGE + Math.floor(value * (MAX_AGE - MIN_AGE + 1))
}

function defaultProfile() {
  return {
    version: 1,
    initialized: false,
    name: "",
    birthday: "",
    maxAge: 0,
    dailyDisplay: true,
    showRemaining: true,
    showBarDays: true,
    barShowsRemaining: false,
    viewMode: "summary",
    gridUnit: "weeks",
    lastShownDate: ""
  }
}

function normalizeProfile(value) {
  var fallback = defaultProfile()
  var source = value && typeof value === "object" ? value : {}
  var name = normalizeName(source.name)
  var birthday = parseIsoDate(source.birthday)
  var maxAge = Math.floor(Number(source.maxAge))
  var validAge = isFinite(maxAge) && maxAge >= MIN_AGE && maxAge <= MAX_AGE
  var initialized = source.initialized === true && name !== "" && birthday !== null && validAge

  return {
    version: 1,
    initialized: initialized,
    name: initialized ? name : fallback.name,
    birthday: initialized ? isoDate(birthday.year, birthday.month, birthday.day) : fallback.birthday,
    maxAge: initialized ? maxAge : fallback.maxAge,
    dailyDisplay: source.dailyDisplay === undefined ? true : source.dailyDisplay === true,
    showRemaining: source.showRemaining === undefined ? true : source.showRemaining === true,
    showBarDays: source.showBarDays === undefined ? true : source.showBarDays === true,
    barShowsRemaining: source.barShowsRemaining === true,
    viewMode: source.viewMode === "grid" ? "grid" : "summary",
    gridUnit: ["days", "weeks", "months", "years"].indexOf(source.gridUnit) >= 0
      ? source.gridUnit : "weeks",
    lastShownDate: parseIsoDate(source.lastShownDate) ? String(source.lastShownDate) : ""
  }
}

function metrics(birthday, maxAge, today) {
  var born = parseIsoDate(birthday)
  var current = parseIsoDate(todayKey(today))
  var age = Math.floor(Number(maxAge))
  if (!born || !current || !isFinite(age) || age <= 0) {
    return {
      endDate: "",
      livedDays: 0,
      totalDays: 0,
      remainingDays: 0,
      beyondDays: 0,
      progress: 0,
      visualProgress: 0,
      beyond: false
    }
  }

  var end = addYearsClamped(born, age)
  var livedDays = Math.max(0, civilDay(current) - civilDay(born))
  var totalDays = Math.max(1, civilDay(end) - civilDay(born))
  var difference = totalDays - livedDays
  var progress = livedDays / totalDays

  return {
    endDate: isoDate(end.year, end.month, end.day),
    livedDays: livedDays,
    totalDays: totalDays,
    remainingDays: Math.max(0, difference),
    beyondDays: Math.max(0, -difference),
    progress: progress,
    visualProgress: Math.max(0, Math.min(1, progress)),
    beyond: difference < 0
  }
}

function unitMetrics(birthday, maxAge, today, unit) {
  var born = parseIsoDate(birthday)
  var current = parseIsoDate(todayKey(today))
  var age = Math.floor(Number(maxAge))
  var selected = ["days", "weeks", "months", "years"].indexOf(unit) >= 0 ? unit : "weeks"
  if (!born || !current || !isFinite(age) || age <= 0)
    return { unit: selected, total: 0, elapsed: 0 }

  var dayMetrics = metrics(birthday, age, today)
  var total = 0
  var elapsed = 0
  if (selected === "days") {
    total = dayMetrics.totalDays
    elapsed = dayMetrics.livedDays
  } else if (selected === "weeks") {
    total = Math.ceil(dayMetrics.totalDays / 7)
    elapsed = Math.floor(dayMetrics.livedDays / 7)
  } else if (selected === "months") {
    total = age * 12
    elapsed = (current.year - born.year) * 12 + current.month - born.month
    if (civilDay(current) < civilDay(addMonthsClamped(born, elapsed))) elapsed--
  } else {
    total = age
    elapsed = current.year - born.year
    if (civilDay(current) < civilDay(addYearsClamped(born, elapsed))) elapsed--
  }

  return {
    unit: selected,
    total: Math.max(0, total),
    elapsed: Math.max(0, Math.min(total, elapsed))
  }
}

function formatNumber(value) {
  var number = Math.max(0, Math.floor(Number(value) || 0))
  return String(number).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

function formatPercent(value) {
  var number = Math.max(0, Number(value) || 0) * 100
  return number.toFixed(2) + "%"
}
