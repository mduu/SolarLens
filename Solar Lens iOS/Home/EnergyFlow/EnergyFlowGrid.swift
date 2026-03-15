import SwiftUI

struct EnergyFlowGrid: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
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
                GridBoubleView(
                    gridInKwh: gridValue,
                    todayGridImportInWh: data.todayGridImported
                )
                .frame(maxHeight: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)

            // Bottom row
            HStack(spacing: hGap) {
                BatteryBoubleView(
                    currentBatteryLevel: data.currentBatteryLevel,
                    currentChargeRate: data.currentBatteryChargeRate
                )
                .frame(maxHeight: .infinity)
                ConsumptionBoubleView(
                    currentConsumptionInKwh: consumption,
                    todayConsumptionInWh: data.todayConsumption
                )
                .frame(maxHeight: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .overlay {
            GeometryReader { geo in
                flowLines(data: data, in: geo.size)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Flow Lines

    @ViewBuilder
    private func flowLines(data: OverviewData, in size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        let cardW = (w - hGap) / 2
        let cardH = (h - vGap) / 2

        let solarCenterX = cardW / 2
        let gridCenterX = cardW + hGap + cardW / 2
        let topCenterY = cardH / 2
        let bottomCenterY = cardH + vGap + cardH / 2

        let topRowBottom = cardH
        let bottomRowTop = cardH + vGap
        let leftCardRight = cardW
        let rightCardLeft = cardW + hGap

        // Solar → Grid (horizontal) — orange-red
        if data.isFlowSolarToGrid() {
            FlowArrow(
                color: Color(red: 1.0, green: 0.4, blue: 0.1),
                power: Double(data.currentSolarToGrid) / 1000,
                from: CGPoint(x: leftCardRight, y: topCenterY),
                to: CGPoint(x: rightCardLeft, y: topCenterY)
            )
        }

        // Solar → Battery (vertical, left) — green
        if data.isFlowSolarToBattery() {
            FlowArrow(
                color: .green,
                power: Double(data.currentBatteryChargeRate ?? 0) / 1000,
                from: CGPoint(x: solarCenterX, y: topRowBottom),
                to: CGPoint(x: solarCenterX, y: bottomRowTop)
            )
        }

        // Grid → House (vertical, right) — orange
        if data.isFlowGridToHouse() {
            FlowArrow(
                color: .orange,
                power: Double(data.currentGridToHouse) / 1000,
                from: CGPoint(x: gridCenterX, y: topRowBottom),
                to: CGPoint(x: gridCenterX, y: bottomRowTop)
            )
        }

        // Battery → House (horizontal, bottom) — green
        if data.isFlowBatteryToHome() {
            FlowArrow(
                color: .green,
                power: abs(Double(data.currentBatteryChargeRate ?? 0)) / 1000,
                from: CGPoint(x: leftCardRight, y: bottomCenterY),
                to: CGPoint(x: rightCardLeft, y: bottomCenterY)
            )
        }

        // Solar → House (diagonal) — green
        if data.isFlowSolarToHouse() {
            FlowArrow(
                color: .green,
                power: Double(data.currentSolarToHouse) / 1000,
                from: CGPoint(x: leftCardRight, y: topRowBottom),
                to: CGPoint(x: rightCardLeft, y: bottomRowTop)
            )
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
