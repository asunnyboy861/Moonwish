import AVFoundation
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class PlaybackService: ObservableObject {
    static let shared = PlaybackService()

    @Published var isPlaying: Bool = false
    @Published var currentTitle: String = ""
    @Published var currentSessionID: UUID?
    @Published var elapsed: Double = 0
    @Published var duration: Double = 1
    @Published var activeSoundscape: String = "Theta Waves"
    @Published var overnightMode: Bool = false
    @Published var sleepDeadline: Date?

    var onPlaybackStarted: ((UUID) -> Void)?

    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var soundscapePlayer: AVAudioPlayer?
    private var timeObserver: Any?
    private var sleepTimer: Timer?
    private var baseVolume: Float = 1.0

    private init() {
        configureSession()
        configureRemoteCommands()
    }

    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    func play(fileName: String, title: String, sessionID: UUID?, soundscape: String, withSoundscape: Bool) {
        let url = AppConfig.sessionURL(fileName: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        stopPlayerOnly()

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.actionAtItemEnd = .advance
        queuePlayer.volume = 1.0
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer
        looper = playerLooper
        currentTitle = title
        currentSessionID = sessionID
        activeSoundscape = soundscape

        let asset = AVURLAsset(url: url)
        Task {
            if let loaded = try? await asset.load(.duration) {
                duration = max(1, loaded.seconds)
            }
        }

        addTimeObserver(to: queuePlayer)
        queuePlayer.play()
        isPlaying = true

        if withSoundscape {
            startSoundscape(named: soundscape)
        }
        updateNowPlaying()
        if let sessionID {
            onPlaybackStarted?(sessionID)
        }
    }

    func startSoundscape(named name: String) {
        soundscapePlayer?.stop()
        guard let style = SoundscapeCatalog.style(named: name),
              let url = SoundscapeLibrary.shared.fileURL(for: style) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.22
            player.prepareToPlay()
            player.play()
            soundscapePlayer = player
        } catch {
            soundscapePlayer = nil
        }
    }

    func setSoundscape(named name: String) {
        activeSoundscape = name
        startSoundscape(named: name)
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            soundscapePlayer?.pause()
            isPlaying = false
        } else {
            player.play()
            soundscapePlayer?.play()
            isPlaying = true
            updateNowPlaying()
        }
    }

    func setSleepTimer(minutes: Int?) {
        sleepTimer?.invalidate()
        sleepTimer = nil
        guard let minutes else {
            sleepDeadline = nil
            return
        }
        let deadline = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepDeadline = deadline
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let deadline = self.sleepDeadline else { return }
                let remaining = deadline.timeIntervalSinceNow
                if remaining <= 0 {
                    self.stop()
                } else if remaining <= 30 {
                    self.player?.volume = self.baseVolume * Float(remaining / 30)
                    self.soundscapePlayer?.volume = 0.22 * Float(remaining / 30)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        sleepTimer = timer
        if let player {
            baseVolume = player.volume
        }
    }

    func stop() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepDeadline = nil
        stopPlayerOnly()
        isPlaying = false
        elapsed = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func stopPlayerOnly() {
        player?.pause()
        player = nil
        looper = nil
        soundscapePlayer?.stop()
        soundscapePlayer = nil
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
    }

    private func addTimeObserver(to player: AVQueuePlayer) {
        let interval = CMTime(seconds: 1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.elapsed = time.seconds
            }
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentTitle,
            MPMediaItemPropertyArtist: "Moonwish",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
}
