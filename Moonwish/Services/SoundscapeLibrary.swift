import AVFoundation
import Foundation

struct SoundscapeStyle: Identifiable, Hashable {
    let id: Int
    let name: String
    let icon: String
    let isPremium: Bool
    let tone: Double
    let modulation: Double
    let noise: Double
}

enum SoundscapeCatalog {
    static let all: [SoundscapeStyle] = [
        SoundscapeStyle(id: 0, name: "Theta Waves", icon: "waveform", isPremium: false, tone: 220, modulation: 6, noise: 0.0),
        SoundscapeStyle(id: 1, name: "432 Hz", icon: "tuningfork", isPremium: false, tone: 432, modulation: 2, noise: 0.0),
        SoundscapeStyle(id: 2, name: "Soft Rain", icon: "cloud.rain.fill", isPremium: false, tone: 120, modulation: 1, noise: 0.35),
        SoundscapeStyle(id: 3, name: "Ocean Breath", icon: "water.waves", isPremium: true, tone: 90, modulation: 0.4, noise: 0.2),
        SoundscapeStyle(id: 4, name: "Night Forest", icon: "tree.fill", isPremium: true, tone: 160, modulation: 0.2, noise: 0.18),
        SoundscapeStyle(id: 5, name: "Ember Glow", icon: "flame.fill", isPremium: true, tone: 110, modulation: 0.6, noise: 0.22),
        SoundscapeStyle(id: 6, name: "Lo-Fi Dusk", icon: "headphones", isPremium: true, tone: 196, modulation: 0.3, noise: 0.08),
        SoundscapeStyle(id: 7, name: "Moon Halo", icon: "moon.circle.fill", isPremium: true, tone: 528, modulation: 3, noise: 0.04),
        SoundscapeStyle(id: 8, name: "Deep Delta", icon: "water.waves.and.arrow.down", isPremium: true, tone: 110, modulation: 2, noise: 0.04),
        SoundscapeStyle(id: 9, name: "Alpha Drift", icon: "waveform.path", isPremium: true, tone: 198, modulation: 8, noise: 0.03),
        SoundscapeStyle(id: 10, name: "Starlight", icon: "star.fill", isPremium: true, tone: 660, modulation: 1, noise: 0.02),
        SoundscapeStyle(id: 11, name: "Silk Wind", icon: "wind", isPremium: true, tone: 80, modulation: 0.5, noise: 0.28),
        SoundscapeStyle(id: 12, name: "Warm Sand", icon: "sun.max.fill", isPremium: true, tone: 140, modulation: 0.3, noise: 0.16),
        SoundscapeStyle(id: 13, name: "Velvet Chords", icon: "pianokeys", isPremium: true, tone: 261, modulation: 0.2, noise: 0.0),
        SoundscapeStyle(id: 14, name: "Cedar Room", icon: "leaf.fill", isPremium: true, tone: 170, modulation: 0.4, noise: 0.1),
        SoundscapeStyle(id: 15, name: "Slow Tide", icon: "water.waves", isPremium: true, tone: 100, modulation: 0.25, noise: 0.3),
        SoundscapeStyle(id: 16, name: "Glass Lake", icon: "sparkles", isPremium: true, tone: 396, modulation: 2, noise: 0.06),
        SoundscapeStyle(id: 17, name: "Quiet Bells", icon: "bell.fill", isPremium: true, tone: 528, modulation: 0.1, noise: 0.0),
        SoundscapeStyle(id: 18, name: "Pillow Drone", icon: "moon.zzz.fill", isPremium: true, tone: 150, modulation: 1.5, noise: 0.02),
        SoundscapeStyle(id: 19, name: "Golden Hour", icon: "sun.horizon.fill", isPremium: true, tone: 320, modulation: 0.2, noise: 0.08),
        SoundscapeStyle(id: 20, name: "Silence", icon: "speaker.slash.fill", isPremium: true, tone: 0, modulation: 0, noise: 0)
    ]

    static func style(named name: String) -> SoundscapeStyle? {
        all.first { $0.name == name }
    }

    static func style(withID id: Int) -> SoundscapeStyle? {
        all.first { $0.id == id }
    }
}

final class SoundscapeLibrary {
    static let shared = SoundscapeLibrary()

    func fileURL(for style: SoundscapeStyle) -> URL? {
        guard style.tone > 0 || style.noise > 0 else { return nil }
        let name = "scape-\(style.id).caf"
        let url = AppConfig.soundscapeDirectory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: url.path) { return url }
        return generate(style: style, url: url)
    }

    private func generate(style: SoundscapeStyle, url: URL) -> URL? {
        let sampleRate = 44100.0
        let duration = 8.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(sampleRate * duration)
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)
        var lowNoise = 0.0
        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample = 0.0
            if style.tone > 0 {
                sample += sin(2 * .pi * style.tone * t) * 0.30
                sample += sin(2 * .pi * style.tone * 2 * t) * 0.10
                sample += sin(2 * .pi * style.modulation * t) * 0.06
            }
            if style.noise > 0 {
                let white = Double.random(in: -1...1)
                lowNoise = lowNoise * 0.82 + white * 0.18
                sample += lowNoise * style.noise
            }
            let fade = min(1.0, min(t / 0.3, (duration - t) / 0.3))
            let value = max(-0.8, min(0.8, sample)) * fade
            channel[i] = Float(value)
        }
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            return url
        } catch {
            return nil
        }
    }
}
