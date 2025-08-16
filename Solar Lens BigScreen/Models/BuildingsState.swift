import Observation

@Observable
class BuildingsState {
    var buildings: [BuildingState] = []
    
    var isAnyLoggedIn: Bool {
        buildings.contains(where: { $0.isLoggedIn })
    }
}
