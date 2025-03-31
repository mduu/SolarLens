//

import SwiftUI

struct DevicePrioritySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    var body: some View {
        VStack(spacing: 0) {
            List {

                ForEach(buildingState.overviewData.devices) { device in
                    HStack {
                        Text(device.name).fontWeight(.bold)
                        Spacer()
                        Text(
                            device.currentPowerInWatts > 0
                                ? "\(device.currentPowerInWatts)W" : ""
                        )
                        Image(systemName: "line.3.horizontal")  // Drag handle icon
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())  // Make the whole row tappable
                }
                .onMove { indices, newOffset in
                    //devices.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.inset)

            Table(buildingState.overviewData.devices) {
                TableColumn("Name") { device in
                    Text(device.name)
                }

                TableColumn("Power") { device in
                    Text(
                        device.currentPowerInWatts > 0
                            ? "\(device.currentPowerInWatts)W" : ""
                    )
                }

                TableColumn("") { device in
                    Image(systemName: "line.3.horizontal")  // Drag handle icon
                        .foregroundColor(.gray)

                }

            }
            .tableColumnHeaders(.visible)
            .tableStyle(.inset)

        }
        .navigationTitle("Device priorities")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        DevicePrioritySheet()
            .environment(CurrentBuildingState.fake())
    }
}
