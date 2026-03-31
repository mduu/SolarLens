import SwiftUI

struct StatisticsEnergyCards: View {
    let statistics: Statistics
    var batteryCharged: Double = 0
    var batteryDischarged: Double = 0
    var carCharged: Double = 0
    var isCurrentlyCharging: Bool = false
    var hasBattery: Bool = false
    var hasCarChargingStation: Bool = false

    private var consumption: Double { statistics.consumption ?? 0 }
    private var production: Double { statistics.production ?? 0 }
    private var selfConsumption: Double { statistics.selfConsumption ?? 0 }
    private var gridImport: Double { max(0, consumption - selfConsumption) }
    private var gridExport: Double { max(0, production - selfConsumption) }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            EnergyCard(
                icon: "sun.max.fill",
                iconColor: .orange,
                label: "Production",
                value: production.formatWattHoursAdaptive(withUnit: true),
                detail: selfConsumptionDetail
            )

            EnergyCard(
                icon: "network",
                iconColor: .purple,
                label: "Grid",
                value: gridImport.formatWattHoursAdaptive(withUnit: true),
                detail: gridExportDetail
            )

            if hasBattery {
                EnergyCard(
                    icon: "battery.100",
                    iconColor: .green,
                    label: "Battery",
                    value: batteryCharged.formatWattHoursAdaptive(withUnit: true),
                    detail: batteryDischargedDetail
                )
            }

            // Car charging moves to battery slot when no battery present
            if !hasBattery && hasCarChargingStation {
                EnergyCard(
                    icon: "ev.charger",
                    iconColor: .green,
                    label: "Car Charging",
                    value: carCharged.formatWattHoursAdaptive(withUnit: true)
                )
            }

            EnergyCard(
                icon: "house.fill",
                iconColor: .teal,
                label: "Consumption",
                value: consumption.formatWattHoursAdaptive(withUnit: true),
                detail: autarkyDetail
            )

            // Car charging in its own row when battery is present
            if hasBattery && hasCarChargingStation {
                Color.clear
                    .cardStyle()
                    .hidden()

                EnergyCard(
                    icon: "ev.charger",
                    iconColor: .green,
                    label: "Car Charging",
                    value: carCharged.formatWattHoursAdaptive(withUnit: true)
                )
            }
        }
        .padding(.horizontal)
    }

    private var selfConsumptionDetail: String? {
        guard let rate = statistics.selfConsumptionRate else { return nil }
        return "\(String(format: "%.0f", rate))% self-consumed"
    }

    private var gridExportDetail: String {
        "\(gridExport.formatWattHoursAdaptive(withUnit: true)) exported"
    }

    private var batteryDischargedDetail: String {
        "\(batteryDischarged.formatWattHoursAdaptive(withUnit: true)) discharged"
    }

    private var autarkyDetail: String? {
        guard let autarky = statistics.autarchyDegree else { return nil }
        return "\(String(format: "%.0f", autarky))% Autarky"
    }
}

#Preview("With Battery") {
    StatisticsEnergyCards(
        statistics: Statistics(
            consumption: 450_000,
            production: 620_000,
            selfConsumption: 320_000,
            selfConsumptionRate: 51.6,
            autarchyDegree: 71.1
        ),
        batteryCharged: 125_000,
        batteryDischarged: 83_000,
        carCharged: 45_000,
        hasBattery: true,
        hasCarChargingStation: true
    )
}

#Preview("No Battery") {
    StatisticsEnergyCards(
        statistics: Statistics(
            consumption: 450_000,
            production: 620_000,
            selfConsumption: 320_000,
            selfConsumptionRate: 51.6,
            autarchyDegree: 71.1
        ),
        hasBattery: false,
        hasCarChargingStation: false
    )
}
