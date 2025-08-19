import SwiftUI

struct WelcomeInfo: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to")
                .font(.title)
                .padding(.bottom)
            Text(verbatim: "Solar Lens")
                .font(.headline)
                .foregroundColor(.accent)
            Text(verbatim: "Big Screen")
                .font(.system(size: 96))
                .foregroundColor(.accent)
        }
    }
}

#Preview {
    WelcomeInfo()
}
