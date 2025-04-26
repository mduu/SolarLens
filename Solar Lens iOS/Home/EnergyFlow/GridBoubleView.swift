import SwiftUI

struct GridBoubleView: View {
    var gridInKwh: Double
    var useGlow: Bool
    
    var body: some View {
        CircularInstrument(
            borderColor: gridInKwh != 0 ? .orange : .gray,
            label: "Grid",
            value: String(format: "%.1f kW", gridInKwh),
            useGlowEffect: useGlow
        ) {
            Image(systemName: "network")
                .foregroundColor(.black)
        }
    }
}

#Preview("No glow") {
    GridBoubleView(gridInKwh: 5.4, useGlow: false)
        .frame(width: 150, height: 150)
}

#Preview("With glow") {
    GridBoubleView(gridInKwh: 5.4, useGlow: true)
        .frame(width: 150, height: 150)
}
