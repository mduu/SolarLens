import SwiftUI

struct LogoConfigurationView: View {
    var body: some View {
        VStack {
            Text("My Logo")
                .font(.title3)

            // Implement a image file upload here

            Spacer()
        }
    }
}

#Preview {
    LogoConfigurationView()
        .frame(width: 600, height: 400)
        .border(.red, width: 1)
}
