struct TariffV1Response: Codable {
    var lowTariff: Double?
    var highTariff: Double?
    var tariffType: String?
    var singleTariff: Double?
    var provider: String?
    var directMarketing: Double?
}
