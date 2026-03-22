import SwiftUI

struct EfficiencyGaugeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.energyManager) private var energyManager

    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?
    var compact: Bool = false

    @AppStorage("cachedOverallProduction") private var cachedOverallProduction: Double = 0
    @AppStorage("cachedOverallProductionFetchDate") private var cachedFetchDate: Double = 0

    private let co2PerWhInKg: Double = 0.00013
    private let boundCo2PerTreePerYearInKg: Double = 20

    var body: some View {
        let selfConsumption = todaySelfConsumptionRate ?? 0
        let autarky = todayAutarchyDegree ?? 0

        VStack(spacing: compact ? 4 : 8) {
            HStack(spacing: 4) {
                Image(systemName: "gauge.medium")
                    .font(.caption2)
                    .foregroundStyle(.indigo)
                Text("Efficiency")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: compact ? 12 : 20) {
                // Self-consumption gauge
                VStack(spacing: compact ? 3 : 6) {
                    GaugeArc(
                        percentage: selfConsumption,
                        color: .indigo
                    )
                    .frame(width: compact ? 36 : 52, height: compact ? 20 : 30)

                    Text(selfConsumption.formatIntoPercentage())
                        .font(compact ? .subheadline : .headline)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)

                    Text("Self cons.")
                        .font(.system(size: compact ? 8 : 9))
                        .foregroundStyle(.primary)
                }

                // Autarky gauge
                VStack(spacing: compact ? 3 : 6) {
                    GaugeArc(
                        percentage: autarky,
                        color: .purple
                    )
                    .frame(width: compact ? 36 : 52, height: compact ? 20 : 30)

                    Text(autarky.formatIntoPercentage())
                        .font(compact ? .subheadline : .headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)

                    Text("Autarky")
                        .font(.system(size: compact ? 8 : 9))
                        .foregroundStyle(.primary)
                }
            }

            if cachedOverallProduction > 0 {
                let co2Avoided = cachedOverallProduction / 10 * co2PerWhInKg
                let treesEquivalent = max(1, co2Avoided / boundCo2PerTreePerYearInKg)

                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("\(treesEquivalent, specifier: "%.0f") trees")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("(\(co2Avoided, specifier: "%.1f") kg CO₂)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            let age = Date().timeIntervalSince1970 - cachedFetchDate
            if cachedOverallProduction == 0 || age > 86400 {
                let stats = try? await energyManager.fetchStatistics(
                    from: nil,
                    to: Date(),
                    accuracy: .low
                )
                if let production = stats?.production {
                    cachedOverallProduction = production
                    cachedFetchDate = Date().timeIntervalSince1970
                }
            }
        }
    }
}

// MARK: - Gauge Arc Shape

private struct GaugeArc: View {
    let percentage: Double
    let color: Color

    var body: some View {
        let lineWidth: CGFloat = 7
        ZStack {
            // Background arc
            ArcShape()
                .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Filled arc
            ArcShape()
                .trim(from: 0, to: min(percentage / 100, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .padding(.horizontal, 2)
    }
}

private struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let radius = min(rect.width / 2, rect.height) - 4
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.maxY),
                radius: max(radius, 1),
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
    }
}

private struct GlassCardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(colorScheme == .dark ? Color(red: 0.165, green: 0.176, blue: 0.196) : Color(red: 0.918, green: 0.933, blue: 0.953))
            .shadow(color: colorScheme == .dark ? .white.opacity(0.05) : .white.opacity(0.7), radius: 8, x: -6, y: -6)
            .shadow(color: colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.15), radius: 8, x: 6, y: 6)
    }
}

#Preview("EN") {
    VStack {
        EfficiencyGaugeView(
            todaySelfConsumptionRate: 81.2,
            todayAutarchyDegree: 92.1
        )
        .frame(maxWidth: 180, maxHeight: 160)

        Spacer()
    }
}

#Preview("DE") {
    VStack {
        EfficiencyGaugeView(
            todaySelfConsumptionRate: 81.2,
            todayAutarchyDegree: 92.1
        )
        .frame(maxWidth: 180, maxHeight: 200)
        .environment(\.locale, Locale(identifier: "DE"))

        Spacer()
    }
}
