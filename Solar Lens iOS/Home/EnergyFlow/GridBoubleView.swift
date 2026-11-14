import SwiftUI

struct GridBoubleView: View {
    var gridInKwh: Double
    var todayGridImportInWh: Int?

    @State private var showGridSheet = false
    @Environment(HomeDetailRouter.self) private var router: HomeDetailRouter?

    var body: some View {
        let todayKwh = Double(todayGridImportInWh ?? 0) / 1000

        let todayFormatted = todayKwh.localized(decimals: 1)

        Button {
            if router?.open(.grid) != true { showGridSheet = true }
        } label: {
            EnergyCard(
                icon: "network",
                iconColor: .purple,
                label: "Grid",
                value: "\(gridInKwh.localized(decimals: 1)) kW",
                detail: todayGridImportInWh != nil ? "\(todayFormatted) kWh today" : nil,
                showChevron: true
            )
        }
        .buttonStyle(CardButtonStyle())
        .detailSelection(router?.detail == .grid)
        .sheet(isPresented: $showGridSheet) {
            NavigationStack {
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
