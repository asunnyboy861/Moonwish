import Foundation
import SwiftData

@MainActor
enum StreakEngine {
    static func state(in context: ModelContext, isPlus: Bool) -> StreakState {
        let descriptor = FetchDescriptor<StreakState>(sortBy: [SortDescriptor(\.lastUpdated)])
        if let existing = try? context.fetch(descriptor).first {
            refreshGraceIfNeeded(state: existing, isPlus: isPlus)
            return existing
        }
        let created = StreakState(graceRemaining: isPlus ? 3 : 1, lastUpdated: Date.distantPast)
        context.insert(created)
        try? context.save()
        return created
    }

    static func markListened(in context: ModelContext, isPlus: Bool, date: Date = Date()) -> StreakState {
        markActivity(in: context, isPlus: isPlus, journaled: false, date: date)
    }

    static func markJournaled(in context: ModelContext, isPlus: Bool, date: Date = Date()) -> StreakState {
        markActivity(in: context, isPlus: isPlus, journaled: true, date: date)
    }

    private static func markActivity(in context: ModelContext, isPlus: Bool, journaled: Bool, date: Date) -> StreakState {
        let day = Calendar.current.startOfDay(for: date)
        let state = state(in: context, isPlus: isPlus)
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.day == day })
        var record: DailyRecord?
        if let existing = try? context.fetch(descriptor).first {
            record = existing
        } else {
            let newRecord = DailyRecord(day: day)
            context.insert(newRecord)
            record = newRecord
        }
        let alreadyCounted = (record?.listened ?? false) || (record?.journaled ?? false)
        if journaled {
            record?.journaled = true
        } else {
            record?.listened = true
        }
        let lastDay = Calendar.current.startOfDay(for: state.lastUpdated)
        if !alreadyCounted {
            if lastDay == day {
            } else if Calendar.current.date(byAdding: .day, value: 1, to: lastDay) == day {
                state.currentStreak += 1
            } else {
                if state.currentStreak > 0 {
                    if state.graceRemaining > 0 {
                        state.graceRemaining -= 1
                        record?.graceUsed = true
                    } else {
                        state.currentStreak = 0
                    }
                }
                state.currentStreak += 1
            }
            state.bestStreak = max(state.bestStreak, state.currentStreak)
        }
        state.lastUpdated = date
        try? context.save()
        return state
    }

    private static func refreshGraceIfNeeded(state: StreakState, isPlus: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let key = formatter.string(from: Date())
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "grace_month") != key {
            defaults.set(key, forKey: "grace_month")
            state.graceRemaining = isPlus ? 3 : 1
        }
    }

    static func dailyRecordCount(in context: ModelContext, days: Int) -> Int {
        let start = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.day >= start })
        let records = (try? context.fetch(descriptor)) ?? []
        return records.filter { $0.listened || $0.journaled }.count
    }
}
