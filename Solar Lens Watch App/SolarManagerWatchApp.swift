import SwiftUI
import WatchKit

@main
struct SolarManagerWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @State var currentBuildingState = CurrentBuildingState(energyManagerClient: SolarManager.shared)
    @State var navigationState = NavigationState()
    @State var automationStateStore = AutomationStateStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppStoreReviewManager.shared.increaseStartupCount()
                }
                .environment(currentBuildingState)
                .environment(navigationState)
                .environment(automationStateStore)
        }
        .onChange(of: scenePhase) { old, new in
            WatchDiagnostics.shared.appendBreadcrumb(
                kind: "scenePhase",
                data: [
                    "from": describe(scenePhase: old),
                    "to": describe(scenePhase: new),
                ]
            )
            WatchDiagnostics.shared.scenePhaseChanged(
                toActive: new == .active
            )
        }
        // For testing specific locale, uncomment:
        // .environment(\.locale, Locale(identifier: "de"))
    }

    private func describe(scenePhase: ScenePhase) -> String {
        switch scenePhase {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Start lifecycle breadcrumbs first so we capture the launch
        // marker before anything else runs.
        WatchDiagnostics.shared.start()

        // Per Apple's guidance the WCSession is activated once and
        // stays active for the rest of the process lifetime.
        AutomationWatchSession.shared.start()
    }

    /// watchOS hands us background tasks here. The only one we care
    /// about is `WKWatchConnectivityRefreshBackgroundTask` — when iOS
    /// delivers a WCSession payload (`applicationContext` or
    /// `transferUserInfo`) while we're suspended, watchOS wakes us
    /// via this task. We MUST hold it open until WCSession's content
    /// queue has drained (`hasContentPending == false`) and only then
    /// call `setTaskCompletedWithSnapshot(false)`. If we don't,
    /// watchOS counts it as misbehavior — over a day of nightly
    /// deliveries that adds up to the resource-budget violation that
    /// pins the app onto the system's do-not-launch list.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if task is WKWatchConnectivityRefreshBackgroundTask {
                WatchDiagnostics.shared.appendBreadcrumb(
                    kind: "bg-task",
                    data: ["type": "WCRefresh"]
                )
                AutomationWatchSession.shared.handle(backgroundTask: task)
            } else {
                // Snapshots, app refresh, URL session tasks — none of
                // these are something we asked for. Acknowledge so
                // the OS doesn't think we're stuck on them either.
                WatchDiagnostics.shared.appendBreadcrumb(
                    kind: "bg-task",
                    data: ["type": String(describing: type(of: task))]
                )
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
