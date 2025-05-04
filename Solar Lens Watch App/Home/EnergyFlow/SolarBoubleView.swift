import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProduction: Int
    var maximumSolarProduction: Double
    
    var body: some View {
        VStack() {
            Gauge(
                value: Double(currentSolarProduction) / 1000,
                in: 0...Double(maximumSolarProduction) / 1000
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    currentSolarProduction.formatWattsAsKiloWatts()
                )
            }
            .gaugeStyle(.circular)
            .tint(getGaugeStyle())
            .accessibilityLabel("Current solar production is \(currentSolarProduction.formatWattsAsKiloWatts()) kilowatts")
            .background(Color.gray.opacity(0.3))
            .cornerRadius(30)
            .frame(width: 40, height: 40)
            .padding(3)
            
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
    SolarBoubleView(
        currentSolarProduction: 1000,
        maximumSolarProduction: 11000)
}

#Preview("Max PV)") {
    SolarBoubleView(
        currentSolarProduction: 11000,
        maximumSolarProduction: 11000)
}


#Preview("Ver-low PV)") {
    SolarBoubleView(
        currentSolarProduction: 45,
        maximumSolarProduction: 11000)
}

#Preview("No PV)") {
    SolarBoubleView(
        currentSolarProduction: 0,
        maximumSolarProduction: 11000)
}
