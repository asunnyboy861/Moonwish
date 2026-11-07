import AVFoundation
import Foundation

enum AudioQuality {
    static func isValid(url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        let asset = AVURLAsset(url: url)
        guard asset.isPlayable else { return false }
        return asset.duration.seconds > 3
    }
}

@MainActor
final class AudioRenderer {
    static let shared = AudioRenderer()

    private init() {}

    func render(script: ManifestationScript, voiceIdentifier: String?, fileName: String) async throws -> URL {
        let url = AppConfig.sessionURL(fileName: fileName)
        try? FileManager.default.removeItem(at: url)

        let synthesizer = AVSpeechSynthesizer()
        let chunks = [script.opening, script.lines.joined(separator: ". "), script.closing]
        var audioFile: AVAudioFile?

        for chunk in chunks {
            let text = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.42
            utterance.pitchMultiplier = 0.94
            utterance.volume = 1.0
            if let voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
                utterance.voice = voice
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var resumed = false
                synthesizer.write(utterance) { buffer in
                    guard let pcm = buffer as? AVAudioPCMBuffer else { return }
                    if pcm.frameLength == 0 {
                        if !resumed {
                            resumed = true
                            continuation.resume()
                        }
                        return
                    }
                    do {
                        if audioFile == nil {
                            audioFile = try AVAudioFile(forWriting: url, settings: pcm.format.settings)
                        }
                        try audioFile?.write(from: pcm)
                    } catch {
                        if !resumed {
                            resumed = true
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }

        guard audioFile != nil, AudioQuality.isValid(url: url) else {
            throw AIError.invalidFormat
        }

        let asset = AVURLAsset(url: url)
        _ = try await asset.load(.duration).seconds
        return url
    }

    func renderPreset(title: String, lines: [String], fileName: String) async throws -> URL {
        let script = ManifestationScript(
            title: title,
            opening: "Settle in. Let your breath slow down.",
            lines: lines,
            closing: "Rest now. The moon is with you.",
            minutes: 8
        )
        return try await render(script: script, voiceIdentifier: nil, fileName: fileName)
    }
}
