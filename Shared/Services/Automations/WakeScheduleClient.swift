internal import Foundation

/// Talks to the Solar Lens wake-schedule API (story #9 / ADR-006).
///
/// This is the *only* thing the app ever tells our server: an APNs device
/// token and when it wants to be woken. No Solar Manager credentials, no
/// tokens, no rules, no measurements — see the server README for the full
/// record shape.
///
/// Every call is best effort. If the server is unreachable the automation
/// still runs exactly as it does today (foreground timer, BG tasks, and the
/// local fallback notification); a failed registration therefore logs and
/// returns rather than surfacing an error to the user.
enum WakeScheduleClient {

    // MARK: - Configuration

    /// Always the production server, even for debug builds: pushes must go
    /// through Apple, and which APNs environment applies is decided by
    /// `environment` below — not by which server we talk to. Pointing debug
    /// builds at localhost would mean no pushes at all on a device.
    ///
    /// A debug build can still be aimed at a locally running Functions host by
    /// setting the `SolarLens.wakeApiBaseUrl` user default, which is how the
    /// registration flow is exercised without deploying.
    private static var baseUrl: String {
        #if DEBUG
            if let override = UserDefaults.standard.string(
                forKey: "SolarLens.wakeApiBaseUrl"
            ), !override.isEmpty {
                return override
            }
        #endif
        return "https://solarlens-upload-func.azurewebsites.net/api/wake"
    }

    /// A debug build's device token is an APNs *sandbox* token; TestFlight and
    /// App Store builds produce production tokens. The server picks the
    /// matching APNs host per schedule.
    static var environment: String {
        #if DEBUG
            "sandbox"
        #else
            "production"
        #endif
    }

    /// User-facing opt-out (Settings → "Server-assisted timing"). Default on.
    /// Read straight from `UserDefaults` so non-SwiftUI callers can consult it.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    static let enabledKey = "serverAssistedTiming"

    // MARK: - Device token

    private static let deviceTokenKey = "SolarLens.apnsDeviceToken"
    private static let activeScheduleKey = "SolarLens.activeWakeScheduleId"

    /// APNs device token as lowercase hex, or `nil` before registration has
    /// completed (or when the user denied notifications).
    static var deviceToken: String? {
        get { AutomationSharedStore.defaults.string(forKey: deviceTokenKey) }
        set {
            let store = AutomationSharedStore.defaults
            guard let newValue else {
                store.removeObject(forKey: deviceTokenKey)
                return
            }
            store.set(newValue, forKey: deviceTokenKey)
        }
    }

    /// Schedule id of the deadline currently registered for the active
    /// automation, so we can cancel exactly that one later.
    static var activeScheduleId: String? {
        get { AutomationSharedStore.defaults.string(forKey: activeScheduleKey) }
        set {
            let store = AutomationSharedStore.defaults
            guard let newValue else {
                store.removeObject(forKey: activeScheduleKey)
                return
            }
            store.set(newValue, forKey: activeScheduleKey)
        }
    }

    // MARK: - API

    enum Result: Equatable {
        case registered
        case cancelled
        /// Nothing was sent — no token yet, or the user opted out.
        case skipped(reason: String)
        case failed(reason: String)
    }

    /// Registers (or updates) the wake-up for a time-bound automation.
    ///
    /// - Parameters:
    ///   - scheduleId: stable id for this run, so a changed reset time updates
    ///     the same row instead of creating a second push.
    ///   - title/body: the fallback notification text, **already localized on
    ///     this device**. The server has no idea what language the user
    ///     speaks, and the extension overwrites this text with the real
    ///     outcome anyway — it only shows if the extension cannot finish.
    @discardableResult
    static func registerDeadline(
        scheduleId: String,
        automation: Automation,
        fireAt: Date,
        title: String,
        body: String,
        deepLink: String? = nil
    ) async -> Result {
        guard isEnabled else {
            return .skipped(reason: "server-assisted timing is turned off")
        }
        guard let token = deviceToken else {
            return .skipped(reason: "no APNs device token yet")
        }

        let payload: [String: Any] = [
            "environment": environment,
            "kind": "deadline",
            "pushKind": "alert",
            "fireAt": ISO8601DateFormatter().string(from: fireAt),
            "automation": automation.rawValue,
            "defaultTitle": title,
            "defaultBody": body,
            "deepLink": deepLink as Any,
            "installSecret": KeychainHelper.installSecret,
        ].compactMapValues { $0 is NSNull ? nil : $0 }

        var request = URLRequest(
            url: URL(string: "\(baseUrl)/\(token)/\(scheduleId)")!
        )
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15

        switch await send(request) {
        case .success:
            activeScheduleId = scheduleId
            return .registered
        case .failure(let reason):
            return .failed(reason: reason)
        }
    }

