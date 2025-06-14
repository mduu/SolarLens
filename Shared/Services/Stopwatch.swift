import Foundation

struct Stopwatch {
    private var startTime: DispatchTime?
    private var endTime: DispatchTime?

    init(startImmediatelly: Bool = true) {
        if startImmediatelly {
            start()
        }
    }
    
    var isRunning: Bool {
        startTime != nil && endTime == nil
    }

    mutating func start() {
        if startTime == nil {
            startTime = .now()
            endTime = nil
        }
    }

    mutating func stop() {
        if startTime != nil && endTime == nil {
            endTime = .now()
        }
    }

    mutating func reset() {
        startTime = nil
        endTime = nil
    }

    func elapsedNanoseconds() -> UInt64? {
        guard let start = startTime, let end = endTime else {
            return nil
        }
        return end.uptimeNanoseconds - start.uptimeNanoseconds
    }

    func elapsedMilliseconds() -> Double? {
        guard let nanoseconds = elapsedNanoseconds() else {
            return nil
        }
        return Double(nanoseconds) / 1_000_000.0
    }

    func elapsedSeconds() -> Double? {
        guard let nanoseconds = elapsedNanoseconds() else {
            return nil
        }
        return Double(nanoseconds) / 1_000_000_000.0
    }
}
