import AppIntents

struct SetChargingModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Set charging mode"

    @Parameter(title: "Charging Mode")
    var chargingMode: ChargingMode

    @Parameter(
        title: "Charing Station",
        description:
            "Sensor-ID of the charging station. Leave empty to use the first charging station."
    )
    var sensorId: String?

    @Parameter(
        title: "Constant current",
        description: "Constant current in watts.")
    var constantCurrent: Int?

    @Parameter(
        title: "Minimum quantity",
        description: "Minimum quantity in kWh.")
    var minQuantity: Int?

    @Parameter(
        title: "Target time",
        description: "Time when the charging must be completed.")
    var targetTime: Date?

    @Parameter(
        title: "Target %",
        description: "Target SOC percent (1-100%).")
    var targetSocPercent: Int?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool>
        & ProvidesDialog
    {
        try validateChargingModeParmaeters()
        let solarManager = SolarManager.instance()
        let choosenSensorId = try await getSensorId(energyManager: solarManager)

        let controlCarChargingRequest: ControlCarChargingRequest =
            switch chargingMode {
            case .constantCurrent:
                ControlCarChargingRequest.init(
                    constantCurrent: constantCurrent!)
            case .minimumQuantity:
                ControlCarChargingRequest.init(
                    minimumChargeQuantityTargetAmount: minQuantity!,
                    targetTime: targetTime!.convertLocalUiToUtc())
            case .chargingTargetSoc:
                ControlCarChargingRequest.init(
                    targetSocPercent: targetSocPercent!,
                    targetTime: targetTime!.convertLocalUiToUtc())
            default: ControlCarChargingRequest.init(chargingMode: chargingMode)
            }

        let success = try await solarManager.setCarChargingMode(
            sensorId: choosenSensorId,
            carCharging: controlCarChargingRequest)

        let dialog = IntentDialog(
            full: success
                ? LocalizedStringResource(
                    "The charging mode as set to \(chargingMode)")
                : LocalizedStringResource(
                    "There was a problem setting the charging mode."),
            systemImageName: "bolt.car.circle"
        )

        return .result(value: success, dialog: dialog)
    }

    private func validateChargingModeParmaeters() throws {
        if chargingMode.isSimpleChargingMode() {
            return
        }

        switch chargingMode {

        case .constantCurrent:
            guard constantCurrent != nil else {
                throw SetChargingModeIntentError.constantCurrentNeeded(
                    "Charging mode constant needs a constant currant value in watts!"
                )
            }
            return

        case .minimumQuantity:
            guard minQuantity != nil && targetTime != nil else {
                throw SetChargingModeIntentError.minimumQuantityNeeded(
                    "Charging mode minimum quantity needs a minium quantity and a target time!"
                )
            }
            return

        case .chargingTargetSoc:
            guard targetSocPercent != nil && targetTime != nil else {
                throw SetChargingModeIntentError.targetSocNeeded(
                    "Charging mode target SOC % needs a percentage and a target time!"
                )
            }
            return
        default:
            throw SetChargingModeIntentError.unknownChargingMode(
                "The selected charging mode is not yet supported!"
            )
        }
    }

    private func getSensorId(energyManager: EnergyManager) async throws
        -> String
    {
        guard let sensorId else {
            // NOTE: If no senstor specified try get the first charging stations sensor-id

            let overvieData = try? await energyManager.fetchOverviewData(
                lastOverviewData: nil)

            if let firstCharging = overvieData?.chargingStations.first {
                return firstCharging.id
            } else {
                throw IntentError.couldNotGetDefaultChargingStation(
                    "Could not get default charging station!")
            }
        }

        return sensorId
    }
}
