import SwiftUI
internal import UserNotifications

@main
struct Solar_Lens_iOSApp: App {
    /// Receives the APNs device token for the server wake schedule (story #9).
    @UIApplicationDelegateAdaptor(PushRegistrar.self) private var pushRegistrar

    @State var currentBuildingState = CurrentBuildingState(
        energyManagerClient: SolarManager.shared)
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // One-shot migration of legacy NotifyOnBatteryLevel automation
        // state into the new NotificationManager store. Must run BEFORE
        // AutomationManager.restorePersistedState (called from its
        // private init) reads the legacy keys, otherwise the now-removed
        // Automation enum case would fail to decode and the running
        // monitor would be silently dropped. See ADR-002.
        NotificationMigration.runIfNeeded()

        AutomationManager.shared.registerBackgroundTask()
        // Touch the shared NotificationManager so its init() restores
        // any persisted monitors and the foreground timer arms itself.
        _ = NotificationManager.shared

        // Make automation notifications visible while the app is in the
        // foreground — without this iOS only adds them to Notification
        // Center and the user has to leave the app to see them.
        UNUserNotificationCenter.current().delegate =
            AutomationNotificationDelegate.shared
        AutomationNotificationDelegate.shared.registerCategories()

        LiveActivityCancelHandler.shared = {
            AutomationManager.shared.cancelActiveAutomation()
        }

        // Activate the watch bridge synchronously so the WCSession
        // delegate is set before iOS delivers any queued transferUserInfo
        // commands from the watch.
        AutomationWatchBridge.shared.start()

        // A rotated APNs token invalidates whatever the server has for this
        // device, so re-register the running automation under the new one.
        PushRegistrar.onTokenChanged = { _ in
            Task { @MainActor in
                // Forced: the old token is dead, so the standing registration
                // must be replaced even if it is recent.
                AutomationManager.shared.resyncWakeSchedule(force: true)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(currentBuildingState)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    AutomationManager.shared
                        .handleScenePhaseChange(oldPhase, newPhase)
                    NotificationManager.shared
                        .handleScenePhaseChange(oldPhase, newPhase)

                    // Refresh OverviewData on return to foreground so any
                    // charging station / battery state mutated while the app was
                    // backgrounded shows up immediately. The 5 s debounce
                    // inside CurrentBuildingState absorbs scene-phase
                    // flickers (.inactive ↔ .active blink during transitions).
                    if newPhase == .active {
                        // Notification permission may have been granted since
                        // the last launch; ask for the token again (no-op if
                        // we already have one) and make sure the server still
                        // knows about a running automation.
                        PushRegistrar.registerIfAuthorized()
                        AutomationManager.shared.resyncWakeSchedule()

                        Task {
                            await currentBuildingState.fetchServerData()
                        }
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: AutomationManager.automationTerminatedNotification
                    )
                ) { notification in
                    // Apply an optimistic UI override BEFORE the refetch
                    // so the in-app charging-mode UI shows the new mode
                    // right away. Without this, the backend takes
                    // 30–60 s to expose the changed charging station mode in
                    // OverviewData, and the user sees the pre-cancel
                    // mode for that entire window.
                    if let stationId = notification.userInfo?[
                        AutomationManager.terminatedChargingStationIdKey
                    ] as? String,
                        let modeRaw = notification.userInfo?[
                            AutomationManager.terminatedChargingModeRawKey
                        ] as? Int,
                        let mode = ChargingMode(rawValue: modeRaw)
                    {
                        currentBuildingState.applyOptimisticChargingMode(
                            sensorId: stationId,
                            mode: mode
                        )
                    }
                    // Bypass the 5 s debounce — we *know* the charging station
                    // mode just changed, so refetch immediately.
                    Task {
                        await currentBuildingState
                            .fetchServerData(force: true)
                    }
                }
        }
        //.environment(\.locale, Locale(identifier: "DE"))
    }
}
