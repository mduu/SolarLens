import SwiftUI

struct ConsumptionView: View {
    var currentOverallConsumptionInW: Int? = nil

    var body: some View {
        VStack {

            Image(systemName: "house")
                .font(.system(size: 50))

            Text(
                currentOverallConsumptionInW?
                    .formatWattsAsKiloWatts(widthUnit: true)
                ?? "-"
            )

        }
    }
}

#Preview {
    ConsumptionView()
}
