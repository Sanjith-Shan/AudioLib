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

        // Prefer m4a over webm/opus. AVAudioPlayer can play partially-written m4a files
        // (moov atom is at the front, audio payload follows), enabling instant-playback
        // via ProgressiveDownloadManager. webm's seek tables make partial playback unreliable.
        let m4aStreams = audioOnlyStreams.filter { $0.fileExtension == .m4a }
        let selectedStream: YouTubeKit.Stream? =
            lowestBitrateStream(from: m4aStreams) ?? lowestBitrateStream(from: audioOnlyStreams)

        guard let selectedStream else {
            throw YouTubeResolverError.noAudioStream
        }

        let fileExt: String
        switch selectedStream.fileExtension {
        case .m4a:  fileExt = "m4a"
        case .webm: fileExt = "webm"
        default:    fileExt = selectedStream.fileExtension.rawValue
        }

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

    private func lowestBitrateStream(from streams: [YouTubeKit.Stream]) -> YouTubeKit.Stream? {
        streams.min {
            let lhs = $0.averageBitrate ?? $0.bitrate ?? Int.max
            let rhs = $1.averageBitrate ?? $1.bitrate ?? Int.max
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
