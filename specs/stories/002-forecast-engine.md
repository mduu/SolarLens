# Story: #2, Smart Forecast Engine

**Status:** Open

## Short Description

Build a smarter PV production forecast that improves on Solar Manager's built-in prediction by combining better weather input (Open-Meteo / MeteoSwiss ICON-CH) with an on-device correction heuristic ("enhanced Dreisatz") calibrated against actual production history. The new forecast is opt-in via a Settings toggle; users who prefer Solar Manager's forecast can keep using it unchanged. This forecast engine is the foundation for downstream smart features (notifications, load shifting, Überschuss-Push).

## Additional Information

Solar Manager uses an ML model (requires 2 weeks bootstrap per installation, learns per site), but is frequently inaccurate in practice. Our approach avoids a long ML bootstrap and stays explainable.

Downstream features that depend on this engine:
- Smart Notifications ("Sonnenfenster", anomaly detection, battery-won't-fill warnings)
- Load shifting recommendations (best time for dishwasher, EV charging, boiler)
- Forecast tracking & transparency (show forecast accuracy over time)
- Überschuss-Push with actionable buttons (via APNs + App Intents)

### Open-Meteo Licensing — Resolved

**Status: Approved for free use.**

Patrick Zippenfenig (OpenMeteo GmbH) confirmed via email (April 2026) that Solar Lens may use the Open-Meteo Free API at no cost, given:
- The app is a small OSS hobby project (GPL-3.0)
- CHF 2 price barely covers the Apple Developer fee, no meaningful profit
- Very light infrastructure load (~50 calls/day from backend cache)

Patrick offered to help if IP rate limiter issues arise. Contact: info@open-meteo.com

**Attribution required** (CC BY 4.0): Display "Weather data by Open-Meteo.com" with link to https://open-meteo.com in the app (Settings / About screen).

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Azure Function (Timer Trigger, every 6 hours)      │
│                                                     │
│  For each of ~10-12 Swiss regional points:          │
│  ├─ GET Open-Meteo Forecast API (GHI, cloud, temp)  │
│  ├─ Write to Blob: forecasts/{region}/latest.json   │
│  └─ Write to Blob: forecasts/{region}/archive/      │
│                     {date}.json                      │
│                                                     │
│  Total Open-Meteo calls: ~50/day (fixed, regardless │
│  of user count)                                     │
│                                                     │
│  Later: also handles APNs push for smart            │
│  notifications (Sonnenfenster, Überschuss, etc.)    │
└───────────────┬─────────────────────────────────────┘
                │ HTTPS (app fetches regional file)
                ▼
┌─────────────────────────────────────────────────────┐
│  iOS / watchOS App                                  │
│                                                     │
│  1. Determine user's region from coordinates        │
│     (static mapping, never sent to backend)         │
│  2. Fetch regional forecast from Azure Blob         │
│  3. Fetch actual production from Solar Manager API  │
│  4. On-device: compute correction factors           │
│  5. On-device: apply corrected forecast             │
│  6. Store everything in SwiftData locally            │
└─────────────────────────────────────────────────────┘
```

#### Why a backend cache even though Free Tier is approved
- **Forecast archive**: We need past forecasts for the Dreisatz. By archiving in Blob Storage, we avoid needing the expensive Historical Forecast API.
- **Push notifications**: Backend must run periodically anyway for smart push features.
- **Rate limit safety**: 50 calls/day from one IP vs. 200+ users hitting Open-Meteo directly.
- **Watch reliability**: WatchOS networking is fragile; better to serve from own endpoint.
- **Privacy**: Backend never knows which user is in which region or has which installation.

#### Cost estimate
- Azure Functions Consumption Plan: 1M executions/month free
- Azure Blob Storage for a few MB of JSON: < CHF 0.50/month
- **Total additional cost: well under CHF 2/month**

### Swiss Region Mapping

~10-12 representative coordinates covering Switzerland's distinct solar/weather zones:

| Region | Representative point | Characteristics |
|---|---|---|
| Mittelland West | Bern area | Flat, fog-prone in winter |
| Mittelland Ost | Zürich area | Similar, slightly different fog patterns |
| Nordwestschweiz | Basel area | Rhine valley, different cloud patterns |
| Ostschweiz | St. Gallen area | Pre-alpine, more precipitation |
| Zentralschweiz | Luzern area | Lake effect, Föhn possible |
| Voralpen Nord | Thun/Interlaken | Altitude ~600-800m, less fog |
| Alpen Nordseite | Brig/Andermatt | High altitude, more sun in winter |
| Alpensüdseite / Tessin | Lugano | Mediterranean influence, most sun hours |
| Wallis | Sion | Inner-alpine dry valley, very high sun hours |
| Jura | Delémont/La Chaux-de-Fonds | Altitude, different from Mittelland |
| Genferseeregion | Lausanne/Genève | Lake Geneva microclimate |
| Graubünden | Chur/Davos | Inner-alpine, complex topography |

**Mapping logic**: User's GPS coordinate → nearest region by simple haversine distance. Computed once at app startup / location change. Stored locally, never transmitted with user identity.

**MVP**: Start with 3-4 regions (Mittelland, Voralpen, Tessin, Wallis) and expand.

### Open-Meteo API Details

#### Forecast API (daily fetch)
```
GET https://api.open-meteo.com/v1/forecast
  ?latitude=47.37&longitude=8.55
  &hourly=shortwave_radiation,direct_radiation,diffuse_radiation,
          cloud_cover,temperature_2m
  &timezone=Europe/Zurich
  &forecast_days=7
  &models=icon_seamless
```

Key variables:
- `shortwave_radiation` (W/m²) = GHI — the primary driver for PV production
- `direct_radiation` + `diffuse_radiation` — for more nuanced modeling later
- `cloud_cover` (%) — for bucketing correction factors
- `temperature_2m` — PV efficiency drops ~0.4%/°C above 25°C

#### Historical Forecast API (one-time bootstrap only)
```
GET https://historical-forecast-api.open-meteo.com/v1/forecast
  ?latitude=47.37&longitude=8.55
  &hourly=shortwave_radiation,cloud_cover,temperature_2m
  &start_date=2026-02-01&end_date=2026-04-15
  &models=icon_seamless
```

Used only for initial bootstrap if we need historical forecasts before our own archive has accumulated enough data. After ~30 days of our own archiving, this is no longer needed.

### The "Enhanced Dreisatz" Algorithm

#### Core concept (Model Output Statistics / MOS correction)

```
CorrectionFactor[month][hour][cloudBucket] =
    median( actual_production / forecasted_GHI )
    over the last 30-90 days for matching conditions

ForecastProduction[h] =
    OpenMeteo_GHI[h] × kWp_baseline × CorrectionFactor[month][hour][cloudBucket]
```

#### Cloud cover buckets
- Clear: 0-20%
- Partly cloudy: 20-50%
- Mostly cloudy: 50-80%
- Overcast: 80-100%

#### What the correction factor implicitly learns (no explicit modeling needed)
- Installation-specific shading (trees, buildings, dormers)
- Module orientation and tilt
- Inverter clipping and efficiency
- Module degradation over time
- Local micro-climate effects
- Snow cover patterns (factor drops to near-zero)

#### Bootstrap sequence
1. App startup: fetch 60-90 days of actual production from Solar Manager API (hourly)
2. Fetch matching period from Open-Meteo Historical Forecast API (or from our archive if available)
3. Compute initial correction factors per (month, hour, cloud_bucket)
4. Daily: add yesterday's real data, update factors (rolling window)

#### kWp baseline
- If available from Solar Manager API: use directly
- Otherwise: estimate from peak historical production (e.g., max hourly production ÷ peak solar radiation at that time)

#### Confidence / uncertainty
- Track sample count per bucket. If < 5 samples, mark forecast as "low confidence"
- Show forecast as range: median ± interquartile range of the correction factors
- Display to user: "8 kWh ±2 kWh (70% confident)"

### SwiftData Schema (Draft)

```swift
@Model
class ForecastSnapshot {
    var region: String              // e.g. "mittelland_ost"
    var fetchedAt: Date             // when we cached this forecast
    var forecastDate: Date          // which day it's for
    var hourlyGHI: [Double]         // 24 values, W/m²
    var hourlyCloudCover: [Double]  // 24 values, %
    var hourlyTemperature: [Double] // 24 values, °C
}

@Model
class ProductionRecord {
    var date: Date                  // day
    var hourlyProduction: [Double]  // 24 values, Wh from Solar Manager
    var hourlyConsumption: [Double] // 24 values, Wh (for future load shifting)
}

@Model
class CorrectionFactor {
    var month: Int                  // 1-12
    var hour: Int                   // 0-23
    var cloudBucket: Int            // 0-3 (clear/partly/mostly/overcast)
    var factor: Double              // median ratio
    var sampleCount: Int            // for confidence
    var iqrLow: Double              // interquartile range lower bound
    var iqrHigh: Double             // interquartile range upper bound
    var lastUpdated: Date
}
```

### Feature Roadmap (Phases)

#### Phase 1 — Forecast Engine MVP (Foundation) — this story
- Azure Function: fetch + cache Open-Meteo for 3-4 Swiss regions
- Blob Storage: live + archive layout
- iOS app: region mapping, fetch from cache, display forecast chart
- On-device Dreisatz: bootstrap from SM history + Open-Meteo historical
- UI: forecast chart comparing Solar Lens vs. Solar Manager prediction
- Running MAPE score ("Solar Lens: ±8%, Solar Manager: ±19%")
- Settings toggle to choose forecast source (Solar Manager vs. Solar Lens); Solar Manager forecast remains the default and stays fully functional
- Attribution in About screen

#### Phase 2 — Smart Notifications (future story)
- Azure Function: daily morning job computing "Sonnenfenster" per user-region
- APNs push: "Heute 14-16 Uhr beste PV, plane Verbraucher ein"
- APNs push: "Batterie wird heute voraussichtlich nicht voll"
- Überschuss-Alert: Push when >X kW flowing to grid unused
- Anomaly detection: production >25% below expected on clear day → "Check system?"
- Interactive notification buttons → trigger SM API actions via App Intents

#### Phase 3 — Smart Recommendations (future story)
- "Grüne Stunden" per device (Boiler, EV, Wärmepumpe): optimal time windows
- EV charge planner: user sets "80% by 7am tomorrow", app computes greenest schedule
- Battery strategy: "don't charge battery full tonight, lots of sun forecast tomorrow"
- Weekly self-sufficiency score with actionable tips
- CO₂ and CHF savings tracker

#### Phase 4 — Advanced (future story)
- What-if simulator: "How much more autarky with +5 kWh battery?"
- Seasonal wrap-up (Spotify Wrapped style)
- Live Activity / Dynamic Island for ongoing EV charging with PV share
- Interactive Widgets: toggle Boiler/Wallbox from homescreen
- Expanded App Intents: `getForecastForDateRange`, `getBestChargingWindow`

### Forecast Source Toggle (Settings)

The new forecast engine is opt-in. Users choose which forecast drives the app:

- **Setting**: "Forecast source" in the app's Settings screen (iOS + watchOS where settings exist)
- **Options**:
  - `Solar Manager` (default for existing users) — use the built-in SM forecast unchanged
  - `Solar Lens (Open-Meteo + Dreisatz)` — use the new engine
- **Persistence**: `AppStorage` key e.g. `forecastSource` with enum `ForecastSource { .solarManager, .solarLens }`; synced across devices via iCloud where Solar Lens already uses iCloud-backed settings
- **Default**: `.solarManager` on upgrade (no surprise switch for existing users); new installs may default to `.solarLens` once the MVP is validated (decide at rollout)
- **Behavior when off (`.solarManager`)**:
  - No Open-Meteo fetch from backend is consumed by the app
  - No on-device correction-factor computation runs
  - No bootstrap fetch of 60-90 days of production history for forecast purposes
  - Forecast-related SwiftData models are not populated; existing rows remain untouched
  - UI falls back to the existing Solar Manager forecast rendering exactly as today
- **Behavior when on (`.solarLens`)**:
  - Region mapping, regional forecast fetch, bootstrap, and correction run as described above
  - Forecast chart shows Solar Lens forecast; Solar Manager forecast remains available as a comparison overlay
  - MAPE comparison is visible so users can judge accuracy before fully committing
- **Switching between sources is non-destructive**: toggling back to `.solarManager` keeps any cached Dreisatz state so a later re-enable does not re-bootstrap from scratch
- **Downstream features (Phase 2+)** that depend on the new engine (Sonnenfenster push, anomaly detection, etc.) are gated on `.solarLens` being active

### Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Weather data source | Open-Meteo (integrates MeteoSwiss ICON-CH) | Free for our use case (confirmed), best Swiss resolution, simple JSON API |
| Forecast method | Heuristic MOS correction, not ML | Simpler, explainable, no bootstrap wait, good enough to beat SM |
| Backend | Azure Functions + Blob Storage | Already exists for tvOS; < CHF 2/month additional cost |
| On-device ML | Deferred to later phase | Dreisatz likely sufficient; Core ML option preserved for Phase 3+ |
| Region granularity | 10-12 Swiss points | Balances accuracy vs. API calls; MVP with 3-4 |
| User privacy | Coordinates never leave device | Region assigned locally; backend only serves regional data |
| Notification delivery | APNs from Azure Function | Reliable; Silent Push for auto-actions, visible Push for user-triggered |
| Forecast source | User-selectable via Settings toggle | Keep Solar Manager forecast as fallback; avoid forcing unproven MVP on existing users |
| Default forecast source | `.solarManager` on upgrade | No surprise behavior change; users opt in when they want to try the new engine |

### Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Open-Meteo changes terms or goes down | Self-hosting via Docker is fallback (OSS, AGPLv3). MeteoSwiss Open Data as alternative (GRIB2, more complex). |
| Dreisatz not significantly better than SM | Phase 1 includes transparent MAPE comparison. If not better, pivot to "SM forecast tracker + translator" value prop instead. |
| Azure costs grow with users | Blob Storage scales linearly but cheaply. Open-Meteo calls stay constant regardless of user count. |
| IP rate limiting from Open-Meteo | Patrick offered to help; contact info@open-meteo.com. Backend-cache design keeps calls minimal. |
| Apple Watch background refresh unreliable | Serve from backend; Watch fetches from iPhone companion via WatchConnectivity when possible. |

### Not in Scope (Explicitly Excluded)

- HomeKit integration (requires MFi certification or local hardware like Homebridge; not feasible for an indie app)
- Own custom ML model competing with SM head-on (Dreisatz is the approach; ML is optional future enhancement)
- MeteoSchweiz direct GRIB2 parsing (complex, no forecast archive, API not ready before Q2 2026)
- Multi-country support (Swiss-only for now; Open-Meteo works globally but region mapping is Swiss-specific)

### References

- Open-Meteo Forecast API: https://open-meteo.com/en/docs
- Open-Meteo Historical Forecast API: https://open-meteo.com/en/docs/historical-forecast-api
- Open-Meteo Previous Runs API (for forecast verification): same docs
- MeteoSwiss Open Data: https://www.meteoswiss.admin.ch/services-and-publications/service/open-data.html
- Solar Manager External API: see `externals/sm_api_swaggers/` in this repo
- Solar Lens architecture: `specs/architecture.md`

## Expected Result

Phase 1 (MVP) delivers an end-to-end forecast pipeline:
- Azure Function fetches Open-Meteo forecasts for 3-4 Swiss regions every 6 hours and writes them to Blob Storage (live + archive).
- iOS/watchOS app maps the user's coordinates to the nearest region locally, fetches the regional forecast from the cache, and combines it with actual production history from Solar Manager.
- On-device "enhanced Dreisatz" computes correction factors per (month, hour, cloud_bucket) and produces a corrected daily forecast with a confidence range.
- A Settings toggle lets users pick the forecast source (Solar Manager vs. Solar Lens). The default is Solar Manager; users opt in to the new engine.
- When set to Solar Manager, the app behaves exactly as before — no Open-Meteo fetches, no Dreisatz computation, no bootstrap.
- When set to Solar Lens, the forecast chart shows Solar Lens vs. Solar Manager predictions plus a running MAPE score.
- Open-Meteo attribution is visible in the Settings / About screen whenever the Solar Lens source is selected (or has been selected).
- User coordinates never leave the device.

## Test Checklist
- [ ] App builds successfully
- [ ] App runs correctly on watchOS Simulator
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [ ] /specs have been updated if necessary
- [ ] If architectural decisions were made, an ADR was created in /specs/adrs
- [ ] Story status has been set to "Done (DD.MM.YYYY)"
- [ ] Story file has been moved to /specs/stories/done/
- [ ] Story has been removed from the backlog

## Tasks

- [ ] Azure Function (Timer Trigger, every 6h): fetch Open-Meteo forecast for 3-4 MVP regions, write `forecasts/{region}/latest.json` and `forecasts/{region}/archive/{date}.json`
- [ ] Define region list + representative coordinates for MVP (Mittelland, Voralpen, Tessin, Wallis)
- [ ] iOS/watchOS: local region mapping from GPS via haversine distance (no coordinates sent to backend)
- [ ] iOS/watchOS: fetch regional forecast from Azure Blob endpoint
- [ ] SwiftData models: `ForecastSnapshot`, `ProductionRecord`, `CorrectionFactor`
- [ ] Bootstrap: fetch 60-90 days of hourly production from Solar Manager API
- [ ] Bootstrap: fetch matching Open-Meteo Historical Forecast data (until own archive is sufficient)
- [ ] Compute initial correction factors per (month, hour, cloud_bucket) with rolling window update
- [ ] Determine kWp baseline (from SM API if available, else estimate from peak production)
- [ ] Confidence handling: sample count threshold, IQR range, "low confidence" marker
- [ ] Forecast chart UI: Solar Lens vs. Solar Manager prediction
- [ ] Running MAPE score display
- [ ] Settings: add "Forecast source" toggle (Solar Manager / Solar Lens) with `AppStorage` key `forecastSource` and default `.solarManager`
- [ ] Gate Open-Meteo fetch, bootstrap, and Dreisatz computation on `forecastSource == .solarLens` (no-op and no network when set to Solar Manager)
- [ ] Ensure the Solar Manager forecast path remains fully functional and is the rendered forecast when the toggle is set to Solar Manager
- [ ] Switching the toggle at runtime is non-destructive (cached Dreisatz state preserved on disable; re-enable does not re-bootstrap from scratch)
- [ ] Open-Meteo attribution in Settings / About screen (CC BY 4.0)
- [ ] Document ADR(s) for backend cache choice and heuristic-over-ML decision
