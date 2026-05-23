import Foundation

struct MacDownloadProgress {
    let status: String        // "pending", "downloading", "done", "failed"
    let percent: Double       // 0–100
    let speedBytesPerSec: Double
    let etaSeconds: Double?
    let title: String
    let fileExtension: String
    let error: String?
}

actor CompanionDownloader {

    static let shared = CompanionDownloader()

    private func baseURL() -> String? {
        let host = UserDefaults.standard.string(forKey: "audiolib.companionHost") ?? ""
        let port = UserDefaults.standard.integer(forKey: "audiolib.companionPort")
        guard !host.isEmpty else { return nil }
        let p = port > 0 ? port : 8787
        return "http://\(host):\(p)"
    }

    var isConfigured: Bool {
        baseURL() != nil
    }

    // Start a Mac-side download job. Returns the jobID.
    func startJob(youtubeURL: String) async throws -> String {
        guard let base = baseURL() else { throw CompanionError.notConfigured }
        let url = URL(string: "\(base)/download/start")!
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["url": youtubeURL])
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONDecoder().decode([String: String].self, from: data)
        guard let jobID = json["jobID"] else { throw CompanionError.badResponse }
        return jobID
    }

    // Poll for Mac download progress. Returns nil if job not found.
    func pollProgress(jobID: String) async throws -> MacDownloadProgress? {
        guard let base = baseURL() else { throw CompanionError.notConfigured }
        let url = URL(string: "\(base)/download/\(jobID)/progress")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let json = try JSONDecoder().decode([String: JSONValue].self, from: data)
        return MacDownloadProgress(
            status: json["status"]?.string ?? "unknown",
            percent: json["percent"]?.double ?? 0,
            speedBytesPerSec: json["speedBytesPerSec"]?.double ?? 0,
            etaSeconds: json["etaSeconds"]?.double,
            title: json["title"]?.string ?? "",
            fileExtension: json["fileExtension"]?.string ?? "m4a",
            error: json["error"]?.string
        )
    }

    // Download the finished file from Mac to outputURL, reporting progress via callback.
    // onProgress: (bytesReceived, totalBytes)
    func downloadFile(
        jobID: String,
        to outputURL: URL,
        onProgress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws {
        guard let base = baseURL() else { throw CompanionError.notConfigured }
        let url = URL(string: "\(base)/download/\(jobID)/file")!

        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CompanionError.badResponse
        }
        let totalBytes = Int64(http.value(forHTTPHeaderField: "Content-Length") ?? "0") ?? 0

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: outputURL)
        defer { try? handle.close() }

        var received: Int64 = 0
        var buffer = Data(capacity: 65536)

        for try await byte in asyncBytes {
            buffer.append(byte)
            if buffer.count >= 65536 {
                handle.write(buffer)
                received += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                onProgress(received, totalBytes)
            }
        }
        if !buffer.isEmpty {
            handle.write(buffer)
            received += Int64(buffer.count)
            onProgress(received, totalBytes)
        }
    }

    enum CompanionError: LocalizedError {
        case notConfigured
        case badResponse
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Companion server not configured."
            case .badResponse: return "Unexpected response from companion server."
            }
        }
    }
}

// Minimal JSON value type for heterogeneous JSON decoding
enum JSONValue: Decodable {
    case string(String), double(Double), bool(Bool), null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let s = try? c.decode(String.self) {
            self = .string(s)
        } else if let d = try? c.decode(Double.self) {
            self = .double(d)
        } else if let b = try? c.decode(Bool.self) {
            self = .bool(b)
        } else {
            self = .null
        }
    }

    var string: String? { if case .string(let s) = self { return s }; return nil }
    var double: Double? {
        if case .double(let d) = self { return d }
        if case .string(let s) = self { return Double(s) }
        return nil
    }
}
