# ADR-006: Solar Lens server as a privacy-neutral push alarm clock

## Status

**Accepted** — being implemented in story #9 (Remote Push for Automations and
Notifications). Partially supersedes [ADR-001](./001-on-device-automation-runner.md)
("no server, no APNs") and complements
[ADR-002](./002-notifications-separate-from-automations.md).

## Context

ADR-001 chose an on-device-only automation runner: foreground timer +
`BGAppRefreshTask` (+ `BGProcessingTask` since story #6), state in
`UserDefaults`, predictive stop conditions. Story #6 improved timing further
with pre-scheduled local notifications wherever the crossing time is
forecastable.

Two limitations survived all of that, and both are structural:

1. **A local notification cannot run code.** `AutomationAutoResetChargingMode`
   pre-schedules a `UNCalendarNotificationTrigger` at `resetAt`. It fires
   exactly on time — and says "open Solar Lens to apply …", because the
   charging-mode API call still needs BG runtime or the user opening the app.
   Display and execution are decoupled; ADR-001 already recorded this as a
   known negative ("notifying at a known time is reliable; *acting* at a known
   time is not").
2. **After a force quit, nothing on-device runs at all** — no BG tasks, no
   silent pushes. The user's mental model ("I set a reset time, it happens") is
   simply not met in that state.

Story #6 rejected a server-side design, but the design it rejected was a
*polling* server: one that holds Solar Manager credentials at rest, calls the
Solar Manager API on the user's behalf, and evaluates rules in the cloud. The
decisive arguments were credential-at-rest security, token-refresh desync,
24×7 cost, and operational criticality — all properties of *polling*, none of
them properties of *push* as such.

## Decision

We introduce a **server that knows nothing except when to wake a device**, and
execute everything on-device as before.

- The app registers with the Solar Lens server: **APNs device token,
  environment, a schedule id, and a timestamp (or a cadence + end time)**.
  Never credentials, never tokens for Solar Manager, never rule contents,
  never measurements.
- For **time-bound automations** (known end time) the server sends a **visible
  alert push with `mutable-content: 1`**. A new **Notification Service
  Extension (NSE)** executes the automation tick on-device — it runs even after
  a force quit and is not subject to the silent-push budget — and rewrites the
  notification text to the actual outcome. Display *is* execution.
- For **automations without an end time** and for the **Notifications
  subsystem**, the server sends **silent pushes** on a coarse cadence as an
  *additional, best-effort* wake source next to `BGAppRefreshTask` /
  `BGProcessingTask`. Nothing existing is removed.
- Every path keeps its **on-device fallback**: the local reset-due notification
  (moved to `resetAt + 2 min`), BG tasks, forecast backstops, foreground timer.
  A server outage degrades to exactly today's behaviour.

The "server-free guarantee" of ADR-001 is therefore narrowed, deliberately,
from *no server at all* to **no server access to Solar Manager, no credentials
off-device, no cloud-side decisions**.

## Options

### Option A: Visible push + NSE for deadlines, silent push as extra wake *(chosen)*

**Pros:**

- Alert pushes are not throttled and the NSE runs **after force quit** — the
  only mechanism available to a third-party app that does.
- The notification the user sees is written *after* the work happened, so it
  can never claim something that did not occur.
- Server stays a dumb alarm clock: no credentials, no Solar Manager API, no
  rules, scale-to-zero-ish cost, no availability obligation.
- Reuses the existing on-device decision code; the NSE calls the same task
  logic the app does.

**Cons:**

- New moving parts: an extension target, an App Group, APNs keys, a scheduler.
- The NSE is a hard ~30 s / ~24 MB sandbox — no heavy dependencies, careful
  code sharing.
- Requires the user to keep notifications enabled; if they disable them, we
  silently fall back to today's (worse) behaviour.
- Automation state must move to an App Group so two processes can share it,
  with a lease to avoid double execution.

### Option B: Silent pushes only

**Pros:** no extension, no visible push, simplest client change.

**Cons:** iOS throttles silent pushes (historically ~2–3/h, budget-based),
gives no delivery feedback, requires Background App Refresh, is degraded in
Low Power Mode, and — decisively — **is not delivered after a force quit**.
Apple explicitly does not position it as a scheduler. Fine as a supplement,
unusable as the guarantee for a deadline. *(Kept as mechanism 2.)*

### Option C: Server polls Solar Manager and decides (the story #6 design)

**Pros:** hard timing bound regardless of device state; would also solve
state-driven automations.

**Cons:** credentials at rest on our infrastructure (Solar Manager tokens are
read+write — a skeleton key), token-refresh desync between app and server,
24×7 cost and criticality. Rejected in story #6 and **still rejected**; this
ADR does not re-open it.

### Option D: Keep pure on-device (status quo)

**Pros:** zero new surface; the story #6 improvements already helped.

**Cons:** leaves the two structural limitations above unfixed. The scheduled
mode reset — a feature whose entire premise is "at this time" — remains
best-effort, and completely dead after a force quit.

## Consequences

### Positive Impact

- Scheduled automations execute at their time, within ~1 min, in app states
  where nothing ran before (suspended, idle, force-quit).
- Notification text is guaranteed to match reality.
- Privacy posture is unchanged in substance: no credential, token, or
  measurement ever reaches our infrastructure; the server learns only
  "device X wants a wake-up at time T".
- Threshold notifications and Battery → Car gain an extra wake source at no
  behavioural risk (purely additive).
- The wake-schedule API is generic — future time-bound automations register a
  timestamp and inherit the mechanism.

### Negative Impact / Risks

- **New operational surface**: APNs .p8 key (rotation), Azure app settings,
  a poison queue to watch. Mitigated by keeping the server non-critical.
- **Two processes share automation state.** Requires App Group persistence,
  a migration off `UserDefaults.standard`, and a lease so app and NSE cannot
  both apply the reset. Bugs here are user-visible (double API call or none).
- **NSE limits**: ~30 s / ~24 MB. Only `Shared/` code may be linked; no UI, no
  ActivityKit — a stale Live Activity is possible until the app next runs.
- **Depends on notifications being enabled.** If the user disables them, the
  precise path is gone without any signal to us. Surfaced in the setup sheet.
- **Device tokens are personal data** (pseudonymous). Requires a privacy-label
  entry and retention discipline (rows deleted after firing / `until`).
- **Silent pushes remain unreliable** — they must never be presented to users,
  or to ourselves in design discussions, as a guarantee.

### Effort

- Slice 1 (App Group + NSE + shared deadline runner): the bulk of the risk.
- Slices 2–3 (Azure scheduler + app-side sync): mostly mechanical.
- One-time manual setup in the Apple Developer portal, Xcode and Azure — see
  the "One-time setup" section of story #9.

## References

- Story: [specs/stories/009-remote-push-for-automations-and-notifications.md](../stories/009-remote-push-for-automations-and-notifications.md)
- Superseded in part: [ADR-001](./001-on-device-automation-runner.md)
- Related: [ADR-002](./002-notifications-separate-from-automations.md), story #6
- Apple: [`UNNotificationServiceExtension`](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension), [Sending notification requests to APNs](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns)
