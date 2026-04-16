import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func activate() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetoothA2DP, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession failed: \(error)")
        }
    }
}
