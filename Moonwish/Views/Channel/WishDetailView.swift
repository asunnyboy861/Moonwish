import SwiftData
import SwiftUI

struct WishDetailView: View {
    @Bindable var wish: Wish

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var capsuleDate: Date = Date().addingTimeInterval(86400 * 30)
    @State private var showCelebration = false
    @State private var playbackItem: PlaybackItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(wish.domain.rawValue.uppercased())
                                .font(.system(.caption, design: .default, weight: .semibold))
                                .tracking(1.4)
                                .foregroundStyle(Theme.gold)
                            Text(wish.text)
                                .font(Theme.title(.title2))
                                .foregroundStyle(Theme.halo)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Wished on \(dateText(wish.createdAt))")
                                .font(.caption)
                                .foregroundStyle(Theme.mist)
                        }

                        if !wish.answers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionTitle(text: "Your choices")
                                FlexibleChips(items: wish.answers)
                            }
                        }

                        capsuleSection

                        sessionsSection

                        if wish.status == .fulfilled {
                            Button {
                                showCelebration = true
                            } label: {
                                Label("Share your celebration", systemImage: "party.popper.fill")
                            }
                            .buttonStyle(GoldButtonStyle())
                        }

                        Button("Delete this wish", role: .destructive) {
                            NotificationService.cancelTimeCapsule(wishID: wish.id)
                            modelContext.delete(wish)
                            try? modelContext.save()
                            dismiss()
                        }
                        .font(.footnote)
                        .padding(.top, 8)
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.mist)
                }
            }
        }
        .sheet(item: $playbackItem) { item in
            PlayerView(item: item)
        }
        .sheet(isPresented: $showCelebration) {
            CelebrationView(wish: wish)
        }
        .onAppear {
            capsuleDate = wish.targetDate ?? Date().addingTimeInterval(86400 * 30)
        }
    }

    private var capsuleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Time Capsule")
            if wish.status == .fulfilled {
                Text("Fulfilled on \(dateText(wish.fulfilledAt ?? Date()))")
                    .font(.body)
                    .foregroundStyle(Theme.gold)
            } else {
                Text(wish.targetDate == nil ? "Pick a date and we will gently check in with you." : "Check-in on \(dateText(wish.targetDate ?? Date()))")
                    .font(.footnote)
                    .foregroundStyle(Theme.mist)
                DatePicker("Arrival", selection: $capsuleDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(Theme.gold)
                    .foregroundStyle(Theme.halo)
                HStack(spacing: 12) {
                    Button("Save date") {
                        wish.targetDate = capsuleDate
                        try? modelContext.save()
                        NotificationService.scheduleTimeCapsule(wishID: wish.id, wishText: wish.text, date: capsuleDate)
                    }
                    .buttonStyle(GhostButtonStyle())

                    Button("It Happened!") {
                        wish.status = .fulfilled
                        wish.fulfilledAt = Date()
                        try? modelContext.save()
                        NotificationService.cancelTimeCapsule(wishID: wish.id)
                        showCelebration = true
                    }
                    .buttonStyle(GoldButtonStyle(compact: true))
                }
            }
        }
        .moonCard()
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Sessions · \(wish.sessions.count)")
            if wish.sessions.isEmpty {
                Text("No audio yet for this wish.")
                    .font(.footnote)
                    .foregroundStyle(Theme.mist)
            } else {
                ForEach(wish.sessions.sorted(by: { $0.createdAt > $1.createdAt })) { session in
                    Button {
                        playbackItem = PlaybackItem(
                            fileName: session.fileName,
                            title: session.title,
                            wishText: wish.text,
                            soundscape: session.soundscape,
                            isPreset: session.isPreset,
                            sessionID: session.id
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .foregroundStyle(Theme.gold)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Theme.cardFill))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.title)
                                    .font(.body)
                                    .foregroundStyle(Theme.halo)
                                Text("\(dateText(session.createdAt)) · \(durationText(session.duration))")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.mist)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.mist)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .moonCard()
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func durationText(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct FlexibleChips: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption)
                    .foregroundStyle(Theme.halo)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(Theme.cardFill))
                    .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
            }
        }
    }
}
