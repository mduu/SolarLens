import SwiftUI

struct BackgroundView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @Environment(\.colorScheme) var colorScheme
    @State private var settings = AppSettings()

    var body: some View {
        let useWarm = settings.appearanceUseWarmBackgroundWithDefault.wrappedValue
        let production = useWarm ? buildingState.overviewData.currentSolarProduction : 0
        let gridImport = useWarm ? buildingState.overviewData.currentGridToHouse : 0

        GeometryReader { geo in
            ZStack {
                // Layer 1: Cool mesh gradient (always neutral/cool — no warm tones)
                if #available(iOS 18.0, *) {
                    meshBackground()
                } else {
                    legacyGradient()
                }

                // Layer 2: Background image — barely recognizable, shimmering through
                Image("bg_neon_solar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(colorScheme == .dark ? 0.20 : 0.30)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)

                // Layer 3: God rays from top — only when producing
                if production > 0 {
                    GodRaysView(
                        production: production,
                        colorScheme: colorScheme
                    )
                }
            }
        }
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 2), value: production)
        .animation(.easeInOut(duration: 2), value: gridImport)
    }

    // MARK: - MeshGradient (iOS 18+)

    @available(iOS 18.0, *)
    @ViewBuilder
    private func meshBackground() -> some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: colorScheme == .dark ? darkMeshColors : lightMeshColors
        )
    }

    // Darker cool mesh so white rays pop with contrast
    private var lightMeshColors: [Color] {
        [
            Color(h: 215, s: 0.22, b: 0.82), Color(h: 220, s: 0.18, b: 0.84), Color(h: 210, s: 0.20, b: 0.83),
            Color(h: 220, s: 0.10, b: 0.88), Color(h: 225, s: 0.08, b: 0.89), Color(h: 215, s: 0.09, b: 0.88),
            Color(h: 220, s: 0.04, b: 0.93), Color(h: 215, s: 0.03, b: 0.94), Color(h: 220, s: 0.04, b: 0.93),
        ]
    }

    private var darkMeshColors: [Color] {
        [
            Color(h: 215, s: 0.45, b: 0.14), Color(h: 220, s: 0.40, b: 0.12), Color(h: 210, s: 0.40, b: 0.13),
            Color(h: 220, s: 0.15, b: 0.09), Color(h: 225, s: 0.10, b: 0.08), Color(h: 215, s: 0.12, b: 0.09),
            Color(h: 220, s: 0.08, b: 0.13), Color(h: 215, s: 0.06, b: 0.12), Color(h: 220, s: 0.08, b: 0.13),
        ]
    }

    // MARK: - Legacy Gradient (< iOS 18)

    @ViewBuilder
    private func legacyGradient() -> some View {
        if colorScheme == .dark {
            LinearGradient(colors: [Color(hex6: 0x0A1628), Color(hex6: 0x0D0D0D)], startPoint: .top, endPoint: .bottom)
        } else {
            LinearGradient(colors: [Color(hex6: 0xCDD4DE), Color(hex6: 0xE8EBF0)], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - God Rays View

private struct GodRaysView: View {
    let production: Int
    let colorScheme: ColorScheme

    /// 0...1 intensity — aggressive curve so even low production shows rays
    private var intensity: Double {
        let raw = min(Double(production) / 3000.0, 1.0)
        return 0.5 + raw * 0.5
    }

    /// > 3kW = "hot summer day" mode
    private var isHighProduction: Bool { production > 3000 }

    private var isDark: Bool { colorScheme == .dark }

    // Pure white rays — no yellow tint
    private let rayColor = Color.white
    private let rayColorIntense = Color.white

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let origin = CGPoint(x: -size.width * 0.05, y: -size.height * 0.04)
                let reach = size.height * (isHighProduction ? 1.0 : 0.85)

                // 1) Diffuse warm glow
                drawDiffuseGlow(context: context, origin: origin, size: size)
                // 2) Ray beams — the hero effect
                drawRays(context: context, origin: origin, maxReach: reach, time: elapsed)
                // 3) Extra rays for high production (hot summer day)
                if isHighProduction {
                    drawBonusRays(context: context, origin: origin, maxReach: reach, time: elapsed)
                }
                // 4) Bright source
                drawSourceGlow(context: context, origin: origin, radius: size.width * (isHighProduction ? 0.45 : 0.35))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bright Source

    private func drawSourceGlow(context: GraphicsContext, origin: CGPoint, radius: Double) {
        let o = isDark ? 0.55 : 1.0

        // Tight bright core
        let coreRadius = radius * 0.35
        let coreGradient = Gradient(stops: [
            .init(color: Color.white.opacity(o), location: 0.0),
            .init(color: Color.white.opacity(o * 0.7), location: 0.4),
            .init(color: Color.clear, location: 1.0),
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: origin.x - coreRadius, y: origin.y - coreRadius,
                                   width: coreRadius * 2, height: coreRadius * 2)),
            with: .radialGradient(coreGradient, center: origin, startRadius: 0, endRadius: coreRadius)
        )

        // Wide white halo
        let haloGradient = Gradient(stops: [
            .init(color: Color.white.opacity(o * 0.6), location: 0.0),
            .init(color: Color.white.opacity(o * 0.3), location: 0.3),
            .init(color: Color.white.opacity(o * 0.08), location: 0.6),
            .init(color: Color.clear, location: 1.0),
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius,
                                   width: radius * 2, height: radius * 2)),
            with: .radialGradient(haloGradient, center: origin, startRadius: 0, endRadius: radius)
        )
    }

    // MARK: - Diffuse Glow

    private func drawDiffuseGlow(context: GraphicsContext, origin: CGPoint, size: CGSize) {
        let o = (isDark ? 0.20 : 0.45) * intensity
        let radius = max(size.width, size.height) * (isHighProduction ? 0.85 : 0.7)

        let gradient = Gradient(stops: [
            .init(color: Color.white.opacity(o), location: 0.0),
            .init(color: Color.white.opacity(o * 0.4), location: 0.35),
            .init(color: Color.clear, location: 1.0),
        ])

        context.fill(
            Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius,
                                   width: radius * 2, height: radius * 2)),
            with: .radialGradient(gradient, center: origin, startRadius: 0, endRadius: radius)
        )
    }

    // MARK: - Main Ray Beams

    private let rayDefs: [(angle: Double, width: Double, opacity: Double)] = [
        (42,   7,  0.6),
        (52,  14,  1.0),
        (60,   5,  0.5),
        (68,  12,  0.95),
        (78,   8,  0.7),
        (88,  16,  1.0),
        (98,   6,  0.55),
        (106, 12,  0.9),
        (116,  9,  0.65),
        (126, 13,  0.8),
        (138,  7,  0.5),
    ]

    // Extra rays for >3kW — fill in the gaps for that "blazing sun" feel
    private let bonusRayDefs: [(angle: Double, width: Double, opacity: Double)] = [
        (47,  10, 0.7),
        (56,   8, 0.6),
        (64,  11, 0.8),
        (73,  14, 0.9),
        (83,   9, 0.65),
        (93,  13, 0.85),
        (102,  7, 0.55),
        (111, 10, 0.7),
        (121,  8, 0.6),
        (132, 11, 0.75),
    ]

    private func drawRays(
        context: GraphicsContext,
        origin: CGPoint,
        maxReach: Double,
        time: Double
    ) {
        drawRaySet(rayDefs, context: context, origin: origin, maxReach: maxReach, time: time, opacityScale: 1.0)
    }

    private func drawBonusRays(
        context: GraphicsContext,
        origin: CGPoint,
        maxReach: Double,
        time: Double
    ) {
        // Bonus rays are slightly less opaque, offset animation phase
        drawRaySet(bonusRayDefs, context: context, origin: origin, maxReach: maxReach, time: time + 45, opacityScale: 0.7)
    }

    private func drawRaySet(
        _ defs: [(angle: Double, width: Double, opacity: Double)],
        context: GraphicsContext,
        origin: CGPoint,
        maxReach: Double,
        time: Double,
        opacityScale: Double
    ) {
        // Animation: slow drift + per-ray pulsing opacity
        let drift: Double = time / 20.0 * .pi * 2

        let baseOpacity: Double = (isDark ? 0.45 : 0.90) * intensity * opacityScale
        let color = isHighProduction ? rayColorIntense : rayColor

        for (index, ray) in defs.enumerated() {
            let seed = Double(index) * 2.3 + 0.7

            // Angle shimmer: rays slowly sway ±2°
            let shimmer: Double = sin(drift + seed * 1.3) * 2.0
            // Opacity pulse: each ray gently breathes ±15%
            let pulse: Double = 0.85 + sin(drift * 0.7 + seed * 2.1) * 0.15

            let centerDeg: Double = ray.angle + shimmer
            let centerRad: Double = centerDeg * .pi / 180.0
            let halfWidthRad: Double = (ray.width / 2.0) * .pi / 180.0

            let leftRad: Double = centerRad - halfWidthRad
            let rightRad: Double = centerRad + halfWidthRad

            let cosL: Double = cos(leftRad)
            let sinL: Double = sin(leftRad)
            let cosR: Double = cos(rightRad)
            let sinR: Double = sin(rightRad)
            let cosC: Double = cos(centerRad)
            let sinC: Double = sin(centerRad)

            let endPoint = CGPoint(
                x: origin.x + cosC * maxReach,
                y: origin.y + sinC * maxReach
            )

            let opacity = baseOpacity * ray.opacity * pulse

            // --- Core ray beam ---
            var corePath = Path()
            corePath.move(to: origin)
            corePath.addLine(to: CGPoint(x: origin.x + cosL * maxReach, y: origin.y + sinL * maxReach))
            corePath.addLine(to: CGPoint(x: origin.x + cosR * maxReach, y: origin.y + sinR * maxReach))
            corePath.closeSubpath()

            let coreGradient = Gradient(stops: [
                .init(color: Color.white.opacity(opacity), location: 0.0),
                .init(color: color.opacity(opacity * 0.85), location: 0.12),
                .init(color: color.opacity(opacity * 0.45), location: 0.35),
                .init(color: color.opacity(opacity * 0.10), location: 0.65),
                .init(color: Color.clear, location: 0.90),
            ])

            var coreCtx = context
            coreCtx.addFilter(.blur(radius: 4))
            coreCtx.fill(corePath, with: .linearGradient(coreGradient, startPoint: origin, endPoint: endPoint))

            // --- Soft glow halo around each ray ---
            let haloHalf: Double = halfWidthRad * 2.5
            let hL: Double = centerRad - haloHalf
            let hR: Double = centerRad + haloHalf

            var haloPath = Path()
            haloPath.move(to: origin)
            haloPath.addLine(to: CGPoint(x: origin.x + cos(hL) * maxReach, y: origin.y + sin(hL) * maxReach))
            haloPath.addLine(to: CGPoint(x: origin.x + cos(hR) * maxReach, y: origin.y + sin(hR) * maxReach))
            haloPath.closeSubpath()

            let haloOpacity = opacity * 0.35
            let haloGradient = Gradient(stops: [
                .init(color: color.opacity(haloOpacity), location: 0.0),
                .init(color: color.opacity(haloOpacity * 0.5), location: 0.25),
                .init(color: Color.clear, location: 0.55),
            ])

            var haloCtx = context
            haloCtx.addFilter(.blur(radius: 14))
            haloCtx.fill(haloPath, with: .linearGradient(haloGradient, startPoint: origin, endPoint: endPoint))
        }
    }
}

// MARK: - HSB Color Helper

private extension Color {
    init(h: Double, s: Double, b: Double) {
        self.init(hue: h / 360, saturation: s, brightness: b)
    }
}

#Preview {
    BackgroundView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
}
