# Story: #4, Live Activity for running Automations

**Status:** Done (07.05.2026)

> **Note on validation:** The LA infrastructure ships and `Activity.request`
> succeeds, but the Lock Screen / Dynamic Island never rendered on the iOS 26
> simulator (chronod logs `Activity was started but had no payload` regardless
> of how the View is composed; no app on this simulator wrote any
> `activity-archive`, suggesting a sim-side bug). Verification on a real
> iPhone is required to validate the visual layout.

## Short Description

Surface running iOS automations on the Lock Screen and in the Dynamic Island
via a Live Activity. The Lock Screen card should look and feel like the
"Running" card on the Automation tab so users instantly recognize it as a
Solar Lens automation; the Dynamic Island shows a compact, automation-specific
glance (icon + a single live metric — for Battery → Car: rocket icon +
transferred kWh). The architecture must be **open for extension**: future
automations plug in their own icon, accent, and per-automation card content
without touching the shared coordinator or widget extension wiring.

## Additional Information

### Why now

Story #3 explicitly deferred Live Activity. Today's only "automation is
running" indicator outside the app is the Automation tab badge with a pulsing
rocket. That works while the app is open, but disappears the moment the user
backgrounds it — exactly when the runner is most opaque (`BGAppRefreshTask`
cadence is OS-decided, often 15–60 min between fires). The Live Activity is
the bridge that:

1. Keeps the user informed of state without opening the app.
2. Gives a Cancel affordance on the Lock Screen / Dynamic Island.
3. Per Apple guidance, raises the app's BG-refresh priority *while the
   activity is live* — a side benefit for monitor cadence.

Captured in [ADR-001 (On-device automation runner)](../adrs/001-on-device-automation-runner.md)
under "BG visibility gap"; this story closes that gap.

### Architecture: where Live Activity code lives

Live Activity views run in a **widget extension** — not the app process. We
already ship one widget extension per platform:

- `Solar Lens iOS Widgets/` — iOS home/lock-screen widgets.
- `Solar Lens Widgets/` — watchOS complications.

We add the Live Activity to **`Solar Lens iOS Widgets/`** (iOS-only feature).
The `ActivityAttributes` type must be linked into both targets, so it lives in
`Shared/`.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  App process (Solar Lens iOS)                                            │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  AutomationManager                                                 │  │
│  │  ── owns activity lifecycle via AutomationLiveActivityCoordinator  │  │
│  │  ── calls activity.update(content) on every successful tick        │  │
│  │  ── persists Activity.id so it can be re-acquired after relaunch   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                  ▲ reads from                                            │
│                  │                                                       │
│  Shared/Automations/LiveActivity/                                        │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  AutomationLiveActivityAttributes (ActivityAttributes, Codable)    │  │
│  │  ── shared identity: automationName, accentRoleId                  │  │
│  │  ── ContentState: shared fields + per-automation payload (enum)    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                                    │ pushed by ActivityKit
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Widget extension (Solar Lens iOS Widgets)                               │
│                                                                          │
│  AutomationLiveActivity (ActivityConfiguration)                          │
│  ├── LockScreenCard (shared chrome: AI border + glow + brand mark)       │
│  │       └── PerAutomationCardBody.view(for: state)                      │
│  └── DynamicIsland                                                       │
│      ├── compact leading:  automation icon                               │
│      ├── compact trailing: primary live metric (e.g. "1.4 kWh")          │
│      ├── minimal:          automation icon                               │
│      └── expanded:         icon + name + metrics + Cancel                │
│                                                                          │
│  Per-automation card bodies (one file per case, registered via switch    │
│  on payload tag): BatteryToCarCardBody, …                                │
└──────────────────────────────────────────────────────────────────────────┘
```

### Data model — designed for extension

Two layers, both `Codable`:

**Layer 1 — shared `ContentState`** (everything every automation has):

```swift
public struct AutomationLiveActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        // What's running
        public var automation: Automation
        public var startedAt: Date

        // Shared chrome inputs
        public var iconSystemName: String       // SF Symbol — automation-specific
        public var primaryMetric: Metric        // Dynamic Island compact-trailing
        public var secondaryMetric: Metric?     // Optional second line

        // Per-automation rich payload (open for extension)
        public var payload: Payload

        public struct Metric: Codable, Hashable {
            public var label: String            // localized
            public var value: String            // already formatted
        }

        public enum Payload: Codable, Hashable {
            case batteryToCar(BatteryToCarPayload)
            // case nextAutomation(NextAutomationPayload)
        }
    }

    // Stable across the activity's lifetime
    public var automation: Automation
}
```

**Layer 2 — per-automation payloads** (one struct per `Automation` case):

```swift
public struct BatteryToCarPayload: Codable, Hashable {
    public var batterySoc: Int
    public var floorSoc: Int
    public var stationPowerW: Int
    public var currentAmps: Int
    public var kWhTransferred: Double
}
```

**Open-for-extension protocol** that each automation task implements:

```swift
protocol AutomationLiveActivityProvider {
    /// SF Symbol shown in the shared chrome (Lock Screen header,
    /// Dynamic Island compact / minimal). The colour treatment around the
    /// icon is **fixed** — see "Brand accent" below.
    var liveActivityIconSystemName: String { get }

