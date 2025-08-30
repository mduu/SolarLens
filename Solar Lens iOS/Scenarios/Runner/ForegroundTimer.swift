import Foundation

actor ForegroundTimer {
    nonisolated let action: (() -> Void)

    static private let interval: TimeInterval = 5
    private var timer: Timer?

    init(action: @escaping (() -> Void)) {
        self.action = action
    }

    public func startTimer() {
        stopTimer()
        timer =
            Timer
            .scheduledTimer(
                withTimeInterval: ForegroundTimer.interval,
                repeats: true
            ) { [weak self] _ in
                self?.timerFired()
            }
    }

    public func stopTimer() {
        if let timer = timer, timer.isValid {
            timer.invalidate()
        }
        self.timer = nil
    }

    nonisolated func timerFired() {
        print("ForegroundTimer: Timer fired!")
        action()
    }

}
