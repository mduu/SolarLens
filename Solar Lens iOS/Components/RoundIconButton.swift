import SwiftUI

struct RoundIconButton: View {
    let imageName: String
    let imageColor: Color = .primary
    var buttonSize: CGFloat = 48  // Define a size for the button
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Blurred Background using a Material
                Circle()
                    .fill(
                        .regularMaterial
                    )  // Use a system material
                    .frame(width: buttonSize, height: buttonSize)
                // Note: No explicit .blur() needed when using Material for this effect

                
                // Image on top
                Image(systemName: imageName)  // Or use Image("your_asset_image_name")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: buttonSize * 0.7,
                        height: buttonSize * 0.7
                    )  // Adjust image size relative to button
                    .foregroundColor(imageColor)  // Tint the image with the accent color
            }
        }
        .buttonStyle(.plain)  // Use plain style to avoid default button appearance
        .contentShape(Circle())  // Make the entire circle tappable
    }
}


#Preview {
    ZStack {
        BackgroundView()
        
        VStack {
            HStack {
                RoundIconButton(imageName: "gear")
                {
                    // Action
                }
                .padding(.top, 20)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}
