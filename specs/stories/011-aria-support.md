# Story: #11, Full Support for Solar Manager Aria

**Status:** Open

## Short Description

Aria is Solar Manager's new forecast-based AI optimization (launched June 2026). Solar Lens currently only *displays* Aria when a battery or car charger is in that mode. This story adds full support: switching devices to Aria (battery, car charger, heat pump, water heater) with the Aria-specific settings, but only for installations that actually have Aria.

## Additional Information

### What Aria is

- Plans instead of reacts: Aria continuously builds a schedule and re-plans when weather or prices change.
- Inputs: PV forecast (weather), household consumption profile, dynamic purchase and feed-in tariffs, temperature curves and building characteristics.
- Goal: the economically best outcome — charge the battery when power is cheap, cut high-tariff peaks, charge the EV ahead of time, use negative prices.
- Devices: heat pump, water heater, EV charger, battery. The user releases the devices Aria may control in the Solar Manager app. No mention of V2X.
- The Solar Manager app shows an Aria widget, a live status with each device's current priority and the reason, and a 12-hour preview of the plan.

Sources: [Aria page](https://www.solarmanager.ch/aria-intelligente-energieoptimierung-fuer-dein-zuhause/), [Aria article](https://www.solarmanager.ch/solar-manager-aria-intelligentes-energiemanagement-das-fuer-dich-denkt/), [installer article](https://www.solarmanager.ch/solar-manager-aria-die-nchste-stufe-im-energiemanagement-fr-moderne-pv-projekte/), [pricing](https://www.solarmanager.ch/preise-und-abo-funktionen/).

### Availability (as of 2026-11)

- **Premium subscription only** (CHF 66 / € 72 per year; Basic is CHF 44). New installations can test Premium for 3 months.
- **Gradual rollout:** tested by selected customers and released step by step; must be actively unlocked after release.
- Beta testers are asked to have a **dynamic tariff**. Unclear whether this stays a requirement.
- Not documented: device compatibility list for Aria, gateway hardware / firmware requirements, countries.

### What the API offers (v1.91.4)

| Device | Endpoint | Aria mode | Aria settings |
|---|---|---|---|
| Battery | `PUT /v2/control/battery/{sensorId}` | `batteryMode` 6 (formerly "AI Optimization") | `mpcLowerSocLimit` (%), `mpcUpperSocLimit` (%), `mpcChargingFromGrid` (bool) |
| Car charger | `PUT /v1/control/car-charger/{sensorId}` | `chargingMode` 8 | none |
| Heat pump | `PUT /v1/control/heat-pump/{sensorId}` | `heatPumpChargingMode` 8 | `mpcHeatPumpSettings` (0 = brine-water, 1 = air-water) |
| Water heater | `PUT /v1/control/water-heater/{sensorId}` | `waterHeaterMode` 7 | `mpcGeneralMainHotWater` (device is the main hot water source; must be sent together with the mode) |

Not available in the API:
- No flag "Aria is unlocked for this installation".
- No access to Aria's plan, the 12-hour preview or the reasons per device.
- `GET /v1/subscription` returns product name, type, fee and end date — enough to guess "Premium", but not whether Aria is unlocked.

### Current state in Solar Lens

- `ChargingMode.aria` (8) and `BatteryMode.Aria` (6) exist and are shown correctly (commits `ccbdbd7`, `55eb52e`).
- Both are **display-only**: `.aria` is excluded from `ChargingMode.allCases`, so pickers, Watch, CarPlay and automations don't offer it; `BatteryModeSheet` doesn't list Aria and `BatteryModeOptionsSheet` shows "Not supported!" for it.
- In Shortcuts, Aria may appear as an `AppEnum` value; `SetChargingModeIntent` rejects it as "not yet supported".
- Heat pump and water heater control are not implemented in Solar Lens at all.

### Why it is not selectable yet

1. Solar Lens cannot tell whether Aria is unlocked for an installation. The API behaviour when setting an Aria mode without the unlock is undocumented — worst case the call succeeds and the device stays idle (car not charging).
2. Battery Aria comes with settings (SoC limits, grid charging) that need their own UI.
3. Aria optimizes across all released devices. Switching single devices from Solar Lens can create mixed states; how Aria interacts with manual per-device modes is undocumented.
4. **The developer has no installation with Aria** — nothing can be tested end to end. This story is blocked until a tester with Aria is available (or Solar Manager provides a test account).

### Open questions (clarify with Solar Manager)

- What happens when an Aria mode is set on an installation without Aria (error code, ignored, accepted)?
- Is there (or will there be) an API field that says Aria is available/unlocked?
- Does setting one device to Aria via API also "release" it in the Aria configuration, or are these separate concepts?
- What defaults apply to the battery `mpc*` settings if they are omitted?
- Will the Aria plan / 12-hour preview be exposed via the API? (Would allow a "What Aria is planning" card in Solar Lens.)
- Is a dynamic tariff a hard requirement?

## Expected Result

- Installations with Aria can switch battery and car charger to Aria from iOS, watchOS and CarPlay, and via Shortcuts and automations.
- Battery Aria has an options sheet for lower/upper SoC limit and grid charging, analogous to Eco / Peak shaving.
- Installations without Aria never see Aria as a selectable option; existing display of an active Aria mode keeps working.
- Aria has its own icon/colour and a short, calm explanation in the mode picker (en, de, da, fr, it).
- Optional (if heat pump / water heater control is added later): Aria modes for those devices with their settings.

## Test Checklist
- [ ] App builds successfully
- [ ] App runs correctly on watchOS Simulator
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [ ] Tested on a real installation **with** Aria (battery and car charger switched to Aria and back)
- [ ] Tested on an installation **without** Aria: no Aria option visible, display unchanged
- [ ] Shortcuts / automations with Aria verified
- [ ] /specs have been updated if necessary
- [ ] If architectural decisions were made, an ADR was created in /specs/adrs
- [ ] Story status has been set to "Done (DD.MM.YYYY)"
- [ ] Story file has been moved to /specs/stories/done/
- [ ] Story has been removed from the backlog

## Tasks

- [ ] Find a beta tester with Aria (or ask Solar Manager for a test account) — **blocker**
- [ ] Clarify the open questions with Solar Manager
- [ ] Decide the availability detection: API flag (if offered) > device seen in Aria mode before > Premium subscription via `/v1/subscription`
- [ ] Persist "Aria available" per installation and expose it via `CurrentBuildingState`
- [ ] Car charger: include `.aria` in selectable modes when available (iOS picker, Watch, CarPlay, `ChargingModeConfiguration`, automations); allow it in `SetChargingModeIntent`
- [ ] Battery: add Aria to `BatteryModeSheet`; `BatteryModeOptionsSheet` with `mpcLowerSocLimit`, `mpcUpperSocLimit`, `mpcChargingFromGrid`; extend `BatteryModeInfo` / control request DTO with the `mpc*` fields
- [ ] Mode descriptions and translations (en, de, da, fr, it)
- [ ] Optional: "What Aria is planning" card if the API exposes the plan
- [ ] Optional: heat pump (mode 8, `mpcHeatPumpSettings`) and water heater (mode 7, `mpcGeneralMainHotWater`) once those devices are controllable in Solar Lens
- [ ] Update `specs/solarmanager_api.md` (endpoints used, Aria notes)