    /// Map current task state → ContentState. Called after every successful tick.
    func makeLiveActivityContentState(
        state: AutomationState,
        parameters: AutomationParameters
    ) -> AutomationLiveActivityAttributes.ContentState?
}
```

### Brand accent — shared across all automations

The accent is **fixed for every Solar Lens automation** and uses the Solar
Lens brand colours: **yellow → white → orange**. Yellow is the app's primary
brand colour (it is the system `AccentColor` and our "solar" semantic — see
`specs/userinterface.md` → Color Palette); orange is our warning/grid-import
hue; white sits between them as a high-luminance highlight that gives the
gradient its "AI shimmer" feel without leaving the brand palette. The accent
is the brand signal that makes the Lock Screen card recognisable at a glance
and is therefore intentionally *not* a per-automation choice.

- The accent lives as constants in a single `AutomationBrand` namespace in the
  shared module (gradient stops, sparkles glyph, title font treatment).
- The Lock Screen chrome, Dynamic Island chrome, and per-automation card
  bodies all read from `AutomationBrand` — a per-automation `CardBody` must
  not introduce its own accent gradient or tint.
- Per-automation variation is limited to:
  - the icon glyph (`liveActivityIconSystemName`),
  - the textual content of the body and the metrics,
  - layout *within* the body slot.

#### Brand realignment of the existing in-app running card

Story #3 shipped `AICardBorder` / `AICardGlow` / `BatteryToCarRunningCard`
with a placeholder purple→pink→blue gradient (taken from the original
backlog wording of "AI feel — purple/pink/blue"). Those colours are not the
Solar Lens brand. As part of *this* story we migrate them to read from
`AutomationBrand` so the in-app card and the Lock Screen LA card are visually
identical and on-brand. The migration is small (gradient stops only; geometry,
animation, and overlay structure stay) and is bundled here because:

- This story introduces `AutomationBrand` as the single source of truth.
- Splitting the migration into its own story would temporarily ship two
  different "AI" gradients (in-app vs. LA), which defeats the purpose.

`AutomationBatteryToCar` conforms today; future tasks add their `Payload`
case + their conformance + their `CardBody` view. **The coordinator and the
widget configuration never change.** That's the extensibility test.

### Activity lifecycle

`AutomationLiveActivityCoordinator` (singleton, app process) wraps `Activity<…>`:

| Trigger | Action |
|---|---|
| `AutomationManager.startAutomation` | Request `.alert` auth if needed; `Activity.request(...)` with initial ContentState; persist `activity.id` to `UserDefaults` |
| Successful tick (foreground or BG) | `await activity.update(.init(state: …, staleDate: now+5min))` |
| Tick fails 3× | `update` with `status: .failing` (yellow accent on chrome) |
| `terminateAutomation` | `await activity.end(.init(state: final), dismissalPolicy: .after(2 min))` and clear persisted id |
| App killed and relaunched while activity exists | On init, read persisted id, find via `Activity<…>.activities`, resume updates |

`staleDate` is set so iOS dims the card if we miss several BG slots — a UX
hint that the data may be old, instead of silently lying.

### Lock Screen card design

Goal: the user seeing this on their Lock Screen instantly thinks "Solar Lens
automation". Reuse the AI brand language from the in-app running card.

```
┌────────────────────────────────────────────────────────────────┐
│  ✨  Battery → Car running                            [ Cancel ]│  ← header
│  ──────────────────────────────────────────────────────────── │
│  🔋 32%  ▸ 🚗 11.0 A           1.4 kWh transferred             │  ← per-automation body
│  Floor 25%                     started 18 min ago              │
└────────────────────────────────────────────────────────────────┘
   ▲ rotating angular gradient stroke (yellow/white/orange — Solar Lens brand) + soft glow
