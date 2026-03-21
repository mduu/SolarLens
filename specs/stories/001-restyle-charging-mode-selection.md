# Story: #1, Re-style Charging Mode Selection

**Status:** Open

## Short Description

Redesign the charging mode selection UI on both iOS and watchOS so that all (or more) charging modes are visible without scrolling, the layout accommodates future additional modes, and multiple charging stations remain supported.

## Additional Information

The current `ChargingModePickerView` (iOS) renders charging modes as a vertical list of rows inside a single card. With 8 modes (and the ability to hide some via `ChargingModeConfiguration`), the list often requires scrolling — especially on smaller iPhones or when car info cards are also shown at the top.

The watchOS equivalent (`ChargingStationModeView` / `ChargingScreen`) has similar constraints due to the small screen.

### Current structure (iOS)

The charging mode picker sheet (`ChargingModePickerView.swift`) contains:
1. **Car info cards** — shown in pairs, each with battery % and remaining km
2. **Charging station status** — icon, current power, today's total
3. **Mode picker** — vertical list of `chargingModeRow` entries, each with icon, label, and checkmark if selected

Each mode row is a bordered rounded rectangle (12pt radius) with an icon badge (36x36), label, and checkmark. Selected mode gets a tinted background and border.

### Charging modes (8 total, from `ChargingMode`)

| Mode | Icon | Color |
|------|------|-------|
| Solar only | `sun.max` | Yellow |
| Solar or low tariff | `sunset` | Orange |
| Always charge | `24.circle` | Teal |
| Off | `poweroff` | Red |
| Constant current | `glowplug` | Green |
| Minimal + solar | `fluid.batteryblock` | Yellow |
| Minimum quantity | `minus.plus.and.fluid.batteryblock` | Blue |
| Target SoC | `bolt.car` | Purple |

Users can hide modes via `ChargingModeConfiguration` (persisted in AppStorage).

### Key files

- **iOS:** `Solar Lens iOS/Home/Charging/ChargingModePickerView.swift` — main sheet
- **iOS:** `Solar Lens iOS/Home/Charging/ChargingView.swift` — home screen card entry point
- **iOS:** `Solar Lens iOS/Home/Charging/ChargingStationView.swift` — station view
- **iOS:** `Solar Lens iOS/Home/Charging/ChargingOptionsPopupView.swift` — options for non-simple modes
- **watchOS:** `Solar Lens Watch App/Charging/ChargingStationModeView.swift` — mode selection
- **watchOS:** `Solar Lens Watch App/Charging/ChargingScreen.swift` — charging screen
- **Shared:** `Shared/Features/Consumption/Charging/ChargingModeConfiguration.swift` — visibility persistence
- **Shared:** `Shared/Features/Consumption/Charging/ChargingModelLabelView.swift` — mode label

## Expected Result

- Charging modes are displayed in a **2-column grid** layout, making each mode a more rectangular touch target instead of a full-width row.
- More modes are visible at once; scrolling is acceptable but significantly reduced compared to today.
- The layout accommodates future additional modes (at least 2 more are planned for the next story).
- Multiple charging stations (typically 1, sometimes 2+) are still supported and listed separately.
- Multiple cars (typically 1–2, occasionally 3) are displayed correctly without dominating the sheet.
- The currently selected mode is clearly indicated.
- Modes that require additional options (non-simple modes) still open the options popup.

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

- [x] Implement 2-column grid layout for charging modes in `ChargingModePickerView.swift` (each mode as a compact rectangular card with icon + label)
- [x] Ensure the grid works well with even and odd numbers of visible modes
- [x] Ensure non-simple modes still trigger `ChargingOptionsPopupView`
- [x] watchOS: kept as full-width rows — 2-column grid would create too-small touch targets on 40-46mm screens
- [ ] Test with 1, 2, and 3+ charging stations (typically 1, sometimes 2+)
- [ ] Test with 1, 2, and 3 cars (typically 1–2, occasionally 3)
- [ ] Test with various modes hidden via `ChargingModeConfiguration`
- [ ] Verify landscape layout on iOS still works
