import SwiftUI

struct SolarView: View {
    var currentSolarProductionInW: Int? = nil

    var body: some View {
        VStack {

            Image(systemName: "sun.max")
                .font(.system(size: 50))

            Text(
                currentSolarProductionInW?
                    .formatWattsAsKiloWatts(widthUnit: true)
                    ?? "-"
            )

        }
    }
}

#Preview {
    SolarView(currentSolarProductionInW: 4321)
}
