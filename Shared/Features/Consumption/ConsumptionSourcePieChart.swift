import Charts
import SwiftUI

struct ConsumptionSourcePieChart: View {
    var consumptionTodayInWatts: Double?
    var todayGridImported: Double?

    let solarColor: Color = .yellow.lighten(0.95)
    let gridColor: Color = .orange.lighten()

    struct EnergyData: Identifiable {
        let id = UUID()
        let type: String  // "Solar" or "Grid"
        let kwh: Double
    }

    var body: some View {
        let todayFromSolar = (consumptionTodayInWatts ?? 0) - (todayGridImported ?? 0)
        let todayFromGrid = todayGridImported ?? 0
        let energyConsumption: [EnergyData] = [
            EnergyData(type: "Grid", kwh: todayFromGrid),
            EnergyData(type: "Solar", kwh: todayFromSolar),
        ]

        ZStack {

            VStack {

                HStack {
                    Text("Solar")
                        .foregroundColor(solarColor)

                    Spacer()

                    Text("Grid")
                        .foregroundColor(gridColor)
                }

                HStack {
                    Text(todayFromSolar.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.footnote)

                    Spacer()

                    Text(todayFromGrid.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.footnote)
                }
            }


            Chart {

                ForEach(energyConsumption) { data in
                    SectorMark(
                        angle: .value("kWh", data.kwh),
                        innerRadius: 35,
                        outerRadius: 50,
                        angularInset: 15
                    )
                    .foregroundStyle(by: .value("Source", data.type))
                }

            }
            .aspectRatio(1, contentMode: .fit)
            .chartForegroundStyleScale([
                "Solar": solarColor,
                "Grid": gridColor,
            ])
            .chartLegend(.hidden)
        }
        .frame(maxHeight: 100)
    }
}

#Preview {
    VStack {
        HStack {

            ConsumptionSourcePieChart(
                consumptionTodayInWatts: 15000,
                todayGridImported: 2413
            )
            .frame(maxWidth: 400, maxHeight: 200)

            Spacer()
        }

        Spacer()
    }
}
