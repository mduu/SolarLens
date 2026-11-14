# Story: #10, Login with Solar Manager API Keys

**Status:** Open

## Short Description

Solar Manager deprecated the email/password login (`/v1/oauth/login`, `/v1/oauth/refresh`) in May 2026 and will **remove it in June 2027**. Solar Lens must switch to API Keys and `POST /v3/auth/refresh` on all platforms and migrate existing users before that date, or the app stops working.

## Additional Information

### What changes in the Solar Manager API (v1.91.4)

| | Today (v1) | New (v3) |
|---|---|---|
| Credential | Email + password | API Key, created by the user in Solar Manager |
| Endpoint | `POST /v1/oauth/login`, `POST /v1/oauth/refresh` | `POST /v3/auth/refresh` |
| Request | `{ email, password }` / `{ refreshToken }` | `{ grant_type: "refresh_token", refresh_token: <API Key or last refresh token> }` |
| Response | camelCase: `accessToken`, `refreshToken`, `expiresIn`, `tokenType`, `accessClaims` | snake_case: `access_token`, `refresh_token`, `expires_in`, `token_type`, `scope` |
| Access token lifetime | — | 1 hour |
| Removal | 2027-06 | — |

- The API Key is treated as a refresh token. Solar Manager asks clients not to send it with every request but to exchange it for a short-lived Bearer access token.
- **Key rotation (optional, per key):** when enabled, every refresh returns a new refresh token and *immediately invalidates the previous one*; refresh tokens are then valid for 30 days. Without rotation the key itself stays valid.
- The swagger also lists an `x-api-key` header scheme, but which endpoints accept it directly is not documented. Do not rely on it.
- Related: `/v1/info/sensors/{smId}` is removed in 2027-05 (→ `/v3/users/{smId}/devices`). That migration is separate, but should ship in the same time frame.

See `specs/solarmanager_api.md` (changelog v1.91.4) and `externals/sm_api_swaggers/swagger_1.91.4.json`.

### How Solar Lens authenticates today

- `SolarManagerApi.login()` / `refresh()` in `Shared/Services/SolarManagerApi/SolarManagerApiClient.swift` call the v1 endpoints.
- `SolarManager.doLogin()` stores **email and password** in the keychain (`KeychainHelper.saveCredentials`). `handleOnTokenExpired()` first tries a refresh, then falls back to a fresh credential login with the stored password.
- Tokens and credentials live in a **shared, iCloud-synchronized keychain** (`KeychainHelper`, access group `…SolarManagerWatch.Shared`, `synchronizable(true)`). iPhone, iPad, Watch, Apple TV, widgets, Live Activities and the Notification Service Extension all read the same values.
- Login UIs: iOS onboarding, watchOS `SettingsView`, tvOS (BigScreen).
- `SolarManager` already deduplicates concurrent refreshes *within one process* (`activeRefreshTask`), because a competing refresh invalidates the other token. Across processes and devices there is no such coordination.

### Key problem: rotation vs. shared keychain

With rotation enabled, two devices (or the app and an extension) sharing the same refresh token will race: the first refresh invalidates the token the second one holds, and the second device is logged out. Today the password fallback hides such failures; after the migration there is no fallback.

Options:
- **A — Support keys without rotation only (recommended).** Store the API Key itself; every process exchanges it independently for its own access token. No coordination needed. Detect a rotating key (refresh token in the response differs from the key) and show a clear message asking the user to create a key without rotation.
- **B — Per-device keys, non-synchronized tokens.** Works with rotation, but every device needs its own key — poor UX on Watch and Apple TV.
- **C — iPhone as the only refresher, distributes access tokens.** Supports rotation with one key, but Watch/TV/widgets depend on the iPhone being reachable. Complex.

Decide in an ADR (see tasks).

### UX constraints

- Target audience are homeowners, not engineers. Creating and pasting an API Key is a technical step — the onboarding needs a short, illustrated guide ("where do I find my API Key?") and paste-from-clipboard support.
- Typing a long key on Apple Watch or Apple TV is not acceptable. These devices should receive the key from the iPhone through the synchronized keychain (as credentials do today), with a fallback (e.g. QR code / pairing from the iPhone on tvOS).
- Existing users must be told well before June 2027, in a calm, non-alarming way, and guided through the switch in a few taps.

### Open questions (clarify with Solar Manager before implementation)

- Where and how does an end customer create an API Key (Solar Manager app, web portal, only via installer)?
- Is rotation on or off by default? Can the user choose?
- Does an API Key have the same permissions as the user login, including the control endpoints (battery, car charger, sensor priority)?
- Can one account have several keys (one per device, option B)?
- Is there a way to create a key programmatically from an authenticated session (would allow a one-tap migration for existing users)?

### Privacy

The API Key is a credential like the password. ADR-001/ADR-006 apply unchanged: it never leaves the user's devices and is never sent to the Solar Lens server.

## Expected Result

- New users sign in with a Solar Manager API Key on iOS; Watch and Apple TV pick it up without manual typing.
- Existing users are prompted in time to add an API Key; after the switch, the stored email and password are deleted from the keychain.
- No call to `/v1/oauth/login` or `/v1/oauth/refresh` remains in a release shipped before 2027-06.
- Background work (automations, push wake-ups, widgets, Notification Service Extension) keeps getting valid access tokens without user interaction.
- The new login ships to the App Store **by spring 2027 at the latest**, so the migration hint reaches users weeks before the removal.

## Test Checklist
- [ ] App builds successfully
- [ ] App runs correctly on watchOS Simulator
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [ ] Login and token refresh verified on iOS, watchOS and tvOS with a real API Key
- [ ] Migration from an existing email/password install verified (credentials removed afterwards)
- [ ] Background refresh verified (widget timeline, automation wake-up, Notification Service Extension) with expired access token
- [ ] Behaviour with a rotating key verified (clear error, no silent logout loop)
- [ ] /specs have been updated if necessary
- [ ] If architectural decisions were made, an ADR was created in /specs/adrs
- [ ] Story status has been set to "Done (DD.MM.YYYY)"
- [ ] Story file has been moved to /specs/stories/done/
- [ ] Story has been removed from the backlog

## Tasks

- [ ] Clarify the open questions with Solar Manager (key creation, rotation default, permissions, multiple keys)
- [ ] ADR: token strategy with the shared keychain (option A/B/C)
- [ ] API client: `POST /v3/auth/refresh` with new request/response DTOs (snake_case)
- [ ] `KeychainHelper`: store the API Key (synchronized, shared access group); keep tokens per strategy from the ADR
- [ ] `SolarManager`: replace credential login and password fallback in `handleOnTokenExpired()` with the API Key exchange; detect rotating keys
- [ ] iOS onboarding: API Key entry with paste support and a short guide where to find the key
- [ ] watchOS `SettingsView` and tvOS login: use the key from the synchronized keychain; fallback for tvOS (QR / pairing)
- [ ] Migration for existing users: in-app hint with deadline, guided switch, delete stored email/password afterwards
- [ ] Remove the password from log output in `SolarManagerApi.login()` (currently printed on failure) — can be done right away
- [ ] Wiki / landing page: how to create an API Key
- [ ] Translations (en, de, da, fr, it)
- [ ] Remove the v1 auth code once the migration release is out
- [ ] Update `specs/solarmanager_api.md` and `specs/architecture.md`
