import SwiftUI
import _AppIntents_SwiftUI

struct ShortcutsView: View {
    var body: some View {
        VStack {
            VStack {
                Text("With Shortcuts you can create workflows you can trigger manually or automatically based on events or time.")
                    .multilineTextAlignment(.leading)
                    .padding()
            }
            
            ShortcutsLink()
            
            Spacer()
        }.navigationTitle("Discover Siri")
    }
}

#Preview {
    ShortcutsView()
}
