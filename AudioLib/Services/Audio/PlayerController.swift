import Foundation
import AVFoundation
import MediaPlayer
#if os(iOS)
import UIKit
#endif

@Observable
class PlayerController: NSObject {
    static let shared = PlayerController()

    // State
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var duration: Double = 0
    var currentBook: Book? = nil
    var playbackRate: Float = 1.0
    var isSleepTimerActive: Bool = false
    var sleepTimerEndDate: Date? = nil
    var volume: Float = 1.0 {
        didSet { player?.volume = volume }
    }

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var sleepTimer: Timer?
    private var lastSaveTime: Date = .distantPast
    private var cachedArtwork: MPMediaItemArtwork?
    private var cachedArtworkBookID: UUID?

    private override init() {
        super.init()
        setupRemoteCommands()
        setupAudioSessionObservers()
    }

    // Plays an m4a file whose moov atom is already written but whose audio payload
    // is still being filled in by ProgressiveDownloadManager. AVAudioPlayer reads
    // sequentially so it will happily keep reading past its original end offset as
    // new bytes arrive on disk.
    func playFromPartialFile(book: Book, partialURL: URL, expectedDuration: Double) {
        stop()
        currentBook = book
        duration = expectedDuration > 0 ? expectedDuration : book.durationSeconds
        playbackRate = book.playbackRate

        if cachedArtworkBookID != book.id {
            cachedArtwork = nil
            cachedArtworkBookID = book.id
            if let artURL = book.artURL,
               FileManager.default.fileExists(atPath: artURL.path),
               let image = PlatformImage(contentsOfFile: artURL.path) {
                cachedArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image.platformUIImage }
            }
        }

        guard FileManager.default.fileExists(atPath: partialURL.path) else { return }

