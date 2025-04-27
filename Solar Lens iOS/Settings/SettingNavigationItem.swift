import SwiftUI

struct SettingNavigationItem<Content: View>: View {
    var imageName: String
    var text: LocalizedStringResource
    var color: Color
    var disabled: Bool = false
    @ViewBuilder let content: Content?

    var body: some View {
        NavigationLink {
            content
        } label: {

            SettingsItemCaption(imageName: imageName, text: text, color: color)

        }
        .disabled(disabled)
        .listRowBackground(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingNavigationItem(
        imageName: "gear",
        text: "Settings",
        color: .purple
    ) {
    }
}
