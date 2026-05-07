import SwiftUI

struct ChargingModelLabelView: View {
    let chargingMode: ChargingMode

    var body: some View {
        Text(chargingMode.localizedTitle)
            .multilineTextAlignment(.leading)
    }
}

#Preview {
    ChargingModelLabelView(chargingMode: .withSolarPower)
}
