import SwiftUI

struct GridToday: View {

    var importToday: Int
    var exportToday: Int
    var importCost: Double?
    var exportRevenue: Double?

    private var netBalance: Double? {
        guard let importCost, let exportRevenue else { return nil }
        return exportRevenue - importCost
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 20) {

                VStack(alignment: .leading) {
                    Text("Export:")
                        .font(.footnote)

                    Text(exportToday.formatWatthoursAsKiloWattsHours(widthUnit: true))
                        .foregroundColor(.indigo)

                    if let exportRevenue {
                        let currencyCode = CurrencyHelper.currencyCode
                        Text(verbatim: "+\(exportRevenue.formatted(.currency(code: currencyCode)))")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading) {
                    Text("Import:")
                        .font(.footnote)

                    Text(importToday.formatWatthoursAsKiloWattsHours(widthUnit: true))
                        .foregroundColor(.purple)

                    if let importCost {
                        let currencyCode = CurrencyHelper.currencyCode
                        Text(verbatim: "−\(importCost.formatted(.currency(code: currencyCode)))")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }

            if let netBalance {
                let currencyCode = CurrencyHelper.currencyCode
                HStack {
                    Text("Balance")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(netBalance.formatted(.currency(code: currencyCode)))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(netBalance >= 0 ? .green : .red)
                }
                .padding(.top, 2)
            }
        }
    }
}

#Preview {
    GridToday(
        importToday: 8000,
        exportToday: 1200,
        importCost: 2.45,
        exportRevenue: 0.85
    )
}

#Preview("No tariff") {
    GridToday(
        importToday: 8000,
        exportToday: 1200
    )
}
