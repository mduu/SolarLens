// 

import SwiftUI

struct ChartSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    @State var isLoading: Bool = false

    var body: some View {
        ZStack {
            VStack {
                Text("Day chart")
            }
            .navigationTitle("Today production vs. consumption")
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
    ChartSheet()
        .environment(CurrentBuildingState.fake())
}
