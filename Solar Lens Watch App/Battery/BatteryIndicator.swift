import SwiftUI

struct BatteryIndicator: View {
    var percentage: Double
    var showPercentage: Bool = true
    var height: CGFloat = 20
    var width: CGFloat = 100
    
    // Computed properties for styling
    private var baseColor: Color {
        switch percentage {
        case 0..<20:
            return .red
        case 20..<40:
            return .orange
        default:
            return .green
        }
    }
    
    private var fillWidth: CGFloat {
        // Calculate width of the fill based on percentage
        // Leaving small padding on sides
        let maxFillWidth = width - 6
        return maxFillWidth * CGFloat(min(max(percentage, 0), 100) / 100.0)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            RoundedRectangle(cornerRadius: height * 0.25 - 3)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .black.opacity(0.1),
                            .gray.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width - 6, height: height)
                .padding(.leading, 3)
            
            // Battery fill with 3D gradient effect
            if fillWidth > 0 {
                RoundedRectangle(cornerRadius: height * 0.25 - 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                baseColor.opacity(0.9),
                                baseColor.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: fillWidth, height: height)
                    .padding(.leading, 3)
            }
            
            // Percentage text if enabled
            if showPercentage {
                Text("\(Int(percentage))%")
                    .font(.system(size: height * 0.5, weight: .bold))
                    .foregroundColor(.white)
                    //.shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                    .frame(width: width, height: height)
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct BatteryIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                BatteryIndicator(percentage: 100)
                BatteryIndicator(percentage: 75)
                BatteryIndicator(percentage: 50)
                BatteryIndicator(percentage: 25)
                BatteryIndicator(percentage: 10)
                
                // Custom sizes
                BatteryIndicator(percentage: 80, height: 15, width: 80)
                BatteryIndicator(percentage: 60, showPercentage: false, width: 60)
            }
            .padding()
            .background(.purple.opacity(0.2))
            .previewLayout(.sizeThatFits)
        }
    }
}
