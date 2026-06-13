# Backlog
Holds ideas for stories that we may do in the future. Refined stories can be found in the ``stories`` subfolder. Done Stories in ``stories/done``.

## Ideas
### Car-Play support
- Add UI for Car-Play
- Ensure the entitlements are correct and the Apple Requirements for CarPlay are fullfilled
- CarPlay UX is very limited (template based).
- Screens:
		- A screen showing the current energy flow or at least shows the current values like Solar, Grid, Battery and Consumption. Maybe this screen can act as the home-screen of Solar Lens CarPlay and also host the menu/buttons to jumpt to the following two screens. Maybe also show the current forecast so the user can descide about charinging-modes etc.
		- A list of charging-stations (if multiple). Show the current charging-mode next to the charging station. Tab on the charging station shows the list of charging-modes and a tab on the mode changes the charging-mode of that charging station. If only one charging-station is present one does not need to pick the station.
		- Screen to change the device priorities. 
- Look at the watchOS screen for general UX. 
### Notification: Smart plug on/off
- Follow-up to story #5 (Notifications subsystem). Notify when a user-selected smart plug switches on or off.
- Different shape from the current threshold-based notifications (boolean state, plug selection, no kW threshold) — slot into the existing `NotificationMonitor` model or branch the protocol if too divergent.

### Notification: Live Activity
- Story #5 dropped Live Activity support when migrating Notify-on-Battery-Level out of Automations. The pre-scheduled "forecast backstop" notification still fires at the predicted moment, so users still get a heads-up — but they no longer get the live Dynamic Island / Lock Screen countdown.
- If user feedback shows this matters, port the existing `NotifyOnBatteryLevelPayload` / `NotifyOnBatteryLevelCardBody` LA pattern back over the new `NotificationMonitor` model.
### Make statistics exportable to Excel and/or CSV