import SwiftUI

struct SelfConsumptionDonut: View {
    var percent: Int?
    var text: LocalizedStringResource

    var body: some View {
        VStack {
            let percentage = percent ?? 0

            MiniDonut(percentage: Double(percentage), color: .indigo, lineWidth: 3)
                .frame(width: 35, height: 35)

            Text(text)
                .foregroundColor(.indigo)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    SelfConsumptionDonut(percent: 42, text: "Month")
}
