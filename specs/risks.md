# Solar Lens – Risks

## Overview

Solar Lens depends on external systems and platforms outside our control. This document identifies key risks, their impact, and mitigation strategies.

## External API Dependency

**Risk: Solar Manager API changes or becomes unavailable**

Solar Lens is entirely dependent on the Solar Manager Cloud API (`cloud.solar-manager.ch`) for all data and device control. Any breaking change, deprecation, or outage directly impacts every feature.

| Aspect | Details |
|--------|---------|
| **Likelihood** | Medium — API is actively evolving (v1 → v3 migration underway) |
| **Impact** | Critical — app becomes non-functional without the API |
| **Current mitigations** | |
| | Swagger snapshots stored in `externals/sm_api_swaggers/` for diffing |
| | API change tracking in [solarmanager_api.md](solarmanager_api.md) |
| | Graceful error handling and retry logic (up to 4 retries with backoff) |
| | Cached widget data (4-min TTL) survives short outages |
| **Recommended actions** | |
| | Periodically diff new swagger against baseline to catch changes early |
| | Migrate off deprecated v1 endpoints before 2026-06 removal deadline |
| | Monitor Solar Manager release notes / community channels |

## API Deprecation Timeline

Two endpoints actively used by Solar Lens are deprecated with a hard removal date:

| Endpoint | Deprecated | Removal | Replacement |
|----------|-----------|---------|-------------|
| `GET /v1/stream/gateway/{smId}` | 2025-06 | **2026-06** | `/v3/users/{smId}/data/stream` |
| `GET /v1/data/sensor/{sensorId}/range` | 2025-06 | **2026-06** | `/v3/devices/{deviceId}/data/range` |

**Impact:** If not migrated before removal, dashboard device power and battery history will break.

## App Store & Platform Risk

**Risk: App Store rejection or policy changes**

| Aspect | Details |
|--------|---------|
| **Likelihood** | Low — app follows standard patterns, no unusual entitlements |
| **Impact** | High — blocks all distribution |
| **Mitigations** | |
| | No private APIs used, pure SwiftUI |
| | Single external dependency (KeychainAccess) — minimal supply chain risk |
| | TestFlight for pre-release validation |

**Risk: Apple deprecates APIs we depend on**

| Aspect | Details |
|--------|---------|
| **Likelihood** | Low-Medium — WidgetKit and AppIntents are actively developed by Apple |
| **Impact** | Medium — requires code updates within a release cycle |
| **Mitigations** | |
| | Minimum deployment targets already set to recent OS versions (iOS 18.2, watchOS 11) |
| | Using modern APIs (`@Observable`, async/await) that are on Apple's forward path |

## Authentication & Credential Risk

**Risk: Credential compromise or token mishandling**

| Aspect | Details |
|--------|---------|
| **Likelihood** | Low |
| **Impact** | High — user's Solar Manager account could be accessed |
| **Mitigations** | |
| | Credentials stored in Keychain (not UserDefaults or plaintext) |
| | OAuth tokens with refresh flow — short-lived access tokens |
| | Credentials cleared on logout |
| | No credentials logged or transmitted to Solar Lens infrastructure |

## Solar Lens Server (Azure Functions)

**Risk: Server costs or outage**

| Aspect | Details |
|--------|---------|
| **Likelihood** | Low — minimal usage (tvOS image upload only) |
| **Impact** | Low — only affects tvOS custom backgrounds; core app functionality unaffected |
| **Mitigations** | |
| | Azure Functions consumption plan — costs scale to zero when unused |
| | Server is optional — all core features work without it |

## Data Accuracy

**Risk: Displayed energy data is incorrect or misleading**

| Aspect | Details |
|--------|---------|
| **Likelihood** | Low — data comes directly from Solar Manager |
| **Impact** | Medium — incorrect data could lead users to wrong conclusions about their energy system |
| **Mitigations** | |
| | Stale data detection (>60s = outdated, shown to user) |
| | Timestamps displayed on all data views |
| | No local calculations that could diverge from Solar Manager's own values |
| | Statistics use Solar Manager's aggregation, not client-side math |

## Summary

| Risk | Likelihood | Impact | Status |
|------|-----------|--------|--------|
| API breaking changes | Medium | Critical | Monitored via swagger tracking |
| API deprecation (2026-06) | Certain | High | Migration needed |
| App Store rejection | Low | High | Following guidelines |
| Apple API deprecation | Low-Medium | Medium | Using modern APIs |
| Credential compromise | Low | High | Keychain + OAuth |
| Azure server issues | Low | Low | Optional component |
| Data accuracy | Low | Medium | Timestamps + stale detection |
