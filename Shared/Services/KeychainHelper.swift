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
    static let installSecretKey = "wakeScheduleInstallSecret"

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

    /// Per-install secret for the Solar Lens wake-schedule API (story #9).
    ///
    /// The API is anonymous — it has no accounts and stores nothing but device
    /// tokens and timestamps. Without a shared secret, anyone who learned a
    /// device token could cancel or spam that device's scheduled pushes, so
    /// every request carries this value and the server compares its hash.
    ///
    /// Generated once, then kept in the same keychain the app already uses.
    /// Deliberately **not** synchronizable: it belongs to this install, and a
    /// restored backup gets a new APNs token anyway.
    static var installSecret: String {
        let keychain = getKeychain()
        if let existing = keychain[installSecretKey], !existing.isEmpty {
            return existing
        }
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let secret =
            status == errSecSuccess
            ? bytes.map { String(format: "%02x", $0) }.joined()
            : UUID().uuidString + UUID().uuidString
        keychain[installSecretKey] = secret
        return secret
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
