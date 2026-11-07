import Foundation
import SwiftData

enum WishStatus: String, Codable, CaseIterable {
    case growing
    case fulfilled
    case released
}

enum WishDomain: String, Codable, CaseIterable, Identifiable {
    case love = "Love"
    case money = "Money"
    case career = "Career"
    case myself = "Myself"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .love: return "heart.fill"
        case .money: return "sparkles"
        case .career: return "briefcase.fill"
        case .myself: return "leaf.fill"
        }
    }

    var prompt: String {
        switch self {
        case .love: return "What does your heart want tonight?"
        case .money: return "What abundance are you calling in?"
        case .career: return "What path is asking for you?"
        case .myself: return "Who are you becoming?"
        }
    }
}

@Model
final class Wish {
    var id: UUID = UUID()
    var text: String = ""
    var category: String = WishDomain.myself.rawValue
    var answersData: String = "Wl0="
    var createdAt: Date = Date()
    var targetDate: Date?
    var statusRaw: String = WishStatus.growing.rawValue
    var fulfilledAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \AudioSession.wish) var sessions: [AudioSession] = []

    init(text: String, category: WishDomain, answers: [String], targetDate: Date? = nil) {
        self.id = UUID()
        self.text = text
        self.category = category.rawValue
        self.answersData = (try? JSONSerialization.data(withJSONObject: answers).base64EncodedString()) ?? "Wl0="
        self.createdAt = Date()
        self.targetDate = targetDate
        self.statusRaw = WishStatus.growing.rawValue
    }

    var domain: WishDomain {
        WishDomain(rawValue: category) ?? .myself
    }

    var status: WishStatus {
        get { WishStatus(rawValue: statusRaw) ?? .growing }
        set { statusRaw = newValue.rawValue }
    }

    var answers: [String] {
        get {
            guard let data = Data(base64Encoded: answersData),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [String] else { return [] }
            return array
        }
        set {
            answersData = (try? JSONSerialization.data(withJSONObject: newValue).base64EncodedString()) ?? "Wl0="
        }
    }
}

@Model
final class AudioSession {
    var id: UUID = UUID()
    var title: String = ""
    var scriptJSON: String = ""
    var fileName: String = ""
    var voiceId: String = ""
    var soundscape: String = "theta"
    var duration: Double = 0
    var engineUsed: String = "local"
    var createdAt: Date = Date()
    var playCount: Int = 0
    var qualityPassed: Bool = false
    var isPreset: Bool = false
    var wish: Wish?

    init(title: String, scriptJSON: String, fileName: String, voiceId: String, soundscape: String, duration: Double, engineUsed: String, qualityPassed: Bool, isPreset: Bool = false) {
        self.id = UUID()
        self.title = title
        self.scriptJSON = scriptJSON
        self.fileName = fileName
        self.voiceId = voiceId
        self.soundscape = soundscape
        self.duration = duration
        self.engineUsed = engineUsed
        self.createdAt = Date()
        self.qualityPassed = qualityPassed
        self.isPreset = isPreset
    }
}