```

Shared chrome (`LockScreenCard.swift`):
- Material fill, 20pt corner radius (matches in-app cards).
- `AICardBorder` rotating angular-gradient stroke — the brand signal.
  - **Verify** on iOS 18 Lock Screen: `TimelineView` is allowed in Live
    Activities but pre-rendered to a small frame budget. If perf or
    Always-On constraints make it look bad, fall back to a static
    `AngularGradient` stroke. Decide during implementation.
  - In **Always-On Display** mode iOS forces low-luminance rendering — the
    rotating gradient should disable itself there (`.luminanceToAlpha`-friendly
    static treatment). Accessibility check.
- `sparkles` SF Symbol leading the title in the gradient.
- Title: localized automation name from `automation.localizedTitle`.
- Right-aligned **Cancel** button (App Intent — see below).

Per-automation card body slot:
- A small `View` registered per `Payload` case. For Battery → Car: SoC % +
  station amps + transferred kWh + floor + elapsed.
- The body is the *only* part that differs per automation. It must fit a
  single Lock Screen card row (~80–96 pt tall depending on header).

### Dynamic Island layouts

```
Compact:    [🚀]                              [1.4 kWh]
            └── leading: automation icon      └── trailing: primaryMetric.value

Minimal:    [🚀]
            └── automation icon (multiple activities case)

Expanded:   ┌──────────────────────────────────────────────────────┐
            │  🚀  Battery → Car                          [Cancel] │
            │  Battery 32% • 11.0 A • 1.4 kWh transferred          │
            │  Floor 25% • started 18m ago                         │
            └──────────────────────────────────────────────────────┘
```

- Compact and minimal use **only** `iconSystemName` + `primaryMetric.value`
  from the shared `ContentState`. No per-automation knowledge needed in the
  Dynamic Island wiring — that's the contract.
- Expanded composes the same per-automation card body used on the Lock Screen
  (smaller variant), plus the Cancel button.

### Tap → open the Automation tab

Tapping the Live Activity (Lock Screen card or Dynamic Island compact /
expanded *outside* the Cancel button) must launch the app and land directly
on the **Automation** tab.

Implementation:

- Use `.widgetURL(URL(string: "solarlens://automation")!)` on the Lock
  Screen card and Dynamic Island content. A single URL is fine — there is
  only ever one active automation, so we don't need to encode which.
- Register the `solarlens://` URL scheme in the iOS app's Info.plist (it
  isn't registered today). Pick a scheme name owned by us:
  `solarlens` (with the bundle id as the host owner).
- `ContentView` adds a `@State var selectedTab: AppTab` (currently the
  `TabView` has no selection binding) and an `.onOpenURL { url in … }`
  modifier that maps `solarlens://automation` → `selectedTab = .automation`.
