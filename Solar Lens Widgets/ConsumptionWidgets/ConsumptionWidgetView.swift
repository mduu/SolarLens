import SwiftUI

struct ConsumptionWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var entry: ConsumptionEntry

    var body: some View {

        switch family {
        case .accessoryCircular:
            ConsumptionCircularWidgetView(
                currentConsumption: entry.currentConsumption,
                carCharging: entry.carCharging,
                consumptionFromSolar: entry.consumptionFromSolar,
                consumptionFromBattery: entry.consumptionFromBattery,
                consumptionFromGrid: entry.consumptionFromGrid)

        case .accessoryCorner:
            ConsumptionCornerWidgetView(
                currentConsumption: entry.currentConsumption,
                carCharging: entry.carCharging,
                consumptionFromSolar: entry.consumptionFromSolar,
                consumptionFromBattery: entry.consumptionFromBattery,
                consumptionFromGrid: entry.consumptionFromGrid,
                isStaleData: entry.isStaleData)

        case .accessoryInline:
            if entry.carCharging ?? false {
                Image(systemName: "car.side")
                    .symbolEffect(
                        .pulse.wholeSymbol, options: .repeat(.continuous))
            } else {
                Image(systemName: "house")
            }
            Text("\(entry.currentConsumption ?? 0) W")

        case .accessoryRectangular:
            if entry.carCharging ?? false {
                Image(systemName: "car.side")
                    .symbolEffect(
                        .pulse.wholeSymbol, options: .repeat(.continuous))
            } else {
                Image(systemName: "house")
            }
            Text("\(entry.currentConsumption ?? 0) W")

        default:
            Image("AppIcon")
        }

    }
}

#Preview {
    ConsumptionWidgetView(
        entry: ConsumptionEntry(
            date: Date(),
            currentConsumption: 850,
            carCharging: true,
            consumptionFromSolar: 1100,
            consumptionFromBattery: 300,
            consumptionFromGrid: 100))
}
