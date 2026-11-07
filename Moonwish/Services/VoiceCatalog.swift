import Foundation
import AVFoundation

enum VoiceCatalog {
    struct Voice: Identifiable, Hashable {
        let id: String
        let name: String
        let isPremiumPlus: Bool

        var voice: AVSpeechSynthesisVoice? {
            AVSpeechSynthesisVoice(identifier: id)
        }
    }

    static var available: [Voice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { lhs, rhs in
                lhs.quality.rawValue > rhs.quality.rawValue
            }
        var results: [Voice] = []
        var seen = Set<String>()
        for voice in voices where !seen.contains(voice.name) {
            seen.insert(voice.name)
            let premium = voice.quality == .premium || voice.quality == .enhanced
            results.append(Voice(id: voice.identifier, name: voice.name, isPremiumPlus: premium))
        }
        if results.isEmpty {
            results.append(Voice(id: AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? "", name: "System Voice", isPremiumPlus: false))
        }
        return Array(results.prefix(8))
    }

    static var defaultVoiceId: String? {
        available.first?.id
    }
}
