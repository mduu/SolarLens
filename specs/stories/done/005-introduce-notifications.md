# Story: #5, Introduce "Notifications"

**Status:** Done (2026-06-07) — pending verification on hardware

## Short Description

Separate the **read-only "Notify on battery level"** monitor from the **controlling automations** (e.g. "Transfer from Battery to Car") into a dedicated **"Notifications"** feature. Add a new top-level **"Notifications"** tab (bell / paper-plane icon) on iOS and a matching screen on watchOS that lists the available notifications. Unlike automations, notifications are read-only and **multiple may run in parallel** (and in parallel with a controlling automation). Expand the catalogue beyond battery level to cover solar production, grid export/import, overall consumption and charging throughput thresholds.

## Additional Information

### Why this story

We recently shipped **Automations** (story #3) with three members of the `Automation` enum: `BatteryToCar`, `AutoResetChargingMode` and `NotifyOnBatteryLevel`. The first two **control** the system (they change charging modes / power). `NotifyOnBatteryLevel` is fundamentally different: it is a **read-only monitor** that only watches a value and fires a local notification when a threshold is crossed. Mixing it into the automation runner forces two semantic problems:

1. **Single-active constraint.** `AutomationManager` enforces *one active automation at a time* (`startAutomation()` blocks when `activeState != nil`). That is correct for controlling automations (you cannot run two charging strategies on the same station), but wrong for notifications: a user legitimately wants to watch *battery < 20 %* **and** *grid import > 3 kW* **while** "Transfer from Battery to Car" is running.
2. **Conceptual clarity.** A notification is a much simpler object than an automation. It needs only (a) a recheck interval/time and (b) a check predicate. Automations are open-ended workflows that differ wildly from each other. Keeping the simple background checks separate from the advanced controlling workflows keeps both code paths honest.

### Server-free constraint (unchanged)

Like automations, notifications are **pure on-device** — no backend, no APNs, no server cron. This is locked in by [ADR-001 (On-device automation runner)](../adrs/001-on-device-automation-runner.md). The same honesty caveat applies: while foregrounded, checks are precise; while backgrounded we rely on `BGAppRefreshTask` + pre-scheduled (forecast) notifications, and the UI must communicate that checks are best-effort while suspended. See the existing forecast-backstop mechanism in `AutomationNotifyOnBatteryLevel.scheduleThresholdDueNotification()`.

### Current code layout (what we build on)

The automation system is already very modular. Relevant pieces (all under `Solar Lens iOS/Automations/` and `Shared/Services/Automations/` unless noted):

| Concern | File(s) |
|---|---|
| Available-automation enum (Shared, used by widget) | `Shared/Services/Automation.swift` |
| Runner / scheduler singleton | `Solar Lens iOS/Automations/Runner/AutomationManager.swift` |
| Task protocol | `Solar Lens iOS/Automations/Runner/AutomationTask.swift` |
| Battery-level monitor task | `Solar Lens iOS/Automations/Runner/Tasks/AutomationNotifyOnBatteryLevel.swift` |
| State / parameters (discriminated unions, Codable) | `Shared/Services/Automations/AutomationState.swift`, `AutomationParameters.swift`, `AutomationNotifyOnBatteryLevelParameters.swift` |
| Local notification delivery + categories/deep-link | `Solar Lens iOS/Automations/Runner/AutomationNotificationDelegate.swift`, `AutomationManager.postFinishedNotification()` |
| BG refresh task | id `com.marcduerst.SolarManagerWatch.AutomationRunner`, registered in `Solar_Lens_iOSApp` |
| Persistence | `UserDefaults` keys `SolarLens.activeAutomationState` / `SolarLens.activeAutomationParameters` |
| iOS↔watch bridge | `Solar Lens iOS/Automations/AutomationWatchBridge.swift`, `Solar Lens Watch App/Automations/AutomationWatchSession.swift`, `AutomationStateStore.swift`, `Shared/Services/Automations/AutomationWatchSnapshot.swift` |
| iOS tab nav | `Solar Lens iOS/ContentView.swift`, `TabSelection.swift` |
| watchOS automations screen | `Solar Lens Watch App/Automations/AutomationsScreen.swift` |

### Restructuring proposal

The backlog explicitly asks for a recommendation on *whether* and *how* to restructure. Recommendation: **extract a separate, lightweight Notification subsystem rather than tagging notifications as "read-only automations".** Reasoning:

- The single-active constraint is baked into `AutomationManager` and the single `activeState` / `activeTaskParameters` slot. Retro-fitting parallel-run semantics into that singleton (to allow N notifications + 1 automation) is more invasive and risky than giving notifications their own manager that holds an **array** of active monitors.
- A notification's contract is genuinely just *(recheck interval/time, check predicate, threshold)*. A dedicated `NotificationMonitor` protocol (returning `fired` / `notYet` / `expired`) is far simpler than the open-ended `AutomationTask` workflow contract and won't accrete automation-specific concerns.
- We still **reuse**, not duplicate, the cross-cutting infrastructure: the `UNUserNotificationCenter` delivery + `AutomationNotificationDelegate` category/deep-link plumbing, the `BGAppRefreshTask` scheduling pattern, the forecast-backstop trick, and the watch-bridge snapshot pattern. These are extracted/shared, not copied.

Concrete shape:

- **New enum** `Notification` (Shared) listing available notification types (so a future Live Activity / widget can reference it), mirroring how `Automation` lives in Shared.
- **New manager** `NotificationManager` (`@Observable @MainActor` singleton) holding `activeMonitors: [NotificationMonitorState]` (array, parallel runs allowed). Owns its own `UserDefaults` keys (`SolarLens.activeNotifications…`) and its own `BGAppRefreshTask` id (`…AutomationRunner` stays for automations; add `…NotificationRunner`, **or** share one BG task that drives both managers — decide during implementation; sharing one BG wake is preferable for iOS budget). Each monitor carries its own `nextCheckAt` so the 60 s foreground timer / BG wake ticks each due monitor.
- **New protocol** `NotificationMonitor` with `check(host:, parameters:, state:) async -> NotificationMonitorState` and a per-type config (threshold value, comparison `.equalOrAbove`/`.equalOrBelow`, recheck interval). Migrate the existing `AutomationNotifyOnBatteryLevel` logic into `NotificationBatteryLevel` largely as-is (it is already a pure read-only monitor with forecast backstop).
- **Shared notification delivery** helper extracted from `AutomationManager.postFinishedNotification()` / `AutomationNotificationDelegate` so both managers post notifications and register categories through one path.
- **Migration:** remove `NotifyOnBatteryLevel` from the `Automation` enum and migrate any persisted active "notify on battery" automation into the new notifications store on first launch (one-shot migration so existing users don't lose a running monitor; if migration is judged not worth it, at minimum fail gracefully and drop the stale automation state). Capture the decision in an ADR.

> If implementation discovers the extraction is disproportionately expensive, the fallback is to keep notifications inside the automation runner but lift the single-active constraint to "one controlling automation + N read-only monitors". Prefer the clean extraction; document the choice in an ADR either way.

### Repeat behaviour (per notification)

Each enabled notification has a **"repeat"** option:

- **Notify once** *(default — matches today's behaviour)*: fire when the threshold is first crossed, then the monitor ends.
- **Notify every time it re-occurs**: fire when the threshold is crossed, then **re-arm** once the condition has clearly become unmet, and fire again on the next crossing. The monitor keeps running until the user disables it.

The re-arm logic must avoid notification spam when a value flaps around the threshold (e.g. battery oscillating 19 / 20 / 19 / 20 %, or grid import briefly dipping below 3 kW between fridge compressor cycles). Use **hysteresis** rather than re-arming on the very next sample:

- After firing, the monitor enters a **`firedWaitingForReset`** state.
- Re-arm (back to `armed`) only after the value has been on the **opposite side** of the threshold by at least a deadband margin for at least a minimum dwell time. Suggested defaults: deadband = a small percentage of the threshold (e.g. ~5 % for percentage thresholds, ~5–10 % of value for kW thresholds, with sensible minimums) and dwell ≥ one recheck interval. Tune per metric during implementation.
- Persist the re-arm state across app launches / BG ticks (it lives in the per-monitor state, same store as the rest of the monitor state).
- Each fire creates a fresh local notification (new request id) — do not silently replace the previous one.
- The pre-scheduled "forecast" notification (carried over from `AutomationNotifyOnBatteryLevel`) only makes sense while the monitor is `armed`; cancel any pending forecast notification when entering `firedWaitingForReset`.

UX:
- The setup sheet exposes a toggle ("Notify once" / "Notify every time it re-occurs"). Default is **Notify once** to preserve today's behaviour.
- The notifications list shows each monitor's repeat mode and, when in `firedWaitingForReset`, an unobtrusive indicator (e.g. "Waiting to re-arm") so the user understands why no new notification fires while the value lingers past the threshold.

### Notification catalogue

Re-home the existing battery-level notification and add the following. All take a user-selected threshold, an above/below comparison, and the repeat option above, mirroring the battery-level UX.

- **Battery level** above/below (%) — *(migrated from the current automation)*
- **Solar production** above/below (kW)
- **Grid export** above/below (kW)
- **Grid import** above/below (kW)
- **Overall consumption** above/below (kW)
- **Charging throughput** above/below (kW)
- **TBD (out of scope for v1, note in backlog):** Smart plug (user selects a plug) switched on/off — different shape (boolean state, plug selection); defer unless cheap.

Verify each metric is available from the existing telemetry / SolarManager API used by the home views before committing it to the catalogue (see `specs/solarmanager_api.md`). Drop or defer any metric that isn't reliably pollable on-device.

### iOS UI

- Add a new top-level **"Notifications"** tab to the `TabView` in `ContentView.swift`, using a bell or paper-plane SF Symbol (e.g. `bell.badge` / `paperplane`). Extend the tab enum in `TabSelection.swift` and add a `solarlens://notifications` deep-link host.
- The tab lists the available notification types (with their current enabled/running state), each opening a setup sheet (reuse the form pattern from `NotifyOnBatteryLevelSetupSheet`). Multiple may be enabled simultaneously.
- Decide tab gating: notification types should only be offered when the underlying metric is meaningful (e.g. grid export/import always; charging throughput only with a charging station; battery only with a battery) — reuse the prerequisite checks already used to gate the Automation tab.

### watchOS UI

- Mirror the change on watchOS: surface notifications (separate from `AutomationsScreen`) and extend the watch bridge so notification state is part of the snapshot (`AutomationWatchSnapshot` → add notifications, bump `schemaVersion`) and start/cancel commands flow back to iPhone like automation commands do. Keep the watch decoupled-store pattern (`AutomationStateStore`-style observable).

## Expected Result

- A new "Notifications" tab on iOS (bell/paper-plane) listing notification types; multiple can run in parallel, including alongside a running automation.
- "Notify on battery level" no longer appears under Automations; it lives under Notifications with identical behaviour.
- New notification types (solar production, grid export, grid import, overall consumption, charging throughput) work with user-selected thresholds and above/below comparison and fire on-device local notifications.
- Each notification supports **"notify once"** (default) and **"notify every time it re-occurs"** with hysteresis-based re-arming that does not spam when the value flaps around the threshold.
- watchOS reflects the same notifications and can start/cancel them.
- Read-only notifications and controlling automations run independently without interfering.
- Architecture decision (extract vs. relax constraint, BG-task sharing, migration of existing users) recorded in an ADR.

## Test Checklist
- [x] App builds successfully
- [x] App runs correctly on watchOS Simulator
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [x] Battery-level notification migrated; existing users with an active "notify on battery" do not lose it (or graceful drop documented)
- [x] Multiple notifications run in parallel, and in parallel with a controlling automation
- [x] Each new notification type fires correctly above/below its threshold
- [x] "Notify once" stops after the first fire; "Notify every time it re-occurs" re-arms after the value clearly leaves the threshold (deadband + dwell) and fires again; flapping values do not spam notifications
- [x] iOS "Notifications" tab + `solarlens://notifications` deep link work; notification taps route correctly
- [x] watchOS notifications screen + start/cancel via watch bridge work (snapshot schemaVersion bumped)
- [x] /specs have been updated if necessary
- [x] If architectural decisions were made, an ADR was created in /specs/adrs
- [x] Story status has been set to "Done (DD.MM.YYYY)"
- [x] Story file has been moved to /specs/stories/done/
- [x] Story has been removed from the backlog

## Tasks

- [x] Decide & ADR: extract `NotificationManager` vs. relax automation single-active constraint; BG-task sharing; user migration strategy
- [x] Add `Notification` enum (Shared) and `NotificationMonitor` protocol + per-type config/state (Codable), including `repeat` option (`once` / `everyReoccurrence`) and re-arm state (`armed` / `firedWaitingForReset`) with hysteresis (deadband + dwell)
- [x] Implement `NotificationManager` (parallel `activeMonitors`, persistence, foreground timer + BG refresh, forecast backstop)
- [x] Extract shared local-notification delivery + category/deep-link helper from automation code
- [x] Migrate `NotifyOnBatteryLevel` out of the `Automation` enum into `NotificationBatteryLevel`; add one-shot migration of persisted state
- [x] Implement new monitors: solar production, grid export, grid import, overall consumption, charging throughput (verify each metric is pollable)
- [x] iOS: add "Notifications" tab, deep link, list view, and setup sheets (reuse form pattern); gate types by prerequisites
- [x] watchOS: notifications screen + extend `AutomationWatchSnapshot` (bump schemaVersion) + start/cancel command flow
- [x] Note "Smart plug on/off" as a deferred follow-up in the backlog
- [x] Update /specs (architecture, userinterface) as needed
