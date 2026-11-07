import Foundation
import SwiftData

enum DataStore {
    static let container: ModelContainer = {
        let schema = Schema([
            Wish.self,
            AudioSession.self,
            DailyRecord.self,
            JournalEntry.self,
            BoardItem.self,
            StreakState.self
        ])
        do {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: [cloud])
        } catch {
            let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try! ModelContainer(for: schema, configurations: [local])
        }
    }()

    static var iCloudAccountAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
