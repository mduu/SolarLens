import SwiftUI

/// Preference key that collects named card anchors for flow line positioning.
private struct CardAnchorsKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

private extension View {
    func cardAnchor(_ name: String) -> some View {
        anchorPreference(key: CardAnchorsKey.self, value: .bounds) { [name: $0] }
    }
}

struct EnergyFlowGrid: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @StateObject private var pinnedConfig = PinnedDevicesConfiguration()
    var showCharging: Bool = false
    private let hGap: CGFloat = 40
    private let vGap: CGFloat = 60

    var body: some View {
        let data = buildingState.overviewData
        let solar = Double(data.currentSolarProduction) / 1000
        let consumption = Double(data.currentOverallConsumption) / 1000
        let gridValue = Double(
            data.isFlowGridToHouse()
                ? data.currentGridToHouse
                : data.currentSolarToGrid
        ) / 1000
        VStack(spacing: vGap) {
            // Top row
            HStack(spacing: hGap) {
                SolarBoubleView(
                    currentSolarProductionInKwh: solar,
                    todaySolarProductionInWh: data.todayProduction
                )
                .frame(maxHeight: .infinity)
                .cardAnchor("solar")
                GridBoubleView(
                    gridInKwh: gridValue,
                    todayGridImportInWh: data.todayGridImported
                )
                .frame(maxHeight: .infinity)
                .cardAnchor("grid")
            }
            .fixedSize(horizontal: false, vertical: true)

            // Bottom row — top-aligned so battery card stays
            // at the same height as consumption, even when charging
            // stations make the right column taller.
            HStack(alignment: .top, spacing: hGap) {
                BatteryBoubleView(
                    currentBatteryLevel: data.currentBatteryLevel,
                    currentChargeRate: data.currentBatteryChargeRate,
                    batteryForecast: data.getBatteryForecast()
                )
                .cardAnchor("battery")

                // Consumption card — combined with charging and/or pinned devices when present
                let hasCharging = showCharging && !data.chargingStations.isEmpty
                let hasPinned = !pinnedDevices(from: data).isEmpty

                if hasCharging || hasPinned {
                    VStack(spacing: 0) {
                        ConsumptionBoubleView(
                            currentConsumptionInKwh: consumption,
                            todayConsumptionInWh: data.todayConsumption,
                            applyCardStyle: false,
                            pinnedConfig: pinnedConfig
                        )

                        if hasCharging {
                            Divider()
                                .padding(.vertical, 8)

                            ChargingView(isVertical: true, applyCardStyle: false)
                        }

                        if hasPinned {
                            Divider()
                                .padding(.vertical, 8)

                            PinnedDevicesView(pinnedConfig: pinnedConfig)
                        }
                    }
                    .cardStyle()
                    .cardAnchor("consumption")
                } else {
                    ConsumptionBoubleView(
                        currentConsumptionInKwh: consumption,
                        todayConsumptionInWh: data.todayConsumption,
                        pinnedConfig: pinnedConfig
                    )
                    .cardAnchor("consumption")
                }
            }
        }
        .overlayPreferenceValue(CardAnchorsKey.self) { anchors in
            GeometryReader { proxy in
                flowLines(data: data, anchors: anchors, proxy: proxy)
            }
            .allowsHitTesting(false)
        }
    }

    private func pinnedDevices(from data: OverviewData) -> [Device] {
        data.devices.filter { device in
            device.deviceType != .battery
                && device.deviceType != .carCharging
                && pinnedConfig.isPinned(deviceId: device.id)
        }
    }

    // MARK: - Flow Lines

    @ViewBuilder
    private func flowLines(
        data: OverviewData,
        anchors: [String: Anchor<CGRect>],
        proxy: GeometryProxy
    ) -> some View {
        // Resolve actual card positions within the overlay coordinate space
        if let solarRect = anchors["solar"].map({ proxy[$0] }),
           let gridRect = anchors["grid"].map({ proxy[$0] }),
           let batteryRect = anchors["battery"].map({ proxy[$0] }),
           let consumptionRect = anchors["consumption"].map({ proxy[$0] })
        {
            let solarCenter = CGPoint(x: solarRect.midX, y: solarRect.midY)
            let gridCenter = CGPoint(x: gridRect.midX, y: gridRect.midY)
            let batteryCenter = CGPoint(x: batteryRect.midX, y: batteryRect.midY)
            let consumptionCenter = CGPoint(x: consumptionRect.midX, y: consumptionRect.midY)

            // Edge points for arrows between cards
            let solarBottom = CGPoint(x: solarRect.midX, y: solarRect.maxY)
            let gridBottom = CGPoint(x: gridRect.midX, y: gridRect.maxY)
            let batteryTop = CGPoint(x: batteryRect.midX, y: batteryRect.minY)
            let consumptionTop = CGPoint(x: consumptionRect.midX, y: consumptionRect.minY)

            // Solar → Grid (horizontal) — orange-red
            if data.isFlowSolarToGrid() {
                FlowArrow(
                    color: Color(red: 1.0, green: 0.4, blue: 0.1),
                    power: Double(data.currentSolarToGrid) / 1000,
                    from: CGPoint(x: solarRect.maxX, y: solarCenter.y),
                    to: CGPoint(x: gridRect.minX, y: gridCenter.y)
                )
            }

            // Solar → Battery (vertical, left) — green
            if data.isFlowSolarToBattery() {
                FlowArrow(
                    color: .green,
                    power: Double(data.currentBatteryChargeRate ?? 0) / 1000,
                    from: solarBottom,
                    to: batteryTop
                )
            }

            // Grid → House (vertical, right) — orange
            if data.isFlowGridToHouse() {
                FlowArrow(
                    color: .orange,
                    power: Double(data.currentGridToHouse) / 1000,
                    from: gridBottom,
                    to: consumptionTop
                )
            }

            // Battery → House (horizontal, bottom) — green
            if data.isFlowBatteryToHome() {
                FlowArrow(
                    color: .green,
                    power: abs(Double(data.currentBatteryChargeRate ?? 0)) / 1000,
                    from: CGPoint(x: batteryRect.maxX, y: batteryCenter.y),
                    to: CGPoint(x: consumptionRect.minX, y: batteryCenter.y)
                )
            }

            // Solar → House (diagonal) — green
            if data.isFlowSolarToHouse() {
                FlowArrow(
                    color: .green,
                    power: Double(data.currentSolarToHouse) / 1000,
                    from: CGPoint(x: solarRect.maxX, y: solarRect.maxY),
                    to: CGPoint(x: consumptionRect.minX, y: consumptionTop.y)
                )
            }
        }
    }
}

