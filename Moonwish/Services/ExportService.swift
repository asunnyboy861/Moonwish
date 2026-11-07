import Foundation
import SwiftData

enum ExportService {
    static func makePackage(wishes: [Wish], entries: [JournalEntry], sessions: [AudioSession]) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let folderName = "Moonwish-Export-\(formatter.string(from: Date()))"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let audioFolder = folder.appendingPathComponent("Audio", isDirectory: true)
            try FileManager.default.createDirectory(at: audioFolder, withIntermediateDirectories: true)

            for session in sessions where !session.fileName.isEmpty {
                let source = AppConfig.sessionURL(fileName: session.fileName)
                if FileManager.default.fileExists(atPath: source.path) {
                    let destination = audioFolder.appendingPathComponent(session.fileName)
                    try? FileManager.default.copyItem(at: source, to: destination)
                }
            }

            let wishPayload = wishes.map { wish in
                [
                    "text": wish.text,
                    "category": wish.domain.rawValue,
                    "createdAt": ISO8601DateFormatter().string(from: wish.createdAt),
                    "status": wish.status.rawValue,
                    "sessions": wish.sessions.count
                ] as [String: Any]
            }
            let journalPayload = entries.map { entry in
                [
                    "date": ISO8601DateFormatter().string(from: entry.date),
                    "method": entry.method.rawValue,
                    "text": entry.text
                ] as [String: Any]
            }
            let manifest: [String: Any] = [
                "app": AppConfig.appName,
                "exportedAt": ISO8601DateFormatter().string(from: Date()),
                "wishes": wishPayload,
                "journal": journalPayload
            ]
            let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: folder.appendingPathComponent("moonwish-export.json"))
            return folder
        } catch {
            return nil
        }
    }
}
