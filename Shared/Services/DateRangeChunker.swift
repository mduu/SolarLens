internal import Foundation

/// Splits a long date range into monthly tranches so Solar Manager
/// `/data/range` requests stay small and a progress bar can advance one step
/// per tranche. Callers fetch each chunk, stitch the results, and report
/// progress as `index / chunks.count`.
enum DateRangeChunker {

    /// Monthly `[start, end)` bounds covering `[from, to)`.
    static func monthlyChunks(from start: Date, to end: Date) -> [(start: Date, end: Date)] {
        guard start < end else { return [] }
        let calendar = Calendar.current
        var chunks: [(start: Date, end: Date)] = []
        var s = start
        while s < end {
            let next = calendar.date(byAdding: .month, value: 1, to: s) ?? end
            chunks.append((s, min(next, end)))
            s = next
        }
        return chunks
    }
}
