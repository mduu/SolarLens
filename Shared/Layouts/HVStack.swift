import SwiftUI

/// A custom container view that switches between VStack and HStack
struct HVStack<Content: View>: View {
    var isVertical: Bool
    @ViewBuilder let content: Content

    var body: some View {
        if isVertical {
            VStack {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}
