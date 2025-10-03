import SwiftUI

struct LoginForm: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState
    @State var email: String = ""
    @State var password: String = ""

    @Namespace private var focusNamespace

    var body: some View {
        GlassEffectContainer(spacing: 40.0) {
            VStack(alignment: .leading) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .prefersDefaultFocus(email.isEmpty, in: focusNamespace)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .prefersDefaultFocus(!email.isEmpty && password.isEmpty, in: focusNamespace)

                Button(action: {
                    Task {
                        await model.tryLogin(
                            email: email,
                            password: password
                        )
                    }
                }) {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Login")
                    }
                    .padding()
                }
                .font(.title2)
                .buttonStyle(.borderedProminent)
                .disabled(isValidLogin())
                .prefersDefaultFocus(!email.isEmpty && !password.isEmpty, in: focusNamespace)

                if model.didLoginSucceed == false {
                    VStack(alignment: HorizontalAlignment.center, spacing: 8) {
                        Text("Login failed!")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(50)
                        
                        Text(
                            "Please make sure you are using the correct email and passwort from your Solar Manager login."
                        )
                        .padding(.horizontal, 50)
                        .padding(.bottom, 50)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    }
                    .background(Color.red)
                    .cornerRadius(20)
                    .padding(.top, 100)
                }
            }
            .padding(.horizontal, 30)
            .focusScope(focusNamespace)
        }
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
                with: email
            )
        return valid
    }

    func isValidPassword() -> Bool {
        let valid = password.count > 4
        return valid
    }
}

#Preview("English") {
    LoginForm()
        .environment(CurrentBuildingState.fake())
}

#Preview("Failed") {
    LoginForm()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .fake(),
                loggedIn: false,
                isLoading: false,
                didLoginSucceed: false
            )
        )
}
