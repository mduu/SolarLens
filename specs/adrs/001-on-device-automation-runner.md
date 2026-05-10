# ADR-001: On-device-only automation runner (no server, no APNs)

## Status

**Accepted** — implemented in story #3 (Automation: Transfer from Battery to Car), shipped in iOS 4.1.0.

## Context

Story #3 introduces an "Automation" tab in the iOS app whose first workflow
("Transfer from Battery to Car") needs to run for tens of minutes to several
hours, monitor live PV/battery/grid signals every ~60 s, re-tune the charging station
amperage, and stop predictively before a user-set battery floor is crossed or
sustained grid import becomes unavoidable.

Constraints:

- **No backend.** Solar Lens deliberately keeps a "server-free" guarantee for
  iOS. The Solar Lens server today exists only for tvOS image uploads
  (see `architecture.md` → Infrastructure). Adding a cron worker, queue, or
  APNs gateway purely to support iOS automations would erode that guarantee
  and add operational surface (uptime, secrets, billing).
- **iOS does not allow third-party apps reliable always-on background
  execution.** No background-thread budget, no minute-accurate scheduler, no
  silent push fan-out. `BGTaskScheduler` is opaque: typical 15–60 min between
  refreshes, never guaranteed.
- **The user's expectation is "the automation just works"**, even if they
  background or kill the app.
- **Future automations** (excess-PV-to-heat-pump, off-peak grid charging,
  scheduled mode switches, ...) will share the same constraints. The runner
  must be reusable.

## Decision

We adopted **Option A** — an on-device-only runner that combines a foreground
timer, opportunistic `BGAppRefreshTask`, and a `UserDefaults`-persisted state
snapshot, with **predictive** stop conditions to absorb BG throttling. A
Live Activity will later bridge the BG visibility gap (see "Consequences").

Concrete shape:

- `AutomationManager` (`@Observable @MainActor`, singleton) owns at most one
  active automation. Identifier: `com.marcduerst.SolarManagerWatch.AutomationRunner`.
- Foreground: 60 s `Timer.scheduledTimer` ticks the active task.
- Background: `BGAppRefreshTask` re-scheduled with `earliestBeginDate = now + 60s`
  on every successful tick and on `scenePhase == .background`.
- Persistence: `activeState` + `activeTaskParameters` written to
  `UserDefaults` (key `SolarLens.activeAutomationState`) after every tick;
  restored on `init`.
- Stop conditions are **predictive**, not reactive. For battery-floor stops
  the runner stops early by an EWMA-based safety buffer (drain rate × smoothed
  tick interval × 1.5 safety factor, clamped 1–8 %), so overshoot during a
  long BG gap is bounded.

## Options

### Option A: On-device runner with predictive stops *(chosen)*

**Description:** Foreground timer + `BGAppRefreshTask` + persisted state +
predictive stop conditions. No server, no APNs.

**Pros:**

- Preserves the server-free guarantee.
- No new operational surface.
- Works fully offline-from-our-infra (still depends on Solar Manager Cloud API).
- Same runner is reusable for any future iOS automation.
- Predictive stops bound the worst-case overshoot when iOS is stingy with BG slots.

**Cons:**

- Not minute-accurate while suspended; we explicitly accept that the user *may*
  see the battery dip a few % below their floor in pathological BG-throttling.
- BG cadence is opaque — we cannot promise users a refresh rate.
- The "is something happening?" UX in the background depends on Live Activity,
  which is non-trivial and was deferred to a follow-up story.

### Option B: Server cron + APNs

**Description:** Solar Lens server runs a worker that polls Solar Manager,
makes the same decisions, and pushes silent APNs to the iOS app to update UI /
fire local notifications.

**Pros:**

- Minute-accurate regardless of app state.
- Survives device-off, reboot, OS upgrades.
- No iOS BG-throttling concerns.

**Cons:**

- Breaks the server-free guarantee for iOS.
- New operational surface: APNs certs, queue, secrets, observability, billing.
- Requires user credentials at rest on our server (compliance impact).
- Existing server is .NET Azure Functions sized for tvOS image uploads, not a
  long-poll fleet.
- Doesn't compose with "no Solar Lens account" — today users only need a
  Solar Manager account.

### Option C: Foreground-only ("user must keep the app open")

**Description:** Only run automations while the app is in the foreground. If
the user backgrounds the app, pause; resume on next foreground.

**Pros:**

- Simplest; no BG entitlement, no Live Activity, no predictive stop.
- Behaviour is fully deterministic.

**Cons:**

- Practically unusable: a "Battery → Car" run is 30 min – 3 h. No user keeps
  the app foregrounded for hours on a phone.
- Breaks the user expectation that automations "just run".

### Option D: Always-on Location / Background Audio entitlements

**Description:** Acquire a continuous BG entitlement under a different premise
(e.g. claim location relevance) so the timer keeps running in the background.

**Pros:**

- Closest thing to a "real" BG thread on iOS.

**Cons:**

- App Review will reject — the entitlement does not match Solar Lens's actual
  use case.
- Privacy-hostile if granted; users would see "Solar Lens is using your location"
  with no plausible reason.
- Hard dependency on a misused entitlement is fragile across iOS versions.

### Option E: User-configured iOS Shortcut / Personal Automation

**Description:** Ship an `AppIntent` and ask the user to wire up a Personal
Automation (e.g., "every 5 min run Solar Lens").

**Pros:**

- Zero BG infrastructure on our side.

**Cons:**

- Requires user setup outside the app — high drop-off.
- Personal Automations are not minute-accurate either, and they're throttled
  by iOS the same way BG refresh is.
- No in-app cancel UX; cancel state has to round-trip through Shortcuts.

## Consequences

### Positive Impact

- Server-free guarantee preserved. Adding future automations is a Swift-only
  change.
- One runner, one persistence model, one identifier — future automations
  inherit the architecture (state shape, BG scheduling, log surface, cancel UX).
- Predictive stops give us *bounded* worst-case behaviour during BG throttling
  instead of unbounded overshoot.
- All telemetry stays on the user's device.

### Negative Impact / Risks

- **No minute-accurate guarantee while suspended.** Documented in the setup
  sheet and the story. Mitigated by predictive stop logic and (future) Live
  Activity.
- **BG visibility gap.** Until the Live Activity ships (deferred from story
  #3), the only running indicator outside the app is a tab badge. For the
  Battery → Car automation this is acceptable because the charging station itself
  surfaces the active charge. Future automations without a physical
  side-effect surface will need the Live Activity before shipping.
- **Field-tuned magic numbers.** The `200 W` grace band on grid flow and the
  `1.5 ×` predictive safety factor were chosen from first principles and one
  CH installation. Heat-pump installations may need re-tuning. Captured as a
  remaining test in story #3.
- **`BGAppRefreshTask` budget is shared across the whole app.** Adding more
  automations in parallel won't multiply BG slots — the runner enforces "one
  active automation at a time" partly for this reason.

### Effort

- Story #3 implementation: ~2 weeks calendar including design, multiple
  TestFlight iterations, and field testing.
- Future automation onboarding: estimate ~3–5 days per new automation,
  reusing `AutomationManager`, `AutomationLogManager`, persistence, BG
  scheduling, and the AI-style card components.

## References

- [Story #3 — Automation: Transfer from Battery to Car](../stories/003-automation-battery-to-car.md)
- [architecture.md → On-Device Automation Runner](../architecture.md)
- Apple docs: [`BGTaskScheduler`](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler), [`ActivityKit`](https://developer.apple.com/documentation/activitykit)
