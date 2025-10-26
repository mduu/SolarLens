import Charts
import SwiftUI

struct SelfConsumptionSourcePieChart: View {
    var productionTodayInWatts: Double?
    var todayGridExported: Double?

    let selfConsumptionColor: Color = .indigo
    let gridColor: Color = .purple

    struct EnergyData: Identifiable {
        let id = UUID()
        let type: String  // "SelfConsumption" or "Grid"
        let kwh: Double
    }

    var body: some View {
        let todaySelfConsumption = (productionTodayInWatts ?? 0) - (todayGridExported ?? 0)
        let todayToGrid = todayGridExported ?? 0
        let energyConsumption: [EnergyData] = [
            EnergyData(type: "Exported", kwh: todayToGrid),
            EnergyData(type: "Self consumption", kwh: todaySelfConsumption),
        ]
        let todayTotal = todaySelfConsumption + todayToGrid

        ZStack {

            VStack {

                HStack {
                    Text("Self consumption")
                        .foregroundColor(selfConsumptionColor)
                        .font(.system(size: 24))

                    Spacer()

                    Text("Exported")
                        .foregroundColor(gridColor)
                        .font(.system(size: 24))
                }

                HStack {
                    Text(todaySelfConsumption.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.footnote)

                    Spacer()

                    Text(todayToGrid.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.footnote)
                }
            }

            Chart {

                if todayTotal == 0
                {

                    SectorMark(
                        angle: .value("kWh", 100),
                        innerRadius: 40,
                        outerRadius: 50,
                        angularInset: 15
                    )
                    .cornerRadius(10)
                    .foregroundStyle(.white.opacity(0.1))


                } else {

                    ForEach(energyConsumption) { data in
                        SectorMark(
                            angle: .value("kWh", data.kwh),
                            innerRadius: 40,
                            outerRadius: 50,
                            angularInset: 15
                        )
                        .cornerRadius(10)
                        .foregroundStyle(by: .value("Source", data.type))
                    }

                }
            }
            .aspectRatio(1, contentMode: .fit)
            .chartForegroundStyleScale([
                "Self consumption": selfConsumptionColor,
                "Exported": gridColor,
            ])
            .chartLegend(.hidden)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]

                        VStack {
                            Text("\(todayTotal.formatWattHoursAsKiloWattsHours(widthUnit: false))")
                                .font(.footnote)
                        }  // :VStack
                        .position(x: frame.midX, y: frame.midY)

                    }
                }
            }
        }
        .frame(maxHeight: 100)
    }
}

#Preview {
    VStack {
        HStack {

            SelfConsumptionSourcePieChart(
                productionTodayInWatts: 15000,
                todayGridExported: 2413
            )
            .frame(maxWidth: 600, maxHeight: 200)

            Spacer()
        }

        Spacer()
    }
}

#Preview("No prod.") {
    VStack {
        HStack {

            SelfConsumptionSourcePieChart(
                productionTodayInWatts: 0,
                todayGridExported: 0
            )
            .frame(maxWidth: 600, maxHeight: 200)

            Spacer()
        }

        Spacer()
    }
}
