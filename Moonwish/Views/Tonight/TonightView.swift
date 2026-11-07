import SwiftData
import SwiftUI

struct TonightView: View {
    @Binding var showComposer: Bool

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \Wish.createdAt, order: .reverse) private var wishes: [Wish]
    @Query(sort: \AudioSession.createdAt, order: .reverse) private var sessions: [AudioSession]

    @State private var streakCount = 0
    @State private var graceRemaining = 0
    @State private var playbackItem: PlaybackItem?
    @State private var showPaywall = false
    @State private var presetLoading = false
    @State private var savedAffirmation = false
    @State private var errorMessage: String?

    private var latestSession: AudioSession? {
        sessions.first { !$0.isPreset }
    }

    private var moonName: String {
        MoonPhaseCalculator.name()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? "Morning Moon Letter" : "Tonight's Affirmation"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                BreathingMoon(phase: MoonPhaseCalculator.phase(), glow: min(1, Double(streakCount) / 21))
                    .frame(height: 230)

                HStack(spacing: 8) {
                    StatPill(icon: "moon.stars.fill", text: moonName)
                    StatPill(icon: "flame.fill", text: "\(streakCount) night streak")
                    StatPill(icon: "cloud.fill", text: "\(graceRemaining) grace")
                }

                affirmationCard

                VStack(spacing: 12) {
                    Button {
                        playTonight()
                    } label: {
                        Label(latestSession == nil ? "Create tonight's audio" : "Tonight ritual", systemImage: latestSession == nil ? "sparkles" : "play.fill")
                    }
                    .buttonStyle(GoldButtonStyle())
                    .accessibilityHint("Plays your latest session or opens wish creation")

                    Button {
                        showComposer = true
                    } label: {
                        Label("New Wish", systemImage: "plus")
                    }
                    .buttonStyle(GhostButtonStyle())
                }

                if let latestSession {
                    lastSessionCard(latestSession)
                }

                if wishes.isEmpty {
                    emptyState
                }

                quickActions

                if let errorMessage {
                    StatusBanner(text: errorMessage, isError: true)
                }
            }
            .padding(22)
        }
        .background(Theme.background.ignoresSafeArea())
        .overlay {
            if presetLoading {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(Theme.gold)
                        Text("Preparing your audio…")
                            .font(.footnote)
                            .foregroundStyle(Theme.halo)
                    }
                    .padding(24)
                    .moonCard(fill: Theme.midnight)
                }
            }
        }
        .sheet(item: $playbackItem) { item in
            PlayerView(item: item)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear(perform: refresh)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tonight")
                    .font(Theme.title(.largeTitle))
                    .foregroundStyle(Theme.halo)
                Text(dateText)
                    .font(.footnote)
                    .foregroundStyle(Theme.mist)
            }
            Spacer()
            Button {
                showPaywall = true
            } label: {
                Image(systemName: purchaseManager.isPlus ? "crown.fill" : "sparkles")
                    .foregroundStyle(Theme.gold)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.cardFill))
                    .overlay(Circle().stroke(Theme.cardStroke, lineWidth: 1))
            }
            .accessibilityLabel("Moonwish Plus")
        }
        .padding(.top, 8)
    }

    private var affirmationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: greeting)
            Text(DailyAffirmation.today())
                .font(Theme.title(.title3))
                .foregroundStyle(Theme.halo)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                Button {
                    savedAffirmation = true
                } label: {
                    Label(savedAffirmation ? "Saved" : "Keep this", systemImage: savedAffirmation ? "checkmark" : "bookmark")
                        .font(.footnote)
                }
                .buttonStyle(GhostButtonStyle())

                Button {
                    playPreset(PresetCatalog.tracks.first { $0.id == "morning-moon" } ?? PresetCatalog.tracks[0])
                } label: {
                    Label("Hear it", systemImage: "play.circle")
                        .font(.footnote)
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .moonCard()
    }

    private func lastSessionCard(_ session: AudioSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Last session")
            Button {
                playbackItem = PlaybackItem(
                    fileName: session.fileName,
                    title: session.title,
                    wishText: session.wish?.text ?? "Your saved session",
                    soundscape: session.soundscape,
                    isPreset: session.isPreset,
                    sessionID: session.id
                )
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "play.fill")
                        .foregroundStyle(Theme.midnightDeep)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.gold))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.title)
                            .font(.body)
                            .foregroundStyle(Theme.halo)
                            .lineLimit(1)
                        Text(session.wish?.text ?? "Saved audio")
                            .font(.caption)
                            .foregroundStyle(Theme.mist)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(durationText(session.duration))
                        .font(.caption2)
                        .foregroundStyle(Theme.mist)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(session.title)")
        }
        .moonCard()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your first audio is waiting")
                .font(Theme.title(.title3))
                .foregroundStyle(Theme.halo)
            Text("Tell the moon one sentence. You will hear it back with your own personalized ritual in under two minutes.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .moonCard()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                if let track = PresetCatalog.tracks.first(where: { $0.id == "sos-calm" }) {
                    playPreset(track)
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(Theme.gold)
                    Text("SOS Calm")
                        .font(.caption)
                        .foregroundStyle(Theme.halo)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .moonCard(padding: 0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play SOS calming audio")

            Button {
                showComposer = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.gold)
                    Text("Manifest now")
                        .font(.caption)
                        .foregroundStyle(Theme.halo)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .moonCard(padding: 0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create a new manifestation")
        }
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func durationText(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func refresh() {
        let state = StreakEngine.state(in: modelContext, isPlus: purchaseManager.isPlus)
        streakCount = state.currentStreak
        graceRemaining = state.graceRemaining
    }

    private func playTonight() {
        guard let latestSession else {
            showComposer = true
            return
        }
        playbackItem = PlaybackItem(
            fileName: latestSession.fileName,
            title: latestSession.title,
            wishText: latestSession.wish?.text ?? "Your saved session",
            soundscape: latestSession.soundscape,
            isPreset: latestSession.isPreset,
            sessionID: latestSession.id
        )
    }

    private func playPreset(_ track: PresetTrack) {
        presetLoading = true
        errorMessage = nil
        Task {
            let item = await PresetPlayback.item(for: track)
            presetLoading = false
            if let item {
                playbackItem = item
            } else {
                errorMessage = "We could not prepare this audio. Please try again."
            }
        }
    }
}
