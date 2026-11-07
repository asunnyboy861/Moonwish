import Foundation

enum AppConfig {
    static let bundleId = "com.zzoutuo.Moonwish"
    static let appName = "Moonwish"
    static let contactEmail = "iocompile67692@gmail.com"
    static let feedbackURL = URL(string: "https://msg.calcs.top/api/feedback")!
    static let policyBase = "https://asunnyboy861.github.io/Moonwish"
    static let supportURL = URL(string: "\(policyBase)/support.html")!
    static let privacyURL = URL(string: "\(policyBase)/privacy.html")!
    static let termsURL = URL(string: "\(policyBase)/terms.html")!

    static let monthlyProductId = "com.zzoutuo.Moonwish.plus.monthly"
    static let yearlyProductId = "com.zzoutuo.Moonwish.plus.yearly"
    static let boosterProductId = "com.zzoutuo.Moonwish.cloud.booster"

    static let glmAppId = "moonwish"

    static var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    static var sessionsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("MoonwishSessions", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    static var boardDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("MoonwishBoard", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    static var soundscapeDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("MoonwishSoundscapes", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    static func sessionURL(fileName: String) -> URL {
        sessionsDirectory.appendingPathComponent(fileName)
    }
}
