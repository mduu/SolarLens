import SwiftUI

struct AutarkyDonut: View {
    var autarkyPercent: Double

    var body: some View {
        Donut(
            percentage: autarkyPercent,
            color: .purple,
            text: "Autarky")
    }
}

#Preview {
    AutarkyDonut(
        autarkyPercent: 56
    )
}
