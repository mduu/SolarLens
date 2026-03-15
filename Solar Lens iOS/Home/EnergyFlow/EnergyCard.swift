import SwiftUI

struct EnergyCard<DetailContent: View>: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var detail: String?
    var showChevron: Bool = false
    var customDetail: (() -> DetailContent)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let customDetail {
                    customDetail()
                } else if let detail {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                        Text(detail)
                            .font(.caption2)
                    }
                    .foregroundStyle(.primary.opacity(0.6))
                } else {
                    Text(" ")
                        .font(.caption2)
                        .hidden()
                }
            }

            Spacer(minLength: 4)

            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .cardStyle()
    }
}

// Convenience init without custom detail
extension EnergyCard where DetailContent == EmptyView {
    init(icon: String, iconColor: Color, label: String, value: String,
         detail: String? = nil, showChevron: Bool = false) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.value = value
        self.detail = detail
        self.showChevron = showChevron
        self.customDetail = nil
    }
}

#Preview {
    HStack(spacing: 40) {
        EnergyCard(
            icon: "sun.max.fill",
            iconColor: .orange,
            label: "Production",
            value: "4.5 kW",
            detail: "25.7 kWh today",
            showChevron: true
        )
        EnergyCard(
            icon: "network",
            iconColor: .purple,
            label: "Grid",
            value: "0.8 kW",
            detail: "46.2 kWh"
        )
    }
    .padding()
}
