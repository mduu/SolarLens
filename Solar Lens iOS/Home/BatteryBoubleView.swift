import Charts
import SwiftUI

struct BatteryBoubleView: View {
    @Binding var currentBatteryLevel: Int?
    @Binding var currentChargeRate: Int?
    
    var body: some View {
        let batteryLevel: Int = currentBatteryLevel ?? 0
        
        Chart {
            SectorMark(
                angle: .value("Full", 0..<batteryLevel),
                innerRadius: 56,
                angularInset: 1
            )
            .cornerRadius(5)
            .foregroundStyle(batteryLevel > 5 ? .green : .red)
            
            SectorMark(
                angle: .value("Empty", batteryLevel..<100),
                innerRadius: 56,
                angularInset: 1
            )
            .cornerRadius(5)
            .foregroundStyle(.gray.opacity(0.4))
        }
        .chartBackground { chartProxy in
          GeometryReader { geometry in
              if let anchor = chartProxy.plotFrame {
                  let frame = geometry[anchor]
                  ZStack {
                      Circle()
                          .fill(.white)
                          .opacity(0.8)
                      
                      VStack {
                          Text("Battery")
                              .font(.system(size: 18, weight: .light))
                              .foregroundColor(.black)
                          
                          Text("\(batteryLevel)%")
                              .foregroundColor(getColor())
                              .font(.system(size: 24, weight: .bold))
                          
                          getBatterImage()
                              .foregroundColor(.black)
                      } // :VStack
                      .position(x: frame.midX, y: frame.midY)
                      
                  } // :ZStack
              }
          }
        }
        .frame(width: 120, height: 120)
    }
    
    private func getColor() -> Color {
        currentBatteryLevel ?? 0 < 10
            ? .red
            : currentBatteryLevel ?? 0 == 100
                ? .green
                : .black
    }

    private func getBatterImage() -> Image {
        if currentChargeRate ?? 0 > 0 {
            return Image(systemName: "battery.100percent.bolt")
        }

        if currentBatteryLevel ?? 0 >= 95 {
            return Image(systemName: "battery.100percent")
        }

        if currentBatteryLevel ?? 0 >= 70 {
            return Image(systemName: "battery.75percent")
        }

        if currentBatteryLevel ?? 0 >= 50 {
            return Image(systemName: "battery.50percent")
        }

        if currentBatteryLevel ?? 0 >= 10 {
            return Image(systemName: "battery.25percent")
        }

        return Image(systemName: "battery.0percent")
    }
}

#Preview {
    BatteryBoubleView(
        currentBatteryLevel: .constant(33),
        currentChargeRate: .constant(1234)
    )
}
