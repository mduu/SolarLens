import SwiftUI

struct AppReviewRequestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Please rate us! 🌟")
                    .font(.headline)
                    .foregroundColor(.accent)

                Text(
                    "Your feedback matters! Please consider rating us. Your support helps us improve."
                )

                Text("Here is how:")
                    .foregroundColor(.accent)
                    .padding(.top, 4)
                Text("Use the App-Store app on your iPhone and search for 'Solar Lens'.")
                
                Text("Thank you! 💖")
                    .foregroundColor(.accent)
                    .padding(.top, 4)

            }  // :VStack
        }  // :ScrollView
        .onAppear() {
            AppStoreReviewManager.shared.reviewShown()
        }
    }
}

#Preview {
    AppReviewRequestView()
}
