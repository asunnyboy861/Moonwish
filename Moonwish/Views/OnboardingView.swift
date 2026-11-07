import SwiftUI

struct OnboardingView: View {
    let onStart: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            StarField().ignoresSafeArea()
            VStack(spacing: 26) {
                Spacer()
                BreathingMoon(phase: MoonPhaseCalculator.phase(), glow: 0.6)
                    .frame(maxWidth: 360)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.92)
                VStack(spacing: 10) {
                    Text("Tell the Moon.\nIt listens.")
                        .font(Theme.title(.largeTitle))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.halo)
                    Text("Speak one wish tonight. Moonwish turns it into a personalized manifestation audio that stays with you until morning.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.mist)
                        .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1 : 0)
                Spacer()
                VStack(spacing: 12) {
                    Button("Create my first wish", action: onStart)
                        .buttonStyle(GoldButtonStyle())
                        .accessibilityHint("Opens the wish creation flow")
                    Text("Free to start. No account needed to listen.")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                appeared = true
            }
        }
    }
}
