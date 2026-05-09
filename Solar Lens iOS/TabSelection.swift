import Observation
import SwiftUI

/// Process-wide selected top-level tab. Lifted out of `ContentView`'s
/// local state so child screens can drive it via gestures (swipe to
/// switch tabs) without having to plumb a binding through every view.
@Observable
final class TabSelection {
    static let shared = TabSelection()
    var selectedTab: AppTab = .now
    private init() {}
}

/// Tab order on the bottom bar. Single source of truth so the swipe
/// modifier and `StatisticsScreen`'s boundary handling stay in sync if
/// we ever reorder.
enum TopLevelTabOrder {
    static let tabs: [AppTab] = [.now, .automation, .statistics]
}

/// Horizontal drag gesture that moves the selection one tab forward
/// (left-swipe) or back (right-swipe). Vertical scrolling is preserved
/// because we (1) require horizontal translation > vertical and
/// (2) attach via `simultaneousGesture` so a `ScrollView` underneath
/// still wins on vertical-dominant drags.
///
/// The transition itself is intentionally instant. Apple's HIG does
/// not endorse swipe-between-tabs for bottom-tab-bar layouts (their
/// own first-party apps don't ship it), and there is no system
/// primitive that animates a page slide between bottom-tab-bar tabs:
/// `.tabViewStyle(.page)` and paginated `ScrollView` both replace the
/// tab bar. So we keep the gesture as a discoverable shortcut and
/// match how the system swaps tabs on a tab-bar tap — instantly.
private struct TopLevelTabSwipeModifier: ViewModifier {
    let selection: TabSelection

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    let h = value.translation.width
                    let v = value.translation.height
                    guard abs(h) > abs(v) else { return }
                    let order = TopLevelTabOrder.tabs
                    guard let i = order.firstIndex(
                        of: selection.selectedTab
                    ) else { return }
                    if h < 0, i < order.count - 1 {
                        selection.selectedTab = order[i + 1]
                    } else if h > 0, i > 0 {
                        selection.selectedTab = order[i - 1]
                    }
                }
        )
    }
}

extension View {
    /// Adds a horizontal-swipe gesture that moves between the iOS
    /// top-level tabs (`Now` ↔ `Automation` ↔ `Statistics`).
    func topLevelTabSwipe() -> some View {
        modifier(TopLevelTabSwipeModifier(selection: TabSelection.shared))
    }
}
