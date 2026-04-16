internal import Foundation

/// Runs `body` with a timeout. If the body does not complete within `seconds`,
/// the in-flight work is cancelled and the call throws `CancellationError`.
///
/// Implementation notes:
/// - The underlying work runs in a child `Task` so it can be cancelled from
///   outside (by the companion sleep task) without relying on cooperative
///   cancellation checks inside `body`.
/// - The timeout task is always cancelled on exit to avoid leaking a sleeping
///   task after a fast success/failure.
func withFetchTimeout<T: Sendable>(
    _ seconds: TimeInterval,
    _ body: @Sendable @escaping () async throws -> T
) async throws -> T {
    let workTask = Task { try await body() }
    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
        workTask.cancel()
    }
    defer { timeoutTask.cancel() }

    return try await workTask.value
}
