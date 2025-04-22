import SwiftUI

struct SettingListItem<Content: View>: View {
    var imageName: String
    var text: String
    var color: Color
    @ViewBuilder let content: Content?

    var body: some View {
        NavigationLink {
            content
        } label: {

            ZStack {
                // Background view
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 40, height: 40)  // Size of the background

                // Symbol on top with padding
                Image(systemName: imageName)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }

            Text(text)
        }
        .listRowBackground(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingListItem(
        imageName: "gear",
        text: "Settings",
        color: .purple
    ) {
    }
}
