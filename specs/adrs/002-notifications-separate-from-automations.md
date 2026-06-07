# ADR-002: Separate "Notifications" subsystem from "Automations"

## Status

**Accepted**

## Context

Solar Lens shipped an **Automations** feature (story #3) with three members in the `Automation` enum: `BatteryToCar`, `AutoResetChargingMode`, `NotifyOnBatteryLevel`. The first two **control** the system; the third is a **read-only monitor** that polls a value and posts a local notification when a threshold is crossed.

`AutomationManager` enforces *one active automation at a time* (`activeState != nil` blocks new starts). That is correct for controlling automations — two charging strategies on the same charging station would fight each other — but wrong for monitors:

- A user legitimately wants to run *battery ≤ 20 %* **and** *grid import ≥ 3 kW* **while** "Transfer from Battery to Car" is running.
- Story #5 expands the monitor catalogue from one (battery level) to six (battery, solar production, grid export, grid import, overall consumption, charging throughput) — five new metric checks, each parallel-runnable.

A monitor's contract is also far simpler than an automation's: only a recheck cadence and a check predicate. Automations are open-ended workflows. Mixing both into one runner has already started leaking automation-specific concerns (`mapStopReason` switching on `notifyOnBatteryLevel`, per-automation `populateNotifyOnBatteryLevel` notification builder in `AutomationManager`) and would worsen as monitors multiply.

Constraints in force:
- **Server-free** per [ADR-001](./001-on-device-automation-runner.md). No APNs / server cron / cloud function. All scheduling and delivery on-device.
- **iOS BG runtime budget** is shared across the whole app — running two BG refresh tasks (automation + notifications) burns budget faster than running one.
- **Persisted state compatibility**: existing TestFlight users may have an active "Notify on battery level" automation in `UserDefaults`. Decoding a future `Automation` enum without that case fails silently, which would drop their running monitor.

## Decision

We decided on **Option A: Extract a separate `NotificationManager` subsystem alongside `AutomationManager`**, with:

1. **Parallel runs**: `NotificationManager.shared.activeMonitors: [NotificationMonitor]` (array, not single slot). Each monitor carries its own `nextCheckAt` so the foreground timer and BG wake tick each due monitor independently.
2. **Shared BG task identifier**: the existing `com.marcduerst.SolarManagerWatch.AutomationRunner` BGAppRefreshTask wakes BOTH managers in one budget allocation. No second `…NotificationRunner` identifier — iOS treats per-identifier budgets independently and we don't want to halve our wake-up budget.
3. **Shared local-notification delivery**: `AutomationNotificationDelegate` (UNUserNotificationCenter delegate + category registration + deep-link routing) is reused by both subsystems. The delegate already routes any `solarlens://…` deep-link, so the notifications subsystem just posts requests with the appropriate userInfo.
4. **One-shot persisted-state migration**: at app launch, before either manager restores state, a `NotificationMigration` pass reads the legacy `SolarLens.activeAutomationState` / `SolarLens.activeAutomationParameters` keys, detects a `NotifyOnBatteryLevel` automation (by parsing the raw JSON, not the typed `AutomationState`), translates it into a `NotificationMonitor` and writes it into the notifications store. The legacy keys are then cleared so the now-modified `Automation` enum decodes cleanly. Failure to migrate (corrupted data, schema drift) silently drops the legacy state — the user loses the running monitor but the app continues to launch.
5. **Live Activity is not provided for notifications in v1.** The Battery-Level monitor's existing `NotifyOnBatteryLevelPayload` and `AutomationNotifyOnBatteryLevel+LiveActivity.swift` are deleted along with the `Automation.NotifyOnBatteryLevel` case. The LA was useful for the long-running, evolving automation visualization; notifications are point-in-time threshold alerts where the pre-scheduled forecast-backstop notification covers the imminent-fire UX. Add later if user demand justifies the per-payload widget code.

The fallback option (relax the single-active constraint inside `AutomationManager`) is documented below for completeness; we did not take it.

## Options

### Option A: Extract a separate `NotificationManager` *(chosen)*

**Description:** New `@Observable @MainActor` singleton with an array of active monitors. Shares BG-task identifier and notification-delivery delegate with `AutomationManager`; otherwise independent (own protocol `NotificationMonitor`, own UserDefaults keys, own watch-bridge surface).

**Pros:**
- The array model is the natural fit for parallel monitors; no contortion of the single-slot automation runner.
- `NotificationMonitor` protocol is just `check(host:, monitor:) async -> NotificationMonitor` — far simpler than `AutomationTask`. New monitor kinds (solar production, grid kW, …) implement a one-screen function; the manager handles cadence, hysteresis, persistence, delivery.
- Removes monitor-specific code paths from `AutomationManager` (`mapStopReason` notifyOnBatteryLevel branch, `populateNotifyOnBatteryLevel`, the `notifyOnBatteryLevel` cancel arm). The automation runner gets simpler, not more complex.
- Story #5's repeat-with-hysteresis behaviour (re-arm after value clearly leaves the threshold, deadband + dwell) belongs to the monitor type contract, not the automation contract; cleaner to live with the new subsystem.

**Cons:**
- More code: a new manager, a new protocol, a new tab, parallel UI patterns.
- One-shot migration is now mandatory for the small population of users with an active battery-level monitor when they upgrade.
- Two managers ticking from one BG wake means the BG handler has to drain both, costing slightly more BG runtime per wake.

### Option B: Relax the single-active constraint inside `AutomationManager`

**Description:** Keep `NotifyOnBatteryLevel` as an `Automation`. Change `AutomationManager` to hold *one controlling automation + N read-only automations*. Add `Automation.isReadOnly` so the start path can decide whether to block.

**Pros:**
- No new manager, no migration. Existing persisted state continues to decode.
- Reuses all of `AutomationManager`'s persistence, BG scheduling, Live Activity coordination.

**Cons:**
- Reuse comes with a cost: `activeState`/`activeTaskParameters`/`mapStopReason`/`postFinishedNotification` all become "for the one controlling automation OR the array of read-only ones," and we'd need parallel storage anyway.
- `Automation.isReadOnly` is the kind of flag that quietly grows special-cases everywhere it's checked (Live Activity coordinator, watch bridge, cancel flow).
- Doesn't solve the problem that monitors are conceptually simpler than automations — the protocol stays the open-ended `AutomationTask` even for what is essentially "poll a number, compare, maybe post."

### Option C: Defer notifications subsystem; keep `NotifyOnBatteryLevel` as-is, do not add new metrics

**Description:** Reject story #5; revisit later.

**Pros:** zero work.

**Cons:** the user-facing pain (can't run battery monitor alongside Battery-to-Car) is exactly what the story is opening; deferring just defers the resolution. Out of scope.

## Consequences

### Positive Impact

- Multiple monitors can run in parallel and can run alongside a controlling automation — the headline user-facing requirement.
- `AutomationManager` becomes a controlling-automations-only runner; its API surface shrinks.
- Adding a new metric to monitor is a small, well-bounded change: a new `SolarLensNotification` case, a `check()` function, a setup-sheet variant. No automation runner changes.
- Repeat-with-hysteresis re-arm logic is encapsulated in `NotificationManager` and reusable across all monitor kinds.

### Negative Impact / Risks

- **Migration risk**: if the legacy JSON shape changes shape unexpectedly between releases, migration drops the running monitor silently. Mitigated by parsing the raw JSON (not the now-changed `AutomationState`) and by logging the drop into the automation log so the user can see what happened.
- **BG wake congestion**: with both managers draining work on each BG wake, individual ticks have less BG runtime. Today's 5-min battery-level cadence already shares with Battery-to-Car's 1-min cadence, so this is incremental, not new.
- **Two persistence stores**: `SolarLens.activeAutomationState` and a new `SolarLens.notifications.monitors` UserDefaults key. Both backed up to iCloud the same way; no functional difference.
- **Live Activity gap**: the migrated battery-level monitor loses its LA / Dynamic Island treatment. The pre-scheduled forecast-backstop notification still fires at the predicted moment, so the user still gets a heads-up on the Lock Screen — just no live countdown. Acceptable for v1.

### Effort

- New code (rough order): NotificationManager + protocol + per-kind monitors (~600 LoC), iOS Notifications tab + 6 setup sheets (~500 LoC), shared types (~150 LoC), watch parity (~300 LoC), migration (~50 LoC), tests/cleanup. Several days of focused work.

## References

- Story: [specs/stories/005-introduce-notifications.md](../stories/005-introduce-notifications.md)
- Prior ADR: [001-on-device-automation-runner.md](./001-on-device-automation-runner.md)
- Backlog entry that fed the story: `specs/backlog.md` "Introduce Notification"
