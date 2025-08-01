//

import SwiftUI

struct ScenarioScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    .white,
                    .orange.opacity(0.3),
                    .pink.opacity(0.3),
                    .purple.opacity(0.2),
                    .purple.opacity(0.1),
                    .white,
                    .purple.opacity(0.2),
                    .cyan.opacity(0.4),
                ]),
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: [.leading, .trailing, .top])

            VStack(alignment: .leading) {

                VStack(alignment: .leading) {
                    Text("Scenarios")
                        .font(.largeTitle)
                        .foregroundColor(.orange.opacity(0.5))
                        .fontWeight(.bold)
                        .padding(.top, 10)

                    Text(
                        "Scenarios are practical automations that help you to control your energy in your house the smart way."
                    )
                    .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.5))
                )
                .padding(.bottom, 20)

                Grid(horizontalSpacing: 30) {

                    GridRow(alignment: .top) {

                        ScenarioButton(
                            imageName: "bolt.car.circle",
                            title: "Battery to car",
                            description: "Transfer energy from battery to car.",
                            scenario: .BatteryToCar,
                            activateAction: {
                                print("Battery to car pressed")
                                ScenarioManager.shared.startScenario(
                                    scenario: .BatteryToCar,
                                    parameters: ScenarioBatteryToCarParameters(
                                        minBatteryLevel: 20
                                    )
                                )
                            }
                        )

                        ScenarioButton(
                            imageName: "bolt.car",
                            title: "1x Tariff",
                            description:
                                "Charge car with tariff optimized, then switch back to previouse mode.",
                            scenario: .OneTimeTariff,
                            activateAction: {
                                print("1x Tariff pressed")
                            }
                        )
                    }

                }  // :Grid
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)

                Spacer()

                LogCountBubble(messages: ScenarioManager.shared.log)
            }  // :VStack
            .padding()

        }
    }
}

#Preview {
    ScenarioScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
}
