//

import SwiftUI

struct TodayChartButton: View {
    @State var showSheet: Bool = false

    var body: some View {
        RoundIconButton(
            imageName: "chart.line.uptrend.xyaxis.circle",
            buttonSize: 60
        )
        {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            NavigationView {
                TodayChartSheet()
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    TodayChartButton()
}
