internal import Foundation

extension TimeInterval {

    func formatAsHMS() -> LocalizedStringResource {
        let totalSeconds = abs(Int(self))  // Get total seconds as an integer, use absolute value
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            let value = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            return "\(value) ago"
        }

        if minutes > 1 {
            let value = String(format: "%02d:%02d", minutes, seconds)
            return "\(value) ago"
        }

        if seconds >= 5 {
            let value = String(format: "%01ds", seconds)
            return "\(value) ago"
        }

        return "just now"
    }
}
