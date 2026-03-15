import SwiftUI

struct HeaderView: View {
    let onRefresh: () -> Void
    @Binding var showError: Bool

    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    private let sideWidth: CGFloat = 110

    var body: some View {
        HStack {
            // Left: refresh + update timestamp + error indicator
            HStack(spacing: 4) {
                RefreshButton(onRefresh: { onRefresh() })

                UpdateTimeStampView(
                    isStale: buildingState.overviewData.isStaleData,
                    updateTimeStamp: buildingState.overviewData.lastSuccessServerFetch,
                    isLoading: buildingState.isLoading,
                    onRefresh: nil
                )
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

                if buildingState.error != nil || buildingState.errorMessage ?? "" != "" {
                    Button(action: { showError = true }) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            .font(.system(size: 12))
                            .symbolEffect(.rotate.byLayer, options: .repeat(.continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                }
            }
            .frame(width: sideWidth, alignment: .leading)
            .padding(.leading, 16)

            Spacer()

            AppLogo()

            Spacer()

            // Right: settings
            HStack {
                SettingsButton()
            }
            .frame(width: sideWidth, alignment: .trailing)
            .padding(.trailing, 16)

        }  // :HStack
        .sheet(isPresented: $showError) {
            NavigationView {
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading) {
                        Text("Error message:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        Text(buildingState.errorMessage ?? "-")
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Error:")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.red)

                        Text(String(describing: buildingState.error))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showError = false }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.red)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("Error")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

#Preview("top center") {
    VStack {
        HeaderView(onRefresh: {}, showError: .constant(false))
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake()
                )
            )

        Spacer()
    }
}
