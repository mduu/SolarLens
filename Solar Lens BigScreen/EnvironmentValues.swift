import SwiftUI

extension EnvironmentValues {
    var buildings: CurrentBuildingState {
        get { self[CurrentBuildingStateKey.self] }
        set { self[CurrentBuildingStateKey.self] = newValue }
    }
}

private struct CurrentBuildingStateKey: EnvironmentKey {
    static var defaultValue: CurrentBuildingState {
        return CurrentBuildingState()
    }
}
