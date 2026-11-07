import LocalAuthentication
import SwiftData
import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("faceIDLock") private var faceIDLock = false
    @State private var showOnboarding = false
    @State private var showComposer = false
    @State private var locked = false
    @State private var lockError: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            TabView {
                TonightView(showComposer: $showComposer)
                    .tabItem { Label("Tonight", systemImage: "moon.stars.fill") }
                ChannelView()
                    .tabItem { Label("My Channel", systemImage: "waveform") }
                BoardView()
                    .tabItem { Label("Board", systemImage: "square.grid.2x2.fill") }
                JournalView()
                    .tabItem { Label("Journal", systemImage: "book.closed.fill") }
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }

            if locked {
                LockGateView(lockError: $lockError) {
                    authenticate()
                }
            }
        }
        .onAppear {
            if !hasOnboarded {
                showOnboarding = true
            }
            if faceIDLock {
                locked = true
                authenticate()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if faceIDLock {
                    locked = true
                    authenticate()
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasOnboarded = true
                showOnboarding = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showComposer = true
                }
            }
        }
        .fullScreenCover(isPresented: $showComposer) {
            WishComposerView()
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            locked = false
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your Moonwish space") { success, _ in
            DispatchQueue.main.async {
                locked = !success
                lockError = success ? nil : "Face ID did not recognize you. Try again."
            }
        }
    }
}

struct LockGateView: View {
    @Binding var lockError: String?
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Theme.midnightDeep.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.gold)
                Text("Moonwish is private")
                    .font(Theme.title(.title2))
                    .foregroundStyle(Theme.halo)
                if let lockError {
                    Text(lockError)
                        .font(.footnote)
                        .foregroundStyle(Theme.mist)
                }
                Button("Unlock", action: onUnlock)
                    .buttonStyle(GoldButtonStyle(compact: true))
            }
            .padding(24)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
