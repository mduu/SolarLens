import SwiftUI

extension EnvironmentValues {
    var energyManager: EnergyManager {
        get { self[EnergyManagerKey.self] }
        set { self[EnergyManagerKey.self] = newValue }
    }
}

private struct EnergyManagerKey: EnvironmentKey {
    static var defaultValue: EnergyManager {
        return SolarManager()
    }
}
