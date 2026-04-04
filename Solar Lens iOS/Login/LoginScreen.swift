import SwiftUI

struct LoginScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState
    @Environment(\.colorScheme) var colorScheme

    @State var email: String = ""
    @State var password: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            LoginBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // App icon
                    Image("solarlens")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    // Title
                    Text(verbatim: "Solar Lens")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(h: 215, s: 0.40, b: 0.25))
                        .padding(.bottom, 8)

                    // Login form card
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Sign in with your Solar Manager account.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Grouped fields (Apple HIG style — stacked with divider)
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .password }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.leading, 44)

                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit { login() }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                        .background(
                            .background.opacity(colorScheme == .dark ? 0.3 : 0.6),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )

                        Button(action: login) {
                            Text("Login")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isValidLogin())
                    }
                    .padding(24)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)

                    // Error message
                    if model.didLoginSucceed == false {
                        VStack(spacing: 8) {
                            Label("Login failed!", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(
                                "Please make sure you are using the correct email and passwort from your Solar Manager login."
                            )
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color.red.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 30)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.didLoginSucceed)
    }

    private func login() {
        Task {
            await model.tryLogin(email: email, password: password)
        }
    }

    func isValidLogin() -> Bool {
        guard !isValidEmail() else { return false }
        guard !isValidPassword() else { return false }
        return true
    }

    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let valid = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            .evaluate(
                with: email)
        return valid
    }

    func isValidPassword() -> Bool {
        let valid = password.count > 4
        return valid
    }
}

// MARK: - Login Background

private struct LoginBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if #available(iOS 18.0, *) {
                    meshBackground()
                } else {
                    legacyGradient()
                }

                // Background image overlay
                Image("bg_neon_solar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(colorScheme == .dark ? 0.20 : 0.30)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)

                // Sun ray effect matching home screen
                LoginGodRaysView(colorScheme: colorScheme)
            }
        }
        .ignoresSafeArea(.all)
    }

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

    @ViewBuilder
    private func legacyGradient() -> some View {
        if colorScheme == .dark {
            LinearGradient(colors: [Color(hex6: 0x0A1628), Color(hex6: 0x0D0D0D)], startPoint: .top, endPoint: .bottom)
        } else {
            LinearGradient(colors: [Color(hex6: 0xCDD4DE), Color(hex6: 0xE8EBF0)], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Login God Rays (full sun ray effect matching home screen)

private struct LoginGodRaysView: View {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }
    private let rayColor = Color.white

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let origin = CGPoint(x: -size.width * 0.05, y: -size.height * 0.04)
                let reach = size.height * 1.0

                drawDiffuseGlow(context: context, origin: origin, size: size)
                drawRays(context: context, origin: origin, maxReach: reach, time: elapsed)
                drawBonusRays(context: context, origin: origin, maxReach: reach, time: elapsed)
                drawSourceGlow(context: context, origin: origin, radius: size.width * 0.45)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bright Source

    private func drawSourceGlow(context: GraphicsContext, origin: CGPoint, radius: Double) {
        let o = isDark ? 0.55 : 1.0

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
        let o = isDark ? 0.20 : 0.45
        let radius = max(size.width, size.height) * 0.85

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

    private func drawRays(context: GraphicsContext, origin: CGPoint, maxReach: Double, time: Double) {
        drawRaySet(rayDefs, context: context, origin: origin, maxReach: maxReach, time: time, opacityScale: 1.0)
    }

    private func drawBonusRays(context: GraphicsContext, origin: CGPoint, maxReach: Double, time: Double) {
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
        let drift = time / 20.0 * .pi * 2
        let baseOpacity = (isDark ? 0.45 : 0.90) * opacityScale

        for (index, ray) in defs.enumerated() {
            let seed = Double(index) * 2.3 + 0.7
            let shimmer = sin(drift + seed * 1.3) * 2.0
            let pulse = 0.85 + sin(drift * 0.7 + seed * 2.1) * 0.15

            let centerDeg = ray.angle + shimmer
            let centerRad = centerDeg * .pi / 180.0
            let halfWidthRad = (ray.width / 2.0) * .pi / 180.0

            let leftRad = centerRad - halfWidthRad
            let rightRad = centerRad + halfWidthRad

            let endPoint = CGPoint(
                x: origin.x + cos(centerRad) * maxReach,
                y: origin.y + sin(centerRad) * maxReach
            )

            let opacity = baseOpacity * ray.opacity * pulse

            // Core ray beam
            var corePath = Path()
            corePath.move(to: origin)
            corePath.addLine(to: CGPoint(x: origin.x + cos(leftRad) * maxReach, y: origin.y + sin(leftRad) * maxReach))
            corePath.addLine(to: CGPoint(x: origin.x + cos(rightRad) * maxReach, y: origin.y + sin(rightRad) * maxReach))
            corePath.closeSubpath()

            let coreGradient = Gradient(stops: [
                .init(color: Color.white.opacity(opacity), location: 0.0),
                .init(color: rayColor.opacity(opacity * 0.85), location: 0.12),
                .init(color: rayColor.opacity(opacity * 0.45), location: 0.35),
                .init(color: rayColor.opacity(opacity * 0.10), location: 0.65),
                .init(color: Color.clear, location: 0.90),
            ])

            var coreCtx = context
            coreCtx.addFilter(.blur(radius: 4))
            coreCtx.fill(corePath, with: .linearGradient(coreGradient, startPoint: origin, endPoint: endPoint))

            // Soft glow halo around each ray
            let haloHalf = halfWidthRad * 2.5
            let hL = centerRad - haloHalf
            let hR = centerRad + haloHalf

            var haloPath = Path()
            haloPath.move(to: origin)
            haloPath.addLine(to: CGPoint(x: origin.x + cos(hL) * maxReach, y: origin.y + sin(hL) * maxReach))
            haloPath.addLine(to: CGPoint(x: origin.x + cos(hR) * maxReach, y: origin.y + sin(hR) * maxReach))
            haloPath.closeSubpath()

            let haloOpacity = opacity * 0.35
            let haloGradient = Gradient(stops: [
                .init(color: rayColor.opacity(haloOpacity), location: 0.0),
                .init(color: rayColor.opacity(haloOpacity * 0.5), location: 0.25),
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

#Preview("English") {
    LoginScreen()
        .environment(CurrentBuildingState.fake())
}

#Preview("Failed") {
    LoginScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .fake(),
                loggedIn: false,
                isLoading: false,
                didLoginSucceed: false
            )
        )
}

#Preview("German") {
    LoginScreen()
        .environment(CurrentBuildingState())
        .environment(\.locale, Locale(identifier: "DE"))
}

#Preview("French") {
    LoginScreen()
        .environment(CurrentBuildingState())
        .environment(\.locale, Locale(identifier: "FR"))
}

#Preview("Italian") {
    LoginScreen()
        .environment(CurrentBuildingState())
        .environment(\.locale, Locale(identifier: "IT"))
}
