import SwiftUI

struct RefreshButton: View {
    let onRefresh: () -> Void
    
    var body: some View {
        RoundIconButton(imageName: "arrow.trianglehead.counterclockwise") {
            onRefresh()
        }
    }
}

#Preview {
    RefreshButton(onRefresh: {})
}
