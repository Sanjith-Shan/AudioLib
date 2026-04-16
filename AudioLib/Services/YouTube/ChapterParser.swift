import Foundation

struct ChapterParser {
    // Parses lines like "0:00 Introduction" or "1:23:45 Chapter Title"
    // Returns sorted array of YTChapter
    static func parse(from description: String) -> [YTChapter] {
        var chapters: [YTChapter] = []
        let lines = description.components(separatedBy: .newlines)

        // Pattern: optional hours, required minutes:seconds, then whitespace + title
        // Matches: "0:00 Intro", "1:23 Title", "1:23:45 Long Title"
        let pattern = #"^((\d{1,2}:)?\d{1,2}:\d{2})\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let range = NSRange(trimmed.startIndex..., in: trimmed)
            guard let match = regex.firstMatch(in: trimmed, range: range) else { continue }

            // Extract timestamp string (group 1)
            guard let timestampRange = Range(match.range(at: 1), in: trimmed),
                  let titleRange = Range(match.range(at: 3), in: trimmed) else { continue }

            let timestamp = String(trimmed[timestampRange])
            let title = String(trimmed[titleRange]).trimmingCharacters(in: .whitespaces)

            guard !title.isEmpty, let seconds = parseTimestamp(timestamp) else { continue }

            chapters.append(YTChapter(title: title, startSeconds: seconds))
        }

        return chapters.sorted { $0.startSeconds < $1.startSeconds }
    }

    // Converts "M:SS", "MM:SS", or "H:MM:SS" / "HH:MM:SS" to total seconds
    private static func parseTimestamp(_ timestamp: String) -> Double? {
        let parts = timestamp.components(separatedBy: ":")
        switch parts.count {
        case 2:
            guard let minutes = Double(parts[0]), let seconds = Double(parts[1]) else { return nil }
            return minutes * 60 + seconds
        case 3:
            guard let hours = Double(parts[0]), let minutes = Double(parts[1]), let seconds = Double(parts[2]) else { return nil }
            return hours * 3600 + minutes * 60 + seconds
        default:
            return nil
        }
    }
}
