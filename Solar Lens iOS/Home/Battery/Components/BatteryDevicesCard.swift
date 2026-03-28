import SwiftUI

struct BatteryDevicesCard: View {
    let batteries: [Device]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Devices")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(batteries) { battery in
                    BatteryView(battery: battery)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
