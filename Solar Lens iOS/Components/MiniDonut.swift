import Charts
import SwiftUI

struct MiniDonut: View {
    var percentage: Double
    var color: Color = .primary

    var body: some View {
        GeometryReader { geometry in

            let innerRadius =
                geometry.size.width > geometry.size.height
                ? Int(geometry.size.height / 2 - 4)
                : Int(geometry.size.width / 2 - 4)

            Chart {
                SectorMark(
                    angle: .value("Full", 0..<percentage),
                    innerRadius: MarkDimension(integerLiteral: innerRadius),
                    angularInset: 3
                )
                .cornerRadius(5)
                .foregroundStyle(color)

                SectorMark(
                    angle: .value("Empty", percentage..<100),
                    innerRadius: MarkDimension(integerLiteral: innerRadius),
                    angularInset: 1
                )
                .cornerRadius(5)
                .foregroundStyle(.gray.opacity(0.4))
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
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

#Preview {
    MiniDonut(percentage: 100, color: .green)
        .frame(width: 40, height: 40)

    MiniDonut(percentage: 35, color: .orange)
        .frame(width: 40, height: 40)
}
