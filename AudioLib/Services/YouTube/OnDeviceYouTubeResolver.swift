import Foundation
import YouTubeKit

@available(iOS 13.0, *)
actor OnDeviceYouTubeResolver: YouTubeResolver {

    func resolve(url: URL) async throws -> YTMetadata {
        guard let videoID = extractVideoID(from: url) else {
            throw YouTubeResolverError.invalidURL
        }

        let yt = YouTube(videoID: videoID)

        // Fetch streams and metadata concurrently
        let streams: [YouTubeKit.Stream]
        do {
            streams = try await yt.streams
        } catch {
            throw YouTubeResolverError.networkError(error)
        }

        // Filter to audio-only streams
        let audioOnlyStreams = streams.filter { $0.includesAudioTrack && !$0.includesVideoTrack }

        // Prefer AAC/m4a (mp4a codec) streams
        let aacStreams = audioOnlyStreams.filter { stream in
            if case .mp4a = stream.audioCodec { return true }
            return false
        }

        let selectedStream: YouTubeKit.Stream
        if let best = bestStream(from: aacStreams) {
            selectedStream = best
        } else if let best = bestStream(from: audioOnlyStreams) {
            // Only opus/webm available — we don't transcode on device
            _ = best
            throw YouTubeResolverError.noAudioStream
        } else {
            throw YouTubeResolverError.noAudioStream
        }

        let fileExt = selectedStream.fileExtension == .m4a ? "m4a" : selectedStream.fileExtension.rawValue

        // Fetch metadata (title, description, thumbnail)
        let ytMetadata = try? await yt.metadata
        let title = ytMetadata?.title ?? "Unknown Title"

        // Parse chapters from description if available
        let chapters: [YTChapter]
        if let description = ytMetadata?.description, !description.isEmpty {
            chapters = ChapterParser.parse(from: description)
        } else {
            chapters = []
        }

        // Build thumbnail URL from video ID
        let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(videoID)/maxresdefault.jpg")!

        return YTMetadata(
            videoID: videoID,
            title: title,
            uploader: "Unknown",   // Not exposed in YouTubeKit v0.4.8 public API
            durationSeconds: 0,    // Not exposed in YouTubeKit v0.4.8 public API
            thumbnailURL: thumbnailURL,
            audioStreamURL: selectedStream.url,
            fileExtension: fileExt,
            chapters: chapters
        )
    }

    // Pick the stream with the highest bitrate
    private func bestStream(from streams: [YouTubeKit.Stream]) -> YouTubeKit.Stream? {
        streams.max {
            let lhs = $0.averageBitrate ?? $0.bitrate ?? 0
            let rhs = $1.averageBitrate ?? $1.bitrate ?? 0
            return lhs < rhs
        }
    }

    // Handles:
    //   https://www.youtube.com/watch?v=XXXXXXXXXXX
    //   https://youtu.be/XXXXXXXXXXX
    //   https://youtube.com/shorts/XXXXXXXXXXX
    private func extractVideoID(from url: URL) -> String? {
        let urlString = url.absoluteString

        // youtu.be/<id>
        if url.host == "youtu.be" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if isValidVideoID(id) { return id }
        }

        // youtube.com/watch?v=<id>
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItem = components.queryItems?.first(where: { $0.name == "v" }),
           let id = queryItem.value,
           isValidVideoID(id) {
            return id
        }

        // youtube.com/shorts/<id> or youtube.com/embed/<id>
        let pathComponents = url.pathComponents
        for (i, component) in pathComponents.enumerated() {
            if (component == "shorts" || component == "embed" || component == "v"),
               let nextIndex = pathComponents.indices.first(where: { $0 == i + 1 }) {
                let id = pathComponents[nextIndex]
                if isValidVideoID(id) { return id }
            }
        }

        // Fallback: use YouTubeKit's own extraction
        _ = urlString
        return nil
    }

    private func isValidVideoID(_ id: String) -> Bool {
        id.count == 11 && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}
