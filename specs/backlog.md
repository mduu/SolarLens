# Backlog
Holds ideas for stories that we may do in the future. Refined stories can be found in the ``stories`` subfolder. Done Stories in ``stories/done``.

## Ideas
### Notification: Smart plug on/off
- Follow-up to story #5 (Notifications subsystem). Notify when a user-selected smart plug switches on or off.
- Different shape from the current threshold-based notifications (boolean state, plug selection, no kW threshold) — slot into the existing `NotificationMonitor` model or branch the protocol if too divergent.

### Notification: Live Activity
- Story #5 dropped Live Activity support when migrating Notify-on-Battery-Level out of Automations. The pre-scheduled "forecast backstop" notification still fires at the predicted moment, so users still get a heads-up — but they no longer get the live Dynamic Island / Lock Screen countdown.
- If user feedback shows this matters, port the existing `NotifyOnBatteryLevelPayload` / `NotifyOnBatteryLevelCardBody` LA pattern back over the new `NotificationMonitor` model.
### Make statistics exportable to Excel and/or CSV