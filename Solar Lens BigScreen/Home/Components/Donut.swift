import SwiftUI

struct Donut: View {
    var percentage: Double
    var color: Color = .primary
    var text: LocalizedStringKey

    var body: some View {
        MiniDonut(
            percentage: percentage,
            color: color,
            lineWidth: 6,
            textFont: .title3
        ) {
            Text(text)
                .padding(.horizontal)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    HStack {
        VStack {
            Donut(
                percentage: 88,
                color: .indigo,
                text: "Self Consumption"
            )
            .frame(maxWidth: 200, maxHeight: 200)

            Donut(
                percentage: 88,
                color: .indigo,
                text: "Eigenverbrauch"
            )
            .frame(maxWidth: 200, maxHeight: 200)

            Donut(
                percentage: 88,
                color: .purple,
                text: "Autarky"
            )
            .frame(maxWidth: 200, maxHeight: 200)

            Spacer()
        }

        Spacer()
    }
}
