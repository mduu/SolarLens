import AppIntents

struct GetCarInfosIntent: AppIntent {
    static var title: LocalizedStringResource =
        "What is the charging state of my car?"
    static var description: IntentDescription? =
        "Information about the car's charging state"

    @Parameter(
        title: "Car",
        description: "Select car to query",
    )
    var car: CarInfo?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<CarInfo?>
        & ProvidesDialog
    {
        let carSensorIds: [String] =  car != nil ? [car!.id] : []
        
        let carInfos: [CarInfo] = try await CarInfo.defaultQuery.entities(
            for: carSensorIds
        )
          
        if carInfos.isEmpty {
            throw IntentError.couldNotGetValue(
                "No car found."
            )
        }
        
        let carInfo: CarInfo = carInfos.first!

        let dialog = IntentDialog(
            full:
                LocalizedStringResource(
                    "The \(carInfo.name) is charged \(carInfo.batteryPercent.formatIntoPercentage())."
                ),
            systemImageName: "car.side"
        )

        return .result(value: carInfo, dialog: dialog)
    }
}

struct CarInfoQuery: EntityQuery {

    func entities(for identifiers: [String]) async throws -> [CarInfo] {
        return try await suggestedEntities()
            .filter { carInfo in
                identifiers.isEmpty || identifiers.contains(carInfo.id)
            }
    }

    func suggestedEntities() async throws -> [CarInfo] {
        let solarManager = SolarManager.instance()
        let overviewData = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil
        )

        // DEBUG CODE
        /*
        overviewData?.cars = [
            .init(
                id: "1234",
                name: "EQA",
                priority: 1,
                batteryPercent: 42,
                batteryCapacity: 77,
                signal: .connected,
                currentPowerInWatts: 2351,
                hasError: false
            )
        ]
         */
        // EDN DEBUG CODE

        guard let cars = overviewData?.cars else {
            throw IntentError.couldNotGetValue("Could not get car information.")
        }

        return
            cars
            .sorted { $0.priority < $1.priority }
            .map { car in CarInfo.map(from: car) }
    }
}

struct CarInfo: AppEntity {

    @Property var id: String
    @Property var name: String
    @Property var batteryPercent: Double?
    @Property var batteryCapacity: Double?

    static var typeDisplayRepresentation: TypeDisplayRepresentation =
        "Car Information"

    static var defaultQuery = CarInfoQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    public static func map(from car: Car) -> CarInfo {
        let carInfo = CarInfo()
        carInfo.$id.wrappedValue = car.id
        carInfo.$name.wrappedValue = car.name
        carInfo.$batteryPercent.wrappedValue = car.batteryPercent
        carInfo.$batteryCapacity.wrappedValue = car.batteryCapacity

        return carInfo
    }
}
