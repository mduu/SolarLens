//
//  LoginView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 06.10.2024.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    @State var email: String = ""
    @State var password: String = ""
    @State var isValidEmail = false
    @State var isValidPasswort = false

    var body: some View {
        VStack {
            Text("Solar Manger Login")
                .font(.title3)

            TextField("Email", text: $email)
                .onChange(of: email) { oldValue, newValue in
                    isValidEmail = isValidEmail(newValue)
                }
                .alert(isPresented: $isValidEmail) {
                    Alert(
                        title: Text("Invalid Email"),
                        message: Text("Please enter a valid email address"))
                }

            SecureField("Password", text: $password)
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
                    await model.login(email: email, password: password)
                }
            }
            .disabled(isValidEmail || isValidPasswort)
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
