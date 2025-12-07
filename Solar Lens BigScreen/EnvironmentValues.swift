import SwiftUI

extension EnvironmentValues {
    var buildings: CurrentBuildingState {
        get { self[CurrentBuildingStateKey.self] }
        set { self[CurrentBuildingStateKey.self] = newValue }
    }

    var uiContext: UiContext {
        get { self[UiContextKey.self] }
        set { self[UiContextKey.self] = newValue }
    }

    var energyManager: EnergyManager {
        get { self[EnergyManagerKey.self] }
        set { self[EnergyManagerKey.self] = newValue }
    }
}

private struct CurrentBuildingStateKey: EnvironmentKey {
    static var defaultValue: CurrentBuildingState {
        return CurrentBuildingState()
    }
}

private struct UiContextKey: EnvironmentKey {
    static var defaultValue: UiContext {
        return UiContext()
    }
}

private struct EnergyManagerKey: EnvironmentKey {
    static var defaultValue: EnergyManager {
        return SolarManager()
    }
}
