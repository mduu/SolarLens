import SwiftUI

struct SettingsItemCaption: View {
    var imageName: String
    var text: LocalizedStringResource
    var color: Color
    
    var body: some View {
        SettingsItemIcon(imageName: imageName, color: color)

        Text(text)
            .padding(.leading)
    }
}

#Preview {
    SettingsItemCaption(imageName: "gear", text: "Settings", color: .blue)
}
