import SwiftUI

struct CircularInstrument: View {
    var color: Color
    var largeText: String
    var smallText: String?

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 4)
            VStack {
                Text(largeText)
                    .fontWeight(.bold)
                    .font(.system(size: 18))
                    .padding(.top, 6)

                if smallText != nil {
                    Text(smallText!)
                        .font(.system(size: 8))
                        .padding(.bottom, 4)
                }
            }
        }
    }
}

#Preview {
    CircularInstrument(
        color: .yellow,
        largeText: "45",
        smallText: "kW")
    .frame(width: 45, height: 45)
}
