import SwiftUI

/// Animated dashed line with traveling dots, used for the charging connector.
struct FlowLine: View {
    let isActive: Bool
    let color: Color
    var direction: FlowDirection = .down

    enum FlowDirection {
        case down
        case downLeft
        case downRight
    }

    var body: some View {
        if isActive {
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1.6) / 1.6

                GeometryReader { geo in
                    Canvas { context, _ in
                        let midX = geo.size.width / 2
                        let h = geo.size.height

                        // Dashed line
                        var path = Path()
                        path.move(to: CGPoint(x: midX, y: 0))
                        path.addLine(to: CGPoint(x: midX, y: h))
                        context.stroke(
                            path,
                            with: .color(color.opacity(0.25)),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )

                        // Two traveling dots
                        for i in 0..<2 {
                            let t = (CGFloat(phase) + CGFloat(i) / 2.0)
                                .truncatingRemainder(dividingBy: 1.0)
                            let y = t * h
                            let fade = min(t / 0.15, 1) * min((1 - t) / 0.15, 1)

                            let dotSize: CGFloat = 6
                            context.fill(
                                Circle().path(in: CGRect(
                                    x: midX - dotSize / 2,
                                    y: y - dotSize / 2,
                                    width: dotSize,
                                    height: dotSize
                                )),
                                with: .color(color.opacity(fade * 0.8))
                            )
                        }
                    }
                }
            }
        }
    }
}

#Preview("Flow Line") {
    FlowLine(isActive: true, color: .blue, direction: .down)
        .frame(width: 20, height: 60)
        .padding()
}
