import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {

            Tab {
                Text("Tab 1 Content")

                Button(
                    action: {
                        print("Button 1 pressed")
                    },
                    label: {
                        Text("Button 1")
                    }
                )

            } label: {
                Text("Tab 1")
            }

            Tab {
                Text("Tab 2 Content")
            } label: {
                Text("Tab 2")
            }

        }
        .tabViewStyle(.tabBarOnly)
    }
}

#Preview {
    SettingsView()
}
