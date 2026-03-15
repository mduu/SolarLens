import SwiftUI

struct TodayChartSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.06, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.05)]
                    : [Color(red: 0.95, green: 0.97, blue: 1.0), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                ChartView()
            }
        }
        .navigationTitle("Today production vs. consumption")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.teal)
                }
            }
        }
        .padding()
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
