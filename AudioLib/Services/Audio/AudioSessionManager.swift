#if os(iOS)
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()

    private var didActivate = false
    private let lock = NSLock()

    private init() {}

    /// Configures and activates the shared audio session for playback.
    ///
    /// Robust against iOS 26 returning `NSOSStatusErrorDomain -50`
    /// (`kAudio_ParamError`) when certain category/mode/options combinations
    /// are rejected. Falls back progressively to simpler configurations.
    func activate() {
        lock.lock()
        let already = didActivate
        lock.unlock()
        if already { return }

        let session = AVAudioSession.sharedInstance()

        // Preferred: spoken-audio mode with AirPlay + Bluetooth options.
        do {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
            markActivated()
            return
        } catch {
            print("AudioSession preferred config failed: \(error). Falling back.")
        }

        // Fallback 1: playback category with the same options but default mode.
        do {
            try session.setCategory(
                .playback,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
            markActivated()
            return
        } catch {
            print("AudioSession fallback 1 failed: \(error). Trying minimal config.")
        }

        // Fallback 2: minimal .playback with no options.
        do {
            try session.setCategory(.playback)
            try session.setActive(true)
            markActivated()
        } catch {
            print("AudioSession minimal config failed: \(error)")
        }
    }

    private func markActivated() {
        lock.lock()
        didActivate = true
        lock.unlock()
    }
}

#else

class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}
    func activate() {}
}

#endif
