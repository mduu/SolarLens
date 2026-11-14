import SwiftUI

struct TodayChartSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.closeDetail) private var closeDetail
    @Environment(\.detailHidesNavigationBar) private var hidesNavigationBar
    @Environment(\.colorScheme) var colorScheme

    /// Owned here rather than inside `ChartView` so the day switcher can sit in
    /// the navigation bar. In the medium detent every row of chrome above the
    /// chart is a row the chart does not get, and the bar has the space free.
    @State private var navigator = ChartTimeNavigator(page: .day)
    @State private var store = IntradayChartStore()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.05, green: 0.06, blue: 0.1), Color(red: 0.05, green: 0.05, blue: 0.05)]
                    : [Color(red: 0.94, green: 0.95, blue: 1.0), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                // Without the navigation bar, the day switcher it carried
                // moves in above the chart.
                if hidesNavigationBar {
                    ChartTimeHeader(navigator: navigator, isLoading: store.isLoading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                ChartView(navigator: navigator, store: store)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle("Solar Production")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(hidesNavigationBar ? .hidden : .automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { if let closeDetail { closeDetail() } else { dismiss() } }) {
                    Label("Close", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.orange)
                }
            }

            ToolbarItem(placement: .principal) {
                ChartTimeHeader(navigator: navigator, isLoading: store.isLoading)
            }
        }
    }
}

#Preview {
    TodayChartSheet()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
}
