//

import SwiftUI

struct EfficiencyInfoView: View {
    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        let selfConsumption = todaySelfConsumptionRate ?? 0
        let autarky = todayAutarchyDegree ?? 0

        HStack {

            ZStack {
                MiniDonut(
                    percentage: selfConsumption,
                    color: .yellow,
                    showPerentage: false,
                    lineWidth: 7
                )
                .frame(maxWidth: 60)

                MiniDonut(
                    percentage: autarky,
                    color: .teal,
                    showPerentage: false,
                    lineWidth: 7
                )
                .frame(maxWidth: 42)
            }

            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(
                        "Self consumption:"
                    )
                    .font(.system(size: 9))
                    
                    Text(
                        "\(selfConsumption.formatIntoPercentage())"
                    )
                    .foregroundColor(.yellow.darken(0.3))
                    .font(.subheadline)
                    .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(
                        "Autarky:"
                    )
                    .font(.system(size: 8))

                    Text(
                        "\(autarky.formatIntoPercentage())"
                    )
                    .foregroundColor(.teal)
                    .font(.subheadline)
                    .fontWeight(.bold)
                }
                .padding(.top, 2)

            }
        }
        .frame(maxHeight: 100)
    }
}

#Preview {
    VStack {
        EfficiencyInfoView(
            todaySelfConsumptionRate: 81.2,
            todayAutarchyDegree: 92.1
        )
        .frame(maxWidth: 180, maxHeight: 120)
        
        Spacer()
    }
}
