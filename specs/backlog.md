# Backlog
Holds ideas for stories that we may do in the future. Refined stories can be found in the ``stories`` subfolder. Done Stories in ``stories/done``.

## Ideas

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

### New charging mode: Auto-reset to solar-only

### Make statistics exportable to Excel and/or CSV

### Upgrade deprecated Solar Manager endpoints
- Look at solar manager external API documentation (the newer one) and check which endpoints we use in SolarManagagerApi.swift
- Create a list in story with which endpoints do need upgrade and how to upgrade each of them (does it have a 1:1 replacement (which ) or do we need to change logic etc).
- See ``solarmanager_api.md``
