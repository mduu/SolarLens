import SwiftUI

struct SolarChartView: View {
    @Binding var maxProductionkW: Double
    @StateObject var viewModel = SolarChartViewModel()

    var body: some View {
        ZStack {
            VStack {
                if viewModel.error != nil || viewModel.errorMessage != nil {
                    VStack {
                        Text("Error")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        ScrollView {

                            if viewModel.errorMessage != nil {
                                Text(viewModel.errorMessage!)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }

                            if viewModel.error != nil {
                                Text(viewModel.error!.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                        } // :ScrollView
                    } // :VStack

                } else {

                    Text("Solar Production")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)

                    Spacer()

                    if viewModel.consumptionData != nil {
                        let data = viewModel.consumptionData!
                        SolarChart(
                            maxProductionkW: $maxProductionkW,
                            solarProduction: .constant(data)
                        )
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.accent)
                            .padding()
                            .foregroundStyle(.accent)
                            .background(Color.black.opacity(0.7))
                    }

                } // :else
            }
        }  // :ZStack
        .onAppear {
            Task {
                await viewModel.fetch()
            }
        }
    }
}

#Preview {
    SolarChartView(
        maxProductionkW: .constant(11)
    )
}
