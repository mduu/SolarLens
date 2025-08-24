import SwiftUI

struct StandardLayout: View {
    @Environment(UiContext.self) var uiContext: UiContext

    var body: some View {
        Text("Standard Layout")
    }
}

#Preview {
    StandardLayout()
        .environment(UiContext())
}
