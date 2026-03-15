import SwiftUI

struct EfficiencyGaugeView: View {
    @Environment(\.colorScheme) private var colorScheme

    var todaySelfConsumptionRate: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        let selfConsumption = todaySelfConsumptionRate ?? 0
        let autarky = todayAutarchyDegree ?? 0

        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "gauge.medium")
                    .font(.caption2)
                    .foregroundStyle(.indigo)
                Text("Efficiency")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 20) {
                // Self-consumption gauge
                VStack(spacing: 6) {
                    GaugeArc(
                        percentage: selfConsumption,
                        color: .indigo
                    )
                    .frame(width: 52, height: 30)

                    Text(selfConsumption.formatIntoPercentage())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)

                    Text("Self cons.")
                        .font(.system(size: 9))
                        .foregroundStyle(.primary)
                }

                // Autarky gauge
                VStack(spacing: 6) {
                    GaugeArc(
                        percentage: autarky,
                        color: .purple
                    )
                    .frame(width: 52, height: 30)

                    Text(autarky.formatIntoPercentage())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)

                    Text("Autarky")
                        .font(.system(size: 9))
                        .foregroundStyle(.primary)
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
