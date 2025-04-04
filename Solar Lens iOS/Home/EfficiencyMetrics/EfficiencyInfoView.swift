import SwiftUI

struct EfficiencyInfoView: View {
    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        let selfConsumption = todaySelfConsumptionRate ?? 0
        let autarky = todayAutarchyDegree ?? 0

        VStack {
            Text("Efficiency")
                .font(.headline)
                .foregroundColor(.indigo)
            
            HStack {
                
                ZStack {
                    MiniDonut(
                        percentage: selfConsumption,
                        color: .indigo,
                        showPerentage: false,
                        lineWidth: 7
                    )
                    .frame(maxWidth: 60)
                    
                    MiniDonut(
                        percentage: autarky,
                        color: .purple,
                        showPerentage: false,
                        lineWidth: 7
                    )
                    .frame(maxWidth: 42)
                }
                
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(
                            "Self consumption"
                        )
                        .font(.system(size: 9))
                        
                        Text(
                            "\(selfConsumption.formatIntoPercentage())"
                        )
                        .foregroundColor(.indigo)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(
                            "Autarky"
                        )
                        .font(.system(size: 8))
                        
                        Text(
                            "\(autarky.formatIntoPercentage())"
                        )
                        .foregroundColor(.purple)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    }
                    .padding(.top, 2)
                    
                }
            }
        }
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
