import SwiftData
import SwiftUI

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showEditor = false
    @State private var showWeekly = false

    private var groupedEntries: [(day: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { (day: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        weeklyCard
                        if groupedEntries.isEmpty {
                            emptyState
                        } else {
                            ForEach(groupedEntries, id: \.day) { group in
                                daySection(group.day, group.entries)
                            }
                        }
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Journal")
                        .font(Theme.title(.title2))
                        .foregroundStyle(Theme.halo)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.gold)
                    }
                    .accessibilityLabel("New journal entry")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            JournalEditorView()
        }
        .sheet(isPresented: $showWeekly) {
            WeeklyReportView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Write it into being")
                .font(Theme.title(.title2))
                .foregroundStyle(Theme.halo)
            Text("Three methods, one quiet place. Voice dictation is available if typing is too much tonight.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .padding(.top, 8)
    }

    private var weeklyCard: some View {
        Button {
            showWeekly = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your moon report")
                        .foregroundStyle(Theme.halo)
                    Text("See the week you actually had")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.mist)
            }
            .padding(16)
            .moonCard(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open weekly moon report")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The page is still blank")
                .font(Theme.title(.title3))
                .foregroundStyle(Theme.halo)
            Text("Start with one gratitude line. It counts toward your moon streak.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
            Button("Write tonight") {
                showEditor = true
            }
            .buttonStyle(GhostButtonStyle())
            .padding(.top, 4)
        }
        .moonCard()
    }

    private func daySection(_ day: Date, _ dayEntries: [JournalEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayText(day))
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.mist)
            ForEach(dayEntries) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: entry.method.icon)
                            .foregroundStyle(Theme.gold)
                        Text(entry.method.rawValue)
                            .font(.caption)
                            .foregroundStyle(Theme.halo)
                        Spacer()
                        Text(timeText(entry.date))
                            .font(.caption2)
                            .foregroundStyle(Theme.mist)
                    }
                    Text(entry.text)
                        .font(.body)
                        .foregroundStyle(Theme.halo)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .moonCard()
            }
        }
    }

    private func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject private var dictation = SpeechDictation()

    @State private var method: JournalMethod = .gratitude
    @State private var text: String = ""
    @State private var errorMessage: String?

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Method", selection: $method) {
                        ForEach(JournalMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.gold)

                    Text(method.guidance)
                        .font(.caption)
                        .foregroundStyle(Theme.mist)

                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Write as if it already happened...")
                                .font(.body)
                                .foregroundStyle(Theme.mist)
                                .padding(12)
                        }
                        TextEditor(text: $text)
                            .font(.body)
                            .foregroundStyle(Theme.halo)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 220)
                            .padding(6)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Theme.cardStroke, lineWidth: 1)
                            )
                    )

                    HStack(spacing: 12) {
                        Button {
                            dictation.toggle()
                        } label: {
                            Label(dictation.isRecording ? "Stop" : "Dictate", systemImage: dictation.isRecording ? "waveform.circle.fill" : "mic.fill")
                                .font(.footnote)
                        }
                        .buttonStyle(GhostButtonStyle())

                        if dictation.isRecording {
                            Text("Listening...")
                                .font(.caption)
                                .foregroundStyle(Theme.mist)
                        }
                        Spacer()
                        Button("Save") {
                            save()
                        }
                        .buttonStyle(GoldButtonStyle(compact: true))
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.6)
                    }

                    if let errorMessage {
                        StatusBanner(text: errorMessage, isError: true)
                    }
                    if let message = dictation.errorMessage {
                        StatusBanner(text: message, isError: true)
                    }
                    Spacer()
                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if dictation.isRecording { dictation.stop() }
                        dismiss()
                    }
                    .foregroundStyle(Theme.mist)
                }
            }
        }
        .onChange(of: dictation.transcript) { _, newValue in
            if !newValue.isEmpty {
                text = newValue
            }
        }
        .onDisappear {
            if dictation.isRecording { dictation.stop() }
        }
    }

    private func save() {
        let entry = JournalEntry(date: Date(), method: method, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(entry)
        _ = StreakEngine.markJournaled(in: modelContext, isPlus: purchaseManager.isPlus)
        do {
            try modelContext.save()
            if dictation.isRecording { dictation.stop() }
            dismiss()
        } catch {
            errorMessage = "Could not save this entry. Please try again."
        }
    }
}
