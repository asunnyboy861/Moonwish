import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct BoardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \BoardItem.orderIndex) private var items: [BoardItem]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var caption: String = ""
    @State private var generating = false
    @State private var playbackItem: PlaybackItem?
    @State private var errorMessage: String?
    @State private var showPicker = false

    private var canAddMore: Bool {
        items.count < 9
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        grid
                        captionCard
                        if let errorMessage {
                            StatusBanner(text: errorMessage, isError: true)
                        }
                    }
                    .padding(22)
                }
                if generating {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(Theme.gold)
                            Text("Turning your board into audio…")
                                .font(.footnote)
                                .foregroundStyle(Theme.halo)
                        }
                        .padding(24)
                        .moonCard(fill: Theme.midnight)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Vision Board")
                        .font(Theme.title(.title2))
                        .foregroundStyle(Theme.halo)
                }
            }
        }
        .sheet(item: $playbackItem) { item in
            PlayerView(item: item)
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItems, maxSelectionCount: max(1, 9 - items.count), matching: .images)
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await importPhotos(newItems) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("See it before you live it")
                .font(Theme.title(.title2))
                .foregroundStyle(Theme.halo)
            Text("Add up to nine images that feel like your wish already happened. Then turn the board into an audio.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .padding(.top, 8)
    }

    private var grid: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(items) { item in
                    ZStack(alignment: .topTrailing) {
                        if let image = image(for: item) {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 118)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.cardFill)
                                .frame(height: 118)
                                .overlay(Image(systemName: "photo").foregroundStyle(Theme.mist))
                        }
                        Button {
                            modelContext.delete(item)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.halo)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                        .padding(6)
                        .accessibilityLabel("Remove image")
                    }
                }
                if canAddMore {
                    Button {
                        showPicker = true
                    } label: {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.cardFill)
                            .frame(height: 118)
                            .overlay(
                                VStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Theme.gold)
                                    Text("\(items.count)/9")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.mist)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.cardStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a vision board image")
                }
            }
        }
        .moonCard()
    }

    private var captionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Your vision in words")
            TextField("I see myself...", text: $caption, axis: .vertical)
                .font(.body)
                .foregroundStyle(Theme.halo)
                .lineLimit(2...4)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.cardFill)
                )
            Button {
                generateFromBoard()
            } label: {
                Label("Generate audio from this board", systemImage: "sparkles")
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(items.isEmpty || generating)
            .opacity(items.isEmpty || generating ? 0.6 : 1)

            Text("Cloud vision runs on Plus or your own API key. On the free tier, your caption guides the on-device script.")
                .font(.caption2)
                .foregroundStyle(Theme.mist)
        }
        .moonCard()
    }

    private func image(for item: BoardItem) -> Image? {
        let url = AppConfig.boardDirectory.appendingPathComponent(item.imageFileName)
        guard let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    private func importPhotos(_ newItems: [PhotosPickerItem]) async {
        for item in newItems {
            guard items.count < 9 else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpeg = uiImage.jpegData(compressionQuality: 0.8) {
                let fileName = "board-\(UUID().uuidString).jpg"
                let url = AppConfig.boardDirectory.appendingPathComponent(fileName)
                try? jpeg.write(to: url)
                let boardItem = BoardItem(caption: "", imageFileName: fileName, orderIndex: items.count)
                modelContext.insert(boardItem)
            }
        }
        try? modelContext.save()
        pickerItems = []
    }

    private func generateFromBoard() {
        guard !generating else { return }
        generating = true
        errorMessage = nil
        let wishText = caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "I am living the life on my vision board"
            : caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = WishInput(wish: wishText, category: WishDomain.myself.rawValue, answers: ["Vision board", "\(items.count) images"], targetDate: nil)

        Task {
            let result = await AIEngineRouter.shared.generate(input: input, isPlus: purchaseManager.isPlus)
            let fileName = "board-session-\(UUID().uuidString).caf"
            do {
                let url = try await AudioRenderer.shared.render(script: result.script, voiceIdentifier: VoiceCatalog.defaultVoiceId, fileName: fileName)
                let asset = AVURLAsset(url: url)
                let duration = (try? await asset.load(.duration).seconds) ?? 0
                let wish = Wish(text: wishText, category: .myself, answers: ["Vision board"])
                modelContext.insert(wish)
                let session = AudioSession(
                    title: result.script.title,
                    scriptJSON: (try? JSONEncoder().encode(result.script).base64EncodedString()) ?? "",
                    fileName: fileName,
                    voiceId: VoiceCatalog.defaultVoiceId ?? "",
                    soundscape: "Theta Waves",
                    duration: duration,
                    engineUsed: result.engine,
                    qualityPassed: AudioQuality.isValid(url: url)
                )
                session.wish = wish
                modelContext.insert(session)
                try? modelContext.save()
                generating = false
                playbackItem = PlaybackItem(
                    fileName: fileName,
                    title: result.script.title,
                    wishText: wishText,
                    soundscape: "Theta Waves",
                    isPreset: false,
                    sessionID: session.id
                )
            } catch {
                generating = false
                errorMessage = "We could not render audio from this board. Please try again."
            }
        }
    }
}
