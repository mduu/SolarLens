import SwiftUI

/// Animated energy flow line — a cable with gradient impulses that fade at the tail.
struct FlowArrow: View {
    let color: Color
    let power: Double
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        if power > 0 {
            ZStack {
                energyCable
                kWLabel
            }
        }
    }

    private var midPoint: CGPoint {
        CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
    }

    private var isVertical: Bool { abs(to.x - from.x) < 2 }
    private var isHorizontal: Bool { abs(to.y - from.y) < 2 }

    @ViewBuilder
    private var energyCable: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let phase = CGFloat(timeline.date.timeIntervalSinceReferenceDate)

            Canvas { context, _ in
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)

                let cableWidth: CGFloat = 4

                // Base cable
                context.stroke(path, with: .color(color.opacity(0.12)),
                               style: StrokeStyle(lineWidth: cableWidth, lineCap: .round))

                // Gradient impulses: bright head fading to transparent tail
                let speed: CGFloat = 1.8  // seconds per full cycle — slow & smooth
                let t = (phase / speed).truncatingRemainder(dividingBy: 1.0)
                let impulseCount = 2
                let impulseLen: CGFloat = 0.30  // 30% of path length

                for i in 0..<impulseCount {
                    let head = (t + CGFloat(i) / CGFloat(impulseCount))
                        .truncatingRemainder(dividingBy: 1.0)
                    let tail = head - impulseLen

                    // Draw the impulse as many thin slices with decreasing opacity
                    let slices = 12
                    for s in 0..<slices {
                        let frac = CGFloat(s) / CGFloat(slices)  // 0 = head, 1 = tail
                        let pos = head - frac * impulseLen

                        let sliceStart: CGFloat
                        let sliceEnd: CGFloat

                        if s == 0 {
                            sliceEnd = head
                            sliceStart = head - impulseLen / CGFloat(slices)
                        } else {
                            sliceEnd = head - CGFloat(s) * impulseLen / CGFloat(slices)
                            sliceStart = head - CGFloat(s + 1) * impulseLen / CGFloat(slices)
                        }

                        // Opacity: bright at head, fades to zero at tail
                        let opacity = (1.0 - frac) * 0.75

                        // Normalize positions (handle wrapping)
                        let normStart = ((sliceStart.truncatingRemainder(dividingBy: 1.0)) + 1.0)
                            .truncatingRemainder(dividingBy: 1.0)
                        let normEnd = ((sliceEnd.truncatingRemainder(dividingBy: 1.0)) + 1.0)
                            .truncatingRemainder(dividingBy: 1.0)

                        if normStart < normEnd {
                            let seg = path.trimmedPath(from: normStart, to: normEnd)
                            context.stroke(seg, with: .color(color.opacity(opacity)),
                                           style: StrokeStyle(lineWidth: cableWidth, lineCap: .butt))
                        } else {
                            // Wraps around
                            let seg1 = path.trimmedPath(from: normStart, to: 1.0)
                            let seg2 = path.trimmedPath(from: 0, to: normEnd)
                            let style = StrokeStyle(lineWidth: cableWidth, lineCap: .butt)
                            context.stroke(seg1, with: .color(color.opacity(opacity)), style: style)
                            context.stroke(seg2, with: .color(color.opacity(opacity)), style: style)
                        }
                    }

                    // White core at the head for brightness
                    let corePos = head
                    let coreLen: CGFloat = 0.03
                    let cStart = ((corePos - coreLen).truncatingRemainder(dividingBy: 1.0) + 1.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let cEnd = (corePos.truncatingRemainder(dividingBy: 1.0) + 1.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    if cStart < cEnd {
                        let coreSeg = path.trimmedPath(from: cStart, to: cEnd)
                        context.stroke(coreSeg, with: .color(.white.opacity(0.5)),
                                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var kWLabel: some View {
        let offset: CGFloat = isHorizontal ? -14 : 22

        Text(String(format: "%.1f kW", power))
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .position(
                x: midPoint.x + (isVertical || !isHorizontal ? offset : 0),
                y: midPoint.y + (isHorizontal ? offset : 0)
            )
    }
}
