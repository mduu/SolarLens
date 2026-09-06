import SwiftUI

/// Drives the visible time window of a chart the user can page through.
///
/// One window is on screen at a time and `windowStart` is the single source of
/// truth for it: the chart's x domain, the header label, the data loaders and
/// the totals all read it, so they can never disagree about which day is being
/// shown. `ChartPage.maximumScrollbackPages` sets how far back the user may
/// page; the installation's registration date cuts that shorter when it is
/// more recent.
///
/// iOS only.
@Observable
final class ChartTimeNavigator {

    let page: ChartPage

    /// Start of the visible window, snapped onto the page's bucket grid.
    private(set) var windowStart: Date

    /// Oldest window the user may scroll to.
    private(set) var earliest: Date

    /// Start of the newest window, frozen at init so paging forward always
    /// lands on the same place. `returnToPresent()` re-reads it.
    private(set) var presentWindowStart: Date

    private let calendar = Calendar.current

    init(page: ChartPage, earliest: Date? = nil) {
        self.page = page

        let present = page.presentWindowStart
        let floor = Self.floor(for: page, earliest: earliest)
        self.presentWindowStart = present
        self.earliest = floor
        // Clamped here as well as in `setEarliest`: a navigator built with a
        // known installation date never runs `setEarliest`, and the decade
        // page would otherwise open ten years back whatever the data covers.
        self.windowStart = max(page.align(present), floor)
    }

    // MARK: - Current window

    /// Exclusive end of the visible window.
    ///
    /// Trimmed pages stop at the end of the bucket holding today rather than
    /// at their nominal span, so the bars spread across the whole plot instead
    /// of being squeezed against years that have not happened yet.
    var windowEnd: Date {
        let nominal = page.end(of: windowStart)
        guard page.trimsFutureBuckets else { return nominal }
        return min(nominal, page.endOfCurrentBucket(containing: Date()))
    }

    /// The window the user is looking at, as a fetchable range.
    var window: Range<Date> {
        windowStart..<windowEnd
    }

    /// Label for the ‹ › header.
    var windowLabel: String {
        page.label(for: windowStart, to: windowEnd)
    }

    /// True while the newest window is on screen — the › button and the
    /// "now" shortcut are pointless then.
    var isAtPresent: Bool {
        windowStart >= presentWindowStart
    }

    var canGoBack: Bool {
        windowStart > earliest
    }

    var canGoForward: Bool {
        !isAtPresent
    }

    // MARK: - Chart configuration

    /// Ready-made configuration for `.chartTimeScroll(_:)`.
    func scrollConfig() -> ChartTimeScrollConfig {
        ChartTimeScrollConfig(
            window: window,
            stepBack: { [weak self] in self?.stepBack() },
            stepForward: { [weak self] in self?.stepForward() }
        )
    }

    // MARK: - Stepping

    func stepBack() {
        guard canGoBack else { return }
        move(by: -1)
    }

    func stepForward() {
        guard canGoForward else { return }
        move(by: 1)
    }

    /// Jumps back to the newest window, re-reading "now" so the chart still
    /// lands on today after the app has been open across midnight.
    func returnToPresent() {
        presentWindowStart = page.presentWindowStart
        windowStart = page.align(presentWindowStart)
    }

    private func move(by pages: Int) {
        guard let moved = calendar.date(
            byAdding: scaled(page.step, by: pages), to: windowStart
        ) else { return }
        windowStart = page.align(min(max(moved, earliest), presentWindowStart))
    }

    // MARK: - Range

    /// The visible window widened by `pages` on its older side, clamped at
    /// `earliest`. Callers use it to fetch a little head-room without pulling
    /// in the whole scrollable range.
    func window(withHeadroom pages: Int) -> Range<Date> {
        let widened =
            calendar.date(
                byAdding: scaled(page.span, by: -abs(pages)), to: windowStart
            ) ?? windowStart
        return max(min(widened, windowStart), page.align(earliest))..<windowEnd
    }

    /// Adopts the real installation date once it is known, so the user cannot
    /// scroll back into years that never had data.
    func setEarliest(_ date: Date) {
        let floor = Self.floor(for: page, earliest: date)
        guard floor != earliest else { return }
        earliest = floor
        if windowStart < floor { windowStart = floor }
    }

    private static func floor(for page: ChartPage, earliest: Date?) -> Date {
        let present = page.presentWindowStart
        let limit =
            Calendar.current.date(
                byAdding: scaled(page.span, by: -page.maximumScrollbackPages),
                to: present
            ) ?? present
        guard let earliest else { return page.align(limit) }
        return page.align(max(limit, earliest))
    }

    private func scaled(_ components: DateComponents, by factor: Int) -> DateComponents {
        Self.scaled(components, by: factor)
    }

    private static func scaled(
        _ components: DateComponents, by factor: Int
    ) -> DateComponents {
        var result = components
        for key in [\DateComponents.day, \DateComponents.month, \DateComponents.year] {
            if let value = result[keyPath: key] {
                result[keyPath: key] = value * factor
            }
        }
        return result
    }
}
