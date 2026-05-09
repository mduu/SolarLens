/// Charging modes offered to the user in the Auto-reset Charging Mode
/// setup sheet (iOS + watchOS). We restrict to "simple" modes — the
/// parameter-bearing ones (`.constantCurrent`, `.chargingTargetSoc`,
/// `.minimumQuantity`) would need additional UI to ask for the amperage /
/// target SoC / quantity respectively.
///
/// Easy to extend later by adding to this list and wiring the
/// corresponding sub-parameter into
/// `AutomationAutoResetChargingModeParameters`.
enum AutoResetChargingModeOptions {
    static let selectableModes: [ChargingMode] = [
        .alwaysCharge,
        .withSolarPower,
        .withSolarOrLowTariff,
        .off,
        .minimalAndSolar,
    ]
}
