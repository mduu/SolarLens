# Story: #8, Should I Add a Battery to My House?

**Status:** Done (28.06.2026)

## Short Description

Help a household decide whether buying a home battery (a multi-thousand-CHF investment) is worth it, and roughly how large it should be. Introduce an **Efficiency sheet** (opened from the Efficiency card, for **all** users) with a period selector that shows autarky and self-consumption for the chosen period — today / week / month / year — consolidating numbers that are currently scattered across the Statistics tabs. For users **without** a battery, that sheet also hosts a "what-if" simulation that replays a selected past year of their own production/consumption data through a virtual battery — using their real, time-of-use import/export tariffs — and reports how much money they *could* have saved, plus the autarky and self-consumption they would have gained. As an immediate, lower-effort first step, extend the existing CSV/Excel export so customers can do their own analysis (e.g. sizing a battery from nighttime consumption across the seasons) in a spreadsheet. Battery **owners** already get the financial report on the battery sheet (`BatteryAdvantageCard`); this story extends it from today-only to a selectable period.

## Additional Information

### Origin — Customer Feedback

A customer (no battery yet) asked whether Solar Lens can expose historical production **and** consumption data at **hourly resolution**, primarily for **CSV export**, so they can analyse nighttime consumption across the seasons and derive the **minimum battery size** that would make sense for their home:

> Frage: kommst du an die historischen Produktions und Verbrauchsdaten auch in stündlicher Auflösung? Falls ja, wäre es möglich dies in den Statistiken unter „Custom" anzubieten (mir geht es primär um den CSV Export)?
>
> Ziel/Hintergrund: Ich möchte gerne meinen Verbrauch in der Nacht über die verschiedenen Jahreszeiten auswerten (um in diesem Fall die min. Grösse für eine Batterie zu ermitteln).

The customer also acknowledged the data-volume concern for a full year:

> Das müsste dann für ein ganzes Jahr sein oder? Ich glaube es ginge grundsätzlich, bin mir nur nicht sicher wegen der Datenmenge — vor allem seitens Solar Manager Server. Müsste man ausprobieren ob's bei ihnen zum Problem würde. Evtl. müsste man es dann in Tranchen zusammenfügen.

### Goal

The customer currently owns **no** battery and is weighing a purchase with a serious price tag. We want Solar Lens to:
1. Let them export their own high-resolution data for manual analysis (their explicit ask).
2. Go further and do the analysis *for* them: simulate "what if I had a battery last year?" and show the financial upside in CHF plus the autarky / self-consumption gain.

This complements the existing experience for battery **owners**, who already get a battery card with savings figures.

### What already exists in the app (reuse, don't reinvent)

**Battery detection**
- `OverviewData.hasAnyBattery` — true when any device has `deviceType == .battery` (`Shared/Services/Model/OverviewData.swift:103`). This already gates the battery card / sheet. We reuse it to decide owner vs. non-owner UX.

**Battery owner financial report (already shipped — Part B builds on this)**
- `BatterySheet` shows `BatteryStatusCard`, `BatteryTodayCard`, `BatteryAdvantageCard`, `BatteryDevicesCard` (`Solar Lens iOS/Home/Battery/BatterySheet.swift`).
- `BatteryAdvantageCard` (`Solar Lens iOS/Home/Battery/Components/BatteryAdvantageCard.swift`) already shows, for owners (`hasAnyBattery == true`):
  - **Grid import avoided** (kWh discharged) + **net CHF savings** via `TariffCalculator.batterySavings(...)`.
  - **Autarky improvement** (`+x.x%`) with the "without battery" baseline.
  - **Self-consumption improvement** (`+x.x%`) with the "without battery" baseline.
- watchOS has an equivalent `WatchBatteryAdvantageView`.
- ⇒ The backlog's "owners get money saved / added autarky / added self-consumption" idea is **already implemented**, but only for **today**. Part B of this story extends it with a **period selector** (today / week / month / year).

