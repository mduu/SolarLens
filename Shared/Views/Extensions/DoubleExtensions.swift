
extension Double {

    func formatWattsAsKiloWatts() -> String {
        String(
            format: "%.1f",
            Double(self) / 1000)
    }

    func formatIntoPercentage() -> String {
        String(
            format: "%.0f%%",
            Double(self))
    }
}