// MARK: - Previews with different warmth levels

#Preview("High Production (warm)") {
    EnergyFlowGrid()
        .padding()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
        .background {
            LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.82), Color(red: 0.95, green: 0.94, blue: 0.92)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
}

#Preview("Low Production (medium)") {
    EnergyFlowGrid()
        .padding()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 1200,
                    currentOverallConsumption: 900,
                    currentBatteryLevel: 45,
                    currentBatteryChargeRate: 300,
                    currentSolarToGrid: 0,
                    currentGridToHouse: 0,
                    currentSolarToHouse: 900,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    lastSuccessServerFetch: Date(),
                    isAnyCarCharing: false,
                    chargingStations: [],
                    devices: [],
                    todayAutarchyDegree: 65
                )
            )
        )
        .background {
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.90), Color(red: 0.95, green: 0.94, blue: 0.93)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
}

#Preview("Night (cool)") {
    EnergyFlowGrid()
        .padding()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 0,
                    currentOverallConsumption: 900,
                    currentBatteryLevel: 6,
                    currentBatteryChargeRate: 0,
                    currentSolarToGrid: 0,
                    currentGridToHouse: 900,
                    currentSolarToHouse: 0,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    lastSuccessServerFetch: Date(),
                    isAnyCarCharing: false,
                    chargingStations: [],
                    devices: [],
                    todayAutarchyDegree: 15
                )
            )
        )
        .background {
            LinearGradient(colors: [Color(red: 0.93, green: 0.94, blue: 0.96), Color(red: 0.95, green: 0.95, blue: 0.95)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
}
