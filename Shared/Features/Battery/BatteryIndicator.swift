import SwiftUI

struct BatteryIndicator: View {
    var percentage: Double
    var showPercentage: Bool = true
    var height: CGFloat = 20
    var width: CGFloat = 100

    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var bubbleTime: CGFloat = 0
    @State private var glowPulse: Bool = false

    private var baseColor: Color {
        switch percentage {
        case 0..<8:
            return .red
        case 8..<12:
            return .orange
        default:
            return .green
        }
    }

    private var clampedPercent: Double {
        min(max(percentage, 0), 100)
    }

    var body: some View {
        let cornerRadius = height * 0.3
        let inset: CGFloat = 3

        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: cornerRadius + 2)
                .fill(baseColor.opacity(glowPulse ? 0.15 : 0.05))
                .blur(radius: 4)

            // Outer shell — battery casing
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.5),
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.gray.opacity(0.3),
                                    Color.black.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                )

            // Inner cavity
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(inset)

            // Fluid fill with wave
            FluidFillView(
                percentage: clampedPercent,
                baseColor: baseColor,
                waveOffset1: waveOffset1,
                waveOffset2: waveOffset2,
                bubbleTime: bubbleTime,
                cornerRadius: cornerRadius - 1
            )
            .padding(inset)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 1))

            // Glass reflection highlight
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: cornerRadius - 1)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height * 0.4)
                Spacer()
            }
            .padding(inset)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 1))
            .allowsHitTesting(false)

            // Percentage text
            if showPercentage {
                Text("\(Int(percentage))%")
                    .font(.system(size: height * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            // Primary wave — broad slosh back and forth
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                waveOffset1 = .pi * 2
            }
            // Secondary wave — different rhythm, async feel
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                waveOffset2 = .pi * 2.5
            }
            // Bubble animation — continuous
            withAnimation(
                .linear(duration: 4)
                .repeatForever(autoreverses: false)
            ) {
                bubbleTime = .pi * 2
            }
            // Glow pulse
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Fluid Fill

private struct FluidFillView: View {
    let percentage: Double
    let baseColor: Color
    let waveOffset1: CGFloat
    let waveOffset2: CGFloat
    let bubbleTime: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { geo in
            let fillWidth = geo.size.width * CGFloat(percentage / 100)
            let waveAmplitude = max(geo.size.height * 0.12, 2.0)

            ZStack(alignment: .leading) {
                // Main fluid body with rich gradient
                LinearGradient(
                    colors: [
                        baseColor.opacity(0.5),
                        baseColor.opacity(0.9),
                        baseColor.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: fillWidth)

                // Inner glow at top of fluid
                LinearGradient(
                    colors: [
                        baseColor.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(width: fillWidth)

                // Depth shadow at bottom
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.25)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: fillWidth)

                // Wave surface on the right edge
                if percentage > 0 && percentage < 100 {
                    // Primary wave — single broad slosh
                    HorizontalWaveShape(
                        offset: waveOffset1,
                        waveAmplitude: waveAmplitude,
                        waveCount: 0.5
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                baseColor.opacity(0.6),
                                baseColor,
                                baseColor.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: fillWidth + waveAmplitude * 2)

                    // Secondary wave — async, slightly faster rhythm
                    HorizontalWaveShape(
                        offset: waveOffset2,
                        waveAmplitude: waveAmplitude * 0.7,
                        waveCount: 0.7
                    )
                    .fill(baseColor.opacity(0.45))
                    .frame(width: fillWidth + waveAmplitude * 2)

                    // Bright edge highlight on wave crest
                    HorizontalWaveShape(
                        offset: waveOffset1,
                        waveAmplitude: waveAmplitude,
                        waveCount: 0.5
                    )
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: fillWidth + waveAmplitude * 2)
                }

                // Bubbles
                if percentage > 3 {
                    BubbleLayer(
                        waveOffset: bubbleTime,
                        fillWidth: fillWidth,
                        containerHeight: geo.size.height
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Horizontal Wave Shape

private struct HorizontalWaveShape: Shape {
    var offset: CGFloat
    var waveAmplitude: CGFloat
    var waveCount: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let height = rect.height
        let rightEdge = rect.width - waveAmplitude * 2

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rightEdge, y: 0))

        // Wavy right edge — single broad sloshing wave
        for y in stride(from: 0, through: height, by: 0.5) {
            let relativeY = y / height
            let sine = sin(relativeY * .pi * 2 * waveCount + offset)
            let x = rightEdge + sine * waveAmplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Bubble Layer

private struct BubbleLayer: View {
    let waveOffset: CGFloat
    let fillWidth: CGFloat
    let containerHeight: CGFloat

    private struct Bubble {
        let xBase: CGFloat
        let speed: CGFloat
        let radius: CGFloat
        let opacity: CGFloat
        let drift: CGFloat
    }

    private let bubbles: [Bubble] = {
        (0..<10).map { i in
            let seed: CGFloat = CGFloat(i) * 1.618
            return Bubble(
                xBase: 0.05 + ((sin(seed * 3.7) + 1) / 2) * 0.9,
                speed: 0.4 + (sin(seed * 2.1) + 1) * 0.3,
                radius: 0.8 + (sin(seed * 5.1) + 1) * 0.8,
                opacity: 0.1 + (sin(seed * 2.9) + 1) * 0.08,
                drift: (sin(seed * 4.3)) * 0.05
            )
        }
    }()

    var animatableData: CGFloat {
        get { waveOffset }
        set { }
    }

    var body: some View {
        Canvas { context, size in
            // Spread across full width including wave overshoot
            let maxX = fillWidth * 1.15
            for bubble in bubbles {
                let phase = waveOffset * bubble.speed
                // Rise from bottom to top, looping
                let cycleY = (phase / (.pi * 2)).truncatingRemainder(dividingBy: 1.0)
                let y = size.height * (1.0 - cycleY)
                // Horizontal position across entire fill
                let x = maxX * bubble.xBase + sin(phase * 1.7) * maxX * bubble.drift

                guard x > 0 else { continue }

                // Fade in at bottom, fade out at top
                let fadeIn = min(cycleY * 5, 1.0)
                let fadeOut = min((1.0 - cycleY) * 5, 1.0)
                let alpha = bubble.opacity * fadeIn * fadeOut

                let r = bubble.radius
                let bubblePath = Path(ellipseIn: CGRect(
                    x: x - r, y: y - r,
                    width: r * 2, height: r * 2
                ))
                context.fill(bubblePath, with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

struct BatteryIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                BatteryIndicator(percentage: 100)
                BatteryIndicator(percentage: 75)
                BatteryIndicator(percentage: 50)
                BatteryIndicator(percentage: 25)
                BatteryIndicator(percentage: 10)

                // Custom sizes
                BatteryIndicator(percentage: 80, height: 15, width: 80)
                BatteryIndicator(percentage: 60, showPercentage: false, width: 60)

                // Large for detail
                BatteryIndicator(percentage: 65, height: 48, width: 200)
            }
            .padding()
            .background(.purple.opacity(0.2))
            .previewLayout(.sizeThatFits)
        }
    }
}
