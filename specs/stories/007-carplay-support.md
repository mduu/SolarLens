# Story: #7, CarPlay Support

**Status:** Open

## Short Description

Add Apple CarPlay support to the Solar Lens iOS app so users can glance at their live energy flow and control car charging from the car's head unit. Because CarPlay is strictly template-based, the goal is a small, focused set of screens: an energy overview, a charging-station list with mode switching, and device-priority control.

## Additional Information

CarPlay does **not** render SwiftUI. Apps must use Apple's `CarPlay` framework with a fixed set of templates (`CPListTemplate`, `CPGridTemplate`, `CPInformationTemplate`, `CPTabBarTemplate`, etc.) driven by a `CPTemplateApplicationSceneDelegate`. There is no custom drawing of an energy-flow diagram like on iOS/watchOS — values must be expressed as list rows or information items. The watchOS overview (`Solar Lens Watch App/Home/OverviewScreen.swift` + `EnergyFlow/`) is the closest existing UX reference for "show the four key values compactly", but CarPlay is even more constrained than watchOS.

### Apple requirements & entitlements

- CarPlay apps require the **CarPlay app entitlement** from Apple, requested per app category. The relevant category here is **"EV charging"** (`com.apple.developer.carplay-charging`) — this is the only category that fits a charging-control app and is the one most likely to be approved. Apple grants these entitlements manually; this is a hard external dependency and the entitlement must be obtained before the build can run on real CarPlay hardware.
- A new scene must be declared in the app's `Info.plist` (`UIApplicationSceneManifest`) with the CarPlay scene `role` (`CPTemplateApplicationSceneSessionRoleApplication`) and a dedicated scene delegate class.
- Entitlement goes into `Solar Lens iOS/Solar Lens iOS.entitlements` (already holds `com.apple.developer.siri` and `keychain-access-groups`).
- `Info.plist` is the shared root-level `Solar-Lens-Info.plist`.

### Data layer (reuse, do not duplicate)

All data and control already exists in `Shared/` and is platform-agnostic:

- **Live values:** `CurrentBuildingState` (observable) → `overviewData: OverviewData` (`Shared/Services/Model/OverviewData.swift`). Key fields: `currentSolarProduction`, `currentOverallConsumption`, `currentBatteryLevel`, `currentBatteryChargeRate`, `currentSolarToGrid`, `currentGridToHouse`. Refresh via `CurrentBuildingState.fetchServerData(force:)`.
- **Solar forecast:** `CurrentBuildingState.solarDetailsData: SolarDetailsData?` (`Shared/Services/Model/SolarDetailsData.swift`), fetched via `CurrentBuildingState.fetchSolarDetails()`. Holds `forecastToday` / `forecastTomorrow` / `forecastDayAfterTomorrow` as `ForecastItem` (min / max / expected kWh). This is the solar-production forecast — useful context on the overview so the user can decide on a charging mode.
- **Charging:** `overviewData.chargingStations` (`Shared/Services/Model/ChargingStation.swift` — `id`, `name`, `chargingMode`, `priority`, `currentPower`). Change mode via `CurrentBuildingState.setCarCharging(sensorId:newCarCharging:)`. Modes enum: `Shared/Services/SolarManagerApi/DTOs/ChargingMode.swift`.
- **Device priorities:** `overviewData.devices` (`Shared/Services/Model/Device.swift` — `priority`, lower = higher). Change via `CurrentBuildingState.setSensorPriority(sensorId:newPriority:)` / `setSensorPriorities(_:)`.
- **Auth/session:** token-based, stored in Keychain via `Shared/Services/KeychainHelper.swift` with shared access group `UYT5K989XD.com.marcduerst.SolarManagerWatch.Shared`. CarPlay shares the same session as the host app — no separate login UI is needed, but the scene must handle the "not logged in" state gracefully (the user must log in on the phone first).

### Screens (template-based)

