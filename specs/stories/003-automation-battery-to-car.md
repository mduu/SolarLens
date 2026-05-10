# Story: #3, Automation – Transfer from Battery to Car

**Status:** In Progress (TestFlight 4.1.0, build 298) — Live Activity deferred, unit tests pending

## Short Description

Add a new "Automation" tab to the iOS app that lets the user run advanced charging workflows. The first (and currently only) automation is **"Transfer from Battery to Car"**: it sets the selected charging station to *Constant current* with a power level small enough to be served by the house battery alone (no grid import), continuously adjusts that power level as PV / consumers change, and stops when a user-chosen battery floor (%) is reached or grid import becomes unavoidable. After the run, the charging station is switched to a user-selected fallback charging mode and a local notification summarises what was transferred. The automation is **pure client-side** — no server, no cloud function, no APNs.

## Additional Information

### Why iOS only

- We deliberately do **not** add a backend component. The Solar Lens server today is only used by tvOS for background uploads and we want to keep the server-free guarantee for the iOS automation feature.
- This rules out Apple Push Notifications (APNs), server-side cron, and any "always-on" external worker. All scheduling, monitoring and notification has to happen on-device using iOS APIs.
- iOS does not give third-party apps reliable always-on background execution. The implementation has to be honest about this: while the app is foregrounded the automation runs precisely; while it is backgrounded we rely on a combination of `BGAppRefreshTask` and a **Live Activity** to keep the user informed and to drive opportunistic re-runs. The UI must communicate this clearly to the user.

### Existing draft on branch `79-add-scenario-charge-car-from-battery-only`

A WIP implementation already exists. It introduces a generic "Scenario" runner (`ScenarioManager`, `ScenarioHost`, `ScenarioState`, `ScenarioTask`, `ScenarioBatteryToCar`, ...) under `Solar Lens iOS/Scenarios/`. The runner already handles:

- One active scenario at a time (`activeState != nil` blocks new starts).
- A foreground `Timer` (5s tick) that re-invokes the active task when its `nextTaskRun` date has passed.
- `BGAppRefreshTask` scheduling on `scenePhase == .background`, registered with identifier `com.marcduerst.SolarManagerWatch.ScenarioRunner`.
- Per-scenario state and parameters (`ScenarioBatteryToCarState`, `ScenarioBatteryToCarParameters`).
- A scenario log viewer with bubble counter (`ScenarioLogManager`, `ScenarioLogView`, `LogCountBubble`).

What is **not** yet good enough on that branch (and must be redone in this story):

- The existing `ScenarioBatteryToCar.run` only switches to `constantCurrent` once with a hardcoded `6 A` and never re-tunes the current as PV/consumers change — it only checks battery level for the stop condition. Step 4 of the backlog item ("monitor and increase/decrease the energy flowing... only use battery; no grid") is not implemented.
- The TODO `Convert totalMaxBatteryOutputKw into Ampere` is unfinished (no voltage / phase handling).
- There is no fallback-mode parameter — the backlog requires the user to pick what charging mode to switch to *after* the automation finishes (defaulting to "Solar only").
- There is no cancel UI / cancel path that restores the user-selected fallback mode rather than the originally-stored mode.
- There is no local notification on completion.
- There is no Live Activity, so background monitoring is opaque to the user.
- The "Automation" tab does not exist yet — scenarios are surfaced via a `ScenarioScreen` reachable from settings/home, not as a primary tab.
- UI does not yet match the "AI / gradient" feel called out in the backlog item.

We **keep the runner architecture** (it is the right shape) and **rewrite the BatteryToCar task and the surrounding UI** on top of it. We also **rename everything from `Scenario*` to `Automation*`** while cherry-picking, so the user-facing word ("Automation") and the internal types match. Concretely:

| WIP branch (old) | This story (new) |
|---|---|
| `Solar Lens iOS/Scenarios/` | `Solar Lens iOS/Automations/` |
| `ScenarioManager` | `AutomationManager` |
| `ScenarioHost` | `AutomationHost` |
| `ScenarioState` | `AutomationState` |
| `ScenarioStatus` | `AutomationStatus` |
| `ScenarioTask` | `AutomationTask` |
| `ScenarioParameters` | `AutomationParameters` |
| `Scenario` (enum of available scenarios) | `Automation` (enum of available automations) |
| `ScenarioBatteryToCar` | `AutomationBatteryToCar` |
| `ScenarioBatteryToCarState` | `AutomationBatteryToCarState` |
| `ScenarioBatteryToCarParameters` | `AutomationBatteryToCarParameters` |
| `ScenarioLogManager` / `ScenarioLogMessage` / `ScenarioLogLevelExtensions` | `AutomationLogManager` / `AutomationLogMessage` / `AutomationLogLevelExtensions` |
| `ScenarioScreen` | (replaced by new `AutomationScreen`) |
| `ScenarioButton` | `AutomationButton` |
| `ScenarioLogView` | `AutomationLogView` |
| BG task id `com.marcduerst.SolarManagerWatch.ScenarioRunner` | `com.marcduerst.SolarManagerWatch.AutomationRunner` |
| `UserDefaults` key `SolarLens.activeScenarioState` | `SolarLens.activeAutomationState` |
| Localised strings using "Scenario" | "Automation" |

