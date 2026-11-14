import SwiftUI

enum AppTab: Hashable {
    case now
    case automation
    case notifications
    case statistics
    // Devices, listed in the sidebar. On the iPhone they open from their
    // tile on the home screen.
    case battery
    case charging
    case grid
    /// All of them behind one tab bar item, where there is no sidebar.
    case devices
}

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var automationManager = AutomationManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var notificationHistory = NotificationHistoryManager.shared
    @State private var tabSelection = TabSelection.shared
    @State private var commands = AppCommands.shared

    /// Width of the whole window. Decides which sections exist; each screen
    /// measures its own width again for its layout, because the sidebar takes
    /// its share first.
    @State private var layout: LayoutWidth = .compact

    private var hasAutomation: Bool {
        buildingState.overviewData.hasAnyBattery
            || buildingState.overviewData.hasAnyCarChargingStation
    }

    /// A wide window has room for automations and notifications side by side,
    /// so they share one section there.
    private var combinesAutomationAndNotifications: Bool {
        layout == .wide && hasAutomation
    }

    var body: some View {
        @Bindable var tabSelection = tabSelection
        @Bindable var commands = commands

        if !buildingState.loginCredentialsExists {
            LoginScreen()
        } else {
            TabView(selection: $tabSelection.selectedTab) {
                Tab("Now", systemImage: "bolt.fill", value: AppTab.now) {
                    HomeScreen()
                        .topLevelTabSwipe()
                }

                if hasAutomation {
                    // "Automation" also where the section holds both: the
                    // sidebar has no room for the two names side by side.
                    Tab(
                        "Automation",
                        systemImage: "wand.and.stars",
                        value: AppTab.automation
                    ) {
                        if combinesAutomationAndNotifications {
                            AutomationHubScreen()
                        } else {
                            AutomationScreen()
                                .topLevelTabSwipe()
                        }
                    }
                    .badge(automationBadge)
                }

                if !combinesAutomationAndNotifications {
                    Tab(
                        "Notifications",
                        systemImage: "bell.badge",
                        value: AppTab.notifications
                    ) {
                        NotificationsScreen()
                            .topLevelTabSwipe()
                    }
                    .badge(notificationBadge)
                }

                Tab(
                    "Statistics",
                    systemImage: "chart.bar.fill",
                    value: AppTab.statistics
                ) {
                    // StatisticsScreen has its own period-paging swipe;
                    // it bubbles up to switch the top-level tab when the
                    // user crosses the today (first-period) boundary.
                    StatisticsScreen()
                }

                if layout != .compact {
                    // Sidebar: one entry per device.
                    TabSection("Devices") {
                        if buildingState.overviewData.hasAnyBattery {
                            Tab("Battery", systemImage: "battery.75percent", value: AppTab.battery) {
                                DevicesScreen(fixed: .battery)
                            }
                        }
                        if buildingState.overviewData.hasAnyCarChargingStation {
                            Tab("Charging", systemImage: "ev.charger", value: AppTab.charging) {
                                DevicesScreen(fixed: .charging)
                            }
                        }
                        Tab("Grid", systemImage: "network", value: AppTab.grid) {
                            DevicesScreen(fixed: .grid)
                        }
                    }
                    .defaultVisibility(.hidden, for: .tabBar)

                    // Tab bar: a section would collapse into one item that
                    // only shows its first entry, so it gets a single item
                    // with a picker inside instead.
                    Tab("Devices", systemImage: "powerplug", value: AppTab.devices) {
                        DevicesScreen()
                    }
                    .defaultVisibility(.hidden, for: .sidebar)
                }
            }
            // Sidebar on a wide iPad or Mac window, collapsible into a tab
            // bar at the top; the usual bottom tab bar on the iPhone.
            .tabViewStyle(.sidebarAdaptable)
            // Settings are visited rarely, so they do not get a section of
            // their own: a quiet gear at the foot of the sidebar, as in
            // Apple's own iPad apps. With the sidebar collapsed, the gear in
            // the home screen's header does the same.
            .tabViewSidebarBottomBar {
                Button {
                    commands.showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .tint(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .onGeometryChange(for: LayoutWidth.self) { proxy in
                LayoutWidth.from(width: proxy.size.width)
            } action: { newValue in
                layout = newValue
                normalizeSelection()
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newValue in
                tabSelection.windowWidth = newValue
            }
            .onChange(of: combinesAutomationAndNotifications) {
                normalizeSelection()
            }
            .onChange(of: tabSelection.selectedTab) {
                normalizeSelection()
            }
            .sheet(isPresented: $commands.showSettings) {
                NavigationStack {
                    SettingsScreen()
                }
                .presentationDetents([.large])
                .tint(.indigo)
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onAppear {
                applyMinimumWindowSize()
            }
        }
    }

    /// Stage Manager and the Mac let a window shrink to a sliver. Below this
    /// even the iPhone layout no longer fits its tiles side by side.
    private func applyMinimumWindowSize() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.sizeRestrictions?.minimumSize = CGSize(width: 375, height: 600)
        }
    }

    // Badge semantics for notifications:
    // - unread fired notifications → red badge with count
    //   (cleared when the history sheet is opened)
    // - no unread, but at least one kind enabled → plain red
    //   dot (a space renders as a numberless badge)
    // - neither → no badge
    private var notificationBadge: Text? {
        notificationHistory.unreadCount > 0
            ? Text("\(notificationHistory.unreadCount)")
            : (notificationManager.hasActiveMonitors
                ? Text(verbatim: " ")
                : nil)
    }

    /// The combined section carries both badges: a running automation wins,
    /// otherwise it shows what the Notifications section would.
    private var automationBadge: Text? {
        if automationManager.activeAutomation != nil {
            return Text(Image(systemName: "bolt.car.circle.fill"))
        }
        return combinesAutomationAndNotifications ? notificationBadge : nil
    }

    /// Sections come and go with the window width; move the selection to the
    /// one that now holds what the user was looking at.
    private func normalizeSelection() {
        switch tabSelection.selectedTab {
        case .notifications where combinesAutomationAndNotifications:
            tabSelection.selectedTab = .automation
        case .automation where !hasAutomation:
            tabSelection.selectedTab = .notifications
        case .devices where layout == .compact,
             .battery where layout == .compact,
             .charging where layout == .compact,
             .grid where layout == .compact:
            tabSelection.selectedTab = .now
        default:
            break
        }
    }

    private func handleDeepLink(_ url: URL) {
        // solarlens://automation → switch to the Automation tab.
        // The host of the URL is the section identifier; path / query
        // reserved for future per-section deep links.
        guard url.scheme == "solarlens" else { return }
        switch url.host {
        case "automation":
            tabSelection.selectedTab = .automation
        case "notifications":
            tabSelection.selectedTab = .notifications
        case "home", "now":
            tabSelection.selectedTab = .now
        case "statistics":
            tabSelection.selectedTab = .statistics
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
}
