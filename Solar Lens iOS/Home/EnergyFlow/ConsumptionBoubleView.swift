import SwiftUI

struct ConsumptionBoubleView: View {
    var currentConsumptionInKwh: Double
    var todayConsumptionInWh: Double?
    var applyCardStyle: Bool = true
    @ObservedObject var pinnedConfig: PinnedDevicesConfiguration

    @State var isDeviceSheetShown: Bool = false

    var body: some View {
        let todayKwh = (todayConsumptionInWh ?? 0) / 1000

        let todayFormatted = todayKwh.localized(decimals: 1)

        Button { isDeviceSheetShown = true } label: {
            EnergyCard(
                icon: "house.fill",
                iconColor: .teal,
                label: "Consumption",
                value: "\(currentConsumptionInKwh.localized(decimals: 1)) kW",
                detail: todayConsumptionInWh != nil ? "\(todayFormatted) kWh today" : nil,
                showChevron: true,
                applyCardStyle: applyCardStyle
            )
        }
        .buttonStyle(CardButtonStyle())
        .sheet(isPresented: $isDeviceSheetShown) {
            NavigationView {
                DevicePrioritySheet(pinnedConfig: pinnedConfig)
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    ConsumptionBoubleView(
        currentConsumptionInKwh: 4.5,
        todayConsumptionInWh: 34595,
        pinnedConfig: PinnedDevicesConfiguration()
    )
    .padding()
}
