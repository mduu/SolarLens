import SwiftUI

struct CarRow: View {
    var car: Car

    @Environment(NavigationState.self) private var navigationState

    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Image(systemName: "car.side")
                    .font(.system(size: 14))
            }
            .frame(minWidth: 30)
            .frame(width: 30)
            .scaledToFit()

            VStack(alignment: .leading) {
                HStack {
                    Text(car.name).foregroundColor(.primary)

                    Spacer()
                }  // :HStack

                HStack {


                    HStack {
                        if let batteryPercent = car.batteryPercent {
                            let batteryPercentText = batteryPercent.formatIntoPercentage()

                            Image(systemName: getBatteryIconName(percent: batteryPercent))
                            Text(batteryPercentText)
                        }

                        if let remainingDistance = car.remainingDistance {
                            Text(verbatim: "\(remainingDistance)km")
                        }

                    }.foregroundColor(.cyan)
                        .font(.footnote)

                    Spacer()
                }

            }  // :VStack
            .padding(.trailing, 4)

            Button(action: {
                navigationState.navigate(to: .charging)
            }) {
                Image(
                    systemName: "bolt.circle"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .foregroundColor(.primary)

        }  // :HStack
        .frame(minHeight: 50)
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(.cyan.opacity(0.1))
        )

    }

    func getBatteryIconName(percent: Double) -> String {
        if percent > 95 {
            return "battery.100percent"
        } else if percent > 70 {
            return "battery.75percent"
        } else if percent > 45 {
            return "battery.50percent"
        } else if percent > 20 {
            return "battery.25percent"
        } else {
            return "battery.0percent"
        }
    }
}

#Preview {
    VStack {
        CarRow(
            car: Car(
                id: "1234",
                name: "Car 1",
                priority: 0,
                batteryPercent: 78,
                batteryCapacity: 77,
                remainingDistance: 372,
                lastUpdate: Date(),
                signal: .connected,
                currentPowerInWatts: 0,
                hasError: false
            )
        )
        .environment(NavigationState.init())
    }
    .background(Color.cyan.opacity(0.1))
    .frame(maxHeight: 60)
}
