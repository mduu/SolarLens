# Backlog
Holds ideas for stories that we may do in the future. Refined stories can be found in the ``stories`` subfolder. Done Stories in ``stories/done``.

## Ideas

### Notification: Improve battery-level notification timing
- Customer feedback (v4.1): the battery-level notification often arrives much too late. Root cause analysis (v4.1 vs. v4.2 — mechanism unchanged): the 5-min poll only runs in background when iOS grants a BG refresh, which is opportunistic and often delayed by 15–60+ min. The 15-min linear forecast backstop only helps when (a) the app got a tick shortly before the threshold and (b) the extrapolated charge rate holds — it misses when charge/discharge fluctuates.
- Improvement ideas, in ascending effort:
  1. Widen the forecast-backstop window (e.g. 60 min instead of 15) and re-adjust the pre-scheduled notification on every tick — cheapest lever, no new infrastructure.
  2. Staggered backstops (e.g. at forecasted −10 %, −5 %, and threshold) that replace each other as forecasts refresh.
  3. Server-side pushes via the existing Azure Functions backend — the only path to genuinely reliable timing since it is independent of iOS BG scheduling; requires push registration, server-side monitor state, and APNs setup.
- Applies to all threshold notifications, but battery level is where customers notice latency (slow-moving value, user waits for it).

### Notification: Smart plug on/off
- Follow-up to story #5 (Notifications subsystem). Notify when a user-selected smart plug switches on or off.
- Different shape from the current threshold-based notifications (boolean state, plug selection, no kW threshold) — slot into the existing `NotificationMonitor` model or branch the protocol if too divergent.

### Notification: Live Activity for the Battery-Level monitor
- Story #5 dropped Live Activity support when migrating Notify-on-Battery-Level out of Automations. The pre-scheduled "forecast backstop" notification still fires at the predicted moment, so users still get a heads-up — but they no longer get the live Dynamic Island / Lock Screen countdown.
- If user feedback shows this matters, port the existing `NotifyOnBatteryLevelPayload` / `NotifyOnBatteryLevelCardBody` LA pattern back over the new `NotificationMonitor` model.

### Re-style charging mode selection
- Show more (all) charging modes without the need to scroll.
- Make room for additional charging modes.
- If a user have multiple charging station more of them get - at partially - visible.
- Do this on the iOS and the watchOS app.
- Make sure multiple charging stations still gets supported and listed below each other (as today).
  
### Automation: Transfer from battery to car
- In branch ``79-add-scenario-charge-car-from-battery-only`` there is a draft of a new scenario management. I am not happy with that implementation but there is draft implementation of a background worker (in ``ScenarioManager``). Maybe what makes sense for this implementation too.
- A new tab on the mainscreen called "Automation"
- On this tab there will be advanced automation workflows in the future. Currently we do one automatisch which is "Transfer from Battery to Car".
- The automation works as follows:
	1. Select the charging station.
	2. Ask the user for how much power (%) should remain in the house battery. Also ask the user what charging-mode should be selected after this charging-mode (process is done) and default to "solar".
	3. Switch to charging-mode "constant" and automatically choose the minimal power based on the max. throughput the battery can provide so charging starts using energy only from the battery but not from the grid.
	4. Monitor the process and increase/decrease the energy flowing (parameter from "constant" mode) accordingly as sunshine (PV, solar) changes and/or other consumers kick in. All together should only use battery; no grid.
	5. If the selected battery percentage is reached or if the total consumption is too high to only use batter (notable grid import happen) end this charging mode.
	6. Switch to the user selected charging-mode (see step 2).
	7. Show a notification (iOS local "push" notification) to the user with a summary / info that the mode stopped on x % of house battery and how much energy as transfered.
- Implement it with pure client-side in the app - no server usage.
- Add a cancel feature to cancel the automation before it is done. If the automation is cancelled, the charing mode from step 2 is activated.
- If an automation is aready running, no other automation can be started.
- The UI should match the style of the existing UI and also look modern and let the user feel like "AI" (artificial intelligence). This means color gradient effects in purple/pink/blue etc.

### Make statistics exportable to Excel and/or CSV