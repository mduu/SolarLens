import AppIntents
import SwiftUI

struct SolarLensShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenAppIntent(),
            phrases: [
                "Show solar overview in \(.applicationName)",
                "Open solar overview in \(.applicationName)",
            ],
            shortTitle: "Show solar overview",
            systemImageName: "sun.max"
        )

        AppShortcut(
            intent: GetSolarProductionIntent(),
            phrases: [
                "Show solar production in \(.applicationName)",
                "Show current solar production in \(.applicationName)",
                "How much power does my house produce in \(.applicationName)",
            ],
            shortTitle: "Get current solar production",
            systemImageName: "sun.max"
        )

        AppShortcut(
            intent: GetBatteryLevelIntent(),
            phrases: [
                "Show battery level in \(.applicationName)",
                "Show current battery level in \(.applicationName)",
                "What is the current battery level of my house in \(.applicationName)",
            ],
            shortTitle: "Get current battery level",
            systemImageName: "battery.50percent"
        )

        AppShortcut(
            intent: GetConsumptionIntent(),
            phrases: [
                "Show power consumption in \(.applicationName)",
                "Show current energy consumption in \(.applicationName)",
                "What is the current power consumption of my house in \(.applicationName)",
            ],
            shortTitle: "Get current power consumption",
            systemImageName: "poweroutlet.type.n.fill"
        )

        AppShortcut(
            intent: IsAnyCarChargingIntent(),
            phrases: [
                "Is any car charging in \(.applicationName)",
                "Does any car currently charge in \(.applicationName)",
                "Is any car currently charging in \(.applicationName)",
            ],
            shortTitle: "Is any car currently charging",
            systemImageName: "bolt.car.circle"
        )

        AppShortcut(
            intent: SetChargingModeIntent(),
            phrases: [
                "Set charging mode to \(\.$chargingMode) in \(.applicationName)",
                "Set charging mode in \(.applicationName)",
                "Change charging mode to \(\.$chargingMode) in \(.applicationName)",
                "Change charging mode in \(.applicationName)",
            ],
            shortTitle: "Set charging mode",
            systemImageName: "bolt.car"
        )
    }
}
