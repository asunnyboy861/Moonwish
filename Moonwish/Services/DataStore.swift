import Foundation
import SwiftData

enum DataStore {
    static let container: ModelContainer? = {
        let schema = Schema([
            Wish.self,
            AudioSession.self,
            DailyRecord.self,
            JournalEntry.self,
            BoardItem.self,
            StreakState.self
        ])
        if let cloud = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]) {
            return cloud
        }
        if let local = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)]) {
            return local
        }
        return try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    }()

    static var iCloudAccountAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
