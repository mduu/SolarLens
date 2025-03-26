// 

import SwiftUI

struct EfficiencyInfoView: View {
    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        VStack {
            Text("Efficiency")
                .font(.headline)
                .foregroundColor(.accent)
            
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    VStack {
                        Text("Self consumption:")
                            .font(.caption2)
                        
                        let selfConsumption = todaySelfConsumptionRate ?? 0
                        
                        MiniDonut(
                            percentage: selfConsumption,
                            color: selfConsumption > 60 ? .green : .orange
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width / 2)
                    .frame(maxHeight: .infinity)
                    
                    VStack {
                        Text("Autarky:")
                            .font(.caption2)
                        
                        let autarky = todayAutarchyDegree ?? 0
                        
                        MiniDonut(
                            percentage: autarky,
                            color: autarky > 60 ? .green : .orange
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width / 2)
                    .frame(maxHeight: .infinity)
                }
                .padding()
                .background(.accent.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    EfficiencyInfoView(
        todaySelfConsumptionRate: 81.2,
        todayAutarchyDegree: 92.1
    )
    .frame(maxWidth: 180, maxHeight: 120)
}
