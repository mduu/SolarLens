import Charts
import SwiftUI

struct BatteryBoubleView: View {
    var currentBatteryLevel: Int?
    var currentChargeRate: Int?
    var useGlow: Bool
    
    @State var showBatterySheet: Bool = false
    
    var body: some View {
        if (currentBatteryLevel != nil) {
            
            let batteryLevel: Int = currentBatteryLevel ?? 0
            
            GeometryReader { geometry in
                let innerRadius = geometry.size.width > geometry.size.height
                    ? Int(geometry.size.height / 2 - 4)
                    : Int(geometry.size.width / 2 - 4)
                
                Chart {
                    let color: Color = batteryLevel > 5 ? .green : .red
                    
                    SectorMark(
                        angle: .value("Full", 0..<batteryLevel),
                        innerRadius: MarkDimension(integerLiteral: innerRadius),
                        angularInset: 3
                    )
                    .cornerRadius(5)
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(useGlow ? 0.5 : 0), radius: useGlow ? 5 : 0, x: 0, y: 0)

                    SectorMark(
                        angle: .value("Empty", batteryLevel..<100),
                        innerRadius: MarkDimension(integerLiteral: innerRadius),
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
                                    .shadow(radius: 5, x: 4, y: 4)

                                VStack {
                                    Text("Battery")
                                        .font(.system(size: 14, weight: .light))
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
                .onTapGesture {
                    showBatterySheet = true
                }
                .sheet(isPresented: $showBatterySheet) {
                    NavigationView {
                        BatterySheet()
                    }
                    .presentationDetents([.medium])
                }
            } // :GeometryReader
        } // :if
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

#Preview("Data") {
    BatteryBoubleView(
        currentBatteryLevel: 33,
        currentChargeRate: 1234,
        useGlow: false
    )
    .frame(width: 120, height: 120)
}

#Preview("Data lg") {
    BatteryBoubleView(
        currentBatteryLevel: 5,
        currentChargeRate: 1234,
        useGlow: false
    )
    .frame(width: 300, height: 290)
}

#Preview("Data lg & glow") {
    BatteryBoubleView(
        currentBatteryLevel: 5,
        currentChargeRate: 1234,
        useGlow: true
    )
    .frame(width: 300, height: 290)
}

#Preview("No Data") {
    BatteryBoubleView(
        currentBatteryLevel: nil,
        currentChargeRate: nil,
        useGlow: false
    )
    .frame(width: 120, height: 120)
}