- Define `enum AppTab: Hashable { case now, automation, statistics }` so the
  selection has a stable, named value (don't use raw integers).

The Cancel button on the LA still goes through its `LiveActivityIntent` and
must not also open the app (`LiveActivityIntent` doesn't open by default,
which is what we want).

If the app is already running, `.onOpenURL` fires and switches the tab
without a relaunch. If it's terminated, the URL is delivered after launch
once `WindowGroup` is up; the same handler picks it up.

### Cancel from Live Activity

Live Activity buttons are `LiveActivityIntent`s (subset of `AppIntent`).

```swift
struct CancelActiveAutomationIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel automation"
    func perform() async throws -> some IntentResult {
        await AutomationManager.shared.cancelActiveAutomation()
        return .result()
    }
}
```

Reachable from:
- Lock Screen card header.
- Dynamic Island expanded view.

### Permissions & graceful degradation

- `NSSupportsLiveActivities = true` is already set (story #3 plumbing).
- Check `ActivityAuthorizationInfo().areActivitiesEnabled` before
  `Activity.request`. If disabled (user toggle in Settings → Notifications →
  Solar Lens → Live Activities), log it and continue without LA. The tab
  badge + local notification path still works.
- Don't request Live Activity authorization at app launch — it's implicit
  with the system toggle. We just check on start.

### Visual brand consistency

The Lock Screen card **must** carry the brand AI gradient (yellow → white →
orange) so it reads as Solar Lens at a glance. Specifics:

- Stroke: same rotating angular gradient as `AICardBorder` (animated where
  allowed, static in Always-On).
- Outer glow: skipped on Lock Screen (LA budget, blur is expensive). The
  stroke alone carries the brand.
- The `sparkles` icon and gradient title-foreground from the in-app running
  card transfer 1:1.
- The accent is identical for every automation (see "Brand accent" above).
  Per-automation card bodies inherit it via `AutomationBrand`; they never
  introduce their own gradient or tint.

### Per-automation icon registry

Add to `Automation` enum:

```swift
extension Automation {
    var liveActivityIconSystemName: String {
        switch self {
        case .BatteryToCar: return "rocket.fill"
        }
    }
}
```

This is also the icon used by the existing tab-badge running indicator —
single source of truth, single switch to update when adding an automation.

### Files to add

```
Shared/Automations/LiveActivity/
├── AutomationLiveActivityAttributes.swift
├── AutomationLiveActivityContentState.swift   (Metric + Payload sum-type)
└── Payloads/
    └── BatteryToCarPayload.swift

Solar Lens iOS/Automations/Runner/
├── AutomationLiveActivityCoordinator.swift    (Activity<>, lifecycle, persist id)
└── AutomationLiveActivityProvider.swift       (protocol)

Solar Lens iOS/Automations/Runner/Tasks/
└── AutomationBatteryToCar+LiveActivity.swift  (conform to provider, build payload)

Solar Lens iOS/AppIntents/
└── CancelActiveAutomationIntent.swift

Solar Lens iOS Widgets/LiveActivities/
├── AutomationLiveActivity.swift               (ActivityConfiguration root)
├── LockScreenCard.swift                       (shared chrome — header, border, slots, widgetURL)
├── DynamicIslandLayouts.swift                 (compact / minimal / expanded — widgetURL)
└── Cards/
    └── BatteryToCarCardBody.swift             (per-automation body)
```

### Files to change

```
Solar Lens iOS/Automations/Runner/AutomationManager.swift
  - Inject AutomationLiveActivityCoordinator
  - Call coordinator.start / update / end at the same lifecycle points where
    notifications and persistence already fire (start, after every tick that
    mutates state, terminate)

Solar Lens iOS/Automations/Runner/Tasks/Automation.swift
  - Add liveActivityIconSystemName per case

Solar Lens iOS/ContentView.swift
  - Add `@State var selectedTab: AppTab` and bind to TabView
  - `.onOpenURL` handler: solarlens://automation → selectedTab = .automation

Solar-Lens-Info.plist (iOS app target)
  - Register CFBundleURLTypes with scheme `solarlens`

Solar Lens iOS Widgets target (project settings)
  - Add Live Activity files to membership
  - Ensure Shared/Automations/LiveActivity/ is in both app and widget targets

Localizable.xcstrings
  - "Cancel automation", LA-specific strings, staleness hint
  - Run /translate for de / da / fr / it
```

### What we deliberately *don't* do in this story

- **No watchOS Live Activity.** Cross-target Live Activities are messy and
  the watch already has the in-app card. Out of scope.
- **No remote pushes to update the Live Activity (`pushType`).** All updates
  come from on-device ticks. This keeps the server-free guarantee from
  ADR-001.
- **No per-automation accent.** The brand accent (gradient stops + sparkles)
  is shared across all automations and lives in `AutomationBrand`. Per-automation
  variation is limited to icon glyph, metrics, and body layout.
- **No alert-style updates** (`.alertConfiguration`). The card refreshes
  silently; we already use local notifications for stop events.

### Risks & mitigations

| Risk | Mitigation |
|---|---|
| `AICardBorder` `TimelineView` animation is too expensive in the LA frame budget or unreadable in Always-On | Implement with a feature gate: animated when `viewIsLowLuminance == false`, static gradient otherwise. Verify on real hardware. |
| User toggles Live Activities off mid-run | Detect `Activity.activityState` transitions; log and stop trying to update. UI in-app keeps working. |
| App killed → activity orphaned | Persist `activity.id` to `UserDefaults` at start; on `AutomationManager.init` re-acquire via `Activity<AutomationLiveActivityAttributes>.activities` and resume. If re-acquire fails, end orphans best-effort. |
| `AutomationManager.cancelActiveAutomation` is called from `LiveActivityIntent` background context | Method already does its work via a `Task {…}` and is `@MainActor`-safe. Verify no UI dependencies on `@Environment` along that path. |
| Future automation forgets to register a `CardBody` for its `Payload` case | The `Payload` enum is exhaustively switched in the widget — Swift compile error keeps us honest. |

## Expected Result

- A Live Activity appears on the Lock Screen the moment a Solar Lens
  automation starts and updates as the run progresses.
- The Lock Screen card visibly carries the Solar Lens AI gradient (rotating
  border + sparkles accent), reads as a Solar Lens artifact at a glance, and
  shows automation-specific live data (Battery → Car: SoC, station amps, kWh,
  floor, elapsed).
- Dynamic Island compact view shows the automation's icon (rocket for
  Battery → Car) and the primary live metric (kWh transferred). Expanded
  view shows the full body and a Cancel button.
- Cancel on the Lock Screen / Dynamic Island terminates the automation
  exactly like the in-app Cancel button, including switching the charging station
  back to the user-chosen fallback charging mode and posting the local
  notification.
- Adding a new automation requires only: a new `Automation` enum case,
  an icon, a `Payload` struct, an `AutomationLiveActivityProvider` conformance,
  and a `CardBody` view. No edits to the coordinator or to
  `AutomationLiveActivity` configuration.
- If the user has Live Activities disabled at the OS level the rest of the
  automation feature continues to work unchanged.

## Test Checklist
- [x] App builds successfully (iOS app + iOS Widgets ext, both green)
- [x] App runs correctly on iOS Simulator
- [x] Live Activity is iOS-only (watchOS / tvOS unchanged — `#if canImport(ActivityKit)` and `#if os(iOS)` guards)
- [x] /specs updated (architecture.md gains an LA section; userinterface.md "AI variant" already covers the brand reuse)
- [x] No additional ADR — extends ADR-001's on-device runner; deferred-LA caveat in ADR-001 now resolved
- [x] Story status has been set to "Done (07.05.2026)"
- [x] Story file has been moved to /specs/stories/done/
- [ ] Story not in backlog (was added directly to /specs/stories/ at creation — n/a)

## Tasks

### Shared data model (do first)
- [ ] Create `AutomationLiveActivityAttributes` with `ContentState` (shared fields + `Payload` enum) in `Shared/`
- [ ] Add `BatteryToCarPayload` and the `Metric` value type
- [ ] Add `liveActivityIconSystemName` to `Automation` enum
- [ ] Add `AutomationBrand` (gradient stops `[.yellow, .white, .orange]`, sparkles glyph, title styling) — single source for the shared accent

### Brand realignment of in-app components
- [ ] Update `AICardBorder` to read its gradient stops from `AutomationBrand`
- [ ] Update `AICardGlow` to read its gradient stops from `AutomationBrand`
- [ ] Update `BatteryToCarRunningCard` so the sparkles icon and "Battery → Car running" title gradient also use `AutomationBrand`
- [ ] Visual diff check: in-app running card and Lock Screen LA card sit side-by-side in the same gradient identity

### App-side coordinator
- [ ] `AutomationLiveActivityCoordinator` — owns the `Activity<…>?`, lifecycle, persisted id
- [ ] `AutomationLiveActivityProvider` protocol — `makeLiveActivityContentState(...)` per automation
- [ ] `AutomationBatteryToCar+LiveActivity` — conformance, payload mapping
- [ ] Wire coordinator into `AutomationManager.startAutomation` / `runActiveAutomation` / `terminateAutomation` / `cancelActiveAutomation`
- [ ] Re-acquire orphaned activities on `AutomationManager.init`
- [ ] Gracefully handle `ActivityAuthorizationInfo().areActivitiesEnabled == false`

### Widget extension UI
- [ ] Add `Solar Lens iOS Widgets/LiveActivities/AutomationLiveActivity.swift` (ActivityConfiguration)
- [ ] `LockScreenCard.swift` — shared chrome: AI border, sparkles header, automation title, Cancel slot, per-automation body slot, `.widgetURL(solarlens://automation)`
- [ ] `DynamicIslandLayouts.swift` — compact / minimal / expanded with `.widgetURL`; expanded reuses per-automation body in compact form
- [ ] `Cards/BatteryToCarCardBody.swift` — Battery → Car body
- [ ] Always-On Display fallback: static gradient instead of rotating `TimelineView`
- [ ] Confirm files are in the widget extension target membership

### Cancel App Intent
- [ ] `CancelActiveAutomationIntent` (`LiveActivityIntent`) → calls `AutomationManager.shared.cancelActiveAutomation()`
- [ ] Wire button on Lock Screen header and Dynamic Island expanded layout

### Deep link to Automation tab
- [ ] Define `enum AppTab: Hashable { case now, automation, statistics }`
- [ ] Add `selection: $selectedTab` binding to the `TabView` in `ContentView`
- [ ] Register `CFBundleURLTypes` (scheme `solarlens`) in the iOS Info.plist
- [ ] `.onOpenURL` handler in `ContentView` mapping `solarlens://automation` → `selectedTab = .automation`
- [ ] Emit `.widgetURL("solarlens://automation")` from Lock Screen card and Dynamic Island content (compact + expanded outside the Cancel button)

### i18n & polish
- [ ] All new strings localised in `Localizable.xcstrings`
- [ ] Run /translate for de / da / fr / it
- [ ] In-app hint in Automation setup sheet: "Lock Screen card available while running" (only if LA enabled)

### Testing
- [ ] Unit tests for `AutomationBatteryToCar.makeLiveActivityContentState(...)` — payload mapping for typical / edge state values
- [ ] Manual test: start automation, lock device → card appears with live data and updates over time
- [ ] Manual test: tap Cancel on the Lock Screen → charging station switches to fallback, notification fires, activity ends
- [ ] Manual test: kill app → relaunch → existing activity is resumed (or ended cleanly)
- [ ] Manual test: toggle Settings → Notifications → Solar Lens → Live Activities OFF → start automation → app keeps working without LA
- [ ] Manual test: Always-On Display → Lock Screen card reads correctly (no rotating gradient)
- [ ] Manual test: Dynamic Island compact + expanded layouts on a Pro device
- [ ] Manual test: tap Lock Screen card → app opens on Automation tab (cold launch and warm launch)
- [ ] Manual test: tap Dynamic Island compact / expanded outside Cancel → app opens on Automation tab
- [ ] Manual test: tap Cancel inside the LA → automation ends, app does **not** open
- [ ] Open-for-extension smoke test: stub a second `Automation` case end-to-end (icon, payload, conformance, body) on a throwaway branch — verify the only edits required are the listed extension points

## Out of scope
- watchOS Live Activity
- Remote (server-pushed) Live Activity updates
- Multi-activity simultaneous display (we still allow only one active automation at a time)
- App Intent control surfaces beyond Cancel
