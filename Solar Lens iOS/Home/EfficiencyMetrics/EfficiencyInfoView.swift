//

import SwiftUI

struct EfficiencyInfoView: View {
    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        let selfConsumption = todaySelfConsumptionRate ?? 0
        let autarky = todayAutarchyDegree ?? 0

        VStack {

            ZStack {
                MiniDonut(
                    percentage: selfConsumption,
                    color: .yellow,
                    showPerentage: false,
                    lineWidth: 5
                )
                .frame(maxWidth: 50)

                MiniDonut(
                    percentage: autarky,
                    color: .teal,
                    showPerentage: false,
                    lineWidth: 5
                )
                .frame(maxWidth: 38)
            }

            VStack {
                HStack(spacing: 4) {
                    Circle()
                        .foregroundColor(.yellow)
                        .frame(width: 6, height: 6)
                    
                    Text(
                        "Self consumption: \(selfConsumption.formatIntoPercentage())"
                    )
                    .font(.system(size: 9))
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .foregroundColor(.teal)
                        .frame(width: 6, height: 6)
                    
                    Text(
                        "Autarky: \(selfConsumption.formatIntoPercentage())"
                    )
                    .font(.system(size: 8))
                }

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
