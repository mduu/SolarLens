import SwiftUI

struct LoginView: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var email: String = ""
    @State var password: String = ""
    @State var isValidEmail = false
    @State var isValidPasswort = false

    var body: some View {
        ScrollView {
            if model.didLoginSucceed == false {
                VStack(alignment: HorizontalAlignment.center) {
                    Text("Login failed!")
                        .foregroundStyle(Color.red)
                        .font(.title3)

                    Text(
                        "Please make sure you are using the correct email and passwort from your Solar Manager login."
                    )
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                    Button("Try again") {
                        model.didLoginSucceed = nil
                    }
                }
            } else {
                
                VStack {
                    Text("Solar Manger Login")
                        .font(.title3)
                        .padding(0)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textContentType(.username)
                        .onChange(of: email) { oldValue, newValue in
                            isValidEmail = isValidEmail(newValue)
                        }
                        .alert(isPresented: $isValidEmail) {
                            Alert(
                                title: Text("Invalid Email"),
                                message: Text("Please enter a valid email address"))
                        }
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .onChange(of: password) { oldValue, newValue in
                            isValidPasswort = isValidPassword(newValue)
                        }
                        .alert(isPresented: $isValidPasswort) {
                            Alert(
                                title: Text("Invalid passwort"),
                                message: Text("Please enter a valid password"))
                        }
                    
                    Button("Login") {
                        Task {
                            await model.tryLogin(email: email, password: password)
                        }
                    }
                    .disabled(isValidEmail || isValidPasswort)
                }
            }
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(
            with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        return password.count < 5
    }
}

#Preview("English") {
    LoginView()
}

#Preview("German") {
    LoginView()
        .environment(\.locale, Locale(identifier: "DE"))
}

#Preview("French") {
    LoginView()
        .environment(\.locale, Locale(identifier: "FR"))
}

#Preview("Italian") {
    LoginView()
        .environment(\.locale, Locale(identifier: "IT"))
}
