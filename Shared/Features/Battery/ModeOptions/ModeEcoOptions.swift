import SwiftUI

enum PercentageField: Hashable {
    case minPercentage
    case morningPercentage
    case maxPercentage
    case none  // No field is specifically focused
}

struct ModeEcoOptions: View {
    var battery: Device

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var minPercentage: Double = 5
    @State var morningPercentage: Double = 80
    @State var maxPercentage: Double = 100

    @FocusState private var focusedField: PercentageField?

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Min.:")
                Spacer()
                Text("\(Int(minPercentage)) %")
                    .padding(2)
                    .foregroundColor(.purple)
                    .fontWeight(.bold)
                    .focusable()
                    .scaleEffect(
                        focusedField == .minPercentage ? 1.1 : 1.0
                    )  // Subtle scaling on focus
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: focusedField == .minPercentage
                    )  // Animate the scale
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                focusedField == .minPercentage
                                ? Color.purple : Color.clear,
                                lineWidth: 1
                            )  // Border on focus
                    )
                    .onTapGesture {
                        focusedField = .minPercentage
                    }
                    .digitalCrownRotation(
                        $minPercentage,
                        from: 5,
                        through: 100,
                        by: 5.0,
                        sensitivity: .low,
                        isHapticFeedbackEnabled: true
                    )
                    .focused($focusedField, equals: .minPercentage)
            }

            HStack {
                Text("Morning.:")
                Spacer()
                Text("\(Int(morningPercentage)) %")
                    .padding(2)
                    .foregroundColor(.purple)
                    .fontWeight(.bold)
                    .scaleEffect(
                        focusedField == .morningPercentage ? 1.1 : 1.0
                    )  // Subtle scaling on focus
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: focusedField == .morningPercentage
                    )  // Animate the scale
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                focusedField == .morningPercentage
                                ? Color.purple : Color.clear,
                                lineWidth: 1
                            )  // Border on focus
                    )
                    .onTapGesture {
                        focusedField = .morningPercentage
                    }
                    .focusable()
                    .digitalCrownRotation(
                        $morningPercentage,
                        from: 5,
                        through: 100,
                        by: 5.0,
                        sensitivity: .low,
                        isHapticFeedbackEnabled: true
                    )
                    .focused($focusedField, equals: .morningPercentage)
            }

            HStack {
                Text("Max.:")
                Spacer()
                Text("\(Int(maxPercentage)) %")
                    .padding(2)
                    .foregroundColor(.purple)
                    .fontWeight(.bold)
                    .scaleEffect(
                        focusedField == .maxPercentage ? 1.1 : 1.0
                    )  // Subtle scaling on focus
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: focusedField == .maxPercentage
                    )  // Animate the scale
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                focusedField == .maxPercentage
                                ? Color.purple : Color.clear,
                                lineWidth: 1
                            )  // Border on focus
                    )
                    .onTapGesture {
                        focusedField = .maxPercentage
                    }
                
                    .focusable()
                    .digitalCrownRotation(
                        $maxPercentage,
                        from: 5,
                        through: 100,
                        by: 5.0,
                        sensitivity: .low,
                        isHapticFeedbackEnabled: true
                    )
                    .focused($focusedField, equals: .maxPercentage)
            }

            Spacer()
        }
    }
}

#Preview {
    ModeEcoOptions(
        battery: .fakeBattery()
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .init(
                currentSolarProduction: 4550,
                currentOverallConsumption: 1200,
                currentBatteryLevel: 78,
                currentBatteryChargeRate: 3400,
                currentSolarToGrid: 10,
                currentGridToHouse: 0,
                currentSolarToHouse: 1200,
                solarProductionMax: 11000,
                hasConnectionError: false,
                lastUpdated: Date(),
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: false,
                chargingStations: [
                    .init(
                        id: "42",
                        name: "Keba",
                        chargingMode: ChargingMode.withSolarPower,
                        priority: 1,
                        currentPower: 0,
                        signal: SensorConnectionStatus.connected
                    )
                ],
                devices: [
                    Device.fakeBattery(currentPowerInWatts: 2390)
                ],
                todayAutarchyDegree: 78
            )
        )
    )
}
