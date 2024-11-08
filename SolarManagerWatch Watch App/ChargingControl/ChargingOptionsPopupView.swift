//
//  ChargingOptionsPopupView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 02.11.2024.
//

import SwiftUI

struct ChargingOptionsPopupView: View {
    @EnvironmentObject var model: BuildingStateViewModel
    @Binding var chargingMode: ChargingMode
    @Binding var chargingStation: ChargingStation

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

    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(
            year: calendar.component(.year, from: Date()),
            month: calendar.component(.month, from: Date()),
            day: calendar.component(.day, from: Date()))
        let endComponents = DateComponents(
            year: calendar.component(.year, from: Date()) + 1,
            month: 12,
            day: 31,
            hour: 23,
            minute: 59,
            second: 59)
        return calendar.date(from: startComponents)!...calendar.date(
            from: endComponents)!
    }()

    var body: some View {

        ZStack {

            switch chargingMode {
            case .constantCurrent: constantCurrentView
            case .minimumQuantity: minimumChargeQuantity
            default:
                Text("Unknown charging mode")
                    .foregroundColor(.red)
            }

            if model.isChangingCarCharger {
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
                }
                .buttonStyle(.bordered)
                .foregroundColor(.accent)
                .padding()

                Text("\(constantCurrent) A")

                Button(action: {
                    constantCurrent += 1
                    if constantCurrent > maxConstantCurrent {
                        constantCurrent = maxConstantCurrent
                    }
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.accent)
                .padding()
            }

            Button(action: {
                Task {
                    await model.setCarCharging(
                        sensorId: chargingStation.id,
                        newCarCharging: .init(
                            constantCurrent: constantCurrent))
                    dismiss()
                }
            }) {
                Text("Set")
            }
            .buttonStyle(.bordered)
            .foregroundColor(.green)
            .padding()
        }
    }

    var minimumChargeQuantity: some View {
        ScrollView {
            VStack {

                HStack {

                    Button(action: {
                        minQuantity -= 1
                        if minQuantity < minMinQuantity {
                            minQuantity = minMinQuantity
                        }
                    }) {
                        Image(systemName: "minus")
                    }
                    .buttonBorderShape(.circle)
                    .foregroundColor(.accent)
                    .padding()

                    Text("\(minQuantity) kWh")

                    Button(action: {
                        minQuantity += 1
                        if minQuantity > maxMinQuantity {
                            minQuantity = maxMinQuantity
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonBorderShape(.circle)
                    .foregroundColor(.accent)
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
                }
                .buttonBorderShape(.circle)
                .foregroundColor(.accentColor)
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
                }
                .buttonBorderShape(.circle)
                .foregroundColor(.accentColor)
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
                    let targetTime = $minQuantityDate
                    Task {
                        await model.setCarCharging(
                            sensorId: chargingStation.id,
                            newCarCharging: .init(
                                minimumChargeQuantityTargetAmount: $minQuantity
                                    .wrappedValue,
                                targetTime: combineDateTime(
                                    date: $minQuantityDate.wrappedValue,
                                    time: $minQuantityTime.wrappedValue
                                )))
                        dismiss()
                    }
                }) {
                    Text("Set")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)
                .padding()
            }
        }
    }

    private func combineDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current

        let dateComponents = calendar.dateComponents(
            [.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents(
            [.hour, .minute], from: time)

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
        chargingMode: .constant(.constantCurrent),
        chargingStation: .constant(
            ChargingStation.init(
                id: "id-1",
                name: "Station #1",
                chargingMode: .withSolarPower,
                priority: 1,
                currentPower: 0,
                signal: .connected))
    )
    .environmentObject(
        BuildingStateViewModel.fake(
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
                isAnyCarCharing: true,
                chargingStations: []
            )
        )
    )
}

#Preview("Min. Qty.") {
    ChargingOptionsPopupView(
        chargingMode: .constant(.minimumQuantity),
        chargingStation: .constant(
            ChargingStation.init(
                id: "id-1",
                name: "Station #1",
                chargingMode: .withSolarPower,
                priority: 1,
                currentPower: 0,
                signal: .connected))
    )
    .environmentObject(
        BuildingStateViewModel.fake(
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
                isAnyCarCharing: true,
                chargingStations: []
            )
        )
    )
}
