import SwiftUI

/// The ways a statistics period can be drawn.
enum StatisticsChartStyle: String, CaseIterable, Identifiable {
    /// Where the period's energy came from and went, as one picture.
    case flow
    /// Production minus consumption, one bar per bucket: which day, month
    /// or year ran a surplus and which a deficit.
    case balance
    /// Tiles tinted by autarky, self-consumption or balance — hours, days or
    /// months, depending on the period.
    case map
    /// The four series side by side — what the screen has always drawn.
    case bars

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .flow: "Flow"
        case .balance: "Balance"
        case .map: "Map"
        case .bars: "Bars"
        }
    }

    var systemImage: String {
        switch self {
        case .flow: "arrow.triangle.branch"
        case .balance: "plusminus"
        case .map: "square.grid.3x3.fill"
        case .bars: "chart.bar.fill"
        }
    }
}

/// Switches between the chart styles a period offers.
///
/// A row of icons where the chosen one spells its name out. Icons alone would
/// leave their meaning to guesswork; four labels would not fit next to each
/// other on a phone.
struct StatisticsChartStylePicker: View {
    var styles: [StatisticsChartStyle]
    @Binding var selection: StatisticsChartStyle

    var body: some View {
        HStack(spacing: 2) {
            ForEach(styles) { style in
                let isSelected = style == selection

                Button {
                    withAnimation(.snappy) { selection = style }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: style.systemImage)
                            .font(.system(size: 13, weight: .medium))
                        if isSelected {
                            Text(style.name)
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .padding(.horizontal, isSelected ? 12 : 10)
                    .frame(height: 30)
                    .background(
                        isSelected ? Color.gray.opacity(0.28) : Color.clear,
                        in: Capsule()
                    )
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(style.name))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.gray.opacity(0.12), in: Capsule())
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var selection = StatisticsChartStyle.flow

        VStack(spacing: 20) {
            StatisticsChartStylePicker(
                styles: [.flow, .bars], selection: $selection
            )
            StatisticsChartStylePicker(
                styles: StatisticsChartStyle.allCases, selection: $selection
            )
        }
        .padding()
    }
#endif
