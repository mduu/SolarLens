//
//  KeychainHelper.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import KeychainAccess
import Foundation

class KeychainHelper {
    static let serviceName = "com.marcduerst.SolarManagerWatch"
    static let serviceComment = "SolarManager Watch Login"
    static let usernameKey = "username"
    static let passwordKey = "password"
    static let accessTokenKey = "accessToken"
    static let refreshTokenKey = "refreshToken"
    
    static var accessToken: String? {
        get { getKeychain()[accessTokenKey] }
        set { getKeychain()[accessTokenKey] = newValue }
    }
    
    static var refreshToken: String? {
        get { getKeychain()[refreshTokenKey] }
        set { getKeychain()[refreshTokenKey] = newValue }
    }

    static func saveCredentials(username: String, password: String) {
        let keychain = getKeychain()
        keychain[usernameKey] = username
        keychain[passwordKey] = password
    }

    static func loadCredentials() -> (username: String?, password: String?) {
        let keychain = getKeychain()
        let username = keychain[usernameKey]
        let password = keychain[passwordKey]

        return (username, password)
    }
    
    static func deleteCredentials() {
        let keychain = getKeychain()
        keychain[usernameKey] = nil
        keychain[passwordKey] = nil
    }

    private static func getKeychain() -> Keychain {
        return Keychain(service: serviceName)
            .comment(serviceComment)
    }
}