**Tariff engine (key reuse)**
- `TariffCalculator.resolveRate()` already resolves the correct rate for a given timestamp, honouring **weekday-specific schedules** (Mon–Fri / Sat / Sun) and **multiple time-of-use slots** (`Shared/Services/TariffCalculator.swift:70`).
- It already computes grid import cost, grid export revenue, and battery savings.
- Tariff DTOs: `TariffV1Response` (single, or high/low + directMarketing feed-in) and `TariffSettingsV3Response` (separate `purchase` / `feedIn` configs, up to 6 tariff levels with time-of-use schedules). Fetched from `/v3/users/{smId}/tariffs` (+ `/v3/users/{smId}/tariff/dynamic`), with v1 fallback.

**Historical energy data**
- `EnergyManager.fetchMainData(interval:)` returns time-series `MainDataItem`s, each already carrying `batteryChargedWh` / `batteryDischargedWh` plus production, consumption, grid import, grid export (`Shared/Services/Model/MainData.swift`).
- Backing endpoint: `/v3/users/{smId}/data/range`.
- Supported intervals (seconds): **300** (5 min), **3600** (1 h), **86400** (1 day). Current Statistics logic picks: 300s for ≤7 days, 3600s for 7–90 days, 86400s for >90 days (`Solar Lens iOS/Statistics/StatisticsViewModel.swift:258`).

**Statistics + export**
- Statistics screen supports Today / Week / Month / Year / Overall / **Custom** (user-selectable from/to + resolution day/week/month/year) — `Solar Lens iOS/Statistics/StatisticsScreen.swift`.
- `StatisticsExporter` already produces **CSV** (semicolon-delimited) and **XLSX** (SimpleXLSXWriter). Current columns: `Date;Production (kWh);Consumption (kWh);Grid Import (kWh);Grid Export (kWh)`, **aggregated by day** (`Solar Lens iOS/Statistics/StatisticsExporter.swift`).

**Settings / gating**
- Settings persist via `AppStorage` (e.g. `stats.*.show…` series toggles).
- Environment gating today is `#if DEBUG` only (server URL switch in `ServerUrls.swift`). **There is no TestFlight detection in the codebase yet** — see "Feature gating" below.

### Scope — four parts

#### Part A — Hourly (and finer) CSV/Excel export (the customer's direct ask)

Enhance `StatisticsExporter` and the Custom-range export so users can export at **sub-daily resolution**:
- Add export resolution options: **hourly (3600s)** at minimum; optionally 15/30-min where the API interval allows (the API exposes 300s; 15/30-min would be derived by re-bucketing 300s data).
- For sub-daily export, emit one **row per interval** with a full timestamp column (`DateTime`) instead of one row per day.
- Suggested columns for the high-resolution export:
  `DateTime;Production (kWh);Consumption (kWh);Grid Import (kWh);Grid Export (kWh);Battery Charge (kWh);Battery Discharge (kWh)`
  (battery columns are 0 for non-owners but kept for a consistent schema).
- Make the Custom range honour an **hourly** resolution choice (today the custom resolution picker is day/week/month/year).

