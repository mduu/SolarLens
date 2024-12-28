import Foundation
import KeychainAccess

class KeychainHelper {
    static let serviceName = "com.marcduerst.SolarManagerWatch.watchkitapp"
    static let accessGroup = "UYT5K989XD.com.marcduerst.SolarManagerWatch.Shared"
    static let serviceComment = "Solar Lens Login"

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
        accessToken = nil
        refreshToken = nil
    }

    private static func getKeychain() -> Keychain {
        let shared = Keychain(service: serviceName, accessGroup: accessGroup)
            .comment(serviceComment)

        // Migrate from old Keychain if needed
        if shared[usernameKey] == nil || shared[passwordKey] == nil {
            let oldKeychain = getOldKeychain()
            if oldKeychain["username"] != nil && oldKeychain["password"] != nil
            {
                shared[usernameKey] = oldKeychain["username"]
                shared[passwordKey] = oldKeychain["password"]
                shared[accessTokenKey] = oldKeychain["accessToken"]
                shared[refreshTokenKey] = oldKeychain["refreshToken"]
                
                try! oldKeychain.removeAll()
            }
        }

        return shared
    }

    private static func getOldKeychain() -> Keychain {
        return Keychain(service: "com.marcduerst.SolarManagerWatch")
    }
}
