# Solar Manager API – Change Tracking

## Purpose

This document tracks changes to the [Solar Manager external API](https://external-web.solar-manager.ch/swagger) that are relevant to Solar Lens. The Solar Manager API is the single integration point for all Solar Lens data and functionality — any breaking change, deprecation, or new endpoint directly impacts the app.

## How to use this file

1. **Periodically** download the latest swagger from https://cloud.solar-manager.ch/swagger.json (redirects to `/solarManager/swagger.json` — use `curl -L`)
2. **Diff** it against the current baseline in `externals/sm_api_swaggers/`
3. **Document** any relevant changes below (new endpoints, removed endpoints, changed parameters, deprecations)
4. **Save** the new swagger file in `externals/sm_api_swaggers/` with its version number (e.g., `swagger_1.58.0.json`)
5. **Update** the baseline reference below

## Links

- **Swagger UI:** https://external-web.solar-manager.ch/swagger
- **Swagger JSON:** https://cloud.solar-manager.ch/swagger.json
- **Local copy:** [`externals/sm_api_swaggers/`](../externals/sm_api_swaggers/)

---

## Endpoints Used by Solar Lens

Overview of which Solar Manager API endpoints Solar Lens currently calls, mapped to features.

### Authentication

| Method | Endpoint | Features | Deprecated? |
|--------|----------|----------|-------------|
| POST | `/v1/oauth/login` | Login (all platforms) | ⚠️ **Yes** — since 2026-05, removal **2027-06**. Replaced by API Keys + `/v3/auth/refresh` |
| POST | `/v1/oauth/refresh` | Automatic token refresh / session management | ⚠️ **Yes** — since 2026-05, removal **2027-06**. Replaced by `/v3/auth/refresh` |

### Data – Read

| Method | Endpoint                            | Features                                                      | Deprecated?                                                                            |
| ------ | ----------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| GET    | `/v1/users`                         | System info, gateway discovery, account setup                 | —                                                                                      |
| GET    | `/v1/info/sensors/{smId}`           | Sensor/device discovery, battery & charger detection          | ⚠️ **Yes** — since 2026-05, removal **2027-05**. Replaced by `/v3/users/{smId}/devices` |
| GET    | `/v1/chart/gateway/{smId}`          | Dashboard real-time energy flow                               | —                                                                                      |
| GET    | `/v1/overview`                      | Energy overview statistics                                    | —                                                                                      |
| GET    | `/v1/statistics/gateways/{smId}`    | Today's stats, daily/weekly/monthly statistics, solar details | —                                                                                      |
| GET    | `/v1/consumption/sensor/{sensorId}` | Car charging history, charging data                           | —                                                                                      |
| GET    | `/v3/devices/{deviceId}/data/range` | Battery charge/discharge history                              | —                                                                                      |
| GET    | `/v3/users/{smId}/data/forecast`    | Solar forecast (today, tomorrow, day after)                   | —                                                                                      |
| GET    | `/v3/users/{smId}/data/stream`      | Dashboard device power status                                 | —                                                                                      |
| GET    | `/v3/users/{smId}/data/range`       | Detailed energy data, production/consumption graphs           | —                                                                                      |

### Tariffs – Read

| Method | Endpoint                            | Features                                                                                   | Deprecated? |
| ------ | ----------------------------------- | ------------------------------------------------------------------------------------------ | ----------- |
| GET    | `/v1/tariff/gateways/{smId}`        | V1 tariff fallback (single / high-low / direct-marketing) for cost & savings calculations  | —           |
| GET    | `/v3/users/{smId}/tariffs`          | Detailed import (purchase) & feed-in tariffs incl. time-of-use schedules                    | —           |
| GET    | `/v3/users/{smId}/tariff/dynamic`   | Dynamic / spot import prices (time-series, CHF/kWh) — Story #8 battery savings & what-if    | —           |

### Control – Write

| Method | Endpoint | Features | Deprecated? |
|--------|----------|----------|-------------|
| PUT | `/v2/control/battery/{sensorId}` | Battery mode control (eco, peak shaving, tariff-optimized, etc.) | — |
| PUT | `/v1/control/car-charger/{sensorId}` | EV charger mode control (off, solar, grid) | — |
| PUT | `/v1/configure/sensor-priority/{sensorId}` | Device priority reordering | — |

---

## Current Baseline

| Field | Value |
|-------|-------|
| **API Title** | Solar Manager external API |
| **Version** | 1.91.4 |
| **Local file** | `externals/sm_api_swaggers/swagger_1.91.4.json` |
| **Date recorded** | 2026-11-14 |

### Endpoint Summary (v1.91.4)

#### Auth (3 endpoints)

| Method | Endpoint | Notes |
|--------|----------|-------|
| POST | `/v1/oauth/login` | **DEPRECATED** — Email/password login. Deprecated 2026-05, removal 2027-06. Switch to API Keys + `/v3/auth/refresh` |
| POST | `/v1/oauth/refresh` | **DEPRECATED** — Refresh access token. Deprecated 2026-05, removal 2027-06. Use `/v3/auth/refresh` |
| POST | `/v3/auth/refresh` | **NEW** — Exchange an API Key (used as refresh token, `grant_type=refresh_token`) for a 1 h access token. With key rotation enabled, every call returns a new refresh token and invalidates the old one (valid 30 days) |

Security schemes: `bearerAuth` (JWT), `apiKey` (`x-api-key` header), `basic`.

#### Users (14 endpoints)

| Method | Endpoint | Notes |
|--------|----------|-------|
| GET | `/v1/users` | Current user info and gateway list |
| GET | `/v1/info/user/{uId}` | User details by ID |
| GET | `/v1/info/gateway/{smId}` | Gateway info (now incl. EEBUS info) |
| GET | `/v1/info/sensors/{smId}` | **DEPRECATED** — All sensors for a gateway. Deprecated 2026-05, removal 2027-05. Use `/v3/users/{smId}/devices` |
| GET | `/v3/users/{smId}/devices` | **NEW** — Devices incl. configuration (type, priority, tag, car name, device-specific `data` object) |
| GET | `/v1/customers/{smId}` | Customer info (v1) |
| GET | `/v2/customers` | All customers (v2) |
| GET | `/v2/customers/{smId}` | Customer info (v2) |
| GET | `/v1/subscription` | Current user subscription |
| GET | `/v1/subscriptions/{userId}` | Subscriptions by user ID |
| GET | `/v1/tariff/gateways/{smId}` | Tariff info |
| GET | `/v1/tariff/gateways/{smId}/dynamic` | **DEPRECATED** — Dynamic tariff info. Deprecated 2025-09, removal 2026-09. Use `/v3/users/{smId}/tariff/dynamic` |
| GET | `/v3/users/{smId}/tariffs` | Tariffs (v3) |
| GET | `/v3/users/{smId}/tariff/dynamic` | **NEW** — Dynamic tariff (v3), replaces `/v1/tariff/gateways/{smId}/dynamic` |

#### Users / Data (13 endpoints, unchanged)

| Method | Endpoint | Notes |
|--------|----------|-------|
| GET | `/v1/overview` | Current state snapshot |
| GET | `/v1/chart/gateway/{smId}` | Chart data (real-time power) |
| GET | `/v1/stream/gateway/{smId}` | Sensor stream data |
| GET | `/v1/data/gateway/{gatewayId}` | Gateway data |
| GET | `/v1/consumption/gateway/{smId}` | Consumption data |
| GET | `/v1/consumption/gateway/{smId}/range` | Consumption range data |
| GET | `/v1/statistics/gateways/{smId}` | Historical statistics |
| GET | `/v1/forecast/gateways/{smId}` | Forecast data |
| GET | `/v1/data/string/{stringId}/range` | **DEPRECATED** — String inverter range data. Deprecated 2025-06, removal 2026-06 (date already passed) |
| GET | `/v1/data/zev/{smId}` | ZEV (multi-tenant) data |
| GET | `/v3/users/{smId}/data/forecast` | Forecast (v3) |
| GET | `/v3/users/{smId}/data/range` | Range data (v3) |
| GET | `/v3/users/{smId}/data/stream` | Stream data (v3) |

#### Devices (20 endpoints)

| Method | Endpoint                                     | Notes                                                                                  |
| ------ | -------------------------------------------- | -------------------------------------------------------------------------------------- |
| GET    | `/v1/info/sensor/{sensorId}`                 | **DEPRECATED** — Sensor/device info. Deprecated 2026-05, removal 2027-05. Use `/v3/users/{smId}/devices` |
| GET    | `/v1/consumption/sensor/{sensorId}`          | Sensor consumption data                                                                |
| GET    | `/v1/data/sensor/{sensorId}/range`           | Sensor range data (v1)                                                                 |
| GET    | `/v3/devices/{deviceId}/data/range`          | Device range data (v3)                                                                 |
| GET    | `/v1/stream/sensor/{smId}/{sensorId}`        | Sensor stream                                                                          |
| GET    | `/v1/supported/devices`                      | **DEPRECATED** — Deprecated 2025-10, removal 2026-10. Use `/v3/devices/supported`      |
| GET    | `/v3/devices/supported`                      | **NEW** — Supported device types (v3), replaces `/v1/supported/devices`                |
| GET    | `/v1/control/tariff`                         | Tariff control info                                                                    |
| PUT    | `/v1/configure/sensor-priority/{sensorId}`   | Set sensor priority                                                                    |
| PUT    | `/v1/control/battery/{sensorId}`             | Control battery (v1)                                                                   |
| PUT    | `/v2/control/battery/{sensorId}`             | Control battery (v2). v1.91: mode 6 renamed "AI Optimization" → **Aria** (+ `mpc*` settings), new `tariff*` limit fields |
| PUT    | `/v1/control/car-charger/{sensorId}`         | Control EV charger. v1.91: modes renumbered/extended (6 = Charging Target kWh, 7 = Charging Target SoC, **8 = Aria**), new schedule fields |
| PUT    | `/v1/control/car-charging-system/{sensorId}` | **NEW** — Control car charging system (modes: Max Performance, Optimized, No Charging) |
| PUT    | `/v1/control/heat-pump/{sensorId}`           | Control heat pump                                                                      |
| PUT    | `/v1/control/inverter/{sensorId}`            | Control inverter                                                                       |
| PUT    | `/v1/control/smart-plug/{sensorId}`          | Control smart plug                                                                     |
| PUT    | `/v1/control/switch/{sensorId}`              | Control switch                                                                         |
| PUT    | `/v1/control/v2x/{sensorId}`                 | **DEPRECATED** — Control V2X device (v1). Use `/v2/control/v2x/{sensorId}`             |
| PUT    | `/v2/control/v2x/{sensorId}`                 | **NEW** — Control V2X device (v2, expanded modes)                                      |
| PUT    | `/v1/control/water-heater/{sensorId}`        | Control water heater                                                                   |

### Known API Notes

- `sensorId` and `deviceId` are identical. All v1 endpoints using `sensorId` will eventually be replaced with v3 endpoints using `deviceId`.
- v3 endpoints continue to expand alongside v1/v2 — several v1 endpoints now have v3 replacements and deprecation timelines.
- **Aria** is Solar Manager's new name for the former "AI Optimization" (MPC-based) mode — battery mode 6, heat pump mode 8, water heater mode 7; new for car chargers as mode 8.
- Car charging system control (`/v1/control/car-charging-system/{sensorId}`) is a new endpoint distinct from the existing car charger control (`/v1/control/car-charger/{sensorId}`).

---

## Changelog

### v1.91.4 (2026-11-14)

**File:** `externals/sm_api_swaggers/swagger_1.91.4.json`
(The swagger URL now redirects to `https://cloud.solar-manager.ch/solarManager/swagger.json`; title is now "Solar Manager External API".)

**New endpoints:**
- `POST /v3/auth/refresh` — API Key based auth: the API Key acts as refresh token and is exchanged for a 1 h access token (`RefreshTokenResponse`, snake_case: `access_token`, `refresh_token`, `expires_in`, `token_type`, `scope`). With key rotation enabled, each call rotates the refresh token (30 days validity).
- `GET /v3/users/{smId}/devices` — Device list with configuration (`DevicesConfigV3Schema`: `_id`, `priority`, `type` enum incl. `battery`, `carcharging`, `carchargingsystem`, `v2x`, `heatpump`, …, `tag`, `carName`, untyped `data` object). Replaces `/v1/info/sensors` and `/v1/info/sensor`.

**Changed endpoints (relevant to Solar Lens):**
- `PUT /v1/control/car-charger/{sensorId}` — `chargingMode` max 7 → 8. Modes now: 6 = Charging Target (kWh), 7 = Charging Target (SoC), **8 = Aria**. New body fields: `chargingTargetSocMax`, `minimumChargeQuantityTargetAmountMax`, `chargingTargetSchedule` / `minimumChargeQuantityTargetSchedule` (per weekday `min`/`max`/`endTime`), `chargingTargetSelectCarIds`.
- `PUT /v2/control/battery/{sensorId}` — mode 6 "AI Optimization" renamed to **Aria** with settings `mpcLowerSocLimit`, `mpcUpperSocLimit`, `mpcChargingFromGrid`. New tariff fields: `tariffPriceMode` (0/1/2), `tariffAbsolute/Percentage/Offset{Charge,Discharge}Limit`, `tariffDischargeSocLimit`, `tariffPriceLimitSocMin`.
- `PUT /v1/control/heat-pump/{sensorId}` (mode 8) and `/v1/control/water-heater/{sensorId}` (mode 7) — "AI Optimization" renamed to Aria, new `mpc*` settings.
- `GET /v3/users/{smId}/data/stream` and `GET /v3/devices/{deviceId}/data/range` — device `soc` changed `integer` → `number`; many new device fields: `mode`, `targetPower`, `targetPercent`, `targetCurrent`, `targetPhases`, `limitType`, `percent`, `currentL1-3`, `voltageL1-3`, `temperatureInside/Outside/Supply/Return`; range additionally `iWhTotal`, `eWhTotal`, `remainingRange`, `updatedAt`.
- `GET /v3/users/{smId}/data/range` — new `fw` (firmware) field per data point.
- `GET /v3/users/{smId}/tariffs` — removed `country` and `dynamicTariff.oauth2TokenId`; added `templateKey`, `solarTariff`, `dynamicTariff.label`, `dynamicTariff.subscriptionId`.
- `GET /v3/users/{smId}/tariff/dynamic` — each price entry now carries its own `currency`.
- `GET /v1/tariff/gateways/{smId}` — `commonSeasons.*` changed from object to array of `{from, tariff: low|high}` (Solar Lens does not decode this field).
- `GET /v1/overview` — new `consumption.thisYear`.
- `GET /v1/info/sensors/{smId}` — `waterHeaterType` now enum `Heater` / `HP`.

**Removed / deprecated endpoints:**
- `POST /v1/oauth/login` — deprecated 2026-05, **removal 2027-06**. Replaced by API Keys + `/v3/auth/refresh`
- `POST /v1/oauth/refresh` — deprecated 2026-05, **removal 2027-06**. Replaced by `/v3/auth/refresh`
- `GET /v1/info/sensors/{smId}` — deprecated 2026-05, **removal 2027-05**. Replaced by `/v3/users/{smId}/devices`
- `GET /v1/info/sensor/{sensorId}` — deprecated 2026-05, removal 2027-05. Replaced by `/v3/users/{smId}/devices`
- `GET /v1/data/string/{stringId}/range` — now marked deprecated 2025-06, removal 2026-06 (not used by Solar Lens)
- No endpoints removed yet.

**Impact on Solar Lens:**
- [ ] **Auth migration (deadline 2027-06):** `SolarManagerApiClient.login()` / refresh use `/v1/oauth/*`. Login must move to API Keys + `/v3/auth/refresh` — this changes the onboarding UX (user creates an API Key in Solar Manager instead of entering email/password) and needs a migration path for existing installs, incl. Watch/tvOS/widgets keychain sharing and key rotation handling.
- [ ] **Device discovery migration (deadline 2027-05):** `/v1/info/sensors/{smId}` → `/v3/users/{smId}/devices` (`SensorInfosV1Response`). The v3 response has no live values (`signal`, `soc`) — those must come from the v3 stream.
- [ ] **Charging mode 8 (Aria):** `ChargingMode` decodes unknown values as `.off` → a car in Aria mode is shown as "off". Add `case aria = 8`.
- [ ] **Battery mode 6 (Aria):** `BatteryMode` falls back to `.StandardControlled` for 6. Add the Aria case.
- [ ] **`soc` is now `number`:** `DataStreamV3Device.soc` is `Int?` with synthesized decoding — a fractional value would fail the *whole* stream decode. `DataDeviceV3Schema.soc` silently becomes `nil` (`try? Int`). Change both to `Double`.
- [ ] Feature opportunities: Aria mode switching (battery/charger), charging target schedules, per-phase current/voltage on the charger, heat-pump temperatures, `remainingRange` history, `consumption.thisYear`.

### Solar Lens integration update (2026-06-28)

No API version change. Solar Lens started consuming additional tariff endpoints
for Story #8 ("Should I add a battery to my house?"):

**Newly consumed endpoints:**
- `GET /v3/users/{smId}/tariffs` — detailed import/feed-in tariffs (time-of-use) — `fetchDetailedTariffs()`
- `GET /v3/users/{smId}/tariff/dynamic` — dynamic/spot import prices — `fetchDynamicTariff()` (new `DynamicTariffResponse` DTO + `getV3DynamicTariff` client call)
- `GET /v1/tariff/gateways/{smId}` — V1 tariff fallback — `fetchTariff()`

**Notes / gotchas:**
- Dynamic tariff prices are in **main currency units per kWh** (e.g. `0.2976` CHF/kWh), **not** Rappen/cents — unlike the V1/V3 static tariffs which are in Rappen and divided by 100. `TariffCalculator.importRateCHF` handles both.
- The dynamic endpoint returns near-term prices only; historical valuations (year-back what-if, older battery-advantage periods) fall back to the static tariff when a timestamp isn't covered.

### v1.79.13 (2026-03-23)

**File:** `externals/sm_api_swaggers/swagger_1.79.13.json`

**New endpoints:**
- `GET /v3/devices/supported` — Supported device types (v3), replaces `/v1/supported/devices`
- `GET /v3/users/{smId}/tariff/dynamic` — Dynamic tariff (v3), replaces `/v1/tariff/gateways/{smId}/dynamic`
- `PUT /v1/control/car-charging-system/{sensorId}` — Car charging system control (modes: Max Performance, Optimized, No Charging)
- `PUT /v2/control/v2x/{sensorId}` — V2X control (v2, expanded modes incl. Solar&Tariff optimized, Manual, Target SoC)

**Changed endpoints:**
- (none)

**Removed / deprecated endpoints:**
- `GET /v1/supported/devices` — deprecated 2025-10, removal 2026-10. Replaced by `/v3/devices/supported`
- `GET /v1/tariff/gateways/{smId}/dynamic` — deprecated 2025-09, removal 2026-09. Replaced by `/v3/users/{smId}/tariff/dynamic`
- `PUT /v1/control/v2x/{sensorId}` — deprecated, superseded by `/v2/control/v2x/{sensorId}`

**Impact on Solar Lens:**
- Migrated from deprecated `/v1/stream/gateway/{smId}` to `/v3/users/{smId}/data/stream`
- Migrated from deprecated `/v1/data/sensor/{sensorId}/range` to `/v3/devices/{deviceId}/data/range`
- New `car-charging-system` endpoint may be relevant if Solar Lens adds support for car charging systems (distinct from car chargers)

<!-- Template for future entries:

### vX.Y.Z (YYYY-MM-DD)

**File:** `externals/sm_api_swaggers/swagger_X.Y.Z.json`

**New endpoints:**
- `GET /v3/...` — description

**Changed endpoints:**
- `PUT /v1/...` — what changed (new parameter, changed response, etc.)

**Removed / deprecated endpoints:**
- `GET /v1/...` — replaced by `/v3/...`

**Impact on Solar Lens:**
- [ ] `SolarManagerApi.swift` needs update for ...
- [ ] New feature opportunity: ...

-->
