## Tasks

> **Progress (29.08.2026, branch `feature/009-remote-push`):** Slice 2 is complete
> and verified against Azurite plus the live APNs sandbox endpoint. Slice 1 is
> complete in code — what is left there is the Xcode target and the Apple
> Developer portal configuration, which is manual work done together with the
> owner (see "One-time setup"). Until the App Group and Push capabilities exist,
> the new code degrades to exactly today's behaviour: `AutomationSharedStore`
> falls back to `UserDefaults.standard` / Documents, and no push is ever sent.

### Slice 1 — NSE executes a time-bound automation from a manual test push
- [x] Write ADR-006 (server as privacy-neutral alarm clock; visible push + NSE for deadlines; silent push as additive wake source; rejected alternatives)
- [x] Migrate `AutomationManager` state/parameters and `AutomationLogManager` storage to the App Group with one-shot migration (`AutomationSharedStore`, `AutomationLogWriter`) — falls back to the app-local locations while the entitlement is missing
- [ ] Add the App Group entitlement to the iOS app (+ widget/LA extensions if needed) — **needs Xcode/portal**
- [ ] Add `Solar Lens iOS NotificationService` target with Keychain access group + App Group; keep dependencies to `Shared/` only — **needs Xcode**; sources, `Info.plist` and `.entitlements` are written and waiting in `Solar Lens iOS NotificationService/`
- [x] Extract a UI-free deadline path from `AutomationAutoResetChargingMode` / `AutomationManager` reusable by the NSE (`AutomationDeadlineRunner`); shared-store lease added on both sides to avoid double execution
- [x] NSE: load token + state, run tick, persist outcome + log, rewrite notification content, cancel pending local fallback notification; honest default payload text (`NotificationService.swift`, `AutomationPushPayload`, `AutomationExternalOutcome`)
- [x] App reconciles a run finished by the extension: `AutomationManager.adoptExternalCompletionIfNeeded()` ends the Live Activity, refreshes the UI and posts no duplicate notification
- [x] iOS, watchOS and tvOS targets build with the new shared code (new files excluded from the tvOS and watch-widget targets, which do not compile the automations folder)
- [ ] Verify with `xcrun simctl push` (simulator) and a manual APNs push (device, incl. force-quit) — **blocked on the target**

### Slice 2 — Server scheduler (extend Solar Lens .NET Azure Functions)
- [x] Add `Azure.Data.Tables`, `Azure.Storage.Queues`, `Extensions.Storage.Queues`, `Extensions.Timer` packages; Azurite table/queue for local dev
- [x] `WakeScheduleService` (Azure Table `WakeSchedules`, install-secret hashing, validation/clamping of cadence/until, token format check, device purge, catch-up window)
- [x] HTTP functions `PUT/DELETE/GET /api/wake/…` with `RateLimitService`
- [x] Timer function (`0 * * * * *`): select due rows (with 15-min catch-up), enqueue one message per push, park deadlines / advance windows, daily defensive cleanup
- [x] Queue function: `ApnsClient` (HTTP/2, ES256 JWT cache, sandbox/production hosts, headers incl. `apns-expiration`/`collapse-id`), row re-check for idempotency; invalid token → delete device rows, no retry; transient → self re-enqueue with `visibilityTimeout` until `fireAt + 10 min`, then drop with `Warning`; unexpected → throw → poison queue; one message = one push (no batching)
- [x] Timer function logs `apns-push-poison` depth at `Warning` when > 0; README section "what to do when the poison queue is not empty"
- [ ] Application Insights alert rule on that warning — **needs Azure Portal** (part of "One-time setup")
- [x] `host.json`: `queues.maxPollingInterval` 5 s, `maxDequeueCount` 5, timer function log level `Warning`; App Insights sampling kept on
- [x] Secrets read from Function App settings; `local.settings.json` template; server README (architecture, API, APNs key handling, error classes, local dev)
- [ ] Set the real `Apns__*` app settings in Azure — **needs the .p8 key** (part of "One-time setup")
- [ ] Verify cost lines after 2 weeks in production against the estimate table in this story

**Verified locally** (Azurite + live APNs sandbox): registration API (204 / 400 wrong secret / 400 bad token / 403 without secret), due-selection, deadline parking, window advance and expiry, device purge, `403 InvalidProviderToken` handling, `429` transient re-queue, and dropping a push that is older than `fireAt + 10 min`. Three defects found and fixed in the process:
- Azure Tables' LINQ translator produces a filter that silently matches **nothing** for `DateTimeOffset?` comparisons — replaced with hand-written OData (a silent "no pushes ever sent" failure mode).
- `Extensions.Storage.Queues` 5.5.5 drags `Microsoft.Extensions.*` 10.x into the generated host-side extension bundle, which the Functions host cannot load — pinned to 5.5.0.
- Re-minting the provider JWT on every rejection earns `TooManyProviderTokenUpdates` — a token is now only replaced once it is at least 20 minutes old.

### Slice 3 — App-side registration & sync
- [ ] One-time setup per section "One-time setup" — walked through step by step together with Claude when this slice starts (manual clicks in the Apple Developer portal / Azure Portal; Claude prepares CLI commands, checks entitlements/plist/app settings and verifies with a test push): APNs .p8 key (stored in password manager), App ID capabilities, App Group, NSE App ID, Xcode capabilities/background mode, Azure app settings, App Insights alert, App Store privacy label
- [ ] Push capability + `remote-notification` background mode; token registration and refresh handling; `environment` sandbox/production per build configuration
- [ ] `WakeScheduleClient` in `Shared/`: upsert/delete deadline on automation start/change/cancel/finish; re-sync on launch and on token rotation
- [ ] Move existing local reset-due notification to `resetAt + 2 min` as fallback; wording unchanged
- [ ] Settings toggle "Server-assisted timing" with privacy explanation; off → delete server schedules
- [ ] Setup-sheet copy: precise execution requires notifications enabled

### Slice 4 — Silent-push wake window for Battery → Car and Notifications
- [ ] Register/extend/cancel wake windows from `AutomationManager` (Battery → Car) and `NotificationManager` (active monitors)
- [ ] Handle `didReceiveRemoteNotification` → shared drain routine (both managers), re-arm BG tasks + forecast backstops
- [ ] Server: cadence-based silent push sending until `until`; stop when window deleted

### Slice 5 — Fallbacks, docs, measurement
- [ ] NSE timeout / notifications-disabled / server-down paths verified on device
- [ ] Optional on-device telemetry (local only, shown in the automation log): push received vs. fallback fired, to judge real-world delivery rate
- [ ] Update `architecture.md`, `risks.md`, `userinterface.md`, privacy policy / App Store privacy label
- [ ] Translations for new strings (`/translate`)
