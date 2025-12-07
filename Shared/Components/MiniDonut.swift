import Charts
import SwiftUI

struct MiniDonut<AdditionalContent: View>: View {
    var percentage: Double
    var color: Color
    var showPerentage: Bool
    var lineWidth: Int
    var textFont: Font
    var additionalContent: AdditionalContent

    init(
        percentage: Double,
        color: Color = .primary,
        showPerentage: Bool = true,
        lineWidth: Int = 4,
        textFont: Font = .system(size: 10, weight: .bold),
        @ViewBuilder additionalContent: () -> AdditionalContent = { EmptyView() }
    ) {
        self.percentage = percentage
        self.color = color
        self.showPerentage = showPerentage
        self.lineWidth = lineWidth
        self.textFont = textFont
        self.additionalContent = additionalContent()
    }

    func angle(from percentage: Double) -> Double {
        return percentage * 360.0 / 100.0
    }

    var body: some View {
        GeometryReader { geometry in
            let haldWidth =
                geometry.size.width > geometry.size.height
                ? Int(geometry.size.height / 2)
                : Int(geometry.size.width / 2)
            let innerRadius = haldWidth - lineWidth

            Chart {
                SectorMark(
                    angle: .value("Full", 0..<percentage),
                    innerRadius: MarkDimension(integerLiteral: innerRadius),
                    angularInset: 0
                )
                .cornerRadius(5)
                .foregroundStyle(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.7), color]),  // Soft Gradient
                        center: .center,
                        startAngle: .degrees(-90),  // Start from top center
                        endAngle: .degrees(angle(from: percentage) - 90)  // End at calculated angle
                    )
                )

                SectorMark(
                    angle: .value("Empty", 0.1..<100),
                    innerRadius: MarkDimension(integerLiteral: innerRadius),
                    angularInset: 0
                )
                .foregroundStyle(color.opacity(0.3))
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in


                    if showPerentage {
                        if let anchor = chartProxy.plotFrame {
                            let frame = geometry[anchor]

                            VStack {
                                additionalContent

                                Text("\(String(format: "%.0f", percentage))%")
                                    .foregroundColor(color)
                                    .font(textFont)
                            }  // :VStack
                            .position(x: frame.midX, y: frame.midY)

                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        MiniDonut(percentage: 80, color: .yellow)
            .frame(width: 40, height: 40)

        MiniDonut(percentage: 35, color: .yellow)
            .frame(width: 40, height: 40)

        MiniDonut(percentage: 35, color: .orange, showPerentage: false)
            .frame(width: 40, height: 40)

        MiniDonut(
            percentage: 90, color: .teal, showPerentage: false, lineWidth: 7
        )
        .frame(width: 40, height: 40)

        Spacer()
    }
}
