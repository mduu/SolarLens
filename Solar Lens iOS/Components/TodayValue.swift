import SwiftUI

struct TodayValue: View {
    var valueInWh: Double

    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            Image(systemName: "calendar")
                .foregroundColor(.primary)
                .font(.system(size: 12, weight: .bold, design: .default))

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(String(format: "%.1f", Double(valueInWh) / 1000))
                    .foregroundColor(.primary)
                    .font(.system(size: 12, weight: .bold, design: .default))
                Text("kWh")
                    .foregroundColor(.primary)
                    .font(.system(size: 12, weight: .light, design: .default))
            }
        }
    }
}

#Preview {
    TodayValue(valueInWh: 23542)
        .frame(width: 80, height: 30)
}
