import Foundation

actor CompanionServerResolver: YouTubeResolver {
    private let baseURL: URL

    init(host: String, port: Int = 8787) {
        self.baseURL = URL(string: "http://\(host):\(port)")!
    }

    func resolve(url: URL) async throws -> YTMetadata {
        let resolveURL = baseURL.appendingPathComponent("resolve")

        var request = URLRequest(url: resolveURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["url": url.absoluteString])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw YouTubeResolverError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw YouTubeResolverError.serverError(message)
        }

        let decoded = try JSONDecoder().decode(CompanionResponse.self, from: data)

        guard let audioStreamURL = URL(string: decoded.audioStreamURL) else {
            throw YouTubeResolverError.serverError("Invalid audio stream URL in server response")
        }
        guard let thumbnailURL = URL(string: decoded.thumbnailURL) else {
            throw YouTubeResolverError.serverError("Invalid thumbnail URL in server response")
        }

        let chapters = decoded.chapters.map {
            YTChapter(title: $0.title, startSeconds: $0.startSeconds)
        }

        return YTMetadata(
            videoID: decoded.videoID,
            title: decoded.title,
            uploader: decoded.uploader,
            durationSeconds: decoded.durationSeconds,
            thumbnailURL: thumbnailURL,
            audioStreamURL: audioStreamURL,
            fileExtension: decoded.fileExtension,
            chapters: chapters,
            downloadHeaders: decoded.httpHeaders ?? [:]
        )
    }
}

// MARK: - Decodable response types

private struct CompanionResponse: Decodable {
    let videoID: String
    let title: String
    let uploader: String
    let durationSeconds: Double
    let thumbnailURL: String
    let audioStreamURL: String
    let fileExtension: String
    let chapters: [ChapterResponse]
    let httpHeaders: [String: String]?

    enum CodingKeys: String, CodingKey {
        case videoID = "videoID"
        case title
        case uploader
        case durationSeconds
        case thumbnailURL = "thumbnailURL"
        case audioStreamURL = "audioStreamURL"
        case fileExtension
        case chapters
        case httpHeaders
    }
}

private struct ChapterResponse: Decodable {
    let title: String
    let startSeconds: Double
}
