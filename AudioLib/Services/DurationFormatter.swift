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

    /// Formats a duration in seconds as HH:MM:SS (or MM:SS if under an hour).
    static func timestamp(seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
