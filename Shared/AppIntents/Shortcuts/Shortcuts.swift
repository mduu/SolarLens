import AppIntents
import SwiftUI

struct SolarLensShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenAppIntent(),
            phrases: [
                "Show solar overview in \(.applicationName)",
                "Open solar overview in \(.applicationName)"],
            shortTitle: "Show solar overview",
            systemImageName: "sun.max"
        )
        
        AppShortcut(
            intent: GetSolarProductionIntent(),
            phrases: [
                "How much solar power do we produce",
                "How much is the current solar production in \(.applicationName)",
                "What is the current solar production in \(.applicationName)",
                "How much power does my house produce in \(.applicationName)"
            ],
            shortTitle: "Get current solar production",
            systemImageName: "sun.max"
        )
        
        AppShortcut(
            intent: GetSolarProductionIntent(),
            phrases: [
                "What is the battery level",
                "How much is the current battery level in \(.applicationName)",
                "What is the current battery level in \(.applicationName)",
                "What is the current battery level of my house in \(.applicationName)"
            ],
            shortTitle: "Get current battery level",
            systemImageName: "battery.50percent"
        )
         
        AppShortcut(
            intent: GetConsumptionIntent(),
            phrases: [
                "What is the current power consumption",
                "How much is the current power consumption in \(.applicationName)",
                "What is the current energy consumption in \(.applicationName)",
                "What is the current power consumption of my house in \(.applicationName)"
            ],
            shortTitle: "Get current power consumption",
            systemImageName: "poweroutlet.type.n.fill"
        )
         
        AppShortcut(
            intent: SetChargingModeIntent(),
            phrases: [
                "Set charging mode",
                "Set charging mode to \(\.$chargingMode)",
                "Set charging mode to \(\.$chargingMode) in \(.applicationName)",
                "Set charging mode in \(.applicationName)",
                "Change chrging mode",
                "Change chrging mode to \(\.$chargingMode)",
                "Change chrging mode to \(\.$chargingMode) in \(.applicationName)",
            ],
            shortTitle: "Set charging mode",
            systemImageName: "bolt.car"
        )
    }
}
