import SwiftUI

struct BatterySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading: Bool = false

    var body: some View {
        ZStack {

            GeometryReader { geometry in

                VStack {
                    if model.overviewData.currentBatteryLevel != nil
                        || model.overviewData.currentBatteryChargeRate != nil
                    {
                        if !model.overviewData.isStaleData {

                            BatteryIndicator(
                                percentage: Double(
                                    model.overviewData
                                        .currentBatteryLevel
                                        ?? 0
                                ),
                                showPercentage: true,
                                height: 30,
                                width: geometry.size.width - 30
                            )

                            HStack(alignment: .firstTextBaseline) {
                                HStack {
                                    let charging =
                                        model.overviewData
                                        .currentBatteryChargeRate
                                        ?? 0

                                    if charging >= 0 {
                                        HStack {
                                            Image(
                                                systemName:
                                                    "arrow.right.circle.fill"
                                            )
                                            .foregroundColor(.green)

                                            Text(
                                                "In:"
                                            )
                                            .foregroundColor(.green)

                                            Text(
                                                "\(model.overviewData.currentBatteryChargeRate ?? 0) W"
                                            )
                                        }.padding(.top)
                                    } else if charging < 0 {
                                        HStack {

                                            Image(
                                                systemName:
                                                    "arrow.left.circle.fill"
                                            )
                                            .foregroundColor(.orange)

                                            Text(
                                                "Out:"
                                            )
                                            .foregroundColor(.orange)

                                            Text(
                                                "\(model.overviewData.currentBatteryChargeRate ?? 0) W"
                                            )
                                        }.padding(.top)
                                    }
                                }  // :HStack

                                Divider()
                                    .frame(maxHeight: 20)
                                    .padding(.horizontal, 3)

                                BatteryForecastView(
                                    batteryForecast: model.overviewData
                                        .getBatteryForecast()
                                )
                            }  // :HStack

                            BatteryList(
                                batteryDevices: model.overviewData.devices
                                    .filter { $0.deviceType == .battery }
                            )
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity)

                        } else {
                            Text("Stale data!")
                                .foregroundColor(.red)
                        }

                    } else {
                        Text("No battery data present!")
                            .font(.footnote)
                    }

                } // :VStack
                .navigationTitle("Battery")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")  // Use a system icon
                                .resizable()  // Make the image resizable
                                .scaledToFit()  // Fit the image within the available space
                                .frame(width: 18, height: 18)  // Set the size of the image
                                .foregroundColor(.purple)  // Set the color of the image
                        }

                    }
                }
                .padding()

            }  // :GeometryReader

            if isLoading {
                ProgressView()
            }
        }
    }
}

#Preview {
    NavigationView {
        BatterySheet()
            .environment(CurrentBuildingState.fake())
    }
}