(`LogCountBubble` keeps its name — it's a generic UI component.)

From here on the story uses the new names.

### Tab placement & navigation

```
TabView
├── Now              (HomeScreen) — existing
├── Automation       (AutomationScreen) — NEW
└── Statistics       (StatisticsScreen) — existing
```

- New tab uses `systemImage: "wand.and.stars"` (matches the "AI" framing).
- `AutomationScreen` lists the available automations as cards. With currently one automation, the screen shows:
  - A header card explaining what automation does in plain language.
  - The "Transfer from Battery to Car" card. While running, the card flips to a live state (current battery %, current charging power, kWh transferred so far, elapsed time, Cancel button).
  - Below: a small "Activity" section showing the latest run summary (read from `ScenarioLogManager` — already present in branch).
- When an automation is running, *all other* automation cards are disabled with a hint "Another automation is active".

### Automation flow (matches backlog steps 1–7)

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Setup sheet                                               │
│    - Pick charging station (skipped if only one)             │
│    - Pick *soft* min house-battery % (slider, default 30%)   │
│      Label: "Don't go below (if possible)" — make the soft   │
│      semantics visible to the user                           │
│    - Pick fallback charging mode after run                   │
│      (default ".withSolarPower")                             │
│    - "Start Automation" button                               │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Snapshot & start                                          │
│    - Capture previous chargingMode of the station            │
│      (used only for logging; we restore to the user-chosen   │
│      fallback, not to this value)                            │
│    - Compute initial constant-current amperage from battery  │
│      max discharge power (see "Power → Amps" below)          │
│    - POST /v1/control/car-charging:                          │
│         constantCurrentSetting = computedAmps                │
│         chargingMode = .constantCurrent                      │
│    - Start Live Activity                                     │
│    - Start foreground timer + BG refresh schedule            │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. Monitor loop (every monitorInterval, default 60s active   │
│    / opportunistic in background, see "Monitoring" below)    │
│                                                              │
│    Fetch overview + station live data                        │
│                                                              │
│    Decide:                                                   │
│      a) currentBatteryLevel - safetyBuffer <= floor%         │
│         → STOP (soft-floor reached, predictive)              │
│         (see "Soft floor & predictive stop" below)           │
│      b) currentGridToHouse  > graceWatt → STOP (capped)      │
│         (sustained for 2 consecutive ticks, to ride out      │
│          short transients like an oven turning on)           │
│      c) otherwise → re-tune amperage (see "Tuning" below)    │
│                                                              │
│    Persist state, update Live Activity, log.                 │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Stop                                                      │
│    - POST /v1/control/car-charging:                          │
│         chargingMode = parameters.fallbackChargingMode       │
│    - Compute kWh transferred during run                      │
│      (sum of station power readings × Δt, OR delta of        │
│       station todayTotal — see "kWh accounting" below)       │
│    - End Live Activity                                       │
│    - Schedule local UNNotificationRequest with summary       │
│    - Clear active state                                      │
└──────────────────────────────────────────────────────────────┘
```

### Power → Amps conversion

Solar Manager charging stations accept `constantCurrentSetting` in Amps (range **6–32 A**, see `ControlCarChargingRequest`).

Battery `maxDischargePower` is given in Watts (`BatteryInfo.maxDischargePower: Int`). To convert:

```swift
// Target audience: Switzerland (primary), Germany, Austria, Denmark.
// All four use the same domestic grid: 230 V phase-to-neutral / 400 V line-to-line, 50 Hz.
// Domestic charging stations in this region are typically 3-phase 400 V (11 kW @ 16 A or
// 22 kW @ 32 A). 1-phase 230 V charging stations (≤ 7.4 kW @ 32 A) exist but are less
// common — exposed as an advanced setting; default 3-phase.
//
// → P[W] = √3 · U · I · cos φ ≈ 1.732 · 400 · I (cos φ ≈ 1 for EV charging)
// → I    = P / (√3 · 400) ≈ P / 692.8

let phases = 3                  // default 3-phase; user-configurable per station
let voltageLineToLine = 400.0
let voltageLineToNeutral = 230.0

