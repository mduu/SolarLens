enum EnergyManagerClientError: Error {
    case loginFailed
    case systemInformationNotFound
    case invalidData
    case apiError(apiError: RestError)
    case invalidDateCalculation
}
