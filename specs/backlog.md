# Backlog
Holds ideas for stories that we may do in the future. Refined stories can be found in the ``stories`` subfolder. Done Stories in ``stories/done``.

## Ideas

### Notification: Smart plug on/off
- Follow-up to story #5 (Notifications subsystem). Notify when a user-selected smart plug switches on or off.
- Different shape from the current threshold-based notifications (boolean state, plug selection, no kW threshold) — slot into the existing `NotificationMonitor` model or branch the protocol if too divergent.

### Notification: Live Activity
- Story #5 dropped Live Activity support when migrating Notify-on-Battery-Level out of Automations. The pre-scheduled "forecast backstop" notification still fires at the predicted moment, so users still get a heads-up — but they no longer get the live Dynamic Island / Lock Screen countdown.
- If user feedback shows this matters, port the existing `NotifyOnBatteryLevelPayload` / `NotifyOnBatteryLevelCardBody` LA pattern back over the new `NotificationMonitor` model.

### Re-style charging mode selection
- Show more (all) charging modes without the need to scroll.
- Make room for additional charging modes.
- If a user have multiple charging station more of them get - at partially - visible.
- Do this on the iOS and the watchOS app.
- Make sure multiple charging stations still gets supported and listed below each other (as today).
  
### Automation: Battery-to-Car — add automated tests (tech debt from story #3)
- Story #3 shipped without the automated tests it specified. Backfill them for the pure, already-extracted controller functions:
  - `AmperageRamp.compute(...)`: ramp up, ramp down, dead-band, clamp at 6 A, clamp at 32 A, battery-charging-as-surplus branch.
  - `convertPowerToAmps`: 1-phase, 3-phase, edge values.
  - `SoftFloor.computeSafetyBuffer(...)`: foreground tick (≈1%), mild BG gap (≈4%), long BG gap (clamped 8%), tiny discharge (clamped 1%), zero/negative discharge (minBufferPct).
  - Integration test with `FakeEnergyManager` over a synthetic PV+load hour.
- Also still open from #3: field-tune the 200 W grace band (`AmperageRamp.defaultGraceW`) on a heat-pump installation.

### Make statistics exportable to Excel and/or CSV