let totalAmpsAvailable: Double = {
    switch phases {
    case 3: return Double(maxDischargePowerW) / (sqrt(3) * voltageLineToLine)
    case 1: return Double(maxDischargePowerW) / voltageLineToNeutral
    default: return Double(maxDischargePowerW) / voltageLineToNeutral
    }
}()

let initialAmps = max(6, min(32, Int(floor(totalAmpsAvailable))))
```

We deliberately under-provision (use `floor`) so we start strictly under the battery's max discharge rate. The first monitor tick will then ramp up if the battery can absorb it.

**Edge case:** If multiple batteries are present, sum their `maxDischargePower`. The current `ScenarioBatteryToCar` draft already does this:

```swift
let totalMaxBatteryOutputKw = overviewData.devices
    .filter { $0.deviceType == .battery && $0.batteryInfo != nil }
    .reduce(0) { $0 + $1.batteryInfo!.maxDischargePower }
```

### Tuning algorithm (Step 4 of backlog)

The goal is: *all* car charging energy comes from the battery, none from the grid, but we always squeeze the maximum out of the battery without dipping into grid.

Available signals on every tick (from `OverviewData`):

| Signal | Source | Semantics |
|---|---|---|
| `currentSolarProduction` | overview | PV right now (W) |
| `currentOverallConsumption` | overview | total house consumption (W) |
| `currentBatteryChargeRate` | overview | + = charging, − = discharging (W) |
| `currentGridToHouse` | overview | grid import (W) — should stay ≈ 0 |
| `currentSolarToGrid` | overview | grid export (W) — surplus we could absorb |
| station `currentPower` | overview | charging station draw right now (W) |
| `currentBatteryLevel` | overview | SoC % |

Tuning rule (PI-style, simple and safe):

```
gridImportW   = currentGridToHouse
gridExportW   = currentSolarToGrid
stationPowerW = station.currentPower
batteryDisW   = max(0, -currentBatteryChargeRate)   // discharge in W

// Headroom: how much more the battery could give before we'd need grid
// (positive = we can ramp up; negative = we already over-drew and grid filled in)
let headroomW = gridExportW - gridImportW            // net of grid flow
                + (maxDischargePowerW - batteryDisW) // unused battery capacity

let stepW: Double = 230.0 * Double(phases)           // ≈ 1 A step on 3-phase
var deltaA: Int = 0

let graceW = 200                    // see "Grace band sizing" below
if gridImportW > graceW {
    deltaA = -max(1, Int(ceil(Double(gridImportW) / stepW)))   // ramp DOWN
} else if headroomW > stepW {
    deltaA = 1                       // ramp UP one amp (conservative)
}

let newAmps = max(6, min(32, currentAmps + deltaA))
if newAmps != currentAmps {
    POST /v1/control/car-charging { constantCurrentSetting: newAmps }
}
```

Key properties:

- Asymmetric: ramps down aggressively (any sustained grid import is corrected next tick) and ramps up one step at a time (avoids oscillation when a thermostat or an oven cycles).
- 200 W grace band for grid flow — see "Grace band sizing" below.
- Only writes a new amperage when it actually changes — saves API calls.
- Lower clamp at 6 A: below that the charging station cannot run constant-current at all. If even 6 A causes grid import for two consecutive ticks → STOP (capped) per Step 5.

#### Grace band sizing

`graceW` is the dead-band where we *don't* react to small grid imports. Picking it well matters in practice:

| Source of noise | Typical magnitude |
|---|---|
| SM sensor jitter (PV, battery, consumption sampled with slight skew) | ±50–150 W |
| Fridge compressor turning on | 80–150 W |
| Heat-pump pump / circulator cycling | 50–300 W |
| Battery inverter response lag to a step load (looks like a 60 s transient at our tick rate) | up to ~500 W for ~1–2 s |

100 W is too tight: a fridge cycling on shows up as grid import for ~1–2 s before the battery inverter catches up. With 60 s ticks we sometimes catch that transient and would needlessly ramp down. Two or three of those in a 30-min run and we under-utilise the battery.

**Default: `graceW = 200`.**

- Tolerated grid import per tick: 200 W × 60 s = 3.3 Wh.
- Worst case over a 2-hour run: ~400 Wh — small vs. typical 5–15 kWh transferred from battery.
- Hysteresis comes naturally from the asymmetric rule: ramp-up only fires when there's > one full A-step of export headroom (≈ 690 W on 3-phase), so we can't oscillate around 200 W.

**Tunable**: expose `graceW` only as a build-time constant for now; revisit after real-world testing on at least one CH installation with a heat pump (worst-case noise environment) and one without. If we observe systematic short-cycle ramp-down after the MVP, raise to 300 W.

### Soft floor & predictive stop

The user-chosen battery percentage is a **soft floor**: "don't go below this if possible". Stopping exactly *at* the floor would routinely overshoot it because:

- In foreground we tick every ~60 s — at 5 kW discharge of a 14 kWh battery that's already ~0.6 %/min of slip.
- In background `BGAppRefreshTask` cadence is opaque (often 15–60 min). Between two ticks the battery could drop several %.

So we stop **early**, with a safety buffer that grows with how stale our last tick was:

```swift
// drain rate the *whole house* puts on the battery right now (not just the charging station —
// the fridge / heat-pump / etc. keep running too)
let dischargeW = max(0, -overview.currentBatteryChargeRate)         // W

