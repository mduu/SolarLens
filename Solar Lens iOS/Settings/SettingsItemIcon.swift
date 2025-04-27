import SwiftUI

struct SettingsItemIcon: View {
    var imageName: String
    var color: Color

    var body: some View {
        ZStack {
            // Background view
            RoundedRectangle(cornerRadius: 5)
                .fill(color)
                .frame(width: 32, height: 32)
            
            // Symbol on top with padding
            Image(systemName: imageName)
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SettingsItemIcon(imageName: "gear", color: .blue)
}
