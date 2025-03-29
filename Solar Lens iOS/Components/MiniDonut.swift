import Charts
import SwiftUI

struct MiniDonut: View {
    var percentage: Double
    var color: Color = .primary
    var showPerentage: Bool = true
    var lineWidth: Int = 4

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
                .foregroundStyle(color)

                SectorMark(
                    angle: .value("Empty", percentage..<100),
                    innerRadius: MarkDimension(integerLiteral: innerRadius),
                    angularInset: 0
                )
                .cornerRadius(5)
                .foregroundStyle(color.opacity(0.3))
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if showPerentage {
                        if let anchor = chartProxy.plotFrame {
                            let frame = geometry[anchor]

                            VStack {
                                Text("\(String(format: "%.0f", percentage))%")
                                    .foregroundColor(color)
                                    .font(.system(size: 10, weight: .bold))
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
        MiniDonut(percentage: 100, color: .green)
            .frame(width: 40, height: 40)

        MiniDonut(percentage: 35, color: .orange)
            .frame(width: 40, height: 40)

        MiniDonut(percentage: 35, color: .orange, showPerentage: false)
            .frame(width: 40, height: 40)

        MiniDonut(
            percentage: 35, color: .cyan, showPerentage: false, lineWidth: 7
        )
        .frame(width: 40, height: 40)

        Spacer()
    }
}
