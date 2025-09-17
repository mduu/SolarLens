import Observation

@Observable
class NavigationState {
    var selectedTab: Int = 0
    
    func navigate(to tab: MainTab) {
        selectedTab = tab.rawValue
    }
}


enum MainTab: Int, CaseIterable, Identifiable {
    case overview = 0
    case charging = 1
    case solarProduction = 2
    case consumption = 3
    case battery = 4
    case grid = 5

    var id: Self { self }
}
