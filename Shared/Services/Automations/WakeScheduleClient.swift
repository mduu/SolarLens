internal import Foundation

/// Registers wake-ups with the Solar Lens server.
///
/// All the server ever learns: an APNs device token and when to wake it — no
/// Solar Manager credentials, no rules, no measurements (ADR-006).
///
/// Every call is best effort. A failure only logs, because the automation still
/// runs via BG tasks and the local fallback notification.
enum WakeScheduleClient {

    // MARK: - Configuration

    /// Always the production server: pushes go through Apple either way, and the
    /// APNs environment is decided by `environment`, not by the host. Debug builds
    /// can be pointed at a local Functions host with the `SolarLens.wakeApiBaseUrl`
    /// user default.
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

    /// Debug builds get sandbox tokens, TestFlight and App Store builds production
    /// ones; the server picks the matching APNs host per schedule.
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

    /// Registers or updates the wake-up for a time-bound automation.
    ///
    /// - Parameters:
    ///   - scheduleId: stable per run, so a changed reset time updates the same row
    ///     instead of adding a second push.
    ///   - title/body: fallback notification text, localized **here** — the server
    ///     does not know the user's language, and the extension overwrites it with
    ///     the real outcome anyway.
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

    /// Registers or extends the repeating silent wake window for work with no fixed
    /// end time — a Battery → Car run, active monitors.
    ///
    /// An *extra* wake source next to the BG tasks, never a replacement: iOS
    /// throttles silent pushes, acknowledges nothing and stops them after a force
    /// quit. The window is short and renewed while work runs, so an app that stops
    /// automating stops generating traffic.
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