    /// Registers (or extends) a repeating **silent** wake window.
    ///
    /// Used for work with no fixed end time — a running Battery → Car
    /// automation, active threshold monitors — where the server cannot know
    /// when something interesting happens and simply nudges the app on a
    /// coarse cadence.
    ///
    /// This is explicitly an *extra* wake source next to `BGAppRefreshTask`
    /// and `BGProcessingTask`, not a replacement: iOS throttles silent pushes,
    /// gives no delivery feedback, needs Background App Refresh, and stops
    /// delivering them entirely after a force quit (ADR-006).
    ///
    /// The window is short-lived on purpose and renewed while work is active,
    /// so an app that stops running automations stops generating traffic
    /// instead of pushing until some far-off expiry.
    @discardableResult
    static func registerWindow(
        scheduleId: String,
        cadenceMinutes: Int,
        until: Date
    ) async -> Result {
        guard isEnabled else {
            return .skipped(reason: "server-assisted timing is turned off")
        }
        guard let token = deviceToken else {
            return .skipped(reason: "no APNs device token yet")
        }

        let payload: [String: Any] = [
            "environment": environment,
            "kind": "window",
            "pushKind": "silent",
            "cadenceMinutes": cadenceMinutes,
            "until": ISO8601DateFormatter().string(from: until),
            "installSecret": KeychainHelper.installSecret,
        ]

        var request = URLRequest(
            url: URL(string: "\(baseUrl)/\(token)/\(scheduleId)")!
        )
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15

        switch await send(request) {
        case .success: return .registered
        case .failure(let reason): return .failed(reason: reason)
        }
    }

    /// Cancels one schedule. Safe to call when nothing is registered.
    @discardableResult
    static func cancel(scheduleId: String) async -> Result {
        guard let token = deviceToken else {
            return .skipped(reason: "no APNs device token")
        }
        var request = URLRequest(
            url: URL(string: "\(baseUrl)/\(token)/\(scheduleId)")!
        )
        request.httpMethod = "DELETE"
        request.setValue(
            KeychainHelper.installSecret,
            forHTTPHeaderField: "X-Install-Secret"
        )
        request.timeoutInterval = 15

        let result = await send(request)
        if scheduleId == activeScheduleId { activeScheduleId = nil }
        switch result {
        case .success: return .cancelled
        case .failure(let reason): return .failed(reason: reason)
        }
    }

    /// Cancels whatever is registered for the currently active automation.
    @discardableResult
    static func cancelActive() async -> Result {
        guard let scheduleId = activeScheduleId else {
            return .skipped(reason: "nothing registered")
        }
        return await cancel(scheduleId: scheduleId)
    }

    /// Forgets this device entirely — used when the user turns the feature off
    /// or logs out. The server keeps nothing about them afterwards.
    @discardableResult
    static func forgetDevice() async -> Result {
        guard let token = deviceToken else {
            return .skipped(reason: "no APNs device token")
        }
        var request = URLRequest(url: URL(string: "\(baseUrl)/\(token)")!)
        request.httpMethod = "DELETE"
        request.setValue(
            KeychainHelper.installSecret,
            forHTTPHeaderField: "X-Install-Secret"
        )
        request.timeoutInterval = 15

        let result = await send(request)
        activeScheduleId = nil
        switch result {
        case .success: return .cancelled
        case .failure(let reason): return .failed(reason: reason)
        }
    }

    // MARK: - Transport

    private enum Transport {
        case success
        case failure(reason: String)
    }

    private static func send(_ request: URLRequest) async -> Transport {
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(reason: "no HTTP response")
            }
            // 404 on delete means it is already gone — that is the outcome we
            // wanted, not an error.
            guard (200...299).contains(http.statusCode)
                || http.statusCode == 404
            else {
                return .failure(reason: "HTTP \(http.statusCode)")
            }
            return .success
        } catch {
            return .failure(reason: error.localizedDescription)
        }
    }
}
