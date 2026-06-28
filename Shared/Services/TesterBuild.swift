internal import Foundation

/// Whether the running build is a tester build (local DEBUG or TestFlight) as
/// opposed to a production App Store build.
///
/// Used to expose in-development features to everyone during testing while
/// keeping them gated in production — e.g. the battery what-if simulator,
/// which production only shows to non-battery owners.
enum TesterBuild {

    static var isActive: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }

    /// TestFlight installs carry a sandbox App Store receipt, whereas
    /// production App Store installs carry a `receipt` file.
    private static var isTestFlight: Bool {
        guard let url = Bundle.main.appStoreReceiptURL else { return false }
        return url.lastPathComponent == "sandboxReceipt"
    }
}
