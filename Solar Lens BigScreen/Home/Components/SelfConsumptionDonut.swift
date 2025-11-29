import SwiftUI

struct SelfConsumptionDonut: View {
    var selfConsumptionPercent: Double

    var body: some View {
        Donut(
            percentage: selfConsumptionPercent,
            color: .indigo,
            text: "Self Consumption")
    }
}

#Preview {
    SelfConsumptionDonut(
        selfConsumptionPercent: 79
    )
}
