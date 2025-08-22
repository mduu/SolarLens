import Foundation

actor ForegroundTimer {
    nonisolated let action: (() -> Void)? = nil

    private var timer: Timer?

    public func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true)
        { [weak self] _ in
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
        action?()
    }

}
