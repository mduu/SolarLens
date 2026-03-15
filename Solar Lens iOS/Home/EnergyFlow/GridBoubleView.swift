import SwiftUI

struct GridBoubleView: View {
    var gridInKwh: Double
    var todayGridImportInWh: Int?

    var body: some View {
        let todayKwh = Double(todayGridImportInWh ?? 0) / 1000

        EnergyCard(
            icon: "network",
            iconColor: .purple,
            label: "Grid",
            value: String(format: "%.1f kW", gridInKwh),
            detail: todayGridImportInWh != nil ? String(format: "%.1f kWh today", todayKwh) : nil
        )
    }
}

#Preview {
    GridBoubleView(gridInKwh: 1.7, todayGridImportInWh: 12500)
        .frame(width: 170)
        .padding()
}
