import SwiftUI

struct ConsumptionView: View {
    var currentOverallConsumptionInW: Int? = nil

    var body: some View {
        VStack {

            Image(systemName: "bolt.house")
                .font(.system(size: 50))

            Text(
                currentOverallConsumptionInW?.formatAsKiloWatts(widthUnit: true)
                ?? "-"
            )

        }
    }
}

#Preview {
    ConsumptionView()
}
