//

import SwiftUI

struct TodayChartSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            ChartView()
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
    }
}

#Preview {
    TodayChartSheet()
}
