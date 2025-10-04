import SwiftUI

enum MainMenuItem {
    case home
    case settings
    case logout
}

struct MainMenu: View {
    var action: (MainMenuItem) -> Void

    @State private var showingLogoutConfirmation = false

    var body: some View {
        HStack {

            VStack {

                HStack(alignment: .top, spacing: 9) {
                    Image("SolarLensLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 55)
                        .cornerRadius(13)
                        .padding(.trailing, 5)

                    VStack(alignment: .leading) {
                        Text(verbatim: "Solar Lens")

                        HStack(spacing: 0) {

                            Text(
                                verbatim:
                                    "v \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                            )

                            Text(
                                verbatim: ".\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                            )

                        }  // :HStack
                        .font(.system(size: 18))

                    }

                    Spacer()

                }
                .padding(.bottom, 2)

                Divider()

                Button(
                    action: {
                        action(.home)
                    },
                    label: {
                        Label("Home", systemImage: "house")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .foregroundColor(.primary)

                Button(
                    action: {
                        action(.settings)
                    },
                    label: {
                        Label("Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .foregroundColor(.primary)

                Divider()

                Button(
                    action: {
                        showingLogoutConfirmation = true
                    },
                    label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .foregroundColor(.primary)
                .tint(.red)
                .alert(isPresented: $showingLogoutConfirmation) {
                    Alert(
                        title: Text("Confirm Logout"),
                        message: Text("Are you sure you want to log out?"),

                        primaryButton: .destructive(Text("Yes, log out")) {
                            action(.logout)
                        },

                        // No/Secondary Button (cancels the action)
                        secondaryButton: .cancel(Text("No, Cancel"))
                    )
                }

                Spacer()

            }
            .padding()
            .frame(maxWidth: 360, maxHeight: .infinity)
            .glassEffect(
                .regular,
                in: .rect(cornerRadius: 30.0)
            )

            Spacer()

        }
        .padding()
        .ignoresSafeArea()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        MainMenu(action: { item in
            print("Selected item: \(item)")
        })
    }
    .background(.blue.opacity(0.4).gradient)
}
