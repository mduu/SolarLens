# Solar Lens – Architecture

## Overview

Solar Lens is a set of native Apple apps serving as an alternative client for [Solar Manager](https://solar-manager.ch) energy management systems. It provides real-time monitoring and control of solar production, battery storage, EV charging, and energy consumption across watchOS, iOS, and tvOS.

### Focus & USP

1. **Deep Apple ecosystem integration** — Solar Manager features are surfaced wherever Apple users expect them: Apple Watch app, home screen and lock screen widgets, Smart Stack, watch complications, Siri voice queries, Shortcuts automation, and Apple TV. Energy data is always one glance or voice command away.
2. **Approachable, non-technical interface** — Designed for daily use by homeowners, not engineers. The UI prioritizes clarity over technical detail, making solar energy accessible to medium tech-affinity users.
3. **Features beyond the official app** — Extensive statistics (weekly/monthly breakdowns, efficiency metrics, trend analysis) and visualizations that Solar Manager's own app does not provide.

## Principles

* Native SwiftUI on all platforms — no cross-platform frameworks
* Shared code in `Shared/` — platform-specific UI per target
* Minimal external dependencies (only KeychainAccess)
* Optimistic UI updates for responsive user experience
* Async/await for all networking
* Clarity over complexity — favor simple, glanceable UI over technical dashboards

## Application Model

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          Apple Platforms                                     │
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │  watchOS App     │  │  iOS App         │  │  tvOS App (BigScreen)    │    │
│  │                  │  │                  │  │                          │    │
│  │  - Energy flow   │  │  - Energy flow   │  │  - Dashboard             │    │
│  │  - Battery mode  │  │  - Battery mode  │  │  - Custom backgrounds    │    │
│  │  - Solar gauge   │  │  - Statistics    │  │  - QR-based setup        │    │
│  │  - Consumption   │  │  - Consumption   │  │  - Image upload (Azure)  │    │
│  │  - Charging      │  │  - Charging      │  │                          │    │
│  │  - Grid status   │  │  - Settings      │  │                          │    │
│  └──────────────────┘  └──────────────────┘  └──────────────────────────┘    │
│                                                                              │
│  ┌──────────────────────────────┐  ┌──────────────────────────────────────┐  │
│  │  watchOS Widgets             │  │  iOS Widgets                         │  │
│  │                              │  │                                      │  │
│  │  - Battery level             │  │  - Battery level                     │  │
│  │  - Solar production          │  │  - Solar production                  │  │
│  │  - Consumption               │  │  - Consumption                       │  │
│  │  - Efficiency metrics        │  │  - Efficiency metrics                │  │
│  │  - Today overview timeline   │  │  - Today overview timeline           │  │
│  └──────────────────────────────┘  └──────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────┐│
│  │                         Shared Module                                    ││
│  │                                                                          ││
│  │  Services · State · Components · Features · Widgets · AppIntents         ││
│  └──────────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │  HTTPS (REST API)
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    Solar Manager Cloud API                                   │
│                    https://cloud.solar-manager.ch                            │
│                                                                              │
│  OAuth 2.0 · Real-time data · Device control · Statistics · Forecasts        │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │  (tvOS only)
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    Solar Lens Server (Azure Functions)                       │
│                    Image upload for tvOS custom backgrounds                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Platform Targets

| Platform | Target | Min Version | Primary Device |
|----------|--------|-------------|----------------|
| watchOS | Solar Lens Watch App | 11.0 | Apple Watch |
| iOS | Solar Lens iOS | 18.2 | iPhone / iPad |
| tvOS | Solar Lens BigScreen | latest | Apple TV |
| watchOS | Solar Lens Widgets | 11.0 | Watch complications |
| iOS | Solar Lens iOS Widgets | 18.2 | Home screen widgets |

## Project Structure

```
SolarLens/
├── Shared/                          # Shared code across all platforms
│   ├── Services/                    # API clients & business logic
│   │   ├── SolarManager.swift       # Main EnergyManager implementation
│   │   ├── SolarManagerApi/         # REST API client + DTOs
│   │   ├── RestClient.swift         # HTTP client with retry logic
│   │   ├── KeychainHelper.swift     # Secure credential storage
│   │   └── FakeEnergyManager.swift  # Mock for SwiftUI previews
│   ├── State/                       # Observable state management
│   │   └── CurrentBuildingState.swift
│   ├── Components/                  # Reusable SwiftUI components
│   ├── Features/                    # Feature-specific UI (Battery, Solar, etc.)
│   ├── Widgets/                     # Widget data sources & shared UI
│   ├── AppIntents/                  # Siri Shortcuts (9 intents)
│   ├── AppSettings/                 # User preferences
│   ├── Layouts/                     # Custom layout containers
│   └── Extensions/                  # Swift type extensions
├── Solar Lens iOS/                  # iOS app target
│   ├── Home/                        # Dashboard
│   ├── Login/                       # Authentication
│   ├── Statistics/                  # Charts & analytics
│   ├── Settings/                    # App settings
│   └── Onboardings/                 # First-run flows
├── Solar Lens Watch App/            # watchOS app target
│   ├── Home/                        # Watch dashboard
│   ├── Login/                       # Watch authentication
│   ├── Battery/                     # Battery views
│   ├── Consumption/                 # Consumption views
│   ├── SolarProduction/             # Solar views
│   ├── Charging/                    # EV charging views
│   └── Grid/                        # Grid status views
├── Solar Lens BigScreen/            # tvOS app target
│   ├── Home/                        # TV dashboard
│   ├── Login/                       # TV authentication
│   ├── Settings/                    # TV settings
│   └── Services/                    # Image upload, QR codes
├── Solar Lens iOS Widgets/          # iOS widget extension
├── Solar Lens Widgets/              # watchOS widget extension
│   ├── ProductionAndConsumptionWidgets/
│   ├── SolarTimelineWidgets/
│   └── Generic/
├── Solar Lens Server/               # .NET Azure Functions backend
│   ├── src/ImageUpload.Functions/   # C# Azure Functions
│   └── web/                         # Static upload UI
├── externals/
│   └── sm_api_swaggers/             # Solar Manager OpenAPI specs
├── landingpage/                     # Marketing site (solarlens.ch)
└── specs/                           # Stories, ADRs, backlog
```

## Architecture Patterns

### State Management: Observable + Environment

```
User Action (SwiftUI)
  ↓
CurrentBuildingState (@Observable)
  ↓
SolarManager (EnergyManager protocol)
  ↓
SolarManagerApi (RestClient)
  ↓
Solar Manager Cloud API
  ↓
Response → Model → State update → SwiftUI re-render
```

- **`CurrentBuildingState`** — central `@Observable` state object, injected via `@Environment`
- **`SolarManager`** — singleton implementing `EnergyManager` protocol; handles API calls and data mapping
- **`FakeEnergyManager`** — mock implementation for SwiftUI previews and development
- **Optimistic updates** — UI reflects changes immediately, before server confirmation

### Widget Architecture

- Shared `SolarLensWidgetDataSource` with 4-minute cache TTL
- `TimelineProvider` pattern for WidgetKit
- `AppIntent`-based configuration for deep linking
- Separate widget bundles per platform (iOS / watchOS)

## Solar Manager API Integration

**Base URL:** `https://cloud.solar-manager.ch`
**API docs:** [Swagger UI](https://external-web.solar-manager.ch/swagger) · [swagger.json](https://cloud.solar-manager.ch/swagger.json)
**Change tracking:** [solarmanager_api.md](solarmanager_api.md)

The Solar Manager API is the single integration point for all Solar Lens data and functionality. We track API changes and store approved swagger versions in [`externals/sm_api_swaggers/`](../externals/sm_api_swaggers/).

### Authentication

- OAuth 2.0 with email/password login
- Access + refresh tokens stored in Keychain (synced via iCloud)
- Automatic token refresh on 401 responses

### Key Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /v1/oauth/login` | Login |
| `POST /v1/oauth/refresh` | Token refresh |
| `GET /v1/chart/gateway/{smId}` | Real-time power data |
| `GET /v1/overview` | Current state snapshot |
| `GET /v1/users` | User / system info |
| `GET /v1/statistics` | Historical statistics |
| `GET /v1/stream/gateway/{smId}` | Sensor stream data |
| `POST /v1/control/battery/v2` | Set battery mode |
| `POST /v1/control/car-charging` | Control EV charging |

### Network Configuration

| Setting | watchOS | iOS / tvOS |
|---------|---------|------------|
| Request timeout | 15s | 60s |
| Resource timeout | 30s | 300s |
| Retry attempts | up to 4 | up to 4 |

## Siri Shortcuts (AppIntents)

9 intents for automation and voice control:

- **Read-only:** GetSolarProduction, GetConsumption, GetBatteryLevel, GetGridPower, GetEfficiency
- **Control:** SetChargingMode, SetBatteryMode
- Supports Shortcuts app and Siri voice commands

## Localization

**Supported languages:** English, German, French, Italian, Danish

Translations managed via `Localizable.xcstrings` using SwiftUI `LocalizedStringResource`.

## Dependencies

| Dependency | Purpose |
|------------|---------|
| KeychainAccess | Secure credential storage |
| SwiftUI | UI framework (all platforms) |
| WidgetKit | Widgets & complications |
| AppIntents | Siri Shortcuts |

No CocoaPods, no Carthage — Swift Package Manager only.

## Infrastructure

### Solar Lens Server (Azure Functions)

Used exclusively by the tvOS app for custom background image uploads.

- **Runtime:** .NET / C# Azure Functions
- **Purpose:** Image upload and storage for tvOS backgrounds
- **Details:** See [Solar Lens Server/README.md](../Solar%20Lens%20Server/README.md)

### Build & Distribution

- **Build tool:** Xcode
- **Distribution:** App Store Connect (TestFlight + public release)
- **Export configs:** `ExportOptions-testflight.plist`, `ExportOptions-release.plist`

## References

- [README.md](../README.md) — Project overview
- [CLAUDE.md](../CLAUDE.md) — Build commands & code style
- [User Interface Guidelines](userinterface.md) — Design system and UI patterns
- [Risks](risks.md) — Risk analysis and mitigations
- [Solar Manager API change tracking](solarmanager_api.md) — API changelog and baseline
- [Solar Manager OpenAPI specs](../externals/sm_api_swaggers/) — Stored swagger versions
- [Backlog](backlog.md) — Ideas and planned stories
- [Architecture Decision Records](adrs/) — ADRs
