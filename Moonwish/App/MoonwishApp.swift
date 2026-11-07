import SwiftUI

@main
struct MoonwishApp: App {
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            if let container = DataStore.container {
                RootTabView()
                    .environmentObject(purchaseManager)
                    .modelContainer(container)
                    .tint(Theme.gold)
                    .preferredColorScheme(.dark)
            } else {
                StorageUnavailableView()
            }
        }
    }
}

struct StorageUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Theme.gold)
                Text("Storage is unavailable")
                    .font(Theme.title(.title2))
                    .foregroundStyle(Theme.halo)
                Text("Moonwish could not open its local database. Please restart the app or reinstall it from the App Store.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.mist)
                    .padding(.horizontal, 28)
            }
        }
    }
}
