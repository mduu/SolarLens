import SwiftUI

struct ChargingOptionsPopupView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    var chargingMode: ChargingMode
    var chargingStation: ChargingStation

    @Environment(\.dismiss) var dismiss

    @State var constantCurrent: Int = 6
    private let minConstantCurrent: Int = 6
    private let maxConstantCurrent: Int = 32

    @State var minQuantity: Int = 1
    @State var minQuantityDate: Date = Date()
    @State var minQuantityTime: Date = Date()
    @State var showMinCurrentDatePicker: Bool = false
    @State var showMinCurrentTimePicker: Bool = false
    private let minMinQuantity: Int = 1
    private let maxMinQuantity: Int = 100

    @State var targetSocPercent: Int = 5
    @State var targetSocDate: Date = Date()
    @State var targetSocTime: Date = Date()
    @State var showTargetSocDatePicker: Bool = false
    @State var showTargetSocTimePicker: Bool = false
    private let targetSocMinPercent: Int = 5
    private let targetSocMaxPercent: Int = 100

    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(
            year: calendar.component(.year, from: Date()),
            month: calendar.component(.month, from: Date()),
            day: calendar.component(.day, from: Date())
        )
        let endComponents = DateComponents(
            year: calendar.component(.year, from: Date()) + 1,
            month: 12,
            day: 31,
            hour: 23,
            minute: 59,
            second: 59
        )
        return calendar.date(from: startComponents)!...calendar.date(
            from: endComponents
        )!
    }()

    var body: some View {

        ZStack {

            switch chargingMode {
            case .constantCurrent: constantCurrentView
            case .minimumQuantity: minimumChargeQuantity
            case .chargingTargetSoc: targetSoc
            default:
                Text("Unknown charging mode")
                    .foregroundColor(.red)
            }

            if buildingState.isChangingCarCharger {
                HStack {
                    ProgressView()
                }.background(Color.black.opacity(0.8))
            }

        }
    }

    var constantCurrentView: some View {
        VStack {
            HStack {

                Button(action: {
                    constantCurrent -= 1
                    if constantCurrent < minConstantCurrent {
                        constantCurrent = minConstantCurrent
                    }
                }) {
                    Image(systemName: "minus")
                        .frame(height: 30)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
                .padding()

                Text("\(constantCurrent) A")

                Button(action: {
                    constantCurrent += 1
                    if constantCurrent > maxConstantCurrent {
                        constantCurrent = maxConstantCurrent
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(height: 30)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
                .padding()
            }

            Button(action: {
                Task {
                    await buildingState.setCarCharging(
                        sensorId: chargingStation.id,
                        newCarCharging: .init(
                            constantCurrent: constantCurrent
                        )
                    )
                    dismiss()
                }
            }) {
                Text("Set")
                    .frame(width: 140, height: 30)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.green)
            .tint(.green)
            .padding()
        }
    }

    var minimumChargeQuantity: some View {
        ScrollView {
            VStack {

                HStack {

                    Button(action: {
                        minQuantity = max(minMinQuantity, minQuantity - 1)
                    }) {
                        Image(systemName: "minus")
                            .frame(height: 30)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accent)
                    .padding()

                    Text("\(minQuantity) kWh")

                    Button(action: {
                        minQuantity = min(maxMinQuantity, minQuantity + 1)
                    }) {
                        Image(systemName: "plus")
                            .frame(height: 30)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accent)
                    .padding()
                }

                Button(action: {
                    showMinCurrentDatePicker = true
                }) {
                    VStack {
                        Text("Target date")
                            .font(.callout)
                        Text(
                            "\($minQuantityDate.wrappedValue.formatted(date: .numeric, time: .omitted))"
                        )
                    }
                    .frame(minWidth: 140)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
                .sheet(isPresented: $showMinCurrentDatePicker) {
                    DatePicker(
                        selection: $minQuantityDate,
                        in: dateRange,
                        displayedComponents: [.date]
                    ) {
                        Text("Select target date")
                    }
                    .datePickerStyle(.automatic)
                    .frame(minHeight: 130)
                }

                Button(action: {
                    showMinCurrentTimePicker = true
                }) {
                    VStack {
                        Text("Target time")
                            .font(.callout)
                        Text(
                            "\($minQuantityTime.wrappedValue.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                    .frame(minWidth: 140)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
                .sheet(isPresented: $showMinCurrentTimePicker) {
                    DatePicker(
                        selection: $minQuantityTime,
                        displayedComponents: [.hourAndMinute]
                    ) {
                        Text("Select target time")
                    }
                    .datePickerStyle(.automatic)
                    .frame(minHeight: 130)
                }

                Button(action: {
                    Task {
                        await buildingState.setCarCharging(
                            sensorId: chargingStation.id,
                            newCarCharging: .init(
                                minimumChargeQuantityTargetAmount: $minQuantity
                                    .wrappedValue,
                                targetTime: combineDateTime(
                                    date: $minQuantityDate.wrappedValue,
                                    time: $minQuantityTime.wrappedValue
                                ).convertLocalUiToUtc()
                            )
                        )
                        dismiss()
                    }
                }) {
                    Text("Set")
                        .frame(width: 140, height: 30)
                }
                .buttonStyle(.bordered)
                .tint(.green)

            }  // :VStack
            .frame(maxWidth: .infinity)

        }  // :ScrollView
        .frame(maxWidth: .infinity)
    }

    var targetSoc: some View {
        ScrollView {
            VStack {

                HStack {

                    Button(action: {
                        targetSocPercent = max(
                            targetSocMinPercent,
                            targetSocPercent - 5
                        )
                    }) {
                        Image(systemName: "minus")
                            .frame(height: 30)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accent)
                    .padding()

                    Text("\(targetSocPercent) %")

                    Button(action: {
                        targetSocPercent = min(
                            targetSocMaxPercent,
                            targetSocPercent + 5
                        )
                    }) {
                        Image(systemName: "plus")
                            .frame(height: 30)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accent)
                    .padding()
                }

                Button(action: {
                    showTargetSocDatePicker = true
                }) {
                    VStack {
                        Text("Target date")
                            .font(.callout)
                        Text(
                            "\($targetSocDate.wrappedValue.formatted(date: .numeric, time: .omitted))"
                        )
                    }
                    .frame(width: 140)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
                .sheet(isPresented: $showTargetSocDatePicker) {
                    DatePicker(
                        selection: $targetSocDate,
                        in: dateRange,
                        displayedComponents: [.date]
                    ) {
                        Text("Select target date")
                    }
                    .datePickerStyle(.automatic)
                    .frame(minHeight: 130)
                }

                Button(action: {
                    showTargetSocTimePicker = true
                }) {
                    VStack {
                        Text("Target time")
                            .font(.callout)
                        Text(
                            "\($targetSocTime.wrappedValue.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                    .frame(width: 140)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
                .sheet(isPresented: $showTargetSocTimePicker) {
                    DatePicker(
                        selection: $targetSocTime,
                        displayedComponents: [.hourAndMinute]
                    ) {
                        Text("Select target time")
                    }
                    .datePickerStyle(.automatic)
                    .frame(minHeight: 130)
                }

                Button(action: {
                    let socPercent = $targetSocPercent.wrappedValue
                    let targetTime = combineDateTime(
                        date: $targetSocDate.wrappedValue,
                        time: $targetSocTime.wrappedValue
                    )
                        .convertLocalUiToUtc()

                    Task {
                        await buildingState.setCarCharging(
                            sensorId: chargingStation.id,
                            newCarCharging: .init(
                                targetSocPercent: socPercent,
                                targetTime: targetTime
                            )
                        )
                        dismiss()
                    }
                }) {
                    Text("Set")
                        .frame(width: 140)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .frame(height: 40)
            }
        }
    }

    private func combineDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current

        let dateComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        let timeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: time
        )

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute

        let combinedDate = calendar.date(from: combinedComponents)
        return combinedDate ?? Date()
    }
}

#Preview("Constant Current") {
    ChargingOptionsPopupView(
        chargingMode: .constantCurrent,
        chargingStation: ChargingStation.init(
            id: "id-1",
            name: "Station #1",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        )
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .init(
                currentSolarProduction: 4500,
                currentOverallConsumption: 400,
                currentBatteryLevel: 99,
                currentBatteryChargeRate: 150,
                currentSolarToGrid: 3600,
                currentGridToHouse: 0,
                currentSolarToHouse: 400,
                solarProductionMax: 11000,
                hasConnectionError: false,
                lastUpdated: Date(),
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: true,
                chargingStations: [],
                devices: [],
                todayAutarchyDegree: 78
            )
        )
    )
}

#Preview("Min. Qty.") {
    ChargingOptionsPopupView(
        chargingMode: .minimumQuantity,
        chargingStation: ChargingStation.init(
            id: "id-1",
            name: "Station #1",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        )
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .init(
                currentSolarProduction: 4500,
                currentOverallConsumption: 400,
                currentBatteryLevel: 99,
                currentBatteryChargeRate: 150,
                currentSolarToGrid: 3600,
                currentGridToHouse: 0,
                currentSolarToHouse: 400,
                solarProductionMax: 11000,
                hasConnectionError: false,
                lastUpdated: Date(),
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: true,
                chargingStations: [],
                devices: [],
                todayAutarchyDegree: 78
            )
        )
    )
}

#Preview("SOC") {
    ChargingOptionsPopupView(
        chargingMode: .chargingTargetSoc,
        chargingStation: ChargingStation.init(
            id: "id-1",
            name: "Station #1",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        )
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .init(
                currentSolarProduction: 4500,
                currentOverallConsumption: 400,
                currentBatteryLevel: 99,
                currentBatteryChargeRate: 150,
                currentSolarToGrid: 3600,
                currentGridToHouse: 0,
                currentSolarToHouse: 400,
                solarProductionMax: 11000,
                hasConnectionError: false,
                lastUpdated: Date(),
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: true,
                chargingStations: [],
                devices: [],
                todayAutarchyDegree: 78
            )
        )
    )
}
