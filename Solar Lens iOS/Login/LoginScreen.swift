import SwiftUI

struct LoginScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var email: String = ""
    @State var password: String = ""

    var body: some View {
        VStack(alignment: .center) {
            Image("solarlens")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()

            Text(verbatim: "Solar Lens")
                .font(.largeTitle)
                .foregroundColor(.accent)

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                Task {
                    await model.tryLogin(
                        email: email, password: password)
                }
            }) {
                Image(systemName: "person.badge.key.fill")
                Text("Login")
            }
            .font(.title2)
            .buttonStyle(.borderedProminent)
            .disabled(isValidLogin())

            if model.didLoginSucceed == false {
                VStack(alignment: HorizontalAlignment.center, spacing: 8) {
                    Text("Login failed!")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(16)

                    Text(
                        "Please make sure you are using the correct email and passwort from your Solar Manager login."
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                }
                .background(Color.red)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 30)
    }

    func isValidLogin() -> Bool {
        guard !isValidEmail() else { return false }
        guard !isValidPassword() else { return false }
        return true
    }

    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let valid = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            .evaluate(
                with: email)
        return valid
    }

    func isValidPassword() -> Bool {
        let valid = password.count > 4
        return valid
    }
}

#Preview("English") {
    LoginScreen()
        .environment(CurrentBuildingState())
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

#Preview("German") {
    LoginScreen()
        .environment(CurrentBuildingState())
        .environment(\.locale, Locale(identifier: "DE"))
}

#Preview("French") {
    LoginScreen()
        .environment(CurrentBuildingState())
        .environment(\.locale, Locale(identifier: "FR"))
}

#Preview("Italian") {
    LoginScreen()
        .environment(CurrentBuildingState())
        .environment(\.locale, Locale(identifier: "IT"))
}
