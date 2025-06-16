//

import SwiftUI

struct ScenarioButton: View {
    var imageName: String
    var title: LocalizedStringResource
    var description: LocalizedStringResource

    @State var isPressed: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.purple)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: 140)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 140)
        }
        .padding(20)
        .frame(maxWidth: 160, maxHeight: 200)
        .background(

            RoundedRectangle(cornerRadius: 15)
                .fill(.white.opacity(0.15))
                .shadow(color: .black, radius: 10, x: 5, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.white.opacity(0.8))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .pink, .purple, .cyan,
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .shadow(
                            color: isPressed ? .pink.opacity(0.4) : .clear,
                            radius: 10
                        )
                )
        )
        .onTapGesture { gesture in
            withAnimation {
                isPressed.toggle()  // First toggle with animation
            }

            // Delay and then toggle again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {  // 0.3 seconds = 300ms
                withAnimation {
                    isPressed
                        .toggle()  // Second toggle with animation
                }
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                .white,
                .pink.opacity(0.3),
                .purple.opacity(0.2),
                .purple.opacity(0.1),
                .white,
                .purple.opacity(0.1),
                .teal.opacity(0.1),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)

        VStack {
            ScenarioButton(
                imageName: "bolt.car.circle",
                title: "Battery to car",
                description: "Transfer energy from battery to car."
            )

            ScenarioButton(
                imageName: "bolt.car.circle",
                title: "Battery to car",
                description: "Transfer energy from battery to car.",
                isPressed: true
            )
            .padding(.top, 50)

            Spacer()
        }
    }
}
