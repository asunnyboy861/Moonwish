import SwiftData
import SwiftUI

@MainActor
enum PresetPlayback {
    static func item(for track: PresetTrack) async -> PlaybackItem? {
        let url = AppConfig.sessionURL(fileName: track.fileName)
        if !AudioQuality.isValid(url: url) {
            _ = try? await AudioRenderer.shared.render(script: track.script, voiceIdentifier: nil, fileName: track.fileName)
        }
        guard AudioQuality.isValid(url: url) else { return nil }
        return PlaybackItem(
            fileName: track.fileName,
            title: track.title,
            wishText: track.subtitle,
            soundscape: "Theta Waves",
            isPreset: true,
            sessionID: nil
        )
    }
}
