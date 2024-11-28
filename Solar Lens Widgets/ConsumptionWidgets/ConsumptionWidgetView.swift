import SwiftUI

struct ConsumptionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var entry: ConsumptionEntry

    var body: some View {

        switch family {
        case .accessoryCircular:
            ConsumptionCircularWidgetView(
                currentConsumption: entry.currentConsumption,
                carCharging: entry.carCharging)

        case .accessoryCorner:
            ConsumptionCornerWidgetView(
                currentConsumption: entry.currentConsumption,
                carCharging: entry.carCharging)

        case .accessoryInline:
            if entry.carCharging ?? false {
                Image(systemName: "car.side")
                    .symbolEffect(
                        .pulse.wholeSymbol, options: .repeat(.continuous))
            } else {
                Image(systemName: "house")
            }
            Text("\(entry.currentConsumption ?? 0) W")
                .foregroundColor(
                    renderingMode == .fullColor ? .green : .primary)

        case .accessoryRectangular:
            if entry.carCharging ?? false {
                Image(systemName: "car.side")
                    .symbolEffect(
                        .pulse.wholeSymbol, options: .repeat(.continuous))
            } else {
                Image(systemName: "house")
            }
            Text("\(entry.currentConsumption ?? 0) W")
                .foregroundColor(
                    renderingMode == .fullColor ? .green : .primary)

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
            carCharging: true))
}
