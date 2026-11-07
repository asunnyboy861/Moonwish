import SwiftData
import SwiftUI

struct PlayerView: View {
    let item: PlaybackItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject private var playback = PlaybackService.shared
    @State private var showPaywall = false
    @State private var sleepMinutes: Int?
    @State private var downloaded = false
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        BreathingMoon(phase: MoonPhaseCalculator.phase(), glow: playback.isPlaying ? 0.9 : 0.35)
                            .frame(height: 210)

                        VStack(spacing: 6) {
                            Text(playback.currentTitle.isEmpty ? item.title : playback.currentTitle)
                                .font(Theme.title(.title2))
                                .foregroundStyle(Theme.halo)
                                .multilineTextAlignment(.center)
                            Text(item.wishText)
                                .font(.footnote)
                                .foregroundStyle(Theme.mist)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            ProgressView(value: progress)
                                .tint(Theme.gold)
                            HStack {
                                Text(timeText(playback.elapsed))
                                Spacer()
                                Text("Seamless loop")
                                    .foregroundStyle(Theme.gold)
                                Spacer()
                                Text(timeText(playback.duration))
                            }
                            .font(.caption2)
                            .foregroundStyle(Theme.mist)
                        }
                        .padding(.horizontal, 22)

                        Button {
                            playback.togglePlayPause()
                        } label: {
                            Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.midnightDeep)
                                .frame(width: 76, height: 76)
                                .background(Circle().fill(Theme.gold))
                        }
                        .accessibilityLabel(playback.isPlaying ? "Pause audio" : "Play audio")

                        HStack(spacing: 10) {
                            StatPill(icon: "moon.stars.fill", text: MoonPhaseCalculator.name())
                            StatPill(icon: "arrow.triangle.2.circlepath", text: "Loop")
                            if playback.sleepDeadline != nil {
                                StatPill(icon: "bed.double.fill", text: "Sleep timer on")
                            }
                        }

                        VStack(spacing: 0) {
                            overnightRow
                            Divider().overlay(Theme.cardStroke)
                            sleepTimerRow
                            Divider().overlay(Theme.cardStroke)
                            downloadRow
                        }
                        .moonCard(padding: 0)

                        soundscapeSection

                        Text("Audio is rendered and stored on this device. It keeps playing with the screen off.")
                            .font(.caption2)
                            .foregroundStyle(Theme.mist)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Theme.mist)
                    }
                    .accessibilityLabel("Close player")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text(item.isPreset ? "Moon Library" : "Your Session")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            playback.play(
                fileName: item.fileName,
                title: item.title,
                sessionID: item.sessionID,
                soundscape: item.soundscape,
                withSoundscape: true
            )
            recordPlay()
        }
    }

    private var progress: Double {
        guard playback.duration > 0 else { return 0 }
        return min(1, playback.elapsed / playback.duration)
    }

    private func timeText(_ seconds: Double) -> String {
        let value = Int(seconds)
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    private var overnightRow: some View {
        Button {
            if !purchaseManager.isPlus {
                showPaywall = true
                return
            }
            playback.overnightMode.toggle()
            if playback.overnightMode {
                sleepMinutes = 480
                playback.setSleepTimer(minutes: 480)
            } else {
                sleepMinutes = nil
                playback.setSleepTimer(minutes: nil)
            }
        } label: {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overnight mode")
                        .font(.body)
                        .foregroundStyle(Theme.halo)
                    Text("Eight hours with a gentle fade out")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                Spacer()
                if purchaseManager.isPlus {
                    Image(systemName: playback.overnightMode ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(playback.overnightMode ? Theme.gold : Theme.mist)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Overnight mode")
    }

    private var sleepTimerRow: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundStyle(Theme.gold)
            Text("Sleep timer")
                .foregroundStyle(Theme.halo)
            Spacer()
            Menu {
                Button("Off") {
                    sleepMinutes = nil
                    playback.setSleepTimer(minutes: nil)
                }
                Button("30 minutes") { setSleep(30) }
                Button("60 minutes") { setSleep(60) }
                Button("8 hours") { setSleep(480) }
            } label: {
                Text(sleepLabel)
                    .font(.footnote)
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(16)
    }

    private var downloadRow: some View {
        Button {
            if !purchaseManager.isPlus && !item.isPreset {
                showPaywall = true
                return
            }
            downloaded = true
        } label: {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(downloaded ? "Saved for offline" : "Keep it offline")
                        .foregroundStyle(Theme.halo)
                    Text("The audio file stays on this device")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                Spacer()
                if downloaded {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.success)
                } else if !purchaseManager.isPlus && !item.isPreset {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var soundscapeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Soundscape")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SoundscapeCatalog.all) { style in
                        Button {
                            if style.isPremium && !purchaseManager.isPlus {
                                showPaywall = true
                                return
                            }
                            playback.setSoundscape(named: style.name)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.body)
                                Text(style.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(playback.activeSoundscape == style.name ? Theme.midnightDeep : Theme.halo)
                            .frame(width: 92, height: 66)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(playback.activeSoundscape == style.name ? Theme.gold : Theme.cardFill)
                            )
                            .overlay(alignment: .topTrailing) {
                                if style.isPremium && !purchaseManager.isPlus {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.gold)
                                        .padding(6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(style.name)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var sleepLabel: String {
        guard let sleepMinutes else { return "Off" }
        if sleepMinutes >= 60 {
            return "\(sleepMinutes / 60) hr"
        }
        return "\(sleepMinutes) min"
    }

    private func setSleep(_ minutes: Int) {
        sleepMinutes = minutes
        playback.setSleepTimer(minutes: minutes)
    }

    private func recordPlay() {
        guard let sessionID = item.sessionID else { return }
        let descriptor = FetchDescriptor<AudioSession>(predicate: #Predicate { $0.id == sessionID })
        if let session = try? modelContext.fetch(descriptor).first {
            session.playCount += 1
            try? modelContext.save()
        }
    }
}
