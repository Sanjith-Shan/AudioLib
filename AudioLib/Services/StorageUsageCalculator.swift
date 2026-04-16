import Foundation

struct StorageUsageCalculator {
    struct Usage {
        let audioBytes: Int64
        let artBytes: Int64
        var totalBytes: Int64 { audioBytes + artBytes }

        func formatted() -> String {
            let total = Double(totalBytes)
            if total < 1_000 { return "\(totalBytes) B" }
            if total < 1_000_000 { return String(format: "%.1f KB", total / 1_000) }
            if total < 1_000_000_000 { return String(format: "%.1f MB", total / 1_000_000) }
            return String(format: "%.2f GB", total / 1_000_000_000)
        }
    }

    static func calculate() -> Usage {
        let audio = directorySize(at: FileStore.audioDir)
        let art = directorySize(at: FileStore.artDir)
        return Usage(audioBytes: audio, artBytes: art)
    }

    private static func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]
        ) else { return 0 }

        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            size += Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return size
    }
}
