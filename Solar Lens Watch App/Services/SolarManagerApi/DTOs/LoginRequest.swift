//
//  LoginRequest.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 12.10.2024.
//


class LoginRequest: Codable {
    var email: String
    var password: String

    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}