// 1% of total battery capacity in Wh
let onePercentWh = (totalBatteryCapacityKwh * 1000.0) / 100.0       // Wh per %

// %/min at the current discharge rate
let percentPerMin = (Double(dischargeW) / onePercentWh) / 60.0

// EWMA of the last few observed tick intervals (foreground = ~1 min,
// background = whatever iOS gave us). Recorded in AutomationBatteryToCarState.
let expectedNextTickMin = state.smoothedTickIntervalMinutes          // see below

// Multiply by a safety factor so we tolerate a slightly-longer-than-average gap.
let rawBufferPct = percentPerMin * expectedNextTickMin * safetyFactor // 1.5
let safetyBufferPct = min(maxBufferPct, max(1.0, ceil(rawBufferPct))) // floor 1%, cap 8%

if Double(currentBatteryLevel) - safetyBufferPct <= Double(floorPct) {
    return stop(reason: .softFloorReached)
}
```

Tunables (start with these, adjust after real-world observation):

| Parameter | Value | Why |
|---|---|---|
| `safetyFactor` | 1.5 | tolerate an interval ~50% longer than the recent average |
| `maxBufferPct` | 8 % | hard cap so we never refuse to charge a user with a low floor (e.g., user picks 20%, BG goes silent for 30 min — without the cap we'd stop at 30%+, which the user will perceive as broken) |
| `minBufferPct` | 1 % | always at least 1% — protects against off-by-one when discharge is tiny |

`smoothedTickIntervalMinutes` is an EWMA in `AutomationBatteryToCarState`:

```swift
let observed = max(0.5, Date().timeIntervalSince(state.lastTickAt) / 60.0)
let alpha = 0.4   // weight given to the latest sample
state.smoothedTickIntervalMinutes =
    alpha * observed + (1 - alpha) * state.smoothedTickIntervalMinutes
