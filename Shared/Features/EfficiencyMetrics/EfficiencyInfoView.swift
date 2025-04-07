import SwiftUI

struct EfficiencyInfoView: View {
    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?
    var showLegend: Bool = true
    var showTitle: Bool = true

    var body: some View {
        let selfConsumption = todaySelfConsumptionRate ?? 0
        let autarky = todayAutarchyDegree ?? 0

        VStack {
            if showTitle {
                Text("Efficiency")
                    .font(.headline)
                    .foregroundColor(.indigo)
            }
            
            HStack {
                
                ZStack {
                    MiniDonut(
                        percentage: selfConsumption,
                        color: .indigo,
                        showPerentage: false,
                        lineWidth: 7
                    )
                    .frame(maxWidth: 60)
                    
                    #if os(watchOS)
                    let ringSize = 30
                    #else
                    let ringSize = 42
                    #endif
                    MiniDonut(
                        percentage: autarky,
                        color: .purple,
                        showPerentage: false,
                        lineWidth: 7
                    )
                    .frame(maxWidth: CGFloat(ringSize))
                }
                
                if showLegend {
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
