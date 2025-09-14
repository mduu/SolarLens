import SwiftUI

struct SelfConsumptionDonut: View {
    var percent: Int?
    var text: LocalizedStringResource
    var isSmall: Bool = false

    var body: some View {
        VStack {
            let percentage = percent ?? 0

            MiniDonut(
                percentage: Double(percentage),
                color: .indigo,
                lineWidth: isSmall ? 3 : 4,
                textFont: isSmall ? .system(size: 10) : .caption2
            )
                .frame(
                    width: isSmall ? 30 : 45,
                    height: isSmall ? 30 : 45)

            Text(text)
                .foregroundColor(.indigo)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    VStack {

        Text(verbatim: "Large:")
        SelfConsumptionDonut(percent: 42, text: "Month")

        Divider()

        Text(verbatim: "Small:")
        SelfConsumptionDonut(percent: 42, text: "Month", isSmall: true)
    }

}
