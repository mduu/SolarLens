import SwiftUI

struct GridBoubleView: View {
    var gridInKwh: Double
    
    var body: some View {
        CircularInstrument(
            borderColor: gridInKwh != 0 ? .orange : .gray,
            label: "Grid",
            value: String(format: "%.1f kW", gridInKwh)
        ) {
            Image(systemName: "network")
                .foregroundColor(.black)
        }
    }
}

#Preview {
    GridBoubleView(gridInKwh: 5.4)
        .frame(width: 150, height: 150)
}