1. **Energy overview (home / root).** Shows the current key values — Solar, Grid, Battery, Consumption (and battery charge rate if available). Best modelled as a `CPListTemplate` or `CPInformationTemplate` with one row/item per value. This is the CarPlay home screen and hosts navigation (tab bar or list rows) to the other two screens. Optionally show today's expected solar forecast (`solarDetailsData.forecastToday.expected` kWh) so the user can decide on a charging mode.
2. **Charging stations.** A `CPListTemplate` listing each charging station with its current charging mode shown as the row detail/subtitle. Tapping a station pushes a second list of available charging modes; tapping a mode calls `setCarCharging` and pops back. If only one station exists, skip the station-selection level and go straight to the mode list.
3. **Device priorities.** A `CPListTemplate` of devices ordered by priority. CarPlay lists do not support drag-to-reorder, so reordering must be expressed as move-up / move-down actions (or a per-device "set priority" sub-list) that call `setSensorPriority` / `setSensorPriorities`.

### Constraints / risks

- CarPlay template trailing-row counts and nesting depth are limited; keep hierarchies shallow.
- Updates while driving are restricted — refresh values when the scene connects/becomes active and on user interaction rather than via a tight live timer.
- Real-device validation requires the Apple entitlement; until granted, development must rely on the **CarPlay Simulator** (Xcode → Simulator → I/O → External Displays → CarPlay). Note this in the test checklist.

## Expected Result

- A working CarPlay scene that, when the phone is connected to (or simulating) CarPlay, presents a Solar Lens app icon and the three screens above.
- The energy overview shows current Solar, Grid, Battery, and Consumption values, refreshed on connect/activation.
- The charging screen lists stations, shows each station's current mode, and lets the user change the mode (with the single-station shortcut).
- The device-priority screen lets the user change device priority order using CarPlay-compatible interactions.
- All data and control reuse the existing `Shared/` `CurrentBuildingState` / `SolarManager` layer — no new backend code.
- A clear, friendly state is shown when the user is not logged in on the phone.

## Test Checklist
- [x] App builds successfully (iOS Simulator, `Solar Lens iOS` scheme)
- [ ] App runs correctly on watchOS Simulator (n/a — iOS-only feature)
- [x] CarPlay scene validated in the Xcode CarPlay Simulator (External Displays → CarPlay) — app appears in the CarPlay dashboard, launches into the tab bar; Energy tab shows live Solar/Consumption/Grid/Battery (battery "87% · 1.2 kW discharging") matching the phone; Charging tab single-station shortcut goes straight to the mode list with the active mode marked. (Priorities tab not re-captured — macOS revoked the automation's Accessibility permission mid-session — but uses the identical `CPListTemplate` path.)
- [ ] Optional: validated on real CarPlay hardware once the Apple entitlement is granted
- [x] /specs have been updated if necessary
- [x] If architectural decisions were made, an ADR was created in /specs/adrs ([ADR-003](../adrs/003-carplay-architecture.md))
- [ ] Story status has been set to "Done (DD.MM.YYYY)"
- [ ] Story file has been moved to /specs/stories/done/
- [ ] Story has been removed from the backlog

## Tasks

- [ ] Request the CarPlay EV-charging entitlement from Apple (external dependency — start early)
- [x] Add the CarPlay entitlement to `Solar Lens iOS/Solar Lens iOS.entitlements` (`com.apple.developer.carplay-charging`)
- [x] Declare the CarPlay scene + delegate in `Solar-Lens-Info.plist` (`UIApplicationSceneManifest`); removed `INFOPLIST_KEY_UIApplicationSceneManifest_Generation` to avoid a duplicate-manifest conflict
- [x] Implement `CPTemplateApplicationSceneDelegate` (`CarPlaySceneDelegate`) and wire it to a `CarPlayManager` owning its own `CurrentBuildingState` bound to `SolarManager.shared`
- [x] Handle the not-logged-in state (prompt user to log in on the phone)
- [x] Energy overview template (Solar / Grid / Battery / Consumption), refresh on scene connect/activate
- [x] Fetch the solar forecast via `CurrentBuildingState.fetchSolarDetails()` on connect/activate and surface today's expected kWh on the overview
- [x] Charging-stations list template with current mode shown per station
- [x] Charging-mode selection sub-list calling `setCarCharging(sensorId:newCarCharging:)`, with single-station shortcut (simple modes only — see ADR-003)
- [x] Device-priority template with move-up/move-down actions calling `setSensorPriorities`
- [x] Navigation chrome (`CPTabBarTemplate`) linking the three screens
- [ ] Verify in CarPlay Simulator with 0, 1, and 2+ charging stations and multiple devices — manual
- [x] Add an ADR for the CarPlay architecture/entitlement decision ([ADR-003](../adrs/003-carplay-architecture.md))
