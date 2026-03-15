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
                // Layer 1: MeshGradient (iOS 18+)
                if #available(iOS 18.0, *) {
                    meshBackground(production: production, gridImport: gridImport)
                } else {
                    legacyGradient(production: production, gridImport: gridImport)
                }

                // Layer 2: Faint image overlay — clipped to bounds
                Image("bg_neon_solar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(colorScheme == .dark ? 0.12 : 0.15)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 2), value: production)
        .animation(.easeInOut(duration: 2), value: gridImport)
    }

    // MARK: - MeshGradient (iOS 18+)

    @available(iOS 18.0, *)
    @ViewBuilder
    private func meshBackground(production: Int, gridImport: Int) -> some View {
        let colors = meshColors(production: production, gridImport: gridImport)
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: colors
        )
    }

    private func meshColors(production: Int, gridImport: Int) -> [Color] {
        if colorScheme == .dark {
            return darkMeshColors(production: production, gridImport: gridImport)
        } else {
            return lightMeshColors(production: production, gridImport: gridImport)
        }
    }

    // Neutral bottom colors that match card backgrounds (#EAEEF3 ≈ h:215 s:0.04 b:0.95)
    private let neutralBottom: [Color] = [
        Color(h: 220, s: 0.03, b: 0.95), Color(h: 215, s: 0.02, b: 0.96), Color(h: 220, s: 0.03, b: 0.95),
    ]

    private func lightMeshColors(production: Int, gridImport: Int) -> [Color] {
        // Warmth concentrated in top row, fades to card-matching neutral at bottom
        if gridImport > production && production > 0 {
            // Grid importing — subtle warm-orange top only
            return [
                Color(h: 25, s: 0.18, b: 1.0),  Color(h: 30, s: 0.14, b: 1.0),  Color(h: 20, s: 0.15, b: 0.98),
                Color(h: 25, s: 0.05, b: 0.97),  Color(h: 30, s: 0.03, b: 0.97), Color(h: 25, s: 0.04, b: 0.96),
            ] + neutralBottom
        } else if production > 3000 {
            // High production — warm gold top, neutral bottom
            return [
                Color(h: 42, s: 0.30, b: 1.0),  Color(h: 45, s: 0.25, b: 1.0),  Color(h: 38, s: 0.28, b: 1.0),
                Color(h: 45, s: 0.08, b: 0.98),  Color(h: 48, s: 0.05, b: 0.97), Color(h: 42, s: 0.06, b: 0.97),
            ] + neutralBottom
        } else if production > 0 {
            // Low production — light warm top, neutral bottom
            return [
                Color(h: 45, s: 0.15, b: 1.0),  Color(h: 48, s: 0.10, b: 1.0),  Color(h: 42, s: 0.12, b: 1.0),
                Color(h: 48, s: 0.04, b: 0.97),  Color(h: 50, s: 0.03, b: 0.97), Color(h: 45, s: 0.03, b: 0.96),
            ] + neutralBottom
        } else {
            // Night — cool blue top, neutral bottom
            return [
                Color(h: 215, s: 0.15, b: 0.96), Color(h: 220, s: 0.12, b: 0.97), Color(h: 210, s: 0.14, b: 0.96),
                Color(h: 220, s: 0.06, b: 0.96), Color(h: 225, s: 0.04, b: 0.96), Color(h: 215, s: 0.05, b: 0.96),
            ] + neutralBottom
        }
    }

    // Dark neutral bottom matching card background (#2A2D32 ≈ h:215 s:0.10 b:0.20)
    private let darkNeutralBottom: [Color] = [
        Color(h: 220, s: 0.08, b: 0.13), Color(h: 215, s: 0.06, b: 0.12), Color(h: 220, s: 0.08, b: 0.13),
    ]

    private func darkMeshColors(production: Int, gridImport: Int) -> [Color] {
        if gridImport > production && production > 0 {
            return [
                Color(h: 25, s: 0.35, b: 0.14), Color(h: 20, s: 0.30, b: 0.12), Color(h: 30, s: 0.25, b: 0.13),
                Color(h: 20, s: 0.10, b: 0.10), Color(h: 25, s: 0.08, b: 0.09), Color(h: 20, s: 0.08, b: 0.10),
            ] + darkNeutralBottom
        } else if production > 3000 {
            return [
                Color(h: 42, s: 0.40, b: 0.16), Color(h: 45, s: 0.35, b: 0.14), Color(h: 38, s: 0.35, b: 0.15),
                Color(h: 45, s: 0.12, b: 0.11), Color(h: 48, s: 0.08, b: 0.10), Color(h: 42, s: 0.10, b: 0.11),
            ] + darkNeutralBottom
        } else if production > 0 {
            return [
                Color(h: 42, s: 0.25, b: 0.12), Color(h: 45, s: 0.18, b: 0.11), Color(h: 40, s: 0.20, b: 0.12),
                Color(h: 45, s: 0.08, b: 0.09), Color(h: 48, s: 0.05, b: 0.08), Color(h: 42, s: 0.06, b: 0.09),
            ] + darkNeutralBottom
        } else {
            return [
                Color(h: 215, s: 0.45, b: 0.14), Color(h: 220, s: 0.40, b: 0.12), Color(h: 210, s: 0.40, b: 0.13),
                Color(h: 220, s: 0.15, b: 0.09), Color(h: 225, s: 0.10, b: 0.08), Color(h: 215, s: 0.12, b: 0.09),
            ] + darkNeutralBottom
        }
    }

    // MARK: - Legacy Gradient (< iOS 18)

    @ViewBuilder
    private func legacyGradient(production: Int, gridImport: Int) -> some View {
        let colors = legacyColors(production: production, gridImport: gridImport)
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private func legacyColors(production: Int, gridImport: Int) -> [Color] {
        if colorScheme == .dark {
            let bottom = Color(hex6: 0x0D0D0D)
            if gridImport > production && production > 0 {
                return [Color(hex6: 0x1A0E08), bottom]
            } else if production > 3000 {
                return [Color(hex6: 0x1A1408), bottom]
            } else if production > 0 {
                return [Color(hex6: 0x12100A), bottom]
            } else {
                return [Color(hex6: 0x0A1628), bottom]
            }
        } else {
            if gridImport > production && production > 0 {
                return [Color(hex6: 0xFFF0E6), .white]
            } else if production > 3000 {
                return [Color(hex6: 0xFFF3D4), .white]
            } else if production > 0 {
                return [Color(hex6: 0xFFF8F0), .white]
            } else {
                return [Color(hex6: 0xF0F2F5), .white]
            }
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
