import SwiftUI

struct SolarProductionView: View {
    @Binding var currentSolarProduction: Int
    @Binding var maximumSolarProduction: Double
    
    var body: some View {
        VStack() {
            Gauge(
                value: Double(currentSolarProduction) / 1000,
                in: 0...Double(maximumSolarProduction) / 1000
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.1f",
                        Double(currentSolarProduction) / 1000)
                )
            }
            .gaugeStyle(.circular)
            .tint(getGaugeStyle())

            Image(systemName: "sun.max")
        }
    }
    
    private func getGaugeStyle() -> Gradient {
        if (currentSolarProduction < 50)
        {
            return Gradient(colors: [.gray, .gray])
        } else {
            return Gradient(colors: [.blue, .yellow, .orange])
        }
    }
}

#Preview("Low PV)") {
    SolarProductionView(
        currentSolarProduction: .constant(1000),
        maximumSolarProduction: .constant(11000))
}

#Preview("Max PV)") {
    SolarProductionView(
        currentSolarProduction: .constant(11000),
        maximumSolarProduction: .constant(11000))
}


#Preview("Ver-low PV)") {
    SolarProductionView(
        currentSolarProduction: .constant(45),
        maximumSolarProduction: .constant(11000))
}

#Preview("No PV)") {
    SolarProductionView(
        currentSolarProduction: .constant(0),
        maximumSolarProduction: .constant(11000))
}
