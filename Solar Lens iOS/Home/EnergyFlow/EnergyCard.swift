import SwiftUI

struct EnergyCard<DetailContent: View>: View {
    let icon: String
    let iconColor: Color
    let label: LocalizedStringKey
    let value: String
    var detail: LocalizedStringKey?
    var showChevron: Bool = false
    var applyCardStyle: Bool = true
    var customDetail: (() -> DetailContent)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if customDetail == nil {
                        if let detail {
                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9))
                                Text(detail)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(.primary.opacity(0.6))
                        } else {
                            Text(" ")
                                .font(.caption2)
                                .hidden()
                        }
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

            if let customDetail {
                customDetail()
            }
        }
        .if(applyCardStyle) { $0.cardStyle() }
    }
}

// Convenience init without custom detail
extension EnergyCard where DetailContent == EmptyView {
    init(icon: String, iconColor: Color, label: LocalizedStringKey, value: String,
         detail: LocalizedStringKey? = nil, showChevron: Bool = false,
         applyCardStyle: Bool = true) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.value = value
        self.detail = detail
        self.showChevron = showChevron
        self.applyCardStyle = applyCardStyle
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
