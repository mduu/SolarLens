# Story: #9, Remote Push for Automations and Notifications (visible push + NSE, silent push as extra wake source)

**Status:** Open

## Short Description

Make **time-bound automations** (today: Auto-reset Charging Mode) actually *execute* at their end time instead of merely *notifying* about it: the Solar Lens server sends a visible APNs push at the scheduled time, a new **Notification Service Extension (NSE)** wakes up, runs the automation tick on-device (checks the automation, ends it if due, applies the charging mode), and rewrites the notification text to the real outcome before the user sees it. For **automations without an exact end time** (Battery → Car) and for the **Notifications tab** (threshold monitors), the server additionally sends **silent pushes** as a best-effort extra wake source that complements — never replaces — today's BGTask-based behaviour. Solar Manager credentials and tokens never leave the device; the server only learns "device token X wants to be woken at time T".

## Additional Information

### Problem today

- Both subsystems run purely on-device per [ADR-001](../adrs/001-on-device-automation-runner.md) / [ADR-002](../adrs/002-notifications-separate-from-automations.md): 60 s foreground timer + opportunistic `BGAppRefreshTask` + `BGProcessingTask` (story #6). iOS grants those wakes opportunistically — typically 15–60 min apart, often hours while the phone is idle, and **never after a force quit**.
- `AutomationAutoResetChargingMode` already pre-schedules a local `UNCalendarNotificationTrigger` at `resetAt` (`scheduleResetDueNotification`). That notification fires reliably, but **a local notification cannot run code**: it says "Reset time reached — open Solar Lens to apply …" while the charging station is still on the active mode until a BG tick lands or the user opens the app. Display and execution are decoupled; ADR-001 calls this out explicitly ("notifying at a known time is reliable; *acting* at a known time is not").
- Threshold notifications (story #5/#6) are best-effort "within ~60 min"; the non-forecastable kinds (grid import/export, consumption, charging throughput) depend entirely on BG wakes.

### Why this does not re-open the story #6 "no server" decision

Story #6 rejected a server that **polls Solar Manager** and holds **credentials at rest**. This story keeps that boundary intact and is a different design:

| | Rejected in story #6 | This story |
|---|---|---|
| Server holds Solar Manager credentials/tokens | yes (blocker) | **no — never** |
| Server calls the Solar Manager API | yes | **no** |
| Server knows automation/notification rules | yes | **no** (only device token + timestamps + cadence) |
| Server runtime | 24×7 polling per user | one lightweight timer trigger; no per-user polling |
| Critical dependency | yes | **no** — if the server is down, today's BGTask behaviour still applies |
| Decision/execution | on server | **on device** (NSE / app), same code paths as today |

The "server-free guarantee" of ADR-001 changes from *no server involvement at all* to *server as optional, privacy-neutral alarm clock*. That is an architectural change and needs an **ADR-006** that partially supersedes ADR-001 (the "no APNs" part) and records why silent-push-only was rejected as the primary mechanism.

### Mechanism 1 — Time-bound automations: visible remote push + NSE

Applies to automations whose end time is known in advance (`AutomationAutoResetChargingMode.resetAt`; any future scheduled-mode-switch automation).

**Flow**

1. When the automation starts, the app registers with the server: `{ deviceToken, apnsEnvironment (sandbox|production), wakeAt: resetAt, kind: "automation-deadline" }`. Nothing else — no charging mode, no station id, no credentials.
2. At `wakeAt` the server sends an **alert push** (`apns-push-type: alert`, `apns-priority: 10`) with `mutable-content: 1`, a default title/body that is meaningful on its own (e.g. "Auto-reset Charging Mode — reset time reached, applying …"), the existing notification category, and `userInfo` carrying the automation kind + a `solarlens://…` deep link (reusing `AutomationNotificationDelegate` routing).
3. iOS launches the **NSE** (`UNNotificationServiceExtension`) — a separate process that runs **even after force quit**, and is **not** subject to the silent-push budget.
4. The NSE loads the Solar Manager token from the **shared Keychain access group** (`UYT5K989XD.com.marcduerst.SolarManagerWatch.Shared` — already used by the widget/LA extensions), loads the persisted automation state from an **App Group** container, runs the same tick logic as `AutomationManager.runActiveAutomation()` (for AutoReset: `setCarChargingMode(postMode)`, mark finished, persist), and writes the result back to the shared store + automation log.
5. The NSE rewrites the notification content to the real outcome — e.g. "Charging station reset to *Solar only* ✓" or "Could not reset charging mode (network error) — open Solar Lens." — and calls the content handler. **Display = execution.**
6. Next time the main app runs, `AutomationManager` restores state from the shared store, notices the run is finished, ends the Live Activity and refreshes the UI/watch bridge.

**Fallbacks (belt and braces)**

- Keep scheduling the existing **local** reset-due notification, but at `resetAt + ~2 min` and with today's "open Solar Lens" wording. When the NSE runs successfully it cancels that pending local request (verify `UNUserNotificationCenter.removePendingNotificationRequests` works from the NSE; otherwise the main app cancels it on next launch). If the server/APNs never delivers, the user gets today's behaviour — never a duplicate on the happy path, never silence on the sad path.
- If the NSE exceeds its budget (~30 s wall clock, ~24 MB memory), iOS shows the **original payload** → the default text must be honest ("reset time reached — applying charging mode…"), and the main app reconciles later.
- If the user has **notifications disabled** for Solar Lens, the NSE never runs → BGTask path remains as today. Surface this in the automation setup sheet ("Precise execution requires notifications").
- Wake registration is **idempotent**: cancelling/finishing the automation deletes the schedule; changing `resetAt` upserts it; app launch re-syncs any active deadline (covers server data loss, token rotation, reinstall).

**NSE constraints to design around**

- No heavy frameworks in the extension: reuse only `Shared/` code (`SolarManagerApiClient`, `RestClient`, `KeychainHelper`, automation state/parameters types). Keep UI/observation code out of the extension target.
- `AutomationManager` today persists to `UserDefaults.standard` (`SolarLens.activeAutomationState` / `…Parameters`) and the log to its own store — the NSE cannot read those. Move the relevant persistence to an **App Group** `UserDefaults(suiteName:)` / shared file, with a one-shot migration of existing keys (same pattern as `NotificationMigration`).
- Concurrency: the main app might be foregrounded and ticking at the same moment as the NSE. Use a simple lock/lease in the shared store (e.g. `tickLeaseUntil` timestamp) so only one side executes the reset; the other side just reloads state.
- ActivityKit is not available to update the Live Activity from the NSE — the main app ends/updates the LA on next launch. Verify on device whether the stale LA is acceptable for the short gap; if not, consider LA push updates in a follow-up.
- Automation log entries written by the NSE must show up in `AutomationLogView` → `AutomationLogManager` storage also needs to live in the App Group.

### Mechanism 2 — Silent pushes as an additional best-effort wake source

Applies to automations **without** an exact end time (Battery → Car) and to the **Notifications** subsystem (threshold monitors, especially the non-forecastable kinds).

- While such a run/monitor is active, the app registers an **active window** with the server: `{ deviceToken, apnsEnvironment, kind: "wake", cadenceMinutes, until }` (e.g. every 15 min for Battery → Car with a generous `until`; every 15–30 min for monitors; the app extends/cancels the window on every tick/scene change).
- The server sends **silent pushes** (`content-available: 1`, `apns-push-type: background`, `apns-priority: 5`) on that cadence. On receipt, the app's `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` calls the same drain routine the BG task uses today (`AutomationManager` tick + `NotificationManager.runOverdueMonitorsInBackground()`), then re-arms BG tasks and forecast backstops.
- Honest expectations (this is why silent push is *not* the primary mechanism for deadlines): iOS throttles silent pushes (historically ~2–3/h budget, worse in Low Power Mode, requires Background App Refresh), gives no delivery feedback, and **does not deliver after force quit**. It is purely additive to BGAppRefresh/BGProcessing; every existing on-device mechanism (predictive stops, forecast backstops, 60 s foreground timer) stays untouched.
- Server side, silent pushes stop automatically at `until`, and the app cancels the window when the run/monitor ends, so an idle install generates zero pushes.

### Server (extend the existing Solar Lens .NET Azure Functions app) — part of this story

The `Solar Lens Server` today is a .NET 10 isolated-worker Functions v4 app on the classic **Consumption plan** (westeurope) with one StorageV2 account, used only for tvOS image uploads (HTTP triggers, Blob storage, in-memory rate limiting). It is extended in place — same Function App, same storage account, same deployment — with three new pieces:

```
iOS app ──PUT/DELETE /api/wake──▶ [HTTP Functions] ──▶ Azure Table "WakeSchedules"
                                                              ▲
                                        [Timer Function, every 1 min]
                                          selects due rows, enqueues
                                                              │
                                                              ▼
                                               Azure Storage Queue "apns-push"
                                                     (1 message = 1 push)
                                                              │
                                        [Queue-triggered Function] ──HTTP/2──▶ APNs
                                          (retries, poison queue, 410 cleanup)
```

**1. Registration API (HTTP triggers, `Microsoft.Azure.Functions.Worker.Extensions.Http` — already referenced)**

- `PUT /api/wake/{deviceToken}/{scheduleId}` — upsert one schedule. Body: `{ environment: "sandbox"|"production", kind: "deadline"|"window", fireAt?, cadenceMinutes?, until?, pushKind: "alert"|"silent", category?, deepLink?, installSecret }`. `scheduleId` is a UUID generated on device (= automation run id / monitor id).
- `DELETE /api/wake/{deviceToken}/{scheduleId}` and `DELETE /api/wake/{deviceToken}` (all — used by the Settings toggle / logout).
- `GET /api/wake/{deviceToken}` — optional, re-sync/debug.
- Anonymous like the upload API, protected by the existing `RateLimitService` (per IP) plus an **install secret**: a random 32-byte value generated on first use, stored in the app's Keychain, sent with every request and persisted on the row; updates/deletes must present the same secret so nobody can cancel or spam another device's pushes by guessing tokens. Validate device tokens (64 hex chars) and clamp `cadenceMinutes` (≥ 10) / `until` (≤ 7 days, extend on tick) server-side.
- No Solar Manager data, no rules, no account. The deep link / category are opaque strings for the app.

**2. Azure Table Storage (`Microsoft.Azure.Functions.Worker.Extensions.Tables` + `Azure.Data.Tables`)**

- Table `WakeSchedules`: `PartitionKey = deviceToken`, `RowKey = scheduleId`, columns: environment, kind, pushKind, fireAt / cadenceMinutes / until, `nextFireAt`, category, deepLink, installSecretHash, created/updated, attempts.
- To keep the every-minute query cheap, maintain `nextFireAt` and query with a filter `nextFireAt le now and nextFireAt gt now-15min` (catch-up window for missed minutes, e.g. after a deploy). At 300 users the table is a few hundred rows — a full-table filter scan is a single cheap transaction; a minute-bucket partition (`PartitionKey = yyyyMMddHHmm`) can be introduced later if the table ever grows, no need now.
- Retention: `deadline` rows are deleted once enqueued; `window` rows are advanced (`nextFireAt += cadence`) until `until`, then deleted. A daily cleanup in the same timer removes anything past `until + 1 day` (defensive).
- Same storage account as the blobs (Azurite locally — Tables and Queues are already emulated).

**3. No scheduler timer — the queue is the schedule**

The push is queued when the row is written, with
`visibilityTimeout = fireAt − now`, so it surfaces at the second it is due.
Windows re-queue their next occurrence after each send. Azure Storage caps
invisibility at seven days, so anything further out is queued in hops: the
message surfaces after six days, the sender sees the row is not due yet and
re-queues for the remainder.

This replaced a once-a-minute timer. It is both cheaper and *more* precise:
43k executions a month gone, delivery accurate to seconds rather than to the
next minute boundary, and the host no longer takes a singleton lease every
minute — which had been producing ~1,300 benign `409 container already exists`
warnings a day and a large share of the App Insights ingest.

Once-a-day `DailyHousekeeping` deletes unfetched tvOS images and wake rows that
outlived their window.

**4. Queue-triggered sender (`Microsoft.Azure.Functions.Worker.Extensions.Storage.Queues`)**

- Queue `apns-push`; one execution per message. Sends via **APNs HTTP/2 (`api.push.apple.com` / `api.sandbox.push.apple.com`) with token-based auth** (.p8 key + Key ID + Team ID). There is no Apple server SDK — APNs is a plain HTTP/2 endpoint (`POST /3/device/{token}`), so we write our **own `ApnsClient` (~100 LoC, no NuGet dependency; `dotAPNS` was considered and rejected as unnecessary)**:
  - Registered as a **singleton** in `Program.cs` via `AddHttpClient<ApnsClient>()` with `DefaultRequestVersion = HTTP/2`, `VersionPolicy = RequestVersionOrHigher` and an infinite handler lifetime, so the HTTP/2 connection is reused across invocations (same pattern as the existing `RateLimitService` / `IMemoryCache` singletons).
  - **ES256 JWT** (`{"alg":"ES256","kid":<KeyId>}` / `{"iss":<TeamId>,"iat":now}`) created with `ECDsa.ImportPkcs8PrivateKey` + `SignData(…, SHA256, IeeeP1363FixedFieldConcatenation)`, **cached in the singleton for ~50 min** (Apple: reuse 20–60 min). The cache is per worker process — after a cold start, scale-out or deploy each process simply mints a new JWT, which is the intended pattern; no distributed cache needed.
  - `403 ExpiredProviderToken` / `InvalidProviderToken` → discard the cached JWT, mint once, retry the push immediately; a second `403` is treated as *unexpected* (the key itself is wrong/revoked).
- Headers: `apns-topic = <bundle id>`, `apns-push-type = alert|background`, `apns-priority = 10|5`, `apns-expiration` short for deadlines (e.g. +10 min — a late reset push is useless), `apns-collapse-id = scheduleId`.
- **Error handling — three classes, only one of them ends in the poison queue:**
  - *Invalid device* (`410 Unregistered`, `400 BadDeviceToken` / `DeviceTokenNotForTopic`): the message is done — nothing can ever be delivered to that token. Complete it **and delete all `WakeSchedules` rows for that device token** (the app re-registers with a fresh token on next launch; an uninstalled app simply stops generating traffic). Never retried, never poisoned.
  - *Transient* (`429`, `5xx`, network/timeouts): the Functions runtime would retry 5× within seconds (no retry delay for queue triggers in the isolated worker), which is useless during a multi-minute APNs blip. Instead the function handles this itself: re-enqueue the same message with `visibilityTimeout` 30–60 s and an incremented `attempt` counter **until `fireAt + 10 min`**, then drop it with a `Warning` log — a deadline push older than that is worse than none (the local fallback notification has fired by then), and a silent-window push is superseded by the next tick anyway. Nothing transient ever reaches the poison queue.
  - *Unexpected* (payload bug, `403 InvalidProviderToken` after a .p8 key rotation, `400 TopicDisallowed`, any unhandled exception): the function throws; after `maxDequeueCount` (5) the runtime moves the message to the **poison queue `apns-push-poison`** (auto-created, name fixed by the Functions runtime). This is purely a *diagnostic inbox*: it tells us something is broken and keeps sample messages for debugging. Its contents are by construction stale and are **not replayed** — the fix (rotate key, deploy bug fix) takes longer than a push stays useful. Operate it as: timer function logs the poison-queue depth at `Warning` whenever > 0 (drive an App Insights alert from that), inspect/purge via the Azure Portal storage browser. No dedicated replay/admin function.
- Log status codes and APNs `reason` strings only, never payloads or full tokens (first/last 4 chars for correlation).
- Latency: set `queues.maxPollingInterval` to ~2–5 s in `host.json` so pushes leave within seconds of enqueue; end-to-end accuracy ≈ ±1 min (timer granularity) — acceptable.
- Secrets (`Apns:KeyId`, `Apns:TeamId`, `Apns:P8` as base64, `Apns:BundleId`) in Function App settings (Key Vault reference optional), never in the repo; add to `local.settings.json` template + README.

**Optional refinement (not required):** for `deadline` schedules the API could enqueue the message immediately with a queue `visibilityTimeout = fireAt − now` (max 7 days) and skip the timer entirely; cancellation would then rely solely on the consumer-side row check. Keep the timer regardless for `window` schedules, so the simple uniform design above is the baseline.

### Feasibility & running-cost estimate

**The app runs on Flex Consumption, not the classic Consumption plan.** Checked
31.08.2026: `solarlens-upload-func` (resource group `solarlens_prod`, West
Europe) sits on plan `ASP-solarlensprod-75d6`, SKU **FC1 / FlexConsumption**,
`instanceMemoryMB: 2048`, `alwaysReady: []`. That matters, because Flex bills
differently from the plan the first version of this estimate assumed.

Flex Consumption, pay-as-you-go: a monthly free grant of **250,000 executions
and 100,000 GB-s per subscription**, then $0.40 per million executions and
$0.000026/GB-s. GB-s is *instance memory × active time*, so at 2 GB every
second of execution costs 2 GB-s. Enabling **Always Ready instances would
remove the free grant entirely** — it is currently off and should stay off.

Assumptions: ~300 installs; realistically 50–100 with a monitor or a
Battery → Car run active (a threshold monitor stays enabled for days, so its
window is effectively 24×7); `window` cadence 15 min ⇒ 96 pushes/day per active
device; deadlines 1–2/day per user who schedules one.

| Item | Realistic (~100 active) | Worst case (300 active) |
|---|---|---|
| Timer executions (1/min) | 43,200 | 43,200 |
| Queue executions (1 per push) | ~290,000 | ~865,000 |
| **Executions total vs. 250k free** | ~330k → ~80k billable ⇒ **≈ $0.03** | ~910k → ~660k billable ⇒ **≈ $0.26** |
| GB-s (2 GB × active time; the timer alone dominates) | tens of thousands — a large share of the 100k grant | likely over the grant ⇒ single-digit $ |
| Table + queue transactions | < $0.20 | < $0.60 |
| Storage, egress to APNs, APNs itself | ≈ $0 | ≈ $0 |
| Application Insights | free (5 GB grant) with timer logs at `Warning` | free |
| **Total incremental** | **≈ $0.5–2/month** | **≈ $2–6/month** |

Still small money, but — unlike the earlier estimate — **not automatically
inside the free grant**. The two levers, in order of effect:

1. **Instance memory.** Flex allows smaller instances; going from 2048 MB to
   512 MB cuts every GB-s by 4×. The image-upload function handles 8 MB files,
   so it is plausibly enough, but this affects the existing tvOS feature too —
   measure before changing.
2. **Timer cadence.** Every two minutes instead of every minute halves 43k
   executions and their GB-s, at the price of up to 2 min accuracy on a
   deadline. Alternatively schedule deadline pushes directly with a queue
   `visibilityTimeout` (see the refinement above) and let the timer serve only
   the silent windows.
3. **Silent-window cadence** is the linear driver of the queue executions:
   30 min instead of 15 halves them. Windows must keep being cancelled when
   work ends — an idle install must generate zero traffic.

Other notes:

- Keep App Insights sampling on and the timer function at `Warning`, otherwise
  43k invocations/month of `Information` logs become the largest line.
- Timer precision is "the minute, plus cold-start jitter" ⇒ ≈ ±1 min end to
  end, which matches the goal. A sub-minute guarantee would need a
  Premium/App Service plan (≈ $150+/month) and is explicitly not worth it.
- Single region, no redundancy: acceptable, because the client keeps the
  local-notification + BG-task fallback. Downtime degrades timing, nothing else.
- APNs key rotation and the Apple Developer account become new operational
  secrets; documented in the server README.
- Set a subscription budget alert (e.g. CHF 5/month) as a tripwire — cheaper
  than being surprised.

### One-time setup: Apple Developer, Xcode, Azure

Everything below is manual configuration outside the code and must be done once (per environment). Recorded here so it is not rediscovered later; the server README gets the Azure part, this story is the checklist.

**A. Apple Developer portal (developer.apple.com → Certificates, Identifiers & Profiles)**

1. **APNs auth key (.p8)** — developer.apple.com → *Certificates, Identifiers & Profiles* → **Keys** → "+" → name it (e.g. "Solar Lens APNs") → tick **Apple Push Notifications service (APNs)** → Continue → Register → **Download**. The `.p8` can be downloaded **only once**; store it in the password manager. Note the **Key ID** (10 chars, shown on the confirmation page) and the **Team ID** (`UYT5K989XD`). One key covers sandbox *and* production and every app ID of the team — no per-app certificates and no yearly expiry (Apple allows at most **two active APNs keys** per account, so keep one spare slot for rotation).
2. **App ID `com.marcduerst.SolarManagerWatch`** — *Identifiers → App ID → Capabilities:* enable **Push Notifications** (no certificate needed with token auth) and **App Groups**. (Keychain Sharing is already enabled — access group `…SolarManagerWatch.Shared`.)
3. **App Group** — *Identifiers → "+" → App Groups →* e.g. `group.com.marcduerst.SolarManagerWatch` → then assign it in the App IDs of the iOS app, the new NSE, and (if they should read automation state) `…Solar-Lens-iOS-Widgets` / `…Solar-Lens-iOS-LiveActivities`.
4. **New App ID for the NSE** — `com.marcduerst.SolarManagerWatch.NotificationService` (must be prefixed by the app's bundle id) with capabilities **App Groups** + **Keychain Sharing**. Extensions do not need Push Notifications themselves.
5. **Provisioning profiles** — with Xcode automatic signing this happens on its own once the capabilities are toggled in Xcode; with manual profiles regenerate the iOS app profile (now containing `aps-environment` + app group) and create one for the NSE. Widget/LA profiles only change if they get the app group.

**B. Xcode project**

1. iOS target → *Signing & Capabilities* → **+ Push Notifications** (adds `aps-environment` to `Solar Lens iOS.entitlements`; Xcode uses `development` for debug builds and the App Store/TestFlight pipeline swaps in `production`) and **+ App Groups** (`group.com.marcduerst.SolarManagerWatch`).
2. iOS target → *Background Modes* → tick **Remote notifications** (adds `remote-notification` to `UIBackgroundModes` in `Solar-Lens-Info.plist`, next to the existing `fetch`/`processing`). Required for silent pushes (mechanism 2) — not for the NSE.
3. *File → New → Target → Notification Service Extension* → name "Solar Lens iOS NotificationService", bundle id as above, embed in the iOS app. Add **Keychain Sharing** with the existing access group `$(AppIdentifierPrefix)com.marcduerst.SolarManagerWatch.Shared` and the **App Group** to its entitlements. Keep its deployment target = iOS app's; link only `Shared/` sources.
4. Check `KeychainHelper.serviceName` / access group are reachable from the extension (same values, `kSecAttrAccessGroup` already set).
5. Verify with a **sandbox** push on a debug build (see D) — the token for a debug build is a sandbox token, the same device produces a *different* production token for a TestFlight/App Store build. The app must send `environment` accordingly (`#if DEBUG` → `sandbox`, else `production`; TestFlight builds use **production** APNs).

**C. Azure (existing Function App + storage account)**

1. **App settings** (Portal → Function App → Environment variables, or `az functionapp config appsettings set`): `Apns__TeamId=UYT5K989XD`, `Apns__KeyId=<Key ID>`, `Apns__P8=<base64 of the .p8 file contents>`, `Apns__BundleId=com.marcduerst.SolarManagerWatch`. Optionally store the P8 in Key Vault and reference it (`@Microsoft.KeyVault(...)`). Never commit them; add placeholder entries to `local.settings.json` (git-ignored) and document in the README.
2. **Storage**: table `WakeSchedules` and queue `apns-push` are created on first use by the code (`CreateIfNotExists`); the runtime creates `apns-push-poison` on demand. The existing `BlobStorageConnectionString` / `AzureWebJobsStorage` connection is reused — no new resource.
3. **host.json**: `queues.maxPollingInterval` ≈ `00:00:05`, `queues.maxDequeueCount` 5, function-level log levels (`Function.WakeTimer` → `Warning`).
4. **Application Insights alert**: log-based alert on the "poison queue depth > 0" warning and, optionally, on queue-function failure rate. Optional: enable a cost alert/budget on the subscription (e.g. CHF 5/month) as a tripwire.
5. Deploy as today (`func azure functionapp publish` / existing pipeline); the timer starts firing immediately — make sure the table is empty or valid on first deploy.

**D. Testing without the server**

- **Simulator: not usable for this.** Verified on 29.08.2026 with an iOS 26.5 simulator: `xcrun simctl push` delivers the payload through `CoreSimulatorBridge` as a *local* notification request, so `mutable-content` is ignored and the extension never launches. The simulator also never hands the app an APNs device token — `registerForRemoteNotifications()` is called and neither delegate callback fires. Everything push-related therefore needs a device.
- **Device, without our server**: Apple's **Push Notifications Console** at <https://icloud.developer.apple.com/dashboard/notification> (sign in with the developer account; also reachable from developer.apple.com → iCloud dashboards). Paste the device token, choose *Development* (a debug build's token is a sandbox token), paste the payload, send. It keeps a 30-day delivery history, which is the fastest way to tell "APNs accepted it" from "the device dropped it".
- The device token is logged by the app: watch for it in the Xcode console after granting notification permission, or read `SolarLens.apnsDeviceToken` from the App Group.
- Attach Xcode to the NSE process (*Debug → Attach to Process by PID or Name → "Solar Lens iOS NotificationService"*) to debug it; `os_log` lines show in Console.app.

**E. App Store Connect / privacy**

- App Privacy (App Store Connect → the app → *App Privacy*): add **Device ID → App Functionality, not linked to the user's identity, not used for tracking** (the APNs token). Privacy answers can be updated **without submitting a new build**, so this can be done before or after the release build.
- No new App Review questionnaire is triggered by push / NSE / app groups; TestFlight internal builds are enough to validate production-APNs delivery.
- **Privacy manifest:** the project has **no `PrivacyInfo.xcprivacy`** today. That predates this story, but 2026 App Store submissions are being checked for it, and the app uses required-reason APIs (`UserDefaults`, file timestamps). Worth adding before the next release — a separate, small piece of work, not part of this story.

### App-side plumbing

- Enable **Push Notifications** capability + `remote-notification` background mode; `registerForRemoteNotifications()` after notification authorization; upload/refresh the token on `didRegisterForRemoteNotificationsWithDeviceToken` (tokens rotate — re-sync active schedules whenever it changes).
- New target **"Solar Lens iOS NotificationService"** with the shared Keychain access group + new App Group entitlement (add the App Group to the iOS app, the NSE, and — if they read automation state — the widget/LA extensions).
- `AutomationTask` gets an explicit, UI-free entry point usable from the NSE (e.g. `runDeadlineTick(host:)`), so the NSE and the main app share the exact same decision code.
- Settings: a toggle "Server-assisted timing" (default **on**, with a one-line privacy explanation and a link to what is sent). Turning it off deletes the device's schedules on the server and falls back to today's behaviour. *(Assumption — flip to opt-in if you prefer a stricter default.)*
- Watch app: no changes beyond the existing watch bridge (the watch reflects whatever state the iOS app restores).

### Out of scope

- **State-driven automations** (PV-surplus triggers etc.): the server cannot evaluate conditions without API access (privacy violation), and silent pushes remain throttled. They stay on BGTasks + mechanism 2 as best effort; a separate concept if needed.
- Live Activity updates via push, Solar Manager webhooks/native notifications (re-check availability, per story #6 note), and an account/login for the server.

## Expected Result

- An Auto-reset Charging Mode run whose end time has passed **actually resets the charging station within ~1 min of `resetAt`**, even with the app suspended, the phone idle, or the app force-quit — as long as notifications are enabled and the device has connectivity.
- The notification the user sees reflects the **real outcome** (mode applied ✓ / error with a call to action), never a stale "open the app" message on the happy path; no duplicate notifications.
- If the server, APNs or the NSE fails, behaviour degrades gracefully to **exactly today's** local-notification + BGTask behaviour.
- Battery → Car runs and threshold monitors receive additional silent-push wakes while active, improving average timeliness; all existing on-device safety mechanisms remain unchanged.
- **Privacy**: the server stores only APNs device tokens, environment, timestamps and cadence; no credentials, tokens, rules, or Solar Manager data. This is documented in an ADR, `architecture.md`, `risks.md`, the server README and the privacy label.
- Users can disable server-assisted timing in Settings; the server receives nothing from installs that have no active automation/monitor.

## Test Checklist
- [x] App builds successfully (iOS incl. the new NSE target, watchOS, tvOS; also verified from Xcode itself)
- [ ] App runs correctly on watchOS Simulator
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [ ] Simulator: `xcrun simctl push` with a `mutable-content` payload launches the NSE, which executes a due Auto-reset tick and rewrites the notification text
- [ ] Device: NSE executes the reset after the app was force-quit; main app on next launch shows the run as finished with the log entry written by the NSE
- [ ] Device: no duplicate notification on the happy path; local fallback fires when the push is withheld (server disabled)
- [ ] Device: NSE timeout shows the default payload and the app reconciles on next launch
- [ ] Device: notifications disabled → BGTask/local-notification behaviour unchanged
- [ ] Device: silent-push wake triggers a tick for Battery → Car and for an active threshold monitor; window is cancelled when the run ends
- [ ] Server: schedule upsert/delete/re-sync on token rotation; `410 Unregistered` cleans up rows; sandbox and production environments both deliver
- [ ] Server: invalid token (`410`) deletes the device's rows and does not retry; a simulated APNs `503` re-enqueues with delay and is dropped after `fireAt + 10 min`; an unexpected exception lands in `apns-push-poison` and the timer logs its depth
- [ ] Server: no Solar Manager data, no credentials in storage/logs (review + document)
- [ ] /specs have been updated (`architecture.md` Infrastructure + runner sections, `risks.md` new server dependency, `userinterface.md` settings toggle, server README)
- [ ] If architectural decisions were made, an ADR was created in /specs/adrs (ADR-006 supersedes the "no APNs" part of ADR-001)
- [ ] Story status has been set to "Done (DD.MM.YYYY)"
- [ ] Story file has been moved to /specs/stories/done/
- [ ] Story has been removed from the backlog

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
- [x] Add the App Group entitlement to the iOS app; Push Notifications capability (`aps-environment`) added at the same time — **note:** the next *device* build needs App Groups and Push enabled on the App ID `com.marcduerst.SolarManagerWatch` (automatic signing usually adds them on first build, otherwise enable them in the portal)
- [x] Add `Solar Lens iOS NotificationService` target with Keychain access group + App Group; dependencies kept to a curated `Shared/` subset (services and models only — no UI folders, no `State/`, and no `LocationManager` / `AppStoreReviewManager` / `SolarWeatherService` / `BatterySimulator` / `FakeEnergyManager`)
- [x] Extract a UI-free deadline path from `AutomationAutoResetChargingMode` / `AutomationManager` reusable by the NSE (`AutoResetCompletion`); shared-store lease added on both sides to avoid double execution
- [x] NSE: load token + state, run tick, persist outcome + log, rewrite notification content, cancel pending local fallback notification; honest default payload text (`NotificationService.swift`, `AutomationPushPayload`, `AutomationExternalOutcome`)
- [x] App reconciles a run finished by the extension: `AutomationManager.adoptExternalCompletionIfNeeded()` ends the Live Activity, refreshes the UI and posts no duplicate notification
- [x] iOS, watchOS and tvOS targets build with the new shared code (new files excluded from the tvOS and watch-widget targets, which do not compile the automations folder)
- [x] App Group verified end to end in the simulator: the app writes `automation-logs.json` into the shared container, and the extension's simulated entitlements carry the app group plus the Shared keychain group
- [x] **Push-triggered execution verified on device (31.08.2026, iPhone 16 Pro, iOS 26.6.1, debug build, APNs sandbox via Apple's Push Notifications Console).** With the app **force-quit** and the reset time passed, the push launched the extension, it applied the after-reset mode against the live Solar Manager API, and the banner already showed the result instead of the server's default text. A push sent *before* the reset time correctly took the `notDue` path: nothing was touched and the default payload text was shown. The automation log shows the same sequence
- [x] Notification copy fixed after the device test: the title is the automation's name instead of "… finished/cancelled/stopped", which truncated in the banner in every language (de 34, en 33, fr 40, da 41, it 43 characters against ~30 that fit) and repeated what the body already said
- [x] **End-to-end via our own server verified (31.08.2026).** The app registered the schedule itself (`DefaultTitle`/`DefaultBody` already localized on the device), the minute timer picked it up, the queue sender delivered it, and the extension finished the run **8 seconds** after the scheduled time — against minutes to hours before. The deadline row was deleted after the successful send, the poison queue was never created
- [x] Three defects found by that testing and fixed (PR #97): the reset fired a minute late (`+60 s` in the setup sheet, while watchOS sent the picked value unchanged — the platforms disagreed); a second push arrived because `registerWakeSchedule` minted a new `scheduleId` on every call and the foreground re-sync therefore added a server row per app launch; and the Lock Screen Live Activity was clipped top and bottom (~208 pt of content against roughly 160 pt), which had been an unverified risk since story #4
- [x] The re-sync no longer calls the server on every launch (a registration younger than 12 h is trusted); at 300 users and ten launches a day that would have been ~90k executions a month against Flex Consumption's 250k free grant
- [x] Wake-schedule problems are logged at Info instead of Debug — the log hides Debug by default, so a silent fallback to background execution looked like a perfectly normal log
- [ ] Still open on device: the NSE-timeout path and the notifications-disabled fallback
- [ ] ~~Verify push-triggered execution~~ — **`xcrun simctl push` cannot do this**: on the iOS 26.5 simulator it delivers the payload through `CoreSimulatorBridge` as a *local* notification request (visible in the device log as "Adding notification request"), which ignores `mutable-content` and never launches the extension. Needs a real device with a real APNs push (i.e. the `.p8` key from the one-time setup), including the force-quit case

### Slice 2 — Server scheduler (extend Solar Lens .NET Azure Functions)
- [x] Add `Azure.Data.Tables`, `Azure.Storage.Queues`, `Extensions.Storage.Queues`, `Extensions.Timer` packages; Azurite table/queue for local dev
- [x] `WakeScheduleService` (Azure Table `WakeSchedules`, install-secret hashing, validation/clamping of cadence/until, token format check, device purge, catch-up window)
- [x] HTTP functions `PUT/DELETE/GET /api/wake/…` with `RateLimitService`
- [x] Timer function (`0 * * * * *`): select due rows (with 15-min catch-up), enqueue one message per push, park deadlines / advance windows, daily defensive cleanup
- [x] Queue function: `ApnsClient` (HTTP/2, ES256 JWT cache, sandbox/production hosts, headers incl. `apns-expiration`/`collapse-id`), row re-check for idempotency; invalid token → delete device rows, no retry; transient → self re-enqueue with `visibilityTimeout` until `fireAt + 10 min`, then drop with `Warning`; unexpected → throw → poison queue; one message = one push (no batching)
- [x] Poisoned pushes are reported the moment they land, by a queue trigger on `apns-push-poison` that logs at `Error` — not by a once-a-day depth check
- [x] Application Insights alert created (01.09.2026): action group `solarlens-alerts` → `marc@marcduerst.ch`, log-search rule `solarlens-push-pipeline`, hourly, fires on any exception in `ApnsSender` / `WakeUpsert` / `DailyHousekeeping` or on a poisoned push. The query was run against live telemetry first, so it is known to parse and to return 0 while healthy
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
- [x] Push capability + `remote-notification` background mode; token registration and refresh handling (`PushRegistrar`, registers only once notifications are actually authorized); `environment` sandbox/production per build configuration
- [x] `WakeScheduleClient` in `Shared/`: upsert on automation start, cancel on finish/cancel/external completion, `forgetDevice` for the opt-out; re-sync on foreground and on token rotation. Per-install secret generated into the keychain (`KeychainHelper.installSecret`). Debug builds can point at a local Functions host via the `SolarLens.wakeApiBaseUrl` user default
- [x] Move existing local reset-due notification to `resetAt + 2 min` as fallback; wording unchanged
- [x] Settings toggle "Server-assisted timing" (default on) with a privacy explanation; off → `forgetDevice` removes everything this device has on the server
- [x] Setup-sheet copy: the reset now happens on time via a notification, and notifications must stay enabled

**Verified against the local Functions host**: the exact payload the client
builds is accepted (`PUT` → 204), `GET` returns the row with the automation
echoed back, `DELETE` with the `X-Install-Secret` header works and is
idempotent, and the device-wide delete behind the Settings toggle clears every
row.

**Verified in the simulator with a real Solar Manager login and a real
Auto-reset run** (29.08.2026): the automation started, applied the active
charging mode, and at its reset time the shared `AutoResetCompletion` —
the very code the extension calls — switched the charging station to the
after-reset mode against the live API and finished the run. The registration
path also executed and logged the honest skip, "No server wake-up scheduled:
no APNs device token yet".

**The simulator cannot issue an APNs device token.** `apsd` enables the app's
topic locally (so `simctl push` can deliver) but no token is ever handed to the
app: `registerForRemoteNotifications()` is called, and neither
`didRegisterForRemoteNotificationsWithDeviceToken` nor the failure callback
fires. Together with the `simctl push` limitation above, this means **every
push-dependent part of this story can only be verified on a device**. What the
simulator does prove: the App Group, the shared state, the deadline logic
against the real API, and that the registration path degrades honestly when
there is no token.

One bug found by that run: `@UIApplicationDelegateAdaptor` instantiates its
*own* delegate object, so the app configured `PushRegistrar.shared` while the
system delivered the token callback to a different instance — the token would
never have been forwarded. The delegate's state is static now.

*Tip for the next simulator session:* set user defaults with
`xcrun simctl spawn <device> defaults write <bundle id> <key> <value>` —
writing the preferences plist directly is silently discarded by `cfprefsd`.

### Slice 4 — Silent-push wake window for Battery → Car and Notifications
- [x] Register/extend/cancel wake windows from `AutomationManager` (Battery → Car) and `NotificationManager` (active monitors) — one shared window per device (`WakeWindowCoordinator`), 15-min cadence, 6 h validity, renewed while work is running. Deliberately **not** registered for `AutoResetChargingMode`, which idles until its reset time and is covered by the visible deadline push
- [x] Handle `didReceiveRemoteNotification` → shared drain routine (`AutomationManager.handleRemoteWake()` runs the active automation, checks due monitors) and re-arms the BG tasks, so a push leaves the on-device schedule exactly as a BG wake would
- [x] Server: cadence-based silent push sending until `until`; stops when the window is deleted or expires
- [x] `WakeScheduleClient.registerWindow` + window bookkeeping persisted across launches

**Verified against Azurite** (11 checks): registration produces a silent
schedule due one cadence later; renewal keeps a single row, extends `until`
and — the important one — does **not** postpone the pending push; the cadence
skips slots the device slept through; cancelling and expiry both stop the
pushes; a too-aggressive cadence is clamped server-side.

Two defects found and fixed while testing:
- Renewal recomputed the next fire time, so every cold start (and every
  renewal) pushed the next silent wake 15 minutes further out — on a phone the
  user opens regularly, the silent pushes would effectively never fire. The
  server now keeps a pending fire time and only extends the window.
- The coordinator kept its "registered until" state in memory only, which made
  every launch look like a fresh registration; it is persisted now.

### Slice 5 — Fallbacks, docs, measurement
- [ ] NSE timeout / notifications-disabled / server-down paths verified on device — **needs a device**
- [x] On-device measurement (local only, in the automation log): every reset logs how many seconds after the scheduled time it actually ran, and the log line differs by path ("reset completed" from the app, "reset completed via push" from the extension). Together that answers "did the push arrive, and how late were we" without any telemetry leaving the device
- [x] Update `architecture.md` (runner table now covers force-quit and push wakes; new "Scheduled Automations via Remote Push" section; App Group persistence; Infrastructure now describes both server jobs; principle about credentials never leaving the device)
- [x] Update `risks.md` (server outage now degrades timing rather than breaking anything; new APNs key / device-token risk entry with its blast radius and mitigations; credential section notes the wake scheduler never receives credentials)
- [x] `userinterface.md` — **no change needed**: it documents the design system (colours, typography, components), not individual screens; the Settings toggle introduces no new component
- [ ] Privacy: the App Store privacy label needs "Device ID → App Functionality, not linked to the user, not used for tracking" — part of the one-time setup. The repo has no privacy-policy page; the landing pages claim "no tracking, no data collection, your data stays with you", which stays accurate (the APNs token is neither tracking nor energy data), but it is worth a conscious owner decision before release
- [x] Translations for the 25 new strings (de/da/fr/it, 100 entries) — 8 are user-visible (Settings section and toggle, its privacy caption, the setup-sheet footer, the push fallback text and three notification texts written by the extension); the other 17 are automation-log lines, which are localized because the log is a user-facing screen
- [x] Fixed a localization bug found while translating: two log messages interpolated an English clause built in Swift, so part of the sentence would have stayed English in every language. Each variant is its own key now
