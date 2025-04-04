// 

import SwiftUI

struct TodayChartButton: View {
    @State var showSheet: Bool = false
    
    var body: some View {
        Button(action: {
            showSheet = true;
        }) {
            Image(
                systemName: "chart.line.uptrend.xyaxis"
            )
            .resizable()
            .scaledToFit()
            .padding(.all, 12)
        }
        .buttonBorderShape(.circle)
        .buttonStyle(.borderedProminent)
        .tint(.secondary)
        .sheet(isPresented: $showSheet)
        {
            NavigationView {
                TodayChartSheet()
            }
            .presentationDetents([.medium, .large])
        }
        .frame(maxHeight: 60)
   }
}

#Preview {
    TodayChartButton()
}
