import Observation

@Observable
class BuildingState {
    var isLoggedIn: Bool = false
    var isLoading = false
    var overviewData: OverviewData = .init()
    var isChangingCarCharger: Bool = false
    var energyManager: EnergyManager

    init(
        energyManager: EnergyManager? = nil
    ) {
        self.energyManager = energyManager ?? SolarManager()
    }

    func login(userName: String, password: String) async {
        isLoading = true

        isLoggedIn = await energyManager.login(
            username: userName,
            password: password
        )

        isLoading = false
    }
}
