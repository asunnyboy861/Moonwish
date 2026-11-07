import SwiftUI

@main
struct MoonwishApp: App {
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(purchaseManager)
                .modelContainer(DataStore.container)
                .tint(Theme.gold)
                .preferredColorScheme(.dark)
        }
    }
}
