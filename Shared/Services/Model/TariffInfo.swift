struct TariffInfo {
    var tariffKind: TariffKind?
    var currentTariffType: TariffInfoType
}

enum TariffKind {
    case single
    case variable
}

enum TariffInfoType {
    case high
    case low
    case standard
    case tariff4
    case tariff5
    case tariff6
}
