// 

import SwiftUI

struct EfficiencyInfoView: View {
    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        Grid {
            GridRow(alignment: .top) {
                Text("Self consumption:")
                    .font(.caption2)
                
                Text("Autarky:")
                    .font(.caption2)
            }
            
            GridRow {
                Group {
                    let selfConsumption = todaySelfConsumptionRate ?? 0
                    
                    MiniDonut(
                        percentage: selfConsumption,
                        color: selfConsumption > 60 ? .green : .orange
                    )
                    .frame(maxWidth: 40)
                }
                
                Group {
                    let autarky = todayAutarchyDegree ?? 0
                    
                    MiniDonut(
                        percentage: autarky,
                        color: autarky > 60 ? .green : .orange
                    )
                    .frame(maxWidth: 40)
                }
            }
        }
        .frame(maxHeight: 100)
    }
}

#Preview {
    EfficiencyInfoView(
        todaySelfConsumptionRate: 81.2,
        todayAutarchyDegree: 92.1
    )
    .frame(maxWidth: 180, maxHeight: 120)
}
