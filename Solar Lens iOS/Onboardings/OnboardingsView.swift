import SwiftUI

struct OnboardingsView: View {
    @State var appSettings = AppSettings()
    @State private var selectedTab = 0
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private let numberOfTabs = 2

    var body: some View {

        VStack {
            TabView(selection: $selectedTab) {

                SiriOnboardingView()
                    .tag(0)

                ShortcutsOnboardingView()
                    .tag(1)

            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))  // Hide default dots too
            .toolbar(.hidden, for: .tabBar)  // For iOS 16+

            HStack(spacing: 10) {
                // Loop through the number of tabs to create a dot for each
                ForEach(0..<numberOfTabs, id: \.self) { index in
                    Circle()
                        .fill(
                            selectedTab == index
                                ? Color.primary : Color.gray.opacity(0.5)
                        )  // Change color based on selection
                        .frame(width: 8, height: 8)  // Size of the dot
                        .onTapGesture {
                            // Update the selectedTab state when a dot is tapped
                            withAnimation {
                                selectedTab = index
                            }
                        }
                }

                let isLastPage = selectedTab == numberOfTabs - 1

                if isLastPage {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip")
                    }
                }

            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

#Preview {
    OnboardingsView()
}
