import SwiftUI

struct TodayConsumptionView: View {
    var peakConsumptionInW: Double
    var currentConsumptionInW: Int
    var todayConsumptionInWh: Double

    var body: some View {
        GeometryReader { container in

            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [
                        .teal.opacity(0.7),
                        .teal,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .stroke(.teal)
                .frame(
                    width: container.size.width,
                    height: container.size.height
                )
                .overlay(
                    VStack {
                        Grid(alignment: .leadingFirstTextBaseline) {

                            GridRow {
                                Text("Consumption")
                                    .fontWeight(.bold)
                                    .padding(.top, 8)
                                    .padding(.bottom, 2)
                            }
                            .gridCellColumns(2)

                            GridRow {
                                Text("Current:")
                                
                                Text(
                                    currentConsumptionInW
                                        .formatWattsAsKiloWatts(
                                            widthUnit: true
                                        )
                                )
                                .fontWeight(.bold)
                            }

                            GridRow {
                                Text("Peak:")

                                Text(
                                    peakConsumptionInW.formatAsKiloWatts(
                                        widthUnit: true
                                    )
                                )
                                .fontWeight(.bold)
                            }

                            GridRow {
                                Text("Total:")

                                Text(
                                    todayConsumptionInWh
                                        .formatWattHoursAsKiloWattsHours(
                                            widthUnit: true
                                        )
                                )
                                .fontWeight(.bold)
                            }

                        }  // :Grid
                        .frame(maxWidth: .infinity)
                        .padding(.trailing)

                        Spacer()

                    }  // :VStack
                        .foregroundColor(.white)
                )  // :Overlay
        }
    }
}

#Preview {
    VStack {
        
        TodayConsumptionView(
            peakConsumptionInW: 7539,
            currentConsumptionInW: 6540,
            todayConsumptionInWh: 23423
        )
        .frame(width: 180, height: 180)
        
        Spacer()
    }
}
