import Foundation

// Shared metadata type returned by any resolver
struct YTMetadata {
    let videoID: String
    let title: String
    let uploader: String
    let durationSeconds: Double
    let thumbnailURL: URL
    let audioStreamURL: URL
    let fileExtension: String  // "m4a" or "webm"
    let chapters: [YTChapter]
    // Extra HTTP headers the resolver needs applied to the download request (e.g. from yt-dlp)
    var downloadHeaders: [String: String] = [:]
}

struct YTChapter {
    let title: String
    let startSeconds: Double
}

enum YouTubeResolverError: LocalizedError {
    case invalidURL
    case noAudioStream
    case networkError(Error)
    case serverError(String)
    case streamExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid YouTube URL"
        case .noAudioStream: return "No compatible audio stream found. Try the companion server."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .serverError(let msg): return "Server error: \(msg)"
        case .streamExpired: return "Stream expired. Please try again."
        }
    }
}

protocol YouTubeResolver {
    func resolve(url: URL) async throws -> YTMetadata
}
