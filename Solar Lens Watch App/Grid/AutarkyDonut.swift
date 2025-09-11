import SwiftUI

struct AutarkyDonut: View {
    var percent: Int?
    var text: LocalizedStringResource

    var body: some View {
        VStack {
            let percentage = percent ?? 0

            MiniDonut(percentage: Double(percentage), color: .purple, lineWidth: 3)
                .frame(width: 40, height: 40)

            Text(text)
                .foregroundColor(.purple)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    AutarkyDonut(percent: 42, text: "Month")
}
