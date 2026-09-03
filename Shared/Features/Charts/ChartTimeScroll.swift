import Charts
import SwiftUI

/// Pins a chart to one window of time and lets a horizontal swipe move it.
///
/// Only the iOS app builds one of these. watchOS, tvOS and the widgets pass
/// `nil` and keep rendering the single fixed window they always have.
///
/// The dates are in *plot space*: whatever transform the marks apply to their
/// x values — the intraday series shift theirs by `convertToLocalTime()` — has
/// to be applied here too, or the window and the marks drift apart by the
/// time-zone offset.
///
/// Deliberately an explicit x domain rather than Swift Charts' own scrolling.
/// `chartScrollPosition(x:)` decides for itself where a written value puts the
/// visible window, and re-anchors that offset whenever the marks change, so a
/// chart that loads its data lazily ends up showing a different day from the
/// one the surrounding UI is labelling. An explicit domain always shows
/// exactly the window it is given.
struct ChartTimeScrollConfig {

    /// The window on screen.
    var window: Range<Date>

    /// Moves one window into the past.
    var stepBack: () -> Void

    /// Moves one window towards the present.
    var stepForward: () -> Void
}

extension View {

    /// Shows exactly `config.window`, and pages it with a horizontal swipe.
    /// A `nil` config leaves the chart untouched, which is what every non-iOS
    /// caller passes.
    @ViewBuilder
    func chartTimeScroll(_ config: ChartTimeScrollConfig?) -> some View {
        if let config {
            let pinned = self.chartXScale(
                domain: config.window.lowerBound...config.window.upperBound
            )

            // tvOS has no DragGesture — and no caller there passes a config
            // either, since only the iOS charts page through time.
            #if os(tvOS)
                pinned
            #else
                pinned
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 24)
                            .onEnded { value in
                                let horizontal = value.translation.width
                                guard abs(horizontal) > abs(value.translation.height)
                                else { return }

                                if horizontal > 0 {
                                    config.stepBack()
                                } else {
                                    config.stepForward()
                                }
                            }
                    )
            #endif
        } else {
            self
        }
    }
}
