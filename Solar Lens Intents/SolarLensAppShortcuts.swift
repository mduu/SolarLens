import AppIntents

struct SolarLensShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenOverviewIntent(),
            phrases: [
                "Show solar overview in \(.applicationName)",
                "Open solar overview in \(.applicationName)"],
            shortTitle: "Show solar overview",
            systemImageName: "sun.max"
        )
    }
}
