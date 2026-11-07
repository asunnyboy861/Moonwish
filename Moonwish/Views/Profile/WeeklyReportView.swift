import SwiftData
import SwiftUI

struct WeeklyReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \DailyRecord.day, order: .reverse) private var records: [DailyRecord]
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \AudioSession.createdAt, order: .reverse) private var sessions: [AudioSession]

    @State private var shareImage: UIImage?
    @State private var showShare = false

    private var weekRecords: [DailyRecord] {
        let start = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date())
        return records.filter { $0.day >= start }
    }

    private var weekEntries: [JournalEntry] {
        let start = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date())
        return entries.filter { $0.date >= start }
    }

    private var weekSessions: [AudioSession] {
        let start = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date())
        return sessions.filter { $0.createdAt >= start && !$0.isPreset }
    }

    private var showUpDays: Int {
        weekRecords.filter { $0.listened || $0.journaled }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        WeeklyReportCard(
                            showUpDays: showUpDays,
                            sessions: weekSessions.count,
                            entries: weekEntries.count,
                            streak: StreakEngine.state(in: modelContext, isPlus: purchaseManager.isPlus).currentStreak,
                            moon: MoonPhaseCalculator.name()
                        )
                        .frame(maxWidth: 360)

                        VStack(spacing: 12) {
                            Button {
                                render()
                            } label: {
                                Label("Share this report", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(GoldButtonStyle())
                            Button("Close") { dismiss() }
                                .buttonStyle(GhostButtonStyle())
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.mist)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private func render() {
        let content = WeeklyReportCard(
            showUpDays: showUpDays,
            sessions: weekSessions.count,
            entries: weekEntries.count,
            streak: StreakEngine.state(in: modelContext, isPlus: purchaseManager.isPlus).currentStreak,
            moon: MoonPhaseCalculator.name()
        )
        .frame(width: 360, height: 480)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        if let image = renderer.uiImage {
            shareImage = image
            showShare = true
        }
    }
}

struct WeeklyReportCard: View {
    let showUpDays: Int
    let sessions: Int
    let entries: Int
    let streak: Int
    let moon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.background)
            StarField()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("MOON REPORT")
                        .font(.system(.caption, design: .default, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.gold)
                    Spacer()
                    Text(moon)
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                Text("This week, you kept showing up.")
                    .font(Theme.title(.title2))
                    .foregroundStyle(Theme.halo)
                HStack(spacing: 12) {
                    reportStat(value: "\(showUpDays)", label: "days present")
                    reportStat(value: "\(sessions)", label: "sessions")
                    reportStat(value: "\(entries)", label: "entries")
                }
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.gold)
                    Text("\(streak) night streak")
                        .font(.body)
                        .foregroundStyle(Theme.halo)
                }
                Spacer()
                Text("Moonwish · Manifest While You Sleep")
                    .font(.caption2)
                    .foregroundStyle(Theme.mist)
            }
            .padding(24)
        }
        .frame(height: 480)
    }

    private func reportStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.gold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.mist)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.cardFill)
        )
    }
}
