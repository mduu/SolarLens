import Charts
import SwiftUI

/// Where "now" sits inside a chart's visible window.
///
/// A stored value rather than something derived from `Date()` while rendering:
/// Swift Charts re-anchors its scroll offset whenever its content changes, so
/// the boundary has to stay put between renders.
struct ChartFutureShading {

    /// The visible window, used to measure the plot.
    let window: Range<Date>

    /// 0 means the whole window is still ahead, 1 that none of it is.
    let startFraction: Double

    /// `nil` once the window lies entirely in the past.
    init?(window: Range<Date>) {
        let now = Date()
        let length = window.upperBound.timeIntervalSince(window.lowerBound)
        guard window.contains(now), length > 0 else { return nil }
        self.window = window
        self.startFraction = now.timeIntervalSince(window.lowerBound) / length
    }
}

extension View {

    /// Shades the part of a chart's visible window that has not happened yet.
    ///
    /// The scrollable intraday charts always draw a whole day, so today's chart
    /// runs to tonight's midnight and the hours after "now" sit empty. Without
    /// a marker that gap reads as missing data rather than as a day still in
    /// progress.
    ///
    /// Drawn as a chart background rather than as a `RectangleMark`: these
    /// charts drive their colours through a `chartForegroundStyleScale`
    /// dictionary, and a mark carrying no series value gets nothing from it —
    /// it simply never appears once the series are on screen.
    @ViewBuilder
    func chartFutureShading(_ shading: ChartFutureShading?) -> some View {
        if let shading {
            chartBackground { proxy in
                GeometryReader { geometry in
                    // `position(forX:)` measures the whole scrollable content,
                    // which spans months here — but the distance between the
                    // window's own bounds is exactly the visible plot width.
                    let plotWidth =
                        zip(
                            proxy.position(forX: shading.window.lowerBound),
                            proxy.position(forX: shading.window.upperBound)
                        ).map { $1 - $0 } ?? geometry.size.width
                    let frame = proxy.plotFrame.map { geometry[$0] }
                    let height = frame?.height ?? geometry.size.height
                    let top = frame?.minY ?? 0
                    let start = plotWidth * shading.startFraction

                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: max(0, plotWidth - start), height: height)
                        .offset(x: start, y: top)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 1, height: height)
                        .offset(x: start, y: top)
                }
            }
        } else {
            self
        }
    }
}

/// `Optional.zip`, so two optional proxy positions can be combined without a
/// pyramid of `if let`s inside a view builder.
private func zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
    guard let a, let b else { return nil }
    return (a, b)
}
