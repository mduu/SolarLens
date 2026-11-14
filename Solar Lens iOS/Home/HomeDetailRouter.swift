import Observation
import SwiftUI

/// What the home screen can show in depth.
enum HomeDetail: Hashable {
    case production
    case grid
    case battery
    case consumption
    case charging
    case efficiency
}

/// Decides where a tapped tile shows its detail.
///
/// On the iPhone and in narrow windows every tile opens its own sheet, as it
/// always has. Where the window is wide enough, the dashboard installs this
/// router and the detail appears in a pane beside the tiles instead, so the
/// live figures stay in view while a mode is being changed.
@Observable
final class HomeDetailRouter {
    var detail: HomeDetail?
    /// Set by the dashboard from its width; `false` means "use your sheet".
    var usesPane = false
    /// The pin configuration the consumption tile works on, so the device
    /// list in the pane edits the same instance the tiles read.
    var pinnedConfig: PinnedDevicesConfiguration?

    /// Shows `detail` in the pane. Returns `false` when there is no pane and
    /// the caller should present its sheet.
    func open(_ detail: HomeDetail) -> Bool {
        guard usesPane else { return false }
        self.detail = detail
        return true
    }

    func close() {
        detail = nil
    }

    var isShowingDetail: Bool { detail != nil }
}

/// Where a detail view (battery, grid, charging …) is being shown.
enum DetailPlacement {
    /// Over the home screen, as on the iPhone.
    case sheet
    /// In the pane beside the dashboard.
    case pane
    /// As a section of its own, reached from the sidebar: full width, and
    /// nothing to close.
    case section
}

extension EnvironmentValues {
    /// Closes the detail pane. `nil` inside a sheet, where `dismiss` applies.
    @Entry var closeDetail: (() -> Void)? = nil
    @Entry var detailPlacement: DetailPlacement = .sheet
    /// Set where the screen around a detail view already says what it is,
    /// and its navigation bar would only add an empty band.
    @Entry var detailHidesNavigationBar = false
}

extension View {
    /// Marks the tile whose detail is open in the pane.
    func detailSelection(_ isSelected: Bool) -> some View {
        overlay {
            if isSelected {
                CardMetrics.shape
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
    }
}
