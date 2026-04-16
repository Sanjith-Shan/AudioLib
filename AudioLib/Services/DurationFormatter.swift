import Foundation

enum DurationFormatter {
    /// Formats a duration in seconds to a human-readable string.
    /// - < 60s:    "45s"
    /// - < 3600s:  "12m 08s"
    /// - >= 3600s: "4h 32m"
    static func string(from seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        } else if minutes > 0 {
            return "\(minutes)m \(String(format: "%02d", secs))s"
        } else {
            return "\(secs)s"
        }
    }

    /// Returns a "X remaining" string based on total duration and current progress.
    static func remainingString(total: Double, progress: Double) -> String {
        let remaining = max(0, total - progress)
        return "\(string(from: remaining)) remaining"
    }

    /// Alias for `string(from:)` — formats seconds as a human-readable time string.
    static func format(seconds: Double) -> String {
        string(from: seconds)
    }
}
