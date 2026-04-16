import Foundation
import AVFoundation
import MediaPlayer

@Observable
class PlayerController {
    static let shared = PlayerController()

    // State
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var duration: Double = 0
    var currentBook: Book? = nil
    var playbackRate: Float = 1.0
    var isSleepTimerActive: Bool = false
    var sleepTimerEndDate: Date? = nil

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var sleepTimer: Timer?
    private var lastSaveTime: Date = .distantPast

    private init() {
        setupRemoteCommands()
    }

    func load(book: Book) {
        stop()
        currentBook = book
        duration = book.durationSeconds
        playbackRate = book.playbackRate

        let url = book.audioURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.enableRate = true
            player?.prepareToPlay()
            player?.currentTime = book.progressSeconds
            player?.rate = book.playbackRate
            updateNowPlayingInfo()
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    func play() {
        player?.rate = playbackRate
        player?.play()
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
        player?.currentTime = max(0, min(duration, time))
        currentTime = player?.currentTime ?? time
        saveProgress()
        updateNowPlayingInfo()
    }

    func skipForward(_ seconds: Double = 15) {
        seek(to: currentTime + seconds)
    }

    func skipBackward(_ seconds: Double = 15) {
        seek(to: currentTime - seconds)
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
    }

    // MARK: - Progress persistence

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.player?.currentTime ?? 0

            // Save every 5 seconds
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
        try? PersistenceController.shared.container.viewContext.save()
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

        // Album art
        if let artURL = book.artURL,
           FileManager.default.fileExists(atPath: artURL.path),
           let image = UIImage(contentsOfFile: artURL.path) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
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
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(); return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(); return .success
        }
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
}
