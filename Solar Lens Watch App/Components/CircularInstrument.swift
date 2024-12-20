import SwiftUI

struct CircularInstrument: View {
    @Binding var color: Color
    @Binding var largeText: String
    @Binding var smallText: String?

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 4)
                .frame(maxWidth: 45)
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
        color: Binding<Color>.constant(.yellow),
        largeText: Binding<String>.constant("45"),
        smallText: Binding<String?>.constant("kW"))
}
