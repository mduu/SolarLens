import SwiftUI

struct SolarChartView: View {
    @Binding var maxProductionkW: Double
    @StateObject var viewModel = SolarChartViewModel()
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {
            VStack {
                if viewModel.error == nil && viewModel.errorMessage == nil {
                    
                    Text("Solar Production")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)

                    if viewModel.consumptionData != nil {
                        Text(String(format: "Max today: %.2f kW", getMaxProductionkW()))
                            .font(.footnote)
                        
                        SolarChart(
                            maxProductionkW: $maxProductionkW,
                            solarProduction: .constant(viewModel.consumptionData!)
                        )
                    } else {
                        Spacer()
                        Text("No data")
                            .font(.footnote)
                        Spacer()
                    }
                    
                }
            }
            .padding(8)
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.7))
            }
        }  // :ZStack
        .onAppear {
            Task {
                await viewModel.fetch()
                
                if refreshTimer == nil {
                    refreshTimer = Timer.scheduledTimer(
                        withTimeInterval: 300, repeats: true
                    ) {
                        _ in
                        Task {
                            await viewModel.fetch()
                        }
                    }  // :refreshTimer
                }  // :if
            } // :Task
        } // :onAppear
        .onDisappear {
            if (refreshTimer != nil) {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        } // :onDisappear
    }
    
    private func getMaxProductionkW() -> Double {
        guard let consumptionData = viewModel.consumptionData else { return 0 }
        guard consumptionData.data.isEmpty == false else { return 0 }
        
        let maxProduction: Double? = consumptionData.data
            .map { $0.productionWatts / 1000 }
            .max()

        guard let maxProduction else { return 0 }

        return maxProduction
    }
}

#Preview {
    SolarChartView(
        maxProductionkW: .constant(11000)
    )
    .environmentObject(SolarChartViewModel.previewFake())
}
