enum IntentError: Error {
    case couldNotGetValue(_ message: String)
    case couldNotGetDefaultChargingStation(_ message: String)
    case couldNotGetSolarDetails(_ message: String)
}

enum SetChargingModeIntentError: Error {
    case couldNotGetValue(_ message: String)
    case couldNotGetDefaultChargingStation(_ message: String)
    case constantCurrentNeeded(_ message: String)
    case minimumQuantityNeeded(_ message: String)
    case targetSocNeeded(_ message: String)
    case unknownChargingMode(_ message: String)
}
