internal import Foundation

/// How clean the grid is that a system's solar energy displaces.
///
/// The tree figure is only worth as much as this number. The global average
/// is far dirtier than any European grid, so a reader in Zurich was being
/// shown a saving roughly nine times the real one with no way to say where
/// they stand. Now they can.
///
/// National figures are 2024 averages. They come from different publishers
/// and are not derived the same way — a consumer mix counts imports, a
/// generation mix does not — so treat them as the order of magnitude they
/// are, not as directly comparable to the third digit.
enum GridCarbonRegion: String, CaseIterable, Identifiable {
    case international
    case switzerland
    case germany
    case austria
    case denmark

    /// The one key the picker writes and every reader reads.
    static let storageKey = "gridCarbonRegion"

    /// What a system is assumed to displace until the reader says otherwise.
    /// The global average keeps the figure identical to what earlier versions
    /// showed, so nobody's number changes without them choosing it.
    static let fallback = GridCarbonRegion.international

    init(stored: String?) {
        self = GridCarbonRegion(rawValue: stored ?? "") ?? Self.fallback
    }

    var id: String { rawValue }

    /// Grams of CO₂ per kilowatt-hour of grid electricity.
    var gramsCo2PerKwh: Double {
        switch self {
        case .international: 475  // IEA global average
        case .switzerland: 57  // consumer mix 2024, VSE
        case .germany: 363  // 2024, Umweltbundesamt
        case .austria: 106  // 2024
        case .denmark: 96  // 2024, preliminary
        }
    }

    /// The same figure in the unit the production is measured in.
    var avoidedCo2PerWhInKg: Double { gramsCo2PerKwh / 1_000_000 }

    /// ISO region code, or nil for the global average.
    var regionCode: String? {
        switch self {
        case .international: nil
        case .switzerland: "CH"
        case .germany: "DE"
        case .austria: "AT"
        case .denmark: "DK"
        }
    }

    /// The country's name in the reader's own language. The system already
    /// knows these in every language we ship, so they need no translation of
    /// ours — only the global average does, and that is a real string.
    /// Empty for `.international`; callers show the localized label instead.
    var countryName: String {
        guard let regionCode else { return "" }
        return Locale.current.localizedString(forRegionCode: regionCode)
            ?? regionCode
    }
}
