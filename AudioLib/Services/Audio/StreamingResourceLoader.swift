import AVFoundation
import Foundation

let kStreamingScheme = "audiolib-stream"

final class StreamingResourceLoader: NSObject, AVAssetResourceLoaderDelegate {

    private let progressiveManager: ProgressiveDownloadManager
    private let contentType: String
    private var pendingRequests: [AVAssetResourceLoadingRequest] = []
    private let queue = DispatchQueue(label: "audiolib.resourceloader", qos: .userInitiated)

    init(progressiveManager: ProgressiveDownloadManager, fileExtension: String) {
        self.progressiveManager = progressiveManager
        self.contentType = Self.contentType(for: fileExtension)
    }

    func chunkDidComplete() {
        queue.async { [weak self] in
            self?.processPendingRequests()
        }
    }

    // MARK: - AVAssetResourceLoaderDelegate

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        queue.async { [weak self] in
            self?.handle(loadingRequest)
        }
        return true
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        queue.async { [weak self] in
            self?.pendingRequests.removeAll { $0 === loadingRequest }
        }
    }

    // MARK: - Private

    private func handle(_ request: AVAssetResourceLoadingRequest) {
        if let info = request.contentInformationRequest {
            info.contentType = contentType
            info.contentLength = progressiveManager.totalBytes
            info.isByteRangeAccessSupported = true
            if progressiveManager.totalBytes <= 0 {
                pendingRequests.append(request)
                return
            }
        }

        if request.dataRequest != nil {
            if !processDataRequest(request) {
                pendingRequests.append(request)
            }
        } else if request.contentInformationRequest != nil {
            request.finishLoading()
        }
    }

    private func processDataRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let dataReq = request.dataRequest else { return true }

        var currentOffset = dataReq.currentOffset
        let endOffset = dataReq.requestedOffset + Int64(dataReq.requestedLength) - 1

        while currentOffset <= endOffset {
            let remaining = Int(endOffset - currentOffset + 1)
            let chunkLen = min(1024 * 1024, remaining)
            if progressiveManager.isAvailable(from: currentOffset, length: chunkLen) {
                guard let data = progressiveManager.readData(offset: currentOffset, length: chunkLen) else {
                    return false
                }
                dataReq.respond(with: data)
                currentOffset += Int64(data.count)
                if data.count < chunkLen { return false }
            } else {
                return false
            }
        }

        request.finishLoading()
        return true
    }

    private func processPendingRequests() {
        var stillPending: [AVAssetResourceLoadingRequest] = []
        for request in pendingRequests {
            if request.isCancelled { continue }
            // Re-fill contentInformationRequest if it was deferred (totalBytes unknown).
            if let info = request.contentInformationRequest, info.contentLength == 0,
               progressiveManager.totalBytes > 0 {
                info.contentLength = progressiveManager.totalBytes
            }
            if request.dataRequest == nil && request.contentInformationRequest != nil
               && progressiveManager.totalBytes > 0 {
                request.finishLoading()
                continue
            }
            if processDataRequest(request) {
                continue
            }
            stillPending.append(request)
        }
        pendingRequests = stillPending
    }

    private static func contentType(for ext: String) -> String {
        switch ext.lowercased() {
        case "m4a":  return "public.mpeg-4-audio"
        case "webm": return "org.webmproject.webm"
        case "opus": return "public.opus"
        default:     return "public.audio"
        }
    }
}
