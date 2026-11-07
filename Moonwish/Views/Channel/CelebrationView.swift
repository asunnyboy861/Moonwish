import SwiftUI

struct CelebrationView: View {
    let wish: Wish

    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                VStack(spacing: 24) {
                    CelebrationCard(wish: wish)
                        .frame(maxWidth: 340)
                    VStack(spacing: 12) {
                        Button {
                            renderShareImage()
                        } label: {
                            Label("Share my celebration", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(GoldButtonStyle())
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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

    private func renderShareImage() {
        let renderer = ImageRenderer(content: CelebrationCard(wish: wish).frame(width: 360, height: 520))
        renderer.scale = 3
        if let image = renderer.uiImage {
            shareImage = image
            showShare = true
        }
    }
}

struct CelebrationCard: View {
    let wish: Wish

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.background)
            StarField()
            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.gold)
                Text("IT HAPPENED")
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Theme.gold)
                Text(wish.text)
                    .font(Theme.title(.title2))
                    .foregroundStyle(Theme.halo)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                MoonCanvas(phase: MoonPhaseCalculator.phase(for: wish.createdAt), glow: 0.9)
                    .frame(height: 140)
                VStack(spacing: 4) {
                    Text("Wished on \(dateText(wish.createdAt))")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                    Text("Moonwish")
                        .font(.system(.caption2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(24)
        }
        .frame(height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
