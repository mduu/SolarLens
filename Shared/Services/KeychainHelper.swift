internal import Foundation
import KeychainAccess

class KeychainHelper {
    static let serviceName = "com.marcduerst.SolarManagerWatch.watchkitapp"
    static let accessGroup = "UYT5K989XD.com.marcduerst.SolarManagerWatch.Shared"
    static let serviceComment = "Solar Lens App"

    static let usernameKey = "username"
    static let passwordKey = "password"
    static let accessTokenKey = "accessToken"
    static let refreshTokenKey = "refreshToken"
    static let isSynchronizedKey = "isSynchronized"

    static var accessToken: String? {
        get { getKeychain()[accessTokenKey] }
        set { getKeychain()[accessTokenKey] = newValue }
    }

    static var refreshToken: String? {
        get { getKeychain()[refreshTokenKey] }
        set { getKeychain()[refreshTokenKey] = newValue }
    }
    
    static var isSynchronized: Bool {
        get {
            getKeychain()[isSynchronizedKey] == nil
            ? false
            : getKeychain()[isSynchronizedKey]!.lowercased() == "true"
                ? true
                : false
        }
        set { getKeychain()[isSynchronizedKey] = String(newValue) }
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
        
        if !isSynchronized {
            if username != nil {
                keychain[usernameKey] = username
                keychain[passwordKey] = password
            }
            isSynchronized = true
        }

        return (username, password)
    }

    static func deleteCredentials() {
        let keychain = getKeychain()
        keychain[usernameKey] = nil
        keychain[passwordKey] = nil
        accessToken = nil
        refreshToken = nil
    }

    private static func getKeychain() -> Keychain {
        return Keychain(service: serviceName, accessGroup: accessGroup)
            .synchronizable(true)
            .comment(serviceComment)
    }
}
