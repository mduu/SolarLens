import SwiftUI

struct TodayChartSheet: View {
    @Environment(\.dismiss) var dismiss
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

            ChartView(navigator: navigator, store: store)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle("Solar Production")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.orange)
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
