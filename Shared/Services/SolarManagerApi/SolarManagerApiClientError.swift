enum SolarManagerApiClientError: Error {
    case invalidArguments
    case communicationError
    case errorWhileEncoding
    case errorWhileDecoding
}
