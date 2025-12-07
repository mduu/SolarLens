internal import Foundation

struct ControlCarChargingRequest: Codable {
    /// Charging mode
    /// 0 = Fast Charge
    /// 1 = Only solar
    /// 2 = Solar & tariff optimized
    /// 3 = Do not charge
    /// 4 = Constant current
    /// 5 = Minimal & Solar
    /// 6 = Minimum charge quantity
    /// 7 = Charging Target(%)
    var chargingMode: ChargingMode

    /// Only for "Constant current" mode
    /// 6-32 (Ampere)
    var constantCurrentSetting: Int?

    /// Target date and time - only for "Minimum charge quantity" mode
    /// Example: "2023-12-27T06:00:00.000Z"
    var minimumChargeQuantityTargetDateTime: Date?

    /// Charge quantity - only for "Minimum charge quantity" mode
    /// Min: 1, Max: 100
    var minimumChargeQuantityTargetAmount: Int?

    /// Car battery charge level % - only for "Charging Target(%)" mode
    /// Min: 1, Max: 100
    var chargingTargetSoc: Int?

    /// Target date and time
    /// Example: "2023-12-27T06:00:00.000Z" - only for "Charging Target(%)" mode
    var chargingTargetSocDateTime: Date?

    init(chargingMode: ChargingMode) {
        self.chargingMode = chargingMode
    }

    init(constantCurrent: Int) {
        self.chargingMode = .constantCurrent
        self.constantCurrentSetting = constantCurrent
    }

    init(minimumChargeQuantityTargetAmount: Int, targetTime: Date) {
        self.chargingMode = .minimumQuantity
        self.minimumChargeQuantityTargetAmount =
            minimumChargeQuantityTargetAmount
        self.minimumChargeQuantityTargetDateTime = targetTime
    }

    init(targetSocPercent: Int, targetTime: Date) {
        self.chargingMode = .chargingTargetSoc
        self.chargingTargetSoc = targetSocPercent
        self.chargingTargetSocDateTime = targetTime
    }
}
