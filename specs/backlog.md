# Backlog
Holds ideas for stories that we may do in the future. Refined stories can be found in the ``stories`` subfolder. Done Stories in ``stories/done``.

## Ideas

### Re-style charging mode selection
- Show more (all) charging modes without the need to scroll.
- Make room for additional charging modes.
- If a user have multiple charging station more of them get - at partially - visible.
- Do this on the iOS and the watchOS app.
- Make sure multiple charging stations still gets supported and listed below each other (as today).
### New charging mode: Transfer from battery to car
- In branch ``79-add-scenario-charge-car-from-battery-only`` there is a draft of a new scenario management. I am not happy with that implementation but there is draft implementation of a background worker (in ``ScenarioManager``). Maybe what makes sense for this implementation too.
- The mode works as follows:
	1. Select the mode from the respective charging station.
	2. Ask the user for how much power (%) should remain in the house battery. Also ask the user what charging-mode should be selected after this charging-mode (process is done) and default to "solar".
	3. Switch to charging-mode "constant" and automatically choose the minimal power based on the max. throughput the battery can provide so charging starts using energy only from the battery but not from the grid.
	4. Monitor the process and increase the energy flowing (parameter from "constant" mode) accordingly as sunshine can change or more other cosumers kick in. All together should only use battery.
	5. If the user selected battery percentage is reached or if the total consumption is too high to only use batter (notable grid import happen) end this charging mode.
	6. Switch to the user selected charging-mode in step 2.
	7. Show a notification (iOS local "push" notification) to the user with a summary / info that the mode stopped on x % of house battery.

### New charging mode: Auto-reset to solar-only

### Make statistics exportable to Excel and/or CSV

### Upgrade deprecated Solar Manager endpoints
- Look at solar manager external API documentation (the newer one) and check which endpoints we use in SolarManagagerApi.swift
- Create a list in story with which endpoints do need upgrade and how to upgrade each of them (does it have a 1:1 replacement (which ) or do we need to change logic etc).
- See ``solarmanager_api.md``
