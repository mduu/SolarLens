import SwiftUI
import _AppIntents_SwiftUI

struct ShortcutsOnboardingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts Integration")
                .font(.title)
                .padding(.bottom)
                .bold()
            
            Text("Using Apple Shortcuts you can create automations and custom Siri commands.")
                .font(.headline)
            
            Text("With the build-in integration from Solar Lens you can get information and constrol your Solar Manager using Shortcuts. It is also possible to combine it with other feature of Shortcuts. See what Solar Lens offers in Shortcuts:")

            ShortcutsLink()
                .padding()
            
            Text("You will find more information in Solar Lens settgins menu.")

            Spacer()
        }.padding()
    }
}

#Preview {
    ShortcutsOnboardingView()
}
