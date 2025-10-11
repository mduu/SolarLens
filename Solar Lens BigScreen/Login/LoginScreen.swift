import SwiftUI

struct LoginScreen: View {
    var body: some View {
        HStack(alignment: .top, spacing: 100) {
            Spacer()

            VStack(alignment: .leading) {
                //SolarLensLogo()
                WelcomeInfo()
            }

            VStack {
                LoginForm()
            }

            Spacer()
        }

    }
}

#Preview("Default") {
    LoginScreen()
        .environment(CurrentBuildingState.fake())
}

#Preview("Failed") {
    LoginScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .fake(),
                loggedIn: false,
                isLoading: false,
                didLoginSucceed: false
            )
        )
}
