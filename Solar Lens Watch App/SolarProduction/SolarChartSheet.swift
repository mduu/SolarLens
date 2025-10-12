import SwiftUI

struct SolarChartView: View {
    @Binding var maxProductionkW: Double
    @State var viewModel = SolarChartViewModel()
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {
            
            VStack {
                if viewModel.error == nil && viewModel.errorMessage == nil {
                    
                    if viewModel.consumptionData != nil {
                        
                        SolarChart(
                            maxProductionkW: maxProductionkW,
                            solarProduction: viewModel.consumptionData!
                        )
                        
                        HStack {
                            Text("Max \(Image(systemName: "sun.max")) =")
                                .font(.footnote)
                            Text(String(format: "%.2f kWp", getMaxProductionkW()))
                                .font(.footnote)
                                .foregroundColor(.yellow)
                        }

                    } else {
                        
                        Spacer()
                        Text("No data")
                            .font(.footnote)
                        Spacer()
                        
                    }
                    
                } // :if
            } // :VStack
            .padding(8)
            .ignoresSafeArea(edges: .horizontal.union(.bottom))

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
            .map { Double($0.productionWatts) / 1000 }
            .max()

        guard let maxProduction else { return 0 }

        return maxProduction
    }
}

#Preview {
    SolarChartView(
        maxProductionkW: .constant(11000),
        viewModel: SolarChartViewModel.previewFake()
    )
}
