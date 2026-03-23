# Solar Manager API – Change Tracking

## Purpose

This document tracks changes to the [Solar Manager external API](https://external-web.solar-manager.ch/swagger) that are relevant to Solar Lens. The Solar Manager API is the single integration point for all Solar Lens data and functionality — any breaking change, deprecation, or new endpoint directly impacts the app.

## How to use this file

1. **Periodically** download the latest swagger from https://cloud.solar-manager.ch/swagger.json
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
| POST | `/v1/oauth/login` | Login (all platforms) | — |
| POST | `/v1/oauth/refresh` | Automatic token refresh / session management | — |

### Data – Read

| Method | Endpoint                            | Features                                                      | Deprecated?                                                                            |
| ------ | ----------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| GET    | `/v1/users`                         | System info, gateway discovery, account setup                 | —                                                                                      |
| GET    | `/v1/info/sensors/{smId}`           | Sensor/device discovery, battery & charger detection          | —                                                                                      |
| GET    | `/v1/chart/gateway/{smId}`          | Dashboard real-time energy flow                               | —                                                                                      |
| GET    | `/v1/overview`                      | Energy overview statistics                                    | —                                                                                      |
| GET    | `/v1/statistics/gateways/{smId}`    | Today's stats, daily/weekly/monthly statistics, solar details | —                                                                                      |
| GET    | `/v1/consumption/sensor/{sensorId}` | Car charging history, charging data                           | —                                                                                      |
| GET    | `/v3/devices/{deviceId}/data/range` | Battery charge/discharge history                              | —                                                                                      |
| GET    | `/v3/users/{smId}/data/forecast`    | Solar forecast (today, tomorrow, day after)                   | —                                                                                      |
| GET    | `/v3/users/{smId}/data/stream`      | Dashboard device power status                                 | —                                                                                      |
| GET    | `/v3/users/{smId}/data/range`       | Detailed energy data, production/consumption graphs           | —                                                                                      |

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
| **Version** | 1.79.13 |
| **Local file** | `externals/sm_api_swaggers/swagger_1.79.13.json` |
| **Date recorded** | 2026-03-23 |

### Endpoint Summary (v1.79.13)

#### Auth (2 endpoints, unchanged)

| Method | Endpoint | Notes |
|--------|----------|-------|
| POST | `/v1/oauth/login` | Email/password login, returns access + refresh token |
| POST | `/v1/oauth/refresh` | Refresh access token |

#### Users (13 endpoints)

| Method | Endpoint | Notes |
|--------|----------|-------|
| GET | `/v1/users` | Current user info and gateway list |
| GET | `/v1/info/user/{uId}` | User details by ID |
| GET | `/v1/info/gateway/{smId}` | Gateway info |
| GET | `/v1/info/sensors/{smId}` | All sensors for a gateway |
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
| GET | `/v1/data/string/{stringId}/range` | String inverter range data |
| GET | `/v1/data/zev/{smId}` | ZEV (multi-tenant) data |
| GET | `/v3/users/{smId}/data/forecast` | Forecast (v3) |
| GET | `/v3/users/{smId}/data/range` | Range data (v3) |
| GET | `/v3/users/{smId}/data/stream` | Stream data (v3) |

#### Devices (20 endpoints)

| Method | Endpoint                                     | Notes                                                                                  |
| ------ | -------------------------------------------- | -------------------------------------------------------------------------------------- |
| GET    | `/v1/info/sensor/{sensorId}`                 | Sensor/device info                                                                     |
| GET    | `/v1/consumption/sensor/{sensorId}`          | Sensor consumption data                                                                |
| GET    | `/v1/data/sensor/{sensorId}/range`           | Sensor range data (v1)                                                                 |
| GET    | `/v3/devices/{deviceId}/data/range`          | Device range data (v3)                                                                 |
| GET    | `/v1/stream/sensor/{smId}/{sensorId}`        | Sensor stream                                                                          |
| GET    | `/v1/supported/devices`                      | **DEPRECATED** — Deprecated 2025-10, removal 2026-10. Use `/v3/devices/supported`      |
| GET    | `/v3/devices/supported`                      | **NEW** — Supported device types (v3), replaces `/v1/supported/devices`                |
| GET    | `/v1/control/tariff`                         | Tariff control info                                                                    |
| PUT    | `/v1/configure/sensor-priority/{sensorId}`   | Set sensor priority                                                                    |
| PUT    | `/v1/control/battery/{sensorId}`             | Control battery (v1)                                                                   |
| PUT    | `/v2/control/battery/{sensorId}`             | Control battery (v2)                                                                   |
| PUT    | `/v1/control/car-charger/{sensorId}`         | Control EV charger                                                                     |
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
- Car charging system control (`/v1/control/car-charging-system/{sensorId}`) is a new endpoint distinct from the existing car charger control (`/v1/control/car-charger/{sensorId}`).

---

## Changelog

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