        do {
            player = try AVAudioPlayer(contentsOf: partialURL)
            player?.delegate = self
            player?.enableRate = true
            player?.volume = volume
            player?.prepareToPlay()
            player?.currentTime = book.progressSeconds
            updateNowPlayingInfo()
            play()
        } catch {
            print("Failed to load partial audio: \(error)")
        }
    }

    func load(book: Book) {
        stop()
        currentBook = book
        duration = book.durationSeconds
        playbackRate = book.playbackRate

        if cachedArtworkBookID != book.id {
            cachedArtwork = nil
            cachedArtworkBookID = book.id
            if let artURL = book.artURL,
               FileManager.default.fileExists(atPath: artURL.path),
               let image = PlatformImage(contentsOfFile: artURL.path) {
                cachedArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image.platformUIImage }
            }
        }

        let url = book.audioURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.enableRate = true
            player?.volume = volume
            player?.prepareToPlay()
            player?.currentTime = book.progressSeconds
            updateNowPlayingInfo()
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    func play() {
        // Activate the audio session lazily, right before playback actually
        // begins. This avoids the iOS 26 `NSOSStatusErrorDomain -50` that can
        // fire when activating at app launch.
        AudioSessionManager.shared.activate()
        player?.play()
        player?.rate = playbackRate  // must be set AFTER play() or it resets to 1.0
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        saveProgress()
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: Double) {
        let effective = player != nil ? player!.duration : duration
        let clamped = max(0, min(effective > 0 ? effective : duration, time))
        player?.currentTime = clamped
        currentTime = player?.currentTime ?? clamped
        saveProgress()
        updateNowPlayingInfo()
    }

    func skipForward() {
        let interval = UserDefaults.standard.double(forKey: "audiolib.defaultSkipInterval")
        seek(to: currentTime + (interval > 0 ? interval : 15))
    }

    func skipBackward() {
        let interval = UserDefaults.standard.double(forKey: "audiolib.defaultSkipInterval")
        seek(to: currentTime - (interval > 0 ? interval : 15))
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
        currentBook?.playbackRate = rate
        try? PersistenceController.shared.container.viewContext.save()
        updateNowPlayingInfo()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        stopProgressTimer()
        sleepTimer?.invalidate()
        sleepTimer = nil
        isSleepTimerActive = false
        sleepTimerEndDate = nil
        saveProgress()
    }

    func setSleepTimer(seconds: Double?) {
        sleepTimer?.invalidate()
        sleepTimer = nil
        isSleepTimerActive = false
        sleepTimerEndDate = nil

        guard let seconds = seconds else { return }
        isSleepTimerActive = true
        let end = Date().addingTimeInterval(seconds)
        sleepTimerEndDate = end
        sleepTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.pause()
            self?.isSleepTimerActive = false
            self?.sleepTimerEndDate = nil
        }
    }

    func addBookmark(note: String? = nil) {
        guard let book = currentBook else { return }
        let context = PersistenceController.shared.container.viewContext
        let bookmark = Bookmark(context: context)
        bookmark.id = UUID()
        bookmark.timeSeconds = currentTime
        bookmark.note = note
        bookmark.createdAt = Date()
        bookmark.book = book
        try? context.save()
        Haptics.success()
    }

    // MARK: - Progress persistence

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.player?.currentTime ?? 0

            if Date().timeIntervalSince(self.lastSaveTime) >= 5 {
                self.saveProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func saveProgress() {
        guard let book = currentBook else { return }
        lastSaveTime = Date()
        book.progressSeconds = currentTime
        book.lastPlayedAt = Date()
        try? PersistenceController.shared.container.viewContext.save()

        let bookID = book.id
        let progress = currentTime
        let title = book.title
        let sourceURL = book.sourceURL
        let duration = book.durationSeconds
        let audioFilename = book.audioFilename
        let artFilename = book.artFilename
        Task {
            await SyncService.shared.pushProgress(
                bookID: bookID,
                progressSeconds: progress,
                title: title,
                sourceURL: sourceURL,
                durationSeconds: duration,
                audioFilename: audioFilename,
                artFilename: artFilename
            )
        }
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        guard let book = currentBook else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: book.title,
            MPMediaItemPropertyArtist: book.author ?? "",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: Double(playbackRate)
        ]

        if let artwork = cachedArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play(); return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause(); return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause(); return .success
        }
        let storedInterval = UserDefaults.standard.double(forKey: "audiolib.defaultSkipInterval")
        let skipIntervalNumber = NSNumber(value: storedInterval > 0 ? storedInterval : 15)
        center.skipForwardCommand.preferredIntervals = [skipIntervalNumber]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(); return .success
        }
        center.skipBackwardCommand.preferredIntervals = [skipIntervalNumber]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(); return .success
        }
        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: e.positionTime)
            return .success
        }
        center.changePlaybackRateCommand.supportedPlaybackRates = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
        center.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            self?.setRate(Float(e.playbackRate))
            return .success
        }
    }

    // MARK: - Audio Session Observers

    private func setupAudioSessionObservers() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        #endif
    }

    #if os(iOS)
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            if isPlaying { pause() }
        } else if type == .ended {
            let opts = AVAudioSession.InterruptionOptions(
                rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            )
            if opts.contains(.shouldResume) { play() }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable else { return }

        let prev = info[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
        let wasHeadphones = prev?.outputs.first.map {
            $0.portType == .headphones || $0.portType == .bluetoothA2DP || $0.portType == .bluetoothLE
        } ?? false

        if wasHeadphones && isPlaying {
            DispatchQueue.main.async { [weak self] in self?.pause() }
        }
    }
    #endif
}

// MARK: - AVAudioPlayerDelegate

extension PlayerController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.stopProgressTimer()
            // Reset to beginning so tapping play restarts
            self.currentTime = 0
            if let book = self.currentBook {
                book.progressSeconds = 0
                try? PersistenceController.shared.container.viewContext.save()
            }
            self.updateNowPlayingInfo()
        }
    }
}
