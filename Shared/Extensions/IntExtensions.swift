extension Int {

    func formatWattsAsKiloWatts() -> String {
        String(
            format: "%.1f",
            Double(self) / 1000)
    }

}

extension Int? {
    func formatIntoPercentage() -> String {
        String(
            format: "%.0f%%",
            Double(self ?? 0))
    }

    func formatWattsAsKiloWatts() -> String {
        self == nil
            ? "-"
            : String(
                format: "%.1f",
                Double(self!) / 1000)
    }
}
