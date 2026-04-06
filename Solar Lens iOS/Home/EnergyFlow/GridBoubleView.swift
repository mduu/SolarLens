import SwiftUI

struct GridBoubleView: View {
    var gridInKwh: Double
    var todayGridImportInWh: Int?

    @State private var showGridSheet = false

    var body: some View {
        let todayKwh = Double(todayGridImportInWh ?? 0) / 1000

        let todayFormatted = String(format: "%.1f", todayKwh)

        EnergyCard(
            icon: "network",
            iconColor: .purple,
            label: "Grid",
            value: String(format: "%.1f kW", gridInKwh),
            detail: todayGridImportInWh != nil ? "\(todayFormatted) kWh today" : nil,
            showChevron: true
        )
        .onTapGesture { showGridSheet = true }
        .sheet(isPresented: $showGridSheet) {
            NavigationView {
                GridSheet()
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    GridBoubleView(gridInKwh: 1.7, todayGridImportInWh: 12500)
        .frame(width: 170)
        .padding()
}