```

Initialised to `1.0` (foreground assumption) when the automation starts.

#### Why this is good enough

- **Foreground**: average tick ≈ 1 min, buffer ≈ 1% (clamped low). Effective stop ≈ floor + 1%. Imperceptible to the user, satisfies the "don't go below" intent.
- **Background, mild gaps**: tick ≈ 5 min, 5 kW drain, 14 kWh battery → buffer ≈ 4–5 %. Stop is conservative but still uses most of the configured headroom.
- **Background, long gaps**: tick ≈ 20 min → raw buffer ≈ 18 %, capped at 8 %. We accept the user *may* dip below floor by up to ~5–10 % (= drain during the gap minus our buffer) in pathological cases. That's strictly better than the naive "stop at floor" rule which always overshoots.

#### Optional: BG-aware ramp-down (follow-up)

If `smoothedTickIntervalMinutes > 5` we could *also* ramp the charging station down preemptively (e.g., halve `currentAmps`) so a long sleep can't drain as fast. Defer this for a follow-up story — the predictive stop above already gets us most of the way.

### Monitoring strategy (the pure-iOS part)

| App state | Mechanism | Frequency | Notes |
|---|---|---|---|
| Foreground | `Timer.scheduledTimer` (`AutomationManager.ensureForegroundTimerStarted`) | tick: 60s | Already wired in branch, currently 5s — change to 60s for production. |
| Background, screen on (Live Activity visible on Lock Screen / Dynamic Island) | `BGAppRefreshTask` chained from `scheduleNextBackgroundCall` | iOS-decided, **typically 15–60 min**, never guaranteed | Live Activity stays current via `Activity<...>.update` from each successful run. |
| Background, suspended | none | n/a | The Live Activity is the user's only signal; values may freeze until the next BG refresh fires. |
| Terminated by user / OOM | none | n/a | `AutomationState` is restored on next launch from a `Codable` persisted snapshot in `UserDefaults` (`SolarLens.activeAutomationState`), but no charging changes are made in our absence. |

This means: **we cannot promise minute-accurate stop behaviour while the app is suspended.** Acceptable failure modes:

- We arrive late to "battery floor reached": the charging station is still drawing constant current. Battery dips a few % below the floor before we get a BG slot. This is bounded — once we wake up we stop immediately. We log it as `Stopped X% below target due to background latency`.
- We arrive late to "grid import detected": same shape. Worst case: a few hundred Wh of grid import before we get a BG slot.

Mitigations:

1. **Live Activity** keeps the app process eligible for more frequent BG refresh and shows the user something is happening. Use `ActivityKit` with a small dynamic island view (battery %, station W, "tap to open").
2. **User education**: in the setup sheet, show a non-modal hint *"For best results, keep Solar Lens open while the automation runs. If the app is closed, iOS may throttle updates."*
3. **`BGTaskScheduler.submit` earliestBeginDate = now + 60s** while running, so we ask iOS for the soonest possible re-entry. The OS will still gate based on its budgeting heuristics.
4. **Predictive soft-floor stop** (see "Soft floor & predictive stop") — we don't wait for `currentBatteryLevel ≤ floor`; we stop early proportional to recent tick lag, which is exactly when BG throttling matters most.

### Background-mode entitlements & Info.plist

The current iOS target does **not** declare any background modes (the entitlements file only contains Siri + Keychain). To use `BGTaskScheduler` and `ActivityKit` we need:

- `Info.plist` keys:
  - `UIBackgroundModes` → `["fetch", "processing"]` — for `BGAppRefreshTask`.
  - `BGTaskSchedulerPermittedIdentifiers` → `["com.marcduerst.SolarManagerWatch.AutomationRunner"]` — must match the identifier used in `AutomationManager.registerBackgroundTask`.
  - `NSSupportsLiveActivities` → `true`.
- Register `AutomationManager.shared.registerBackgroundTask()` from `Solar_Lens_iOSApp.init()` (currently not called anywhere).
- Hook `AutomationManager.handleScenePhaseChange` from a `.onChange(of: scenePhase)` modifier on the `WindowGroup`.

These are **the** missing pieces in the existing branch — without them the BG path is dead code.

### Local notification (Step 7)

iOS local notifications via `UNUserNotificationCenter` — no APNs, no server.

```swift
import UserNotifications

