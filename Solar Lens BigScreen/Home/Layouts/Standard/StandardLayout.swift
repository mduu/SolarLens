import SwiftUI

struct StandardLayout: View {
    @Environment(UiContext.self) var uiContext: UiContext

    var body: some View {
        ZStack {
            Image("bg_blue_sunny_clouds_4k")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            HStack {
                Column1()
                    .frame(maxWidth: .infinity)

                VStack {
                    Text("Center")
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("Right")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding()

        }
    }
}

#Preview {
    StandardLayout()
        .environment(UiContext())
}
