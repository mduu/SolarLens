import SwiftUI

struct AutarkyDonut: View {
    var percent: Int?
    var text: LocalizedStringResource
    var isSmall: Bool

    var body: some View {
        VStack {
            let percentage = percent ?? 0

            MiniDonut(
                percentage: Double(percentage),
                color: .purple,
                lineWidth: isSmall ? 3 : 4,
                textFont: isSmall ? .system(size: 10) : .caption2
            )
                .frame(
                    width: isSmall ? 30 : 45,
                    height: isSmall ? 30 : 45)

            Text(text)
                .foregroundColor(.purple)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    VStack {
        Text("Large")
        AutarkyDonut(percent: 42, text: "Month", isSmall: false)

        Divider()

        Text("Small")
        AutarkyDonut(percent: 42, text: "Month", isSmall: true)

    }
}
