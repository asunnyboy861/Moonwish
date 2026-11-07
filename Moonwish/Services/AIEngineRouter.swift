import Foundation

struct GenerationResult {
    let script: ManifestationScript
    let engine: String
}

@MainActor
final class AIEngineRouter {
    static let shared = AIEngineRouter()

    private init() {}

    func generate(input: WishInput, isPlus: Bool, allowCloud: Bool = true) async -> GenerationResult {
        let byoSettings = BYOSettingsStore.shared

        if allowCloud, byoSettings.hasKey {
            if let script = await attempt({ try await CloudAIService.shared.generateWithBYO(input: input) }) {
                return GenerationResult(script: script, engine: "byo")
            }
        }

        if allowCloud, isPlus, CloudQuotaService.shared.canUseCloud {
            if let script = await attempt({ try await CloudAIService.shared.generateWithProxy(input: input) }) {
                CloudQuotaService.shared.recordCloudUse()
                return GenerationResult(script: script, engine: "glm")
            }
        }

        if AppleIntelligenceService.isAvailable {
            if let script = await attempt({ try await AppleIntelligenceService.generate(input: input) }) {
                return GenerationResult(script: script, engine: "apple")
            }
        }

        return GenerationResult(script: LocalScriptComposer.make(input: input), engine: "local")
    }

    private func attempt(_ operation: @escaping () async throws -> String) async -> ManifestationScript? {
        guard let raw = try? await operation() else { return nil }
        return ScriptValidator.parse(raw)
    }
}

final class CloudQuotaService {
    static let shared = CloudQuotaService()
    private let defaults = UserDefaults.standard
    private let monthlyLimit = 30

    var monthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    var usedThisMonth: Int {
        guard defaults.string(forKey: "cloud_quota_month") == monthKey else { return 0 }
        return defaults.integer(forKey: "cloud_quota_used")
    }

    var boosterBalance: Int {
        defaults.integer(forKey: "cloud_booster_balance")
    }

    var remaining: Int {
        max(0, monthlyLimit - usedThisMonth) + boosterBalance
    }

    var canUseCloud: Bool {
        remaining > 0
    }

    func recordCloudUse() {
        if defaults.string(forKey: "cloud_quota_month") != monthKey {
            defaults.set(monthKey, forKey: "cloud_quota_month")
            defaults.set(0, forKey: "cloud_quota_used")
        }
        if usedThisMonth < monthlyLimit {
            defaults.set(usedThisMonth + 1, forKey: "cloud_quota_used")
        } else if boosterBalance > 0 {
            defaults.set(boosterBalance - 1, forKey: "cloud_booster_balance")
        }
    }

    func addBooster(_ amount: Int) {
        defaults.set(boosterBalance + amount, forKey: "cloud_booster_balance")
    }

    var resetDateText: String {
        let calendar = Calendar.current
        let now = Date()
        if let next = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: next)
        }
        return "next month"
    }
}
