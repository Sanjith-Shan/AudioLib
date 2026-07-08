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

    /// Software volume boost. 1.0 == 100% (unity, no change). Values above 1.0
    /// amplify the signal *beyond* the iPhone's hardware max via a real gain
    /// stage in the audio engine — this is what makes quiet audiobooks audible
    /// even when the phone is already at maximum volume. Persisted globally.
    static let maxVolumeBoost: Float = 3.0   // 300%
    var volumeBoost: Float = 1.0 {
        didSet {
            let clamped = min(max(volumeBoost, 0), Self.maxVolumeBoost)
            if clamped != volumeBoost { volumeBoost = clamped; return }
            applyGain()
            UserDefaults.standard.set(volumeBoost, forKey: Self.volumeBoostKey)
        }
    }
    private static let volumeBoostKey = "audiolib.volumeBoost"

    // MARK: - Audio engine graph
    // playerNode → timePitch (playback rate, pitch preserved) → eq (gain boost)
    //            → engine.mainMixerNode → output
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private let eq = AVAudioUnitEQ(numberOfBands: 0)

    private var currentFileURL: URL?
    private var sampleRate: Double = 44100
    /// Absolute position (in seconds) that the currently-scheduled segment
    /// started from. The node's own play-time is relative to the last stop(),
    /// so absolute position = startOffsetSeconds + nodePlayTime.
    private var startOffsetSeconds: Double = 0
    /// Monotonic token used to ignore stale scheduling-completion callbacks
    /// after a seek/stop reschedules the node.
    private var scheduleGeneration = 0
    /// True while playing a file that is still being written to disk by the
    /// progressive downloader; keeps re-scheduling as more audio arrives.
    private var isPartialPlayback = false
    private var partialRetryCount = 0

    private var progressTimer: Timer?
    private var sleepTimer: Timer?
    private var lastSaveTime: Date = .distantPast
    private var cachedArtwork: MPMediaItemArtwork?
    private var cachedArtworkBookID: UUID?

    private override init() {
        super.init()
        if UserDefaults.standard.object(forKey: Self.volumeBoostKey) != nil {
            let stored = UserDefaults.standard.float(forKey: Self.volumeBoostKey)
            volumeBoost = min(max(stored, 0), Self.maxVolumeBoost)
        }

        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.attach(eq)
        applyGain()

        setupRemoteCommands()
        setupAudioSessionObservers()
    }

    // MARK: - Gain

    /// Maps the 0…maxVolumeBoost multiplier onto the EQ's global gain in
    /// decibels. 1.0 → 0 dB (unity), 3.0 → ~+9.5 dB. 0 → effectively muted.
    private func applyGain() {
        if volumeBoost <= 0.001 {
            eq.globalGain = -96
        } else {
            eq.globalGain = max(-96, min(24, 20 * log10(volumeBoost)))
        }
    }

    // MARK: - Loading

    /// Plays an m4a file whose moov atom is already written but whose audio
    /// payload is still being filled in by ProgressiveDownloadManager. We keep
    /// re-reading the growing file and scheduling newly-available audio.
    func playFromPartialFile(book: Book, partialURL: URL, expectedDuration: Double) {
        stop()
        currentBook = book
        duration = expectedDuration > 0 ? expectedDuration : book.durationSeconds
        playbackRate = book.playbackRate
        cacheArtwork(for: book)

        guard FileManager.default.fileExists(atPath: partialURL.path) else { return }
        guard prepareGraph(for: partialURL) else { return }

        isPartialPlayback = true
        partialRetryCount = 0
        startPlayback(fromSeconds: book.progressSeconds)
        play()
    }

    func load(book: Book) {
        stop()
        currentBook = book
        duration = book.durationSeconds
        playbackRate = book.playbackRate
        cacheArtwork(for: book)

        let url = book.audioURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        guard prepareGraph(for: url) else { return }

        isPartialPlayback = false
        startPlayback(fromSeconds: book.progressSeconds)
    }

    private func cacheArtwork(for book: Book) {
        guard cachedArtworkBookID != book.id else { return }
        cachedArtwork = nil
        cachedArtworkBookID = book.id
        if let artURL = book.artURL,
           FileManager.default.fileExists(atPath: artURL.path),
           let image = PlatformImage(contentsOfFile: artURL.path) {
            cachedArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image.platformUIImage }
        }
    }

    /// (Re)connects the engine graph to match the file's processing format and
    /// starts the engine. Returns false if the file can't be opened.
    private func prepareGraph(for url: URL) -> Bool {
        let format: AVAudioFormat
        do {
            let file = try AVAudioFile(forReading: url)
            format = file.processingFormat
            sampleRate = format.sampleRate
        } catch {
            print("Failed to read audio format: \(error)")
            return false
        }

        currentFileURL = url

        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(timePitch)
        engine.disconnectNodeOutput(eq)
        engine.connect(playerNode, to: timePitch, format: format)
        engine.connect(timePitch, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        timePitch.rate = playbackRate
        applyGain()

        if !engine.isRunning {
            engine.prepare()
            do { try engine.start() } catch {
                print("Failed to start audio engine: \(error)")
                return false
            }
        }
        return true
    }

    /// Schedules audio starting at the given absolute position and primes state.
    /// Does not begin playback (call play()).
    private func startPlayback(fromSeconds seconds: Double) {
        scheduleGeneration += 1
        playerNode.stop()
        startOffsetSeconds = max(0, seconds)
        currentTime = startOffsetSeconds
        let startFrame = AVAudioFramePosition(startOffsetSeconds * sampleRate)
        scheduleTail(fromFrame: startFrame, generation: scheduleGeneration)
        updateNowPlayingInfo()
    }

    /// Opens a fresh handle on the (possibly still-growing) file and schedules
    /// everything from `startFrame` to the current end. On completion it looks
    /// for more audio — this both drives natural end-of-file finishing and
    /// progressive "listen while downloading" playback.
    private func scheduleTail(fromFrame startFrame: AVAudioFramePosition, generation: Int) {
        guard generation == scheduleGeneration, let url = currentFileURL else { return }

        let file: AVAudioFile
        do { file = try AVAudioFile(forReading: url) } catch { return }
        let total = file.length

        guard startFrame < total else {
            handleReachedEnd(atFrame: startFrame, generation: generation)
            return
        }

        let frameCount = AVAudioFrameCount(total - startFrame)
        playerNode.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                guard generation == self.scheduleGeneration else { return }
                self.partialRetryCount = 0
                self.scheduleTail(fromFrame: total, generation: generation)
            }
        }
    }

    /// Called when the scheduler has caught up to the end of what's on disk.
    /// For a fully-downloaded file this is the real end. For a partial file we
    /// wait briefly for more bytes before giving up.
    private func handleReachedEnd(atFrame frame: AVAudioFramePosition, generation: Int) {
        let expectedFrames = AVAudioFramePosition(duration * sampleRate)
        let caughtUpToExpected = frame >= expectedFrames - AVAudioFramePosition(sampleRate) // within ~1s

        if isPartialPlayback && !caughtUpToExpected && partialRetryCount < 40 {
            partialRetryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, generation == self.scheduleGeneration else { return }
                self.scheduleTail(fromFrame: frame, generation: generation)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePlaybackFinished(generation: generation)
            }
        }
    }

    // MARK: - Transport

    func play() {
        AudioSessionManager.shared.activate()
        if !engine.isRunning {
            engine.prepare()
            try? engine.start()
        }
        playerNode.play()
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
    }

    func pause() {
        playerNode.pause()
        isPlaying = false
        stopProgressTimer()
        saveProgress()
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: Double) {
        let clamped = max(0, min(duration > 0 ? duration : time, time))
        let wasPlaying = isPlaying
        let startFrame = AVAudioFramePosition(clamped * sampleRate)

        scheduleGeneration += 1
        playerNode.stop()
        startOffsetSeconds = clamped
        currentTime = clamped
        partialRetryCount = 0
        scheduleTail(fromFrame: startFrame, generation: scheduleGeneration)

        if wasPlaying {
            playerNode.play()
            isPlaying = true
        }
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
        timePitch.rate = rate
        currentBook?.playbackRate = rate
        try? PersistenceController.shared.container.viewContext.save()
        updateNowPlayingInfo()
    }

    func stop() {
        scheduleGeneration += 1
        playerNode.stop()
        if engine.isRunning { engine.pause() }
        currentFileURL = nil
        isPartialPlayback = false
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

            if self.isPlaying,
               let nodeTime = self.playerNode.lastRenderTime,
               let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime),
               playerTime.sampleRate > 0 {
                let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate
                self.currentTime = self.startOffsetSeconds + max(0, elapsed)
            }

            if Date().timeIntervalSince(self.lastSaveTime) >= 5 {
                self.saveProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func handlePlaybackFinished(generation: Int) {
        guard generation == scheduleGeneration else { return }
        isPlaying = false
        stopProgressTimer()
        // Reset to beginning so tapping play restarts.
        currentTime = 0
        startOffsetSeconds = 0
        if let book = currentBook {
            book.progressSeconds = 0
            try? PersistenceController.shared.container.viewContext.save()
        }
        // Re-arm from the top so the next play() has audio scheduled.
        if currentFileURL != nil {
            scheduleGeneration += 1
            playerNode.stop()
            scheduleTail(fromFrame: 0, generation: scheduleGeneration)
        }
        updateNowPlayingInfo()
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEngineConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: engine
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

    // The engine can tear down its render graph after a route change
    // (e.g. plugging in headphones). Restart it so playback survives.
    @objc private func handleEngineConfigurationChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.currentFileURL != nil, !self.engine.isRunning else { return }
            self.engine.prepare()
            try? self.engine.start()
            if self.isPlaying { self.playerNode.play() }
        }
    }
    #endif
}
