import Observation
import SwiftUI

/// Actions triggered from the keyboard (and, on the Mac, the menu bar) that a
/// screen further down has to carry out.
@Observable
final class AppCommands {
    static let shared = AppCommands()

    /// Bumped by ⌘R; the home screen reloads when it changes.
    var refreshRequest = 0
    /// Set by ⌘, and the gear in the sidebar; presents Settings as a sheet.
    var showSettings = false

    private init() {}
}

/// ⌘1…⌘4 for the sections, ⌘R to refresh, ⌘, for Settings.
struct SolarLensCommands: Commands {
    var body: some Commands {
        CommandMenu("View") {
            Button("Now") { TabSelection.shared.selectedTab = .now }
                .keyboardShortcut("1", modifiers: .command)
            Button("Automation") { TabSelection.shared.selectedTab = .automation }
                .keyboardShortcut("2", modifiers: .command)
            Button("Notifications") { TabSelection.shared.selectedTab = .notifications }
                .keyboardShortcut("3", modifiers: .command)
            Button("Statistics") { TabSelection.shared.selectedTab = .statistics }
                .keyboardShortcut("4", modifiers: .command)

            Divider()

            Button("Refresh") { AppCommands.shared.refreshRequest += 1 }
                .keyboardShortcut("r", modifiers: .command)
            Button("Settings") {
                AppCommands.shared.showSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
