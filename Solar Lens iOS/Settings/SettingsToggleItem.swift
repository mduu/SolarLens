import SwiftUI

struct SettingsToggleItem: View {
    var imageName: String
    var text: String
    var color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            SettingsItemCaption(
                imageName: imageName,
                text: text,
                color: color
            )

            Toggle(text, isOn: $isOn)
        }
    }
}

#Preview {
    SettingsToggleItem(
        imageName: "gear",
        text: "My Toggle",
        color: .purple,
        isOn: .constant(true)
    )
}