**Data-volume handling (customer's concern):** A full year at hourly resolution is ~8,760 rows — fine for CSV/XLSX, but the Solar Manager `/data/range` call must be **chunked** (e.g. monthly tranches) and stitched together, with a progress indicator, to avoid overloading the SM server and to stay within response-size limits. Reuse the chunking strategy designed for Part C.

#### Part B — Battery owners: period selection on the financial report

For users where `hasAnyBattery == true`, the battery sheet **already** answers "what is my battery doing for me?" via `BatteryAdvantageCard`: money saved (CHF, tariff-adjusted), added autarky, and added self-consumption, each with a "without battery" baseline. The card today is **today-only**.

This story upgrades it to a **selectable period**:
- Add a period selector to the battery advantage report: **today / week / month / year** (and ideally a custom range, consistent with the Statistics screen).
- Re-fetch `MainData` for the selected period via `EnergyManager.fetchMainData(interval:)` and recompute `TariffCalculator.batterySavings(...)`, autarky improvement, and self-consumption improvement over that period.
- Pick the fetch interval by period length (reuse the Statistics heuristic: 300s ≤7 days, 3600s 7–90 days, 86400s >90 days) and reuse the chunked-fetch strategy for long periods.
- Persist the chosen period via `AppStorage` so it sticks across launches.
- Keep look & feel consistent with the existing card and the `EfficiencyGaugeView` gauges.
- Apply the same upgrade to the watchOS `WatchBatteryAdvantageView` where feasible.

#### Part C — New "Efficiency" sheet for all users (period selector for autarky & self-consumption)

Add a dedicated **Efficiency sheet**, opened by tapping the **Efficiency card** on the home dashboard (`EfficiencyGaugeView`). It is available to **all** users (battery owners and non-owners alike).

The home card today shows self-consumption and autarky gauges for **today** only. The Statistics screen *can* show autarky/self-consumption for other periods, but it is spread across separate tabs (Week / Month / Year / Overall / Custom) and mixed with many other series. This sheet **consolidates** the efficiency story into one focused place:
- A **period selector** at the top: **today / week / month / year** (and ideally a custom range, consistent with the Statistics screen).
- The two headline numbers for the selected period: **Autarky** (self-sufficiency %) and **Self-consumption %**, rendered with the existing gauge styling (autarky purple, self-consumption indigo).
- Optionally the supporting absolute figures for the period (production, consumption, grid import/export) so the percentages are legible.
- Re-fetch `MainData` for the selected period via `EnergyManager.fetchMainData(interval:)` and compute autarky/self-consumption over that period (reuse the existing Statistics computation rather than duplicating it). Pick the fetch interval by period length (Statistics heuristic) and reuse the chunked fetch for long periods.
- Persist the chosen period via `AppStorage` so it sticks across launches.

This sheet is the natural home for the battery what-if (Part D): "here's your efficiency — and here's how much a battery could improve it."

#### Part D — Battery what-if simulation (non-owners only), inside the Efficiency sheet

Within the Efficiency sheet, **non-battery owners** (and tester builds — see Feature gating) get an additional **"What if I had a battery?"** section that:
1. Lets the user pick a **year** (default: last full calendar year) and a **battery capacity** to simulate. The user can **enter their own custom capacity** (free numeric input in kWh) and/or compare against a small preset **sweep** (e.g. 5 / 10 / 15 kWh). Because the customer wants to find the *minimum* sensible size, the sweep shows diminishing returns while the custom field lets them model a specific product they're considering.
2. Fetches that year's production & consumption at an appropriate interval (see "Query optimization") via `/v3/users/{smId}/data/range`.
3. Runs an on-device **battery simulation** over the series: at each interval, charge the virtual battery from PV surplus and discharge it to cover load, bounded by capacity, max charge/discharge power, and round-trip efficiency.
4. Applies the user's **real configured import/export tariffs** through `TariffCalculator.resolveRate()` (time-of-use, weekday-aware) to value avoided grid import and changed feed-in.
5. Reports, for the selected year:
   - **CHF saved** (and a simple payback hint if the user enters an approximate battery price — optional).
   - **Autarky** and **self-consumption** before vs. after the virtual battery (tying directly back to the period numbers at the top of the sheet).
   - A short, plain-language verdict ("A ~10 kWh battery would have saved you ~CHF 480 last year").
6. Shows a **progress animation — ideally a real progress bar** — while fetching and computing, because a full year of fine-grained data takes noticeable time.

Battery owners open the same Efficiency sheet but **do not** see the what-if section (their actual battery advantage already lives on the battery sheet, Part B).

### Simulation model — parameters & assumptions

| Parameter | Default | Notes |
|---|---|---|
| Usable capacity | custom user-entered kWh, plus preset sweep 5 / 10 / 15 kWh | The size question is the whole point — let users enter their own size and compare against presets. |
| Max charge / discharge power | user-adjustable, default e.g. 7 kW each | Caps per-interval throughput. Real home batteries commonly handle 7 kW+ in/out, so the default must not be too low — let the user set it. |
| Round-trip efficiency | ~90% | Apply as charge × √η in, discharge × √η out (or a single round-trip factor). |
| Reserve / min SoC | **5%** (fixed for now) | Battery never discharges below 5%. Shown to the user on the sheet for transparency. |
| Initial SoC | 0% (or 50%) | Negligible over a full year. |
| Tariff source | user's real `TariffV1/V3` via `TariffCalculator` | No synthetic prices — accuracy is the value prop. |

Greedy per-interval dispatch (PV-surplus-charges, load-discharges) is sufficient for an estimate; an explicit note in the UI should state this is an **estimate**, not a guarantee, and that real-world results depend on the chosen device, degradation, and future consumption.

**Conservative by design — footnote in the simulator:** the greedy model captures only "store surplus, cover load." A real battery owner can optimize **further** and save **more** than the simulated figure, for example:
- Pre-emptively discharging the battery to flexible loads before they'd otherwise draw from grid (e.g. charge the EV from the battery before leaving in the morning) so the battery is empty and can buffer the day's PV surplus instead of exporting it cheaply.
- Time-of-use / tariff arbitrage: charging from cheap grid in low-tariff windows, discharging during high-tariff windows.
- Peak shaving and other load-shifting strategies.

The simulator should show a short footnote making clear the result is a **conservative lower bound** — actively managing the battery can realise additional savings beyond this number.

### Query optimization (data volume)

A full year is large; optimize and **chunk** SM `/data/range` requests:
- Choose interval by the simulation's needs vs. cost. **Hourly (3600s)** is a good default for a year-long what-if (8,760 points); 15/30-min materially improves accuracy of surplus/deficit accounting but multiplies data volume. Make the interval a deliberate choice (document the trade-off; consider 60min default, 30/15min as "high accuracy" opt-in).
- **Chunk** the year into tranches (e.g. monthly) to respect SM server limits and to drive the progress bar (one tranche ≈ one progress step). Stitch tranches together client-side, as the customer themselves suggested ("in Tranchen zusammenfügen").
- Cache fetched tranches for the session so re-running the sweep across capacities doesn't re-download the year.

### Feature gating

- **Efficiency sheet (Part C):** available to **all** users regardless of battery ownership.
- **What-if simulation (Part D) — production behaviour:** the simulation section is shown to **non-battery owners only** (`hasAnyBattery == false`). Battery owners open the Efficiency sheet but the what-if section is hidden (their real battery advantage already lives on the battery sheet, Part B).
- **What-if simulation (Part D) — testing behaviour:** for TestFlight and local testing, the simulation must be available to **all** users (including battery owners) so it can be exercised on real installations that have battery history. There is currently **no TestFlight detection** in the codebase — add a small helper (e.g. detect sandbox App Store receipt / `appStoreReceiptURL` ending in `sandboxReceipt`, combined with `#if DEBUG`) to express "is this a tester build?" and gate the what-if section on `isTesterBuild || !hasAnyBattery`. Document the chosen mechanism in an ADR.

## Expected Result

- **Export (Part A):** From the Statistics → Custom range, a user can export CSV/XLSX at **hourly** (and ideally 15/30-min) resolution, with one timestamped row per interval and battery columns included. A full year exports successfully via chunked SM queries with a progress indicator, without overloading the Solar Manager server.
- **Owners (Part B):** The battery sheet's advantage report (money saved + added autarky + added self-consumption) gains a **period selector** (today / week / month / year, ideally custom range) instead of being today-only, with the chosen period persisted.
- **Efficiency sheet (Part C):** Tapping the Efficiency card opens a sheet, available to **all** users, with a period selector (today / week / month / year, ideally custom) that shows **autarky** and **self-consumption** for the selected period — consolidating what is today scattered across Statistics tabs. The chosen period is persisted.
- **What-if simulation (Part D):** Inside that sheet, a non-owner can run a "What if I had a battery?" simulation for a chosen year and battery size — entering a **custom capacity** and/or comparing against a preset size sweep. The app fetches their real data, applies their real time-of-use tariffs, and reports CHF saved plus before/after autarky and self-consumption, with a progress bar during the run and a plain-language verdict that helps size the battery.
- **Gating:** The Efficiency sheet is for everyone; the what-if section is non-owner-only in production and available to everyone in DEBUG/TestFlight.
- The simulation result is clearly labelled an **estimate**.

## Test Checklist
- [x] App builds successfully (iOS via Xcode, watchOS via xcodebuild)
- [ ] App runs correctly on watchOS Simulator (simulator runtime out of date locally; verify on-device)
- [ ] Optional for UI changes: UI validated on Apple Watch hardware or simulator
- [x] /specs have been updated (userinterface.md, solarmanager_api.md)
- [x] If architectural decisions were made, an ADR was created in /specs/adrs (ADR-004 simulation model, ADR-005 tester-build gating)
- [x] Story status has been set to "Done (28.06.2026)"
- [x] Story file has been moved to /specs/stories/done/
- [x] Story has been removed from the backlog

> **Follow-ups (tracked outside this story):**
> - watchOS Part B (period selector on `WatchBatteryAdvantageView`) left as today-only.
> - Translations (de/da/fr/it) for the ~36 new strings still pending (run `/translate`).
> - Dynamic tariff valuation covers near-term only; historical periods fall back to the static tariff.
> - Winter/summer tariff window uses the Oct–Mar convention (SM config carries no boundaries).

## Tasks

### Part A — High-resolution export
- [ ] Add an export-resolution option (hourly min.; 15/30-min if feasible by re-bucketing 300s data) to the Custom-range export UI
- [ ] Extend `StatisticsExporter` to emit one timestamped row per interval (`DateTime` column) for sub-daily resolution, including `Battery Charge`/`Battery Discharge` columns
- [ ] Reuse chunked `/data/range` fetching (Part C) so a full year exports without overloading the SM server; show progress
- [ ] Verify CSV (semicolon) and XLSX outputs open cleanly in Excel / Numbers

### Part B — Battery owner financial report: add period selection
- [x] Money saved (CHF) on the battery sheet — `BatteryAdvantageCard` via `TariffCalculator.batterySavings` (exists, today-only)
- [x] Added autarky and added self-consumption with "without battery" baseline — `BatteryAdvantageCard` (exists, today-only)
- [ ] Add a period selector (today / week / month / year, ideally custom range) to the battery advantage report
- [ ] Re-fetch `MainData` per selected period and recompute savings / autarky / self-consumption improvements over that period
- [ ] Choose fetch interval by period length (reuse Statistics heuristic) and reuse chunked fetch for long periods
- [ ] Persist the selected period via `AppStorage`
- [ ] Apply the same period selector to watchOS `WatchBatteryAdvantageView` where feasible

### Part C — "Efficiency" sheet for all users
- [ ] New Efficiency sheet, opened from the Efficiency card (`EfficiencyGaugeView`), available to all users
- [ ] Period selector (today / week / month / year, ideally custom range) at the top of the sheet
- [ ] Show **autarky** and **self-consumption** for the selected period with existing gauge styling (autarky purple, self-consumption indigo); optionally supporting absolute figures
- [ ] Re-fetch `MainData` per selected period and reuse the existing Statistics autarky/self-consumption computation (don't duplicate)
- [ ] Choose fetch interval by period length (Statistics heuristic) and reuse chunked fetch for long periods
- [ ] Persist the selected period via `AppStorage`

### Part D — Battery what-if simulation (non-owners), inside the Efficiency sheet
- [ ] "What if I had a battery?" section in the Efficiency sheet, shown for non-owners (and tester builds)
- [ ] Year picker (default last full year) + custom battery capacity entry (free kWh input) + preset size sweep (e.g. 5/10/15 kWh) + user-adjustable max charge/discharge power (default ~7 kW) & efficiency params
- [ ] On-device greedy battery dispatch simulation over the interval series (5% min SoC reserve, never discharge below it)
- [ ] Surface the assumptions used on the sheet for transparency (e.g. "min SoC 5%", capacity, max power, round-trip efficiency)
- [ ] Apply real time-of-use tariffs via `TariffCalculator.resolveRate()` (v3 with v1 fallback)
- [ ] Output: CHF saved, before/after autarky & self-consumption (relative to the period numbers above), plain-language verdict; optional payback hint from user-entered price
- [ ] Progress bar covering fetch + compute; tranche-based progress steps
- [ ] "Estimate, not a guarantee" disclaimer
- [ ] Footnote: result is a **conservative lower bound** — active battery management (e.g. discharging to the EV before leaving so the battery can buffer more PV, tariff arbitrage, peak shaving) can save even more

### Cross-cutting
- [ ] Chunk SM `/data/range` into monthly tranches, stitch client-side, cache per session
- [ ] Pick & document default interval (60min) and high-accuracy opt-in (30/15min) trade-off
- [ ] Add tester-build detection (`#if DEBUG` + App Store sandbox receipt) and gate the Part D what-if section on `isTesterBuild || !hasAnyBattery`
- [ ] ADR: simulation model & assumptions; ADR: tester-build gating mechanism
- [ ] Update `specs/userinterface.md` (new Efficiency sheet + export changes) and `specs/architecture.md` if needed
