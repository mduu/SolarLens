import SwiftUI

struct FooterView: View {
    var body: some View {
        SiriDiscoveryView()
            .padding(.vertical, 0)
    }
}

#Preview {
    VStack {
        Spacer()

        FooterView()
    }
    .ignoresSafeArea()
}
