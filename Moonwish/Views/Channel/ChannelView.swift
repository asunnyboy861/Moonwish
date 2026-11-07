import SwiftData
import SwiftUI

struct ChannelView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \Wish.createdAt, order: .reverse) private var wishes: [Wish]
    @Query(sort: \AudioSession.createdAt, order: .reverse) private var sessions: [AudioSession]

    @State private var playbackItem: PlaybackItem?
    @State private var selectedWish: Wish?
    @State private var presetLoading: PresetTrack?
    @State private var errorMessage: String?

    private var groupedWishes: [Wish] {
        wishes.filter { !$0.sessions.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        if groupedWishes.isEmpty {
                            emptyState
                        } else {
                            ForEach(groupedWishes) { wish in
                                wishSection(wish)
                            }
                        }
                        librarySection
                        if let errorMessage {
                            StatusBanner(text: errorMessage, isError: true)
                        }
                    }
                    .padding(22)
                }
                if let presetLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(Theme.gold)
                            Text("Rendering \(presetLoading.title)…")
                                .font(.footnote)
                                .foregroundStyle(Theme.halo)
                        }
                        .padding(24)
                        .moonCard(fill: Theme.midnight)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Channel")
                        .font(Theme.title(.title2))
                        .foregroundStyle(Theme.halo)
                }
            }
        }
        .sheet(item: $playbackItem) { item in
            PlayerView(item: item)
        }
        .sheet(item: $selectedWish) { wish in
            WishDetailView(wish: wish)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your personal radio")
                .font(Theme.title(.title2))
                .foregroundStyle(Theme.halo)
            Text("Every wish becomes an audio you can return to, grouped the way you made it.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing here yet")
                .font(Theme.title(.title3))
                .foregroundStyle(Theme.halo)
            Text("Create a wish from Tonight, and your first personalized session will appear here automatically.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .moonCard()
    }

    private func wishSection(_ wish: Wish) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                selectedWish = wish
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wish.text)
                            .font(Theme.title(.title3))
                            .foregroundStyle(Theme.halo)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text("\(wish.domain.rawValue) · \(wish.sessions.count) session\(wish.sessions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Theme.mist)
                    }
                    Spacer()
                    Image(systemName: wish.status == .fulfilled ? "checkmark.seal.fill" : "chevron.right")
                        .foregroundStyle(wish.status == .fulfilled ? Theme.gold : Theme.mist)
                }
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(wish.sessions.sorted(by: { $0.createdAt > $1.createdAt })) { session in
                        sessionCard(session)
                    }
                }
            }
        }
    }

    private func sessionCard(_ session: AudioSession) -> some View {
        Button {
            playbackItem = PlaybackItem(
                fileName: session.fileName,
                title: session.title,
                wishText: session.wish?.text ?? "Saved session",
                soundscape: session.soundscape,
                isPreset: session.isPreset,
                sessionID: session.id
            )
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Theme.dusk, Theme.midnightDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 210, height: 112)
                    Image(systemName: "waveform")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.gold)
                        .opacity(0.8)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(durationText(session.duration))
                                .font(.caption2)
                                .foregroundStyle(Theme.halo)
                                .padding(6)
                                .background(Capsule().fill(Color.black.opacity(0.35)))
                                .padding(8)
                        }
                    }
                    .frame(width: 210, height: 112)
                }
                Text(session.title)
                    .font(.footnote)
                    .foregroundStyle(Theme.halo)
                    .lineLimit(1)
                Text(engineName(session.engineUsed))
                    .font(.caption2)
                    .foregroundStyle(Theme.mist)
            }
            .frame(width: 210, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play \(session.title)")
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Moon Library · \(PresetCatalog.tracks.count) tracks")
            Text("Curated sessions that work without any setup. Tap one to render it on this device.")
                .font(.caption)
                .foregroundStyle(Theme.mist)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(PresetCatalog.tracks) { track in
                    Button {
                        render(track)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: track.icon)
                                    .foregroundStyle(Theme.gold)
                                Spacer()
                                Text(track.category)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.mist)
                            }
                            Text(track.title)
                                .font(Theme.title(.callout))
                                .foregroundStyle(Theme.halo)
                                .lineLimit(1)
                            Text(track.subtitle)
                                .font(.caption2)
                                .foregroundStyle(Theme.mist)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Theme.cardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Theme.cardStroke, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(track.title), \(track.category)")
                }
            }
        }
        .padding(.top, 8)
    }

    private func render(_ track: PresetTrack) {
        errorMessage = nil
        presetLoading = track
        Task {
            let item = await PresetPlayback.item(for: track)
            presetLoading = nil
            if let item {
                playbackItem = item
            } else {
                errorMessage = "We could not render this session. Please try again."
            }
        }
    }

    private func durationText(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func engineName(_ engine: String) -> String {
        switch engine {
        case "apple": return "Apple Intelligence"
        case "glm": return "Moonwish Cloud"
        case "byo": return "Your API key"
        default: return "On-device"
        }
    }
}
