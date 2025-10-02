import SwiftUI

struct GridToday: View {

    var importToday: Int
    var exportToday: Int

    var body: some View {
        HStack(alignment: .top, spacing: 20) {

            VStack(alignment: .leading) {
                Text("Export:")
                    .font(.footnote)

                Text(exportToday.formatWatthoursAsKiloWattsHours(widthUnit: true))
                    .foregroundColor(.indigo)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                Text("Import:")
                    .font(.footnote)

                Text(importToday.formatWatthoursAsKiloWattsHours(widthUnit: true))
                    .foregroundColor(.purple)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        }
    }
}

#Preview {
    GridToday(
        importToday: 8000,
        exportToday: 1200
    )
}
