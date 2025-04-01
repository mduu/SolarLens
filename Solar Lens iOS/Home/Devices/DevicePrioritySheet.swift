import SwiftUI

struct DevicePrioritySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    @State var isLoading: Bool = false

    var body: some View {
        ZStack {

            VStack(spacing: 0) {

                HStack {
                    Text("Device")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 20)

                    Spacer()

                    Image(systemName: "arrow.up.arrow.down")
                        .font(.footnote)
                        .padding(.trailing, 20)
                        .foregroundColor(.gray)
                }

                List {

                    ForEach(buildingState.overviewData.devices) { device in
                        DevicePriorityRow(device: device)
                            .contentShape(Rectangle())  // Make the whole row tappable
                    }
                    .onMove { indices, newOffset in
                        if let index = indices.first {
                            let device = buildingState.overviewData.devices[
                                index
                            ]

                            Task {
                                isLoading = true
                                
                                await buildingState.setSensorPriority(
                                    sensorId: device.id,
                                    newPriority: newOffset + 1
                                )
                                
                                isLoading = false
                            }
                        }
                    }
                }
                .listStyle(.inset)

            }
            .navigationTitle("Devices priorities")
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
                            .foregroundColor(.teal)  // Set the color of the image
                    }

                }
            }
            .padding()
            
            if isLoading {
                ProgressView()
            }
        }
    }
}

#Preview {
    NavigationView {
        DevicePrioritySheet()
            .environment(CurrentBuildingState.fake())
    }
}