func notifyRunFinished(summary: BatteryToCarSummary) async {
    let center = UNUserNotificationCenter.current()
    _ = try? await center.requestAuthorization(options: [.alert, .sound])

    let content = UNMutableNotificationContent()
    content.title = String(localized: "Automation finished")
    content.body  = String(
        localized: "Charged \(summary.kWhTransferred, specifier: "%.1f") kWh from battery (\(summary.startSoc)% → \(summary.endSoc)%). Switched to \(summary.fallbackMode.displayName)."
    )
    content.sound = .default

    // Fire immediately
    let req = UNNotificationRequest(
        identifier: "automation.batteryToCar.\(UUID().uuidString)",
        content: content,
        trigger: nil
    )
    try? await center.add(req)
}
```

We request authorization the first time the user taps "Start Automation" (not at app launch — feels less spammy).

### kWh accounting

Two viable options:

- **Integrate over time** (Riemann sum of `station.currentPower` × Δt between successful ticks). Simple, but undercounts when ticks are sparse (BG throttling).
- **Use station today-total delta** if the SM API exposes a daily energy counter for the station. Robust against sparse ticks. Currently `ChargingStation` model only has `currentPower`; we'd need to extend it (probably from the same overview payload).

For the MVP go with **integrate over time** and accept the undercount; switch to a counter-delta later if/when we surface that field. The notification copy says "approximately" to be honest about it.

### Cancel behaviour

- The Cancel button on `AutomationScreen` (and on the Live Activity) calls `AutomationManager.cancelActiveAutomation()`.
- Cancel performs the same Step-4 work as a normal stop: switch to `parameters.fallbackChargingMode`, end Live Activity, post a notification ("Automation cancelled — switched to *Solar only*. Approx. *X.X* kWh transferred so far.").
- Cancel must be reachable even if the active automation task is currently mid-run (use a Task cancellation flag checked at the top of each iteration).

### "AI" visual treatment

Per backlog: gradient effects in purple / pink / blue.

- Reuse the existing app design language (`Shared/Components`, `applyLiquidGlassTabBar`) but the `AutomationScreen` automation cards get a `LinearGradient(colors: [.purple, .pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.85)` background, with a subtle animated shimmer when an automation is *running* (use `.phaseAnimator` or `TimelineView` for a slow gradient shift).
- Use the SF Symbol `"wand.and.stars"` for the tab and `"sparkles"` accents on running cards.
- Keep contrast / accessibility: all text on the gradient is white with a small material backdrop where needed.

### Files to add

```
Solar Lens iOS/
└── Automation/
    ├── AutomationScreen.swift
    ├── AutomationSetupSheet.swift
    ├── BatteryToCarCard.swift
    ├── BatteryToCarRunningCard.swift
    └── Components/
        ├── AICardBackground.swift          // gradient + shimmer
        └── AmperageRamp.swift              // pure tuning function (testable)
```

### Files to change

```
Solar Lens iOS/Automations/Runner/Tasks/AutomationBatteryToCar.swift
  (cherry-picked + renamed from ScenarioBatteryToCar.swift)
  - Rewrite run() per the flow above
  - Add fallbackChargingMode to AutomationBatteryToCarParameters
  - Add lastTickAt, kWhAccumulator, currentAmps, lastGridImportTickCount
    to AutomationBatteryToCarState
  - Implement the tuning rule via AmperageRamp.compute(...)

Solar Lens iOS/Automations/Runner/AutomationManager.swift
  (cherry-picked + renamed from ScenarioManager.swift)
  - Lower foregroundTimerInterval from 5 to 60 seconds
  - Add cancelActiveAutomation()
  - Persist activeState + activeTaskParameters to UserDefaults on
    every transition, restore on init
  - Wire Live Activity start/update/end into start / runActiveAutomation /
    terminateAutomation
  - Wire local-notification post into terminateAutomation

Solar Lens iOS/ContentView.swift
  - Add Tab("Automation", systemImage: "wand.and.stars") { AutomationScreen() }

Solar Lens iOS/Solar_Lens_iOSApp.swift
  - Call AutomationManager.shared.registerBackgroundTask() on init
  - Wire .onChange(of: scenePhase) → AutomationManager.handleScenePhaseChange

Solar Lens iOS Info.plist (or build settings INFOPLIST_KEY_*):
  - UIBackgroundModes: fetch, processing
  - BGTaskSchedulerPermittedIdentifiers (com.marcduerst.SolarManagerWatch.AutomationRunner)
  - NSSupportsLiveActivities

Localizable.xcstrings
  - All new user-facing strings (DE / EN / FR / IT / DA — use /translate)
  - Audit any existing strings cherry-picked from the WIP branch that contain
    "Scenario" / "Szenario" / etc. and re-key them under "Automation"
```

### Live Activity

A minimal `ActivityAttributes`:

```swift
struct BatteryToCarAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable {
        var batterySoc: Int
        var stationPowerW: Int
        var kWhTransferred: Double
        var currentAmps: Int
        var status: AutomationStatus
    }

    var stationName: String
    var floorSoc: Int
}
```

`AutomationManager` owns the `Activity<BatteryToCarAttributes>?` reference and updates `ContentState` after each successful tick.

Lock-screen layout: name, current SoC (with a thin gradient ring filling toward the floor), charging station W, kWh transferred, Cancel button.
Dynamic Island compact: SoC%, ⚡power. Expanded: full layout with Cancel.

### Why not just one of these alternatives?

| Alternative | Why not |
|---|---|
| Server cron + APNs | Explicitly excluded by backlog. |
| Use only foreground timer | User can't keep the app open for hours. |
| Use only `BGAppRefreshTask` | OS gives no frequency guarantees → user sees a stale UI for minutes. Live Activity is what makes BG palatable. |
| Use Always-on Location | Privacy-hostile, App Review risk for an unrelated capability. |
| Use Background Audio | Same — App Review will reject. |
| Run inside an iOS Shortcut / App Intent on a schedule | Requires user to set up Personal Automation, fragile, no in-app control. |

## Expected Result

- A new "Automation" tab is visible in the iOS app between "Now" and "Statistics".
- Tapping the "Transfer from Battery to Car" card opens a setup sheet asking for charging station, battery floor (%), and post-run charging mode (default "Solar only").
- "Start" sets the charging station to *Constant current* at an amperage matched to the battery's max discharge power, starts a Live Activity, and begins monitoring.
- Every ~60 s while the app is foregrounded (and opportunistically in the background) the amperage is re-tuned: ramped down on grid import, ramped up while the battery has headroom. All of this is visible in the Live Activity and in the running card.
- The run stops *predictively* when the battery is about to cross the soft floor (so it normally stays above the user's chosen %; in the worst-case background-throttling scenario it may dip a few % below), when grid import becomes unavoidable for two consecutive ticks at 6 A, or when the user taps Cancel.
- On stop, the charging station is switched to the user-selected fallback charging mode, the Live Activity ends, and a local notification summarises "Charged ~X.X kWh from battery (Y% → Z%). Switched to *fallback*."
- While an automation is running, no other automation can be started; the UI reflects that.
- No code path in this story talks to any backend other than the existing Solar Manager Cloud API.

## Test Checklist
- [x] App builds successfully
- [x] App runs correctly on iOS Simulator (and on watchOS Simulator — watchOS is unaffected by this change)
- [x] Automation tab is visible only on iOS (watchOS / tvOS unchanged)
- [ ] /specs have been updated if necessary
- [ ] If architectural decisions were made, an ADR was created in /specs/adrs (likely needed: "On-device-only automation runner")
- [ ] Story status has been set to "Done (DD.MM.YYYY)"
- [ ] Story file has been moved to /specs/stories/done/
- [ ] Story has been removed from the backlog

## Tasks

### Plumbing (do first — without these the runner is dead code)
- [x] Cherry-pick the `Solar Lens iOS/Scenarios/` tree from branch `79-add-scenario-charge-car-from-battery-only` and rename per the table above (folder → `Automations/`, all `Scenario*` types → `Automation*`, BG task id → `...AutomationRunner`)
- [x] Drop `ScenarioOneTimeTariff*` and the existing broken `ScenarioBatteryToCar.swift` while cherry-picking
- [x] Add `UIBackgroundModes`, `BGTaskSchedulerPermittedIdentifiers` (= `com.marcduerst.SolarManagerWatch.AutomationRunner`), `NSSupportsLiveActivities` to the iOS target Info.plist / build settings
- [x] Call `AutomationManager.shared.registerBackgroundTask()` from `Solar_Lens_iOSApp.init`
- [x] Wire `.onChange(of: scenePhase)` to `AutomationManager.handleScenePhaseChange`
- [x] Persist `activeState` + `activeTaskParameters` to `UserDefaults` (`SolarLens.activeAutomationState`) and restore on launch
- [x] Lower `foregroundTimerInterval` from 5 s to 60 s

### Tab + UI shell
- [x] Add `AutomationScreen.swift` and the `Automation` tab in `ContentView` (badge shows pulsing rocket icon while running)
- [x] `BatteryToCarCard` (idle) and `BatteryToCarRunningCard` (live state + Cancel)
- [x] `AutomationSetupSheet` with station picker, floor slider (5%-(SoC-1)%), fallback-mode picker (default `.withSolarPower`); whole sheet hides controls when battery too low and explains required level
- [x] Disable other automation cards while one is active (no-op today, future-proofing)
- [x] AI-style gradient + shimmer (`AICardBorder` rotating angular gradient stroke + `AICardGlow` blurred halo)
- [x] Automation log viewer with live updates, search, filter pills with dynamic counts, context-aware Copy/Share menu

### Automation task rewrite
- [x] Rewrite `AutomationBatteryToCar.run` per the flow described above (refactored top-down with extracted methods + private `Telemetry` struct)
- [x] Implement `AmperageRamp.compute(...)` as a pure, unit-testable function (asymmetric controller: ramp down on import > graceW, hold in band, ramp up on export, ramp up when battery is charging — PV surplus is the goal of Battery → Car, ramp up with battery headroom margin)
- [x] Implement `convertPowerToAmps` with 1- and 3-phase support at 230 V / 400 V (default 3-phase — covers CH/DE/AT/DK domestic installs)
- [x] Phase setting per charging station, persisted via `Charging stationPhasesStore` (UserDefaults per charging station ID); supports auto-switching charging stations (`Charging stationPhases.auto` uses observed W/A clamped 180–760)
- [x] Add `fallbackChargingMode` to `AutomationBatteryToCarParameters`
- [x] Extend `AutomationBatteryToCarState` with `currentAmps`, `kWhAccumulator`, `lastTickAt`, `gridImportStreak`, `startSoc`, `smoothedTickIntervalMinutes`, signed `batteryChargeRateW`
- [x] Implement `SoftFloor.computeSafetyBuffer(...)` as a pure, unit-testable function (drain rate × smoothed tick interval × safety factor, clamped 1–8 %)
- [x] Stop conditions: predictive soft-floor reached (`battery − safetyBuffer ≤ floor`) OR `gridImportStreak ≥ 2` at 6 A
- [x] Update setup-sheet copy: floor slider labelled "Don't go below (if possible)"; dynamic threshold message; refuse-to-start state when battery too low
- [x] On stop: switch to `fallbackChargingMode`, schedule local notification (Live Activity end deferred — see below)
- [x] Initial amps start at `PowerToAmps.minAmps` (6A) instead of battery max — avoids overshoot from house load on first tick

### Live Activity (DEFERRED — entitlements declared, implementation postponed)
- [ ] Define `BatteryToCarAttributes`
- [ ] Lock-screen and Dynamic Island layouts (compact + expanded) with Cancel button
- [ ] `AutomationManager` starts/updates/ends the Activity in lock-step with the task

> `NSSupportsLiveActivities = true` is set in Info.plist so the entitlement is in
> place, but the actual `ActivityKit` integration is deferred to a follow-up
> story. The tab badge with pulsing rocket icon currently substitutes as the
> "automation is running" indicator.

### Local notifications
- [x] Request notification authorization the first time "Start Automation" is tapped (not at launch)
- [x] Post finished / cancelled / capped notifications via `UNUserNotificationCenter`

### Cancel
- [x] `AutomationManager.cancelActiveAutomation()` performs the full stop sequence (fallback mode, notification)
- [x] Cancel button on the running card
- [ ] Cancel button in the Live Activity (App Intent) — deferred with Live Activity

### Robustness
- [x] Network errors during a tick: keep `currentAmps`, schedule next run, log warning. Three consecutive failed ticks → stop with `failed` status and notify "Automation stopped due to connection error".
- [x] If overview returns no battery devices: refuse to start with explanatory error.
- [x] If the chosen station disappears between ticks (e.g. user removed it): stop with `failed`.
- [x] Multiple-battery installations: sum `maxDischargePower` across batteries.

### i18n & polish
- [x] All new strings localised in `Localizable.xcstrings` (DE / DA / FR / IT via /translate)
- [x] Onboarding hint in the setup sheet about iOS background limits
- [x] Empty-state for "no charging stations" (offer link to Solar Manager docs)

### Testing
- [ ] Unit tests for `AmperageRamp.compute(...)` covering: ramp up, ramp down, dead-band, clamp at 6 A, clamp at 32 A, battery-charging-as-surplus branch
- [ ] Unit tests for `convertPowerToAmps` (1-phase, 3-phase, edge values)
- [ ] Unit tests for `SoftFloor.computeSafetyBuffer(...)` covering: foreground tick (≈1%), mild BG gap (≈4%), long BG gap (clamped at 8%), tiny discharge (clamped at 1%), zero/negative discharge (returns minBufferPct)
- [ ] Integration test using `FakeEnergyManager` simulating PV + load curves over a synthetic hour
- [x] Manual test: start automation, background the app — state is coherent on return (Live Activity check skipped — feature deferred)
- [x] Manual test: kill the app while running → relaunch → state restored from `UserDefaults`
- [ ] Manual test: cancel from Live Activity (Lock Screen) — deferred with Live Activity
- [x] Field test: real-world test on CH installation surfaced the "battery charging while balanced grid" gap (controller stuck at 6 A while PV was charging the battery); fixed by adding the chargingW > 0 → ramp-up branch in `AmperageRamp.compute`. Further field testing for 200 W grace band tuning still open.

## Implementation notes / deviations from original spec

- **Live Activity deferred.** Entitlement is in place but `ActivityKit` integration was postponed; the tab badge with pulsing rocket icon is the running indicator instead.
- **AI visual treatment** lands as `AICardBorder` (rotating angular gradient stroke via `TimelineView`) + `AICardGlow` (blurred halo), not the `AICardBackground` shimmer originally sketched. Outcome matches the gradient/AI feel from the backlog.
- **Phase setting** is per-charging station (not per-station as a global) and persisted via `Charging stationPhasesStore`. Adds a third option `auto` for charging stations that switch between 1-/3-phase, with live-observed W/A clamped 180–760 W.
- **Floor slider range** is dynamic: `5 ... max(minFloorPct + 1, currentSoC − 1)`. When the battery is too low to start, the whole control set hides and the sheet displays the minimum SoC required.
- **Grace band** stays at 200 W (`AmperageRamp.defaultGraceW`), validated only by initial CH testing. Heat-pump field validation still pending.
- **`run()` refactored** top-down with extracted helpers (`fetchTelemetry`, `updateTickMetrics`, `accumulateTransferredKWh`, `shouldStopOnSoftFloor`, `updateGridCapStreakAndShouldStop`, `retuneAmperage`) and a private `Telemetry` struct that bundles per-tick data (incl. signed `batteryChargeRateW`).
- **Initial amps** start at `PowerToAmps.minAmps` (6 A), not battery max — avoids overshoot from concurrent house load on the first tick.
- **Class is `@MainActor @Observable`** to ensure SwiftUI live updates from background `Task`s.

## Remaining work to mark Done
1. Ship `BatteryToCarAttributes` Live Activity (separate story candidate).
2. Author unit tests for `AmperageRamp`, `PowerToAmps`, `SoftFloor`.
3. Field-validate the 200 W grace band on a heat-pump household.
4. Move story to `done/`, update backlog, set `Status: Done (DD.MM.YYYY)`.
