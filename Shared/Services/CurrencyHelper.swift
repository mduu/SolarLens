internal import Foundation

struct CurrencyHelper {

    /// Returns the currency code for the installation's country.
    /// Falls back to the device locale currency, then EUR.
    static var currencyCode: String {
        if let country = SolarManager.shared.installationCountry {
            return currencyCode(for: country)
        }
        return Locale.current.currency?.identifier ?? "EUR"
    }

    /// Map country name (as returned by Solar Manager API) to ISO currency code
    private static func currencyCode(for country: String) -> String {
        let normalized = country.lowercased().trimmingCharacters(in: .whitespaces)
        switch normalized {
        case "switzerland", "schweiz", "suisse", "svizzera", "ch":
            return "CHF"
        case "germany", "deutschland", "de":
            return "EUR"
        case "austria", "österreich", "at":
            return "EUR"
        case "france", "frankreich", "fr":
            return "EUR"
        case "italy", "italien", "italia", "it":
            return "EUR"
        case "denmark", "dänemark", "danmark", "dk":
            return "DKK"
        case "sweden", "schweden", "sverige", "se":
            return "SEK"
        case "norway", "norwegen", "norge", "no":
            return "NOK"
        case "united kingdom", "großbritannien", "uk", "gb":
            return "GBP"
        case "united states", "usa", "us":
            return "USD"
        default:
            return Locale.current.currency?.identifier ?? "EUR"
        }
    }
}
