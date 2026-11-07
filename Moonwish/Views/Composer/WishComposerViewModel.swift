import AVFoundation
import Foundation
import SwiftData
import SwiftUI

struct ChipQuestion: Identifiable, Hashable {
    let id = UUID()
    let prompt: String
    let options: [String]
}

struct PlaybackItem: Identifiable {
    let id = UUID()
    let fileName: String
    let title: String
    let wishText: String
    let soundscape: String
    let isPreset: Bool
    let sessionID: UUID?
}

@MainActor
final class WishComposerViewModel: ObservableObject {
    enum Step {
        case domain
        case wish
        case chips
        case timing
        case generating
        case finished
    }

    @Published var step: Step = .domain
    @Published var domain: WishDomain?
    @Published var wishText: String = ""
    @Published var questions: [ChipQuestion] = []
    @Published var questionIndex: Int = 0
    @Published var answers: [String] = []
    @Published var wantsCapsule: Bool = false
    @Published var capsuleDate: Date = Date().addingTimeInterval(86400 * 30)
    @Published var streamedLines: [String] = []
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var playbackItem: PlaybackItem?
    @Published var engineLabel: String = ""

    var currentQuestion: ChipQuestion? {
        guard questionIndex < questions.count else { return nil }
        return questions[questionIndex]
    }

    func select(domain: WishDomain) {
        self.domain = domain
        questions = makeQuestions(for: domain)
        step = .wish
    }

    func continueToChips() {
        guard !wishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        questionIndex = 0
        answers = []
        step = .chips
    }

    func choose(option: String) {
        answers.append(option)
        if questionIndex + 1 < questions.count {
            questionIndex += 1
        } else {
            step = .timing
        }
    }

    func skipChips() {
        step = .timing
    }

    func generate(context: ModelContext, isPlus: Bool) async {
        guard let domain else { return }
        let wish = wishText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !wish.isEmpty else {
            errorMessage = "Tell the moon one sentence first."
            step = .wish
            return
        }
        step = .generating
        isGenerating = true
        errorMessage = nil
        streamedLines = []

        let input = WishInput(
            wish: wish,
            category: domain.rawValue,
            answers: answers,
            targetDate: wantsCapsule ? capsuleDate : nil
        )
        let result = await AIEngineRouter.shared.generate(input: input, isPlus: isPlus)
        engineLabel = label(for: result.engine)
        let script = result.script
        let fileName = "session-\(UUID().uuidString).caf"

        do {
            async let renderedURL = AudioRenderer.shared.render(script: script, voiceIdentifier: VoiceCatalog.defaultVoiceId, fileName: fileName)
            for line in script.segments {
                streamedLines.append(line)
                try? await Task.sleep(nanoseconds: 220_000_000)
            }
            let url = try await renderedURL
            let asset = AVURLAsset(url: url)
            let duration = (try? await asset.load(.duration).seconds) ?? 0

            let wishModel = Wish(text: wish, category: domain, answers: answers, targetDate: wantsCapsule ? capsuleDate : nil)
            context.insert(wishModel)

            let session = AudioSession(
                title: script.title,
                scriptJSON: (try? JSONEncoder().encode(script).base64EncodedString()) ?? "",
                fileName: fileName,
                voiceId: VoiceCatalog.defaultVoiceId ?? "",
                soundscape: "Theta Waves",
                duration: duration,
                engineUsed: result.engine,
                qualityPassed: AudioQuality.isValid(url: url)
            )
            session.wish = wishModel
            context.insert(session)
            if let target = wishModel.targetDate {
                NotificationService.scheduleTimeCapsule(wishID: wishModel.id, wishText: wishModel.text, date: target)
            }
            _ = StreakEngine.markListened(in: context, isPlus: isPlus)
            try? context.save()

            playbackItem = PlaybackItem(
                fileName: fileName,
                title: script.title,
                wishText: wish,
                soundscape: "Theta Waves",
                isPreset: false,
                sessionID: session.id
            )
            step = .finished
        } catch {
            let fallback = LocalScriptComposer.make(input: input)
            let fallbackName = "session-\(UUID().uuidString).caf"
            do {
                let url = try await AudioRenderer.shared.render(script: fallback, voiceIdentifier: VoiceCatalog.defaultVoiceId, fileName: fallbackName)
                let asset = AVURLAsset(url: url)
                let duration = (try? await asset.load(.duration).seconds) ?? 0
                let wishModel = Wish(text: wish, category: domain, answers: answers, targetDate: wantsCapsule ? capsuleDate : nil)
                context.insert(wishModel)
                let session = AudioSession(
                    title: fallback.title,
                    scriptJSON: (try? JSONEncoder().encode(fallback).base64EncodedString()) ?? "",
                    fileName: fallbackName,
                    voiceId: VoiceCatalog.defaultVoiceId ?? "",
                    soundscape: "Theta Waves",
                    duration: duration,
                    engineUsed: "local",
                    qualityPassed: AudioQuality.isValid(url: url)
                )
                session.wish = wishModel
                context.insert(session)
                try? context.save()
                playbackItem = PlaybackItem(
                    fileName: fallbackName,
                    title: fallback.title,
                    wishText: wish,
                    soundscape: "Theta Waves",
                    isPreset: false,
                    sessionID: session.id
                )
                engineLabel = "On-device"
                step = .finished
            } catch {
                errorMessage = "We could not render the audio on this device. Please try again."
                step = .timing
            }
        }
        isGenerating = false
    }

    private func label(for engine: String) -> String {
        switch engine {
        case "apple": return "Apple Intelligence"
        case "glm": return "Moonwish Cloud"
        case "byo": return "Your API key"
        default: return "On-device"
        }
    }

    private func makeQuestions(for domain: WishDomain) -> [ChipQuestion] {
        let timing = ChipQuestion(prompt: "When do you want to feel this?", options: ["Tonight", "This week", "No deadline"])
        switch domain {
        case .love:
            return [
                ChipQuestion(prompt: "Who is this wish about?", options: ["Someone specific", "The universe", "Myself"]),
                ChipQuestion(prompt: "How should it feel?", options: ["Excited", "Calm", "Hopeful"]),
                timing
            ]
        case .money:
            return [
                ChipQuestion(prompt: "What feeling matters most?", options: ["Safety", "Freedom", "Generosity"]),
                ChipQuestion(prompt: "How will you notice it?", options: ["A small win", "A steady habit", "A surprise"]),
                timing
            ]
        case .career:
            return [
                ChipQuestion(prompt: "What is the next step?", options: ["A new role", "More visibility", "Peace at work"]),
                ChipQuestion(prompt: "How do you want to feel?", options: ["Confident", "Curious", "Grounded"]),
                timing
            ]
        case .myself:
            return [
                ChipQuestion(prompt: "What are you becoming?", options: ["Calmer", "More confident", "More rested"]),
                ChipQuestion(prompt: "What do you need tonight?", options: ["Softness", "Strength", "Clarity"]),
                timing
            ]
        }
    }
}
