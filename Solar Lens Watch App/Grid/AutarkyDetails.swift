import SwiftUI

struct AutarkyDetails: View {
    var energyOverview: EnergyOverview?

    var body: some View {
        Group {
            HStack {
                Text("Autarky")
                    .font(.system(size: 8))

                Spacer()
            }
            .padding(.vertical, 4)

            HStack(alignment: .center) {
                AutarkyDonut(percent: energyOverview?.autarchy.lastMonth, text: "Month")
                Spacer()
                AutarkyDonut(percent: energyOverview?.autarchy.lastYear, text: "Year")
                Spacer()
                AutarkyDonut(percent: energyOverview?.autarchy.overall, text: "Overall")
            }
        }
    }
}

#Preview {
    AutarkyDetails()
}
