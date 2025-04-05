import SwiftUI

struct TodaySolarView: View {
    var peakProductionInW: Double
    var currentSolarProductionInW: Int
    var todaySolarProductionInWh: Double

    var body: some View {
        GeometryReader { container in

            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [
                        .yellow.opacity(0.7),
                        .yellow,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .stroke(.yellow)
                .frame(
                    width: container.size.width,
                    height: container.size.height
                )
                .overlay(
                    VStack {
                        Grid(alignment: .leadingFirstTextBaseline) {

                            GridRow {
                                Text("Solar Production")
                                    .fontWeight(.bold)
                                    .padding(.top, 8)
                                    .padding(.bottom, 2)
                            }
                            .gridCellColumns(2)

                            GridRow {
                                Text("Current:")

                                Text(
                                    currentSolarProductionInW
                                        .formatWattsAsKiloWatts(
                                            widthUnit: true
                                        )
                                )
                                .fontWeight(.bold)
                            }

                            GridRow {
                                Text("Peak:")

                                let text = peakProductionInW.formatAsKiloWatts(
                                    widthUnit: true
                                )
                                
                                Text(
                                    text
                                )
                                .fontWeight(.bold)
                            }

                            GridRow {
                                Text("Total:")

                                Text(
                                    todaySolarProductionInWh
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
        
        TodaySolarView(
            peakProductionInW: 7539,
            currentSolarProductionInW: 6540,
            todaySolarProductionInWh: 23423
        )
        .frame(width: 180, height: 180)
        
        Spacer()
    }
}
