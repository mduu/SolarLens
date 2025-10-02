internal import Foundation

extension Int {

    func formatWattsAsKiloWatts(widthUnit: Bool = false) -> String {
        String(
            format: widthUnit ? "%.1f \(getUnitKw())" : "%.1f",
            Double(self) / 1000)
    }

    func formatWatthoursAsKiloWattsHours(widthUnit: Bool = false) -> String {
        String(
            format: widthUnit ? "%.1f \(getUnitKwh())" : "%.1f",
            Double(self) / 1000)
    }

    func formatWattsAsWattsKiloWatts(widthUnit: Bool = false) -> String {
        if self < 1000 {
            return "\(self) \(getUnitW())"
        }
        
        return String(
            format: widthUnit ? "%.2f \(getUnitKw())" : "%.2f",
            Double(self) / 1000)
    }

    func formatAsKiloWatts(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(String(format: "%.1f", self)) \(getUnitKw())"
            : String(format: "%.1f", self)
    }

    func formatIntoPercentage() -> String {
        return "\(Int(self))%"
    }

    private func getUnitKw() -> String {
        "kW"
    }

    private func getUnitKwh() -> String {
        "kWh"
    }
    
    private func getUnitW() -> String {
        "W"
    }
}

extension Int? {
    func formatIntoPercentage() -> String {
        String(
            format: "%.0f%%",
            Double(self ?? 0))
    }

    func formatWattsAsKiloWatts(widthUnit: Bool = false) -> String {
        self == nil
            ? "-"
            : String(
                format: widthUnit ? "%.1f kW" : "%.1f",
                Double(self!) / 1000)
    }
}
