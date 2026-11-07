import Foundation
import SwiftData

@Model
final class DailyRecord {
    var id: UUID = UUID()
    var day: Date = Date()
    var listened: Bool = false
    var journaled: Bool = false
    var graceUsed: Bool = false

    init(day: Date, listened: Bool = false, journaled: Bool = false, graceUsed: Bool = false) {
        self.id = UUID()
        self.day = Calendar.current.startOfDay(for: day)
        self.listened = listened
        self.journaled = journaled
        self.graceUsed = graceUsed
    }
}

enum JournalMethod: String, Codable, CaseIterable, Identifiable {
    case threeSixNine = "369"
    case scripting = "Scripting"
    case gratitude = "Gratitude"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .threeSixNine: return "3.circle.fill"
        case .scripting: return "text.book.closed.fill"
        case .gratitude: return "heart.text.square.fill"
        }
    }

    var guidance: String {
        switch self {
        case .threeSixNine: return "Write your wish 3 times in the morning, 6 at midday, 9 at night."
        case .scripting: return "Write about your wish as if it already happened."
        case .gratitude: return "Name what you are grateful for tonight."
        }
    }
}

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var methodRaw: String = JournalMethod.gratitude.rawValue
    var text: String = ""

    init(date: Date, method: JournalMethod, text: String) {
        self.id = UUID()
        self.date = date
        self.methodRaw = method.rawValue
        self.text = text
    }

    var method: JournalMethod {
        JournalMethod(rawValue: methodRaw) ?? .gratitude
    }
}

@Model
final class BoardItem {
    var id: UUID = UUID()
    var caption: String = ""
    var imageFileName: String = ""
    var orderIndex: Int = 0
    var createdAt: Date = Date()

    init(caption: String, imageFileName: String, orderIndex: Int) {
        self.id = UUID()
        self.caption = caption
        self.imageFileName = imageFileName
        self.orderIndex = orderIndex
        self.createdAt = Date()
    }
}

@Model
final class StreakState {
    var id: UUID = UUID()
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var graceRemaining: Int = 1
    var lastUpdated: Date = Date()

    init(currentStreak: Int = 0, bestStreak: Int = 0, graceRemaining: Int = 1, lastUpdated: Date = Date()) {
        self.id = UUID()
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.graceRemaining = graceRemaining
        self.lastUpdated = lastUpdated
    }
}
