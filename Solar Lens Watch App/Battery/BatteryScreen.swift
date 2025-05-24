// 

import SwiftUI

struct BatteryScreen: View {
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [
                    .purple.opacity(0.5), .purple.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack {
                    Text("Hello, Battery")
                }
            }
        }
    }
}

#Preview {
    BatteryScreen()
}
