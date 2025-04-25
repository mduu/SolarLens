import SwiftUI

struct ServerInfoView: View {
    var serverInfo: ServerInfo?

    var dateFormatter: DateFormatter

    init(serverInfo: ServerInfo? = nil) {
        self.serverInfo = serverInfo

        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }

    var body: some View {
        VStack {
            if serverInfo == nil {
                Text("No data")
            } else {

                List {
                    ServerInfoRow(
                        label: "Solar Manager ID:",
                        value: serverInfo!.smId
                    )

                    ServerInfoRow(
                        label: "Email:",
                        value: serverInfo!.email
                    )

                    ServerInfoRow(
                        label: "Hardware Version:",
                        value: serverInfo!.hardwareVersion
                    )

                    ServerInfoRow(
                        label: "Software Version:",
                        value: serverInfo!.softwareVersion
                    )

                    ServerInfoRow(
                        label: "Software Installation:",
                        value: serverInfo!.registrationDate != nil
                            ? dateFormatter.string(
                                from: serverInfo!.registrationDate!
                            )
                            : "-"
                    )

                    ServerInfoRow(
                        label: "Licence:",
                        value: serverInfo!.license ?? "-"
                    )

                    ServerInfoRow(
                        label: "Name:",
                        value: "\(serverInfo!.firstname ?? "-") \(serverInfo!.lastname ?? "-")"
                    )
                    
                    ServerInfoRow(
                        label: "Street:",
                        value: serverInfo!.street ?? "-"
                    )
                    
                    ServerInfoRow(
                        label: "City:",
                        value: "\(serverInfo?.zip ?? "") \(serverInfo?.city ?? "")"
                    )

                    ServerInfoRow(
                        label: "Country:",
                        value: serverInfo!.country ?? "-"
                    )

                    ServerInfoRow(
                        label: "User ID:",
                        value: serverInfo!.userId
                    )

                    ServerInfoRow(
                        label: "Device count:",
                        value: String(serverInfo!.deviceCount)
                    )

                    ServerInfoRow(
                        label: "Car count:",
                        value: String(serverInfo!.carCount)
                    )

                    ServerInfoRow(
                        label: "Energy Assistant:",
                        value: String(serverInfo!.energyAssistantEnable)
                    )

                    ServerInfoRow(
                        label: "Signal:",
                        value: String(serverInfo!.signal)
                    )

                    ServerInfoRow(
                        label: "Status:",
                        value: String(serverInfo!.status)
                    )

                    ServerInfoRow(
                        label: "Peak production:",
                        value: (serverInfo!.kWp ?? 0)
                            .formatAsKiloWatts(widthUnit: false) + " kWp"
                    )

                }
            }
        }.navigationTitle("Server Info")

    }
}

struct ServerInfoRow: View {
    var label: LocalizedStringResource
    var value: String

    var body: some View {
        HStack {

            Text(label).font(.callout).foregroundColor(.secondary)

            Spacer()

            Text(value).bold()
        }
    }
}

#Preview {
    ServerInfoView(serverInfo: ServerInfo.fake())
}
