import Foundation

enum ResolverMode: String {
    case onDevice = "onDevice"
    case companion = "companion"
}

class YouTubeResolverFactory {
    static func makeResolver() -> any YouTubeResolver {
        let mode = ResolverMode(rawValue: UserDefaults.standard.string(forKey: "audiolib.resolverMode") ?? "") ?? .onDevice
        switch mode {
        case .onDevice:
            return OnDeviceYouTubeResolver()
        case .companion:
            let host = UserDefaults.standard.string(forKey: "audiolib.companionHost") ?? "localhost"
            let port = UserDefaults.standard.integer(forKey: "audiolib.companionPort")
            return CompanionServerResolver(host: host, port: port == 0 ? 8787 : port)
        }
    }
}
