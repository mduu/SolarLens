# Story: #6, Improve Notification Timing (on-device)

**Status:** Done (13.06.2026)

## Short Description

Notification delivery is currently far too imprecise to be useful: because checks only run when iOS happens to wake the app in the background, a threshold crossing can be reported **hours late** (observed: ~5 h, only delivered when the user next picked up the iPhone). **Stay on-device** (no server, no credentials off-device, no cloud cost — see "Rejected alternative") and improve timing as far as on-device mechanisms allow. The realistic goal is **best-effort, aiming to notify within ~60 minutes** of the crossing instead of hours late — a large, worthwhile improvement even though no hard bound is achievable on-device.

## Additional Information

### The problem

The Notifications subsystem (story #5) is, by [ADR-001](../adrs/001-on-device-automation-runner.md) and [ADR-002](../adrs/002-notifications-separate-from-automations.md), **pure on-device**: a 60 s foreground timer plus an opportunistic `BGAppRefreshTask`, with a 5-minute poll cadence (`NotificationManager.recheckInterval`).

While foregrounded this is precise. While suspended it is not — and that is the normal case for a "tell me when X happens" feature the user is *not* actively watching:

- `BGAppRefreshTask` is opaque and throttled: typically 15–60 min between wakes, **frequently far longer**, and effectively never while the device is idle/asleep. A monitor can therefore sit unchecked for hours and only tick when the user picks the phone up — at which point the notification fires "now" for an event that happened long ago.
- The only mitigation today is the **battery-level forecast backstop**: when a linear extrapolation predicts the threshold is ≤ 15 min away, a `UNCalendarNotificationTrigger` is pre-scheduled at the predicted moment (`updateBatteryForecastAndBackstop`). This is the *only* path that currently fires on time while suspended, and it has hard limits (only battery; needs a recent tick to seed the forecast; needs the rate to hold).

**Concrete field observation (v4.2):** the house battery reached 100 % at ~10:20; Solar Lens delivered the "Battery level 100 %" notification only at 15:22, the moment the user next picked up the iPhone — a "Grid export" notification fired at the exact same instant, confirming the app had simply not checked for ~5 h. Note this exact failure *is* addressable on-device: a charging battery's trajectory toward 100 % is forecastable, so a wider forecast window (below) would have pre-scheduled a local notification near 10:20 and fired it on time while suspended.

### Why no on-device mechanism gives a hard bound

iOS deliberately offers third-party apps **no guaranteed periodic background execution at any interval** — there is no "wake me every 30/60 min" entitlement. The multi-hour gap is the normal signature of an idle device. The mechanisms and what each can/can't do:

- **`BGAppRefreshTask`** (used today): *opportunistic*, system-throttled from learned usage. `earliestBeginDate` is a floor, not a promise — hours-to-never while idle / Low Power Mode. Tends to improve with frequent app usage and overnight while charging.
- **`BGProcessingTask`**: longer maintenance jobs, granted more readily while charging + on Wi-Fi (often overnight). Not a periodic timer, but a useful *extra* wake source we don't use yet.
- **Local `UNCalendar` / `UNTimeInterval` triggers**: fire on time *without* the app running — the only thing reliable while suspended — but deliver a **fixed, pre-scheduled** message; they cannot run code to re-check a live value first. Usable only when we can *predict the crossing time*.
- **Silent push, PushKit/VoIP, background location/audio**: either require a server (ruled out, see below) or get rejected by App Review for a use case that doesn't match the entitlement.

So the honest framing: we **cannot** promise ±X minutes on-device. What we *can* do is (1) make every rare wake count, (2) add wake sources, and above all (3) **pre-schedule local notifications wherever the crossing time is predictable**, which fires precisely even while suspended. That is enough to move most cases from "hours late" to "minutes-to-~60 min", which is the goal.

### Proposed on-device improvements

Per-kind, because forecastability differs:

**Forecastable kinds → pre-scheduled local notification (the big win).**
- **Battery level** is the prime case (and the most-complained-about): while charging/discharging at a roughly steady rate the crossing time is predictable. Generalise the existing forecast backstop:
  - **Widen the forecast window** from 15 min to ~60–90 min so a crossing predicted well ahead still gets a pre-scheduled notification (directly fixes the 10:20/15:22 case).
  - **Re-arm/reschedule on every tick**: each time the app runs (foreground or BG), recompute the forecast and move the pre-scheduled notification to the corrected time. More ticks → more accurate; zero further ticks → the last estimate still fires on time.
  - **Staggered backstops** (e.g. at forecasted −10 %, −5 %, threshold) as cheap insurance against a single bad estimate.
- **Solar production** is partially forecastable (morning ramp / evening fall are smooth); a level crossing during a monotonic ramp can be pre-scheduled the same way. Cloud-driven noise limits this — apply only when the recent trend is clearly monotonic.
- **Trade-off — false alarms.** A longer-horizon forecast can fire early/late if the rate changes (clouds, load). Mitigations: re-arm on every tick; for **ceiling** crossings (e.g. "reached 100 %") phrase the pre-scheduled copy as an estimate ("battery should be reaching ~100 % about now") rather than a hard claim, and/or reconcile on next app open; for **floor** crossings firing slightly early is harmless (safety-positive). Tune per kind.

**Non-forecastable kinds (grid import/export, overall consumption, charging throughput).**
- These jump in seconds (appliance cycles, EV plug-in, cloud cover) — there is nothing to pre-schedule against. They remain dependent on actually running a check, i.e. on BG wakes. We can only improve the *average*, not bound it:
  - **Make every wake maximal**: on any wake (foreground, BGAppRefresh, BGProcessing), check **all** monitors and refresh **all** forecast backstops, not just the one that triggered the wake.
  - **Add `BGProcessingTask`** as a second wake source (better odds overnight/while charging) alongside the existing `BGAppRefreshTask`; always reschedule both aggressively on every tick and on `scenePhase == .background`.
  - **Set expectations honestly in the UI**: the setup sheet already notes background timing is best-effort; make it explicit that *threshold* notifications for these kinds can be delayed while the phone is idle, whereas battery/solar are more timely. Avoid implying a guarantee we can't keep.

**Cross-cutting.**
- Keep the existing hysteresis / repeat semantics (`armed` / `firedWaitingForReset`, deadband + dwell) unchanged.
- Keep the foreground 60 s timer as the precise fast path.
- Record any expectation-setting copy and the per-kind timeliness difference where users will see it.

### Rejected alternative: server-side polling + APNs push (and why)

A server that polls Solar Manager and sends APNs pushes is the *only* design that could give a hard ±15 min bound regardless of device state. It is **deliberately rejected** for this story:

- **Cloud cost (decisive).** Today the Azure Functions backend is scale-to-zero Consumption (sporadic tvOS image uploads, ~zero cost, nothing critical if idle). A notification service must run **24×7** and becomes a **critical dependency**; per-user polling cost scales with users × cadence (executions + Solar Manager API volume, likely a fixed-cost always-on plan).
- **Cloud ops.** 24×7 criticality brings monitoring, alerting, on-call and an availability burden the project does not have today.
- **Security.** It would put a usable Solar Manager credential **at rest on our infrastructure for the first time**. Solar Manager's normal tokens are **read+write**, so an exfiltrated token is a skeleton key usable directly against Solar Manager's public API — aggregated, a high-value honeypot. ("No write code on our server" is *not* a boundary against credential theft.) A read-only Solar Manager user would shrink the blast radius, but most customers use read-write logins and we cannot downscope them. The owner's standing stance is **against storing any credential/token on the server**.
- **Functional blocker.** Solar Manager access tokens expire (~1 day). A token shared between app and server desyncs on refresh — if the server refreshes, the app login breaks; if it doesn't, server polling dies after a day. Stable operation would require storing the password (worst, unwanted) or Solar Manager supporting multiple independent tokens per account.

This analysis is kept so the decision is not re-litigated. **If** the on-device improvements prove insufficient *and* the cost/ops/security posture is ever reconsidered, the first thing to check is whether **Solar Manager offers a native push/webhook/threshold-notification** we could subscribe to (no polling, no credential-at-rest) — or whether users should simply be pointed at Solar Manager's own notifications for the time-critical cases.

## Expected Result

- Threshold notifications are **substantially more timely**: the common forecastable cases (battery level; solar during a clean ramp) fire close to the actual crossing (minutes) even while suspended, via pre-scheduled local notifications; the non-forecastable cases improve on average via better/more wake sources. The practical aim is "within ~60 min instead of hours late", explicitly **best-effort, not a guarantee**.
- The specific reported failure (battery reaching a level while the phone is idle for hours) is fixed for the forecastable case.
- No new server, no credentials leave the device, no new cloud cost — the server-free guarantee is preserved.
- UI sets honest expectations about background timing and the per-kind difference; no implied guarantee.
- Hysteresis / repeat behaviour and the in-app list/history are unchanged for users.

## Test Checklist
- [x] App builds successfully
- [x] App runs correctly on watchOS Simulator
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [ ] Battery-level crossing predicted >15 min ahead pre-schedules a local notification at the predicted time and fires on time while the app is suspended and the phone is idle (reproduces and fixes the 10:20/15:22 case) — **needs device/field verification**
- [ ] Forecast re-arms/reschedules correctly as the rate changes across ticks (single backstop; staggering intentionally not implemented) — **needs device/field verification**
- [x] Backstop copy reads as an estimate ("forecast … around now — verify"), never a hard claim; real fire only from an actual tick
- [x] `BGProcessingTask` is registered and, together with `BGAppRefreshTask`, every wake checks all monitors and refreshes all backstops (code-verified; runtime grant is iOS-controlled)
- [x] Non-forecastable kinds: UI does not imply a guarantee (timing improvement on average needs field measurement)
- [x] Hysteresis / repeat semantics unchanged (no spam on a flapping value)
- [x] /specs have been updated if necessary (server rejection + on-device design + the per-kind window / keep-good-backstop follow-up are all captured in this story)
- [x] If architectural decisions were made, an ADR was created in /specs/adrs (none needed — no new architectural decision beyond what this story records; ADR-001/002 unchanged)
- [x] Story status has been set to "Done (13.06.2026)"
- [x] Story file has been moved to /specs/stories/done/
- [x] Story has been removed from the backlog (the timing item was already moved into this story when it was created)

> **Note on the two remaining unchecked items** (battery crossing fires on time while suspended; forecast re-arms across ticks): these require on-device/field measurement over real charge cycles, not a code task. The mechanisms are code-verified; closing the story does not assert the field numbers. If field testing still shows late delivery, reopen and revisit the forecast parameters (window, noise floors) or the keep-good-backstop heuristic.

## Tasks

- [x] Generalise the forecast backstop beyond battery: widen the window to 90 min, re-arm/reschedule on every tick, extract the pre-schedule logic so any forecastable kind can use it (`NotificationManager.updateForecastAndBackstop` / `forecastSecondsToThreshold` / `scheduleForecastBackstop`, generic id prefix `notification.forecast.`). **Deviation:** true *staggered* multi-notification backstops were dropped — multiple pre-scheduled notifications risk firing several alerts for one crossing. Replaced by a single backstop re-armed on every tick (corrects its time as the rate changes). Also fixed a latent bug where the post-forecast `nextCheckAt` overwrite discarded the forecast alignment.
- [x] **Follow-up (field testing still showed late alerts on idle devices).** Two on-device hardenings of the backstop:
  - **Per-kind forecast window** (`forecastWindow(for:)`): battery widened to **6 h** (its charge/discharge trajectory is the most stable and most-complained-about, and the device is most likely idle for hours exactly on long sunny-day charge cycles — a crossing predicted 3–5 h out previously got no backstop at all under the 90 min cap); solar kept at 90 min (cloud-driven swings make longer horizons unreliable).
  - **An inconclusive tick no longer deletes a good backstop.** Previously a single sample with a momentary idle rate / passing cloud / crossing-beyond-window called `cancelForecastBackstop`, wiping the pre-scheduled notification; if iOS then never granted another tick the alert only fired hours later when the user next opened the phone — the exact reported failure. Now the last good backstop is kept and only cancelled when the live value is *clearly* moving away from the threshold (`isHeadingAwayFromThreshold`, using the signed battery charge rate / a guarded solar slope above the same noise floors the forecasts use).
- [x] Add solar-production forecasting for monotonic ramps (guarded): two-sample slope (`slopeForecastSeconds`), requires moving toward the threshold from the correct side and above a ~50 W/min noise floor, so flat/cloudy/jittery signals produce no backstop
- [x] Handle false-alarm trade-off: the backstop copy is worded as an estimate ("Forecast to cross … around now — open Solar Lens to verify"), never a hard "reached X" claim; the real confirmation still fires only from an actual tick that meets the condition
- [x] Register and wire a `BGProcessingTask` (`…NotificationProcessing`) as a second wake source alongside `BGAppRefreshTask`; both drain the same subsystems and are rescheduled on tick and on background. Added the identifier to `BGTaskSchedulerPermittedIdentifiers`
- [x] On every wake, tick all active monitors plus every forecastable armed monitor (refresh all backstops, not just the wake's trigger) — `runOverdueMonitorsInBackground` + foreground `.active`
- [x] UI: honest, per-kind background-timing expectation copy in the setup-sheet footer (forecastable kinds arrive close to the crossing; others may be delayed > 1 h while idle); no implied guarantee
- [ ] Field-measure latency before/after (suspended + idle device) for a forecastable kind (battery) and a non-forecastable kind (grid import); document the achieved best-effort numbers — **requires device/field testing**
- [x] /specs: server rejection + on-device design captured in this story; no ADR needed (no new architectural decision beyond what this story records)
