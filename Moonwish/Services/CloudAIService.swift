import Foundation
import StoreKit

enum BYOProvider: String, CaseIterable, Identifiable {
    case glm
    case openAI
    case gemini
    case deepSeek
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glm: return "GLM"
        case .openAI: return "OpenAI-compatible"
        case .gemini: return "Gemini"
        case .deepSeek: return "DeepSeek"
        case .custom: return "Custom endpoint"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .glm: return "https://api.z.ai/api/paas/v4/chat/completions"
        case .openAI: return "https://api.openai.com/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        case .deepSeek: return "https://api.deepseek.com/chat/completions"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .glm: return "glm-5.3-flash"
        case .openAI: return "gpt-4.1-mini"
        case .gemini: return "gemini-2.5-flash"
        case .deepSeek: return "deepseek-chat"
        case .custom: return ""
        }
    }
}

final class BYOSettingsStore: ObservableObject {
    static let shared = BYOSettingsStore()

    @Published var provider: BYOProvider
    @Published var baseURL: String
    @Published var model: String

    private let defaults = UserDefaults.standard
    private let keyAccount = "byo_api_key"

    private init() {
        let providerRaw = defaults.string(forKey: "byo_provider") ?? BYOProvider.glm.rawValue
        self.provider = BYOProvider(rawValue: providerRaw) ?? .glm
        self.baseURL = defaults.string(forKey: "byo_base_url") ?? BYOProvider.glm.defaultBaseURL
        self.model = defaults.string(forKey: "byo_model") ?? BYOProvider.glm.defaultModel
    }

    var apiKey: String? {
        KeychainHelper.read(keyAccount)
    }

    var hasKey: Bool {
        guard let apiKey else { return false }
        return !apiKey.isEmpty
    }

    func apply(provider: BYOProvider) {
        self.provider = provider
        baseURL = provider.defaultBaseURL
        model = provider.defaultModel
        persist()
    }

    func persist() {
        defaults.set(provider.rawValue, forKey: "byo_provider")
        defaults.set(baseURL, forKey: "byo_base_url")
        defaults.set(model, forKey: "byo_model")
    }

    func saveKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainHelper.delete(keyAccount)
        } else {
            KeychainHelper.save(trimmed, account: keyAccount)
        }
    }

    func clearKey() {
        KeychainHelper.delete(keyAccount)
    }
}

final class CloudAIService {
    static let shared = CloudAIService()

    private let model = "glm-5.3-flash"

    func generateWithBYO(input: WishInput) async throws -> String {
        let settings = BYOSettingsStore.shared
        guard let key = settings.apiKey, !key.isEmpty,
              let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AIError.engineUnavailable
        }
        let messages: [[String: Any]] = [
            ["role": "system", "content": ScriptPrompts.system],
            ["role": "user", "content": ScriptPrompts.user(input)]
        ]
        var payload: [String: Any] = [
            "model": settings.model,
            "messages": messages,
            "temperature": 0.8,
            "max_tokens": 4096
        ]
        if settings.provider != .gemini {
            payload["response_format"] = ["type": "json_object"]
        }
        return try await send(url: url, payload: payload, authHeader: "Bearer \(key)")
    }

    func generateWithProxy(input: WishInput) async throws -> String {
        let messages: [[String: Any]] = [
            ["role": "system", "content": ScriptPrompts.system],
            ["role": "user", "content": ScriptPrompts.user(input)]
        ]
        let payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": 4096,
            "response_format": ["type": "json_object"]
        ]
        var body: [String: Any] = [
            "appId": AppConfig.glmAppId,
            "userId": proxyUserId,
            "payload": payload
        ]
        if let jws = await currentEntitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey = proxyDevKey {
            body["devKey"] = devKey
        } else {
            throw AIError.receiptRejected
        }
        do {
            return try await sendWithFallback(payload: body)
        } catch AIError.network {
            return try await send(url: proxyFallbackURL, payload: body, authHeader: nil)
        }
    }

    private let proxyURL = URL(string: "https://cramjam-api.calcs.top")!
    private let proxyFallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!

    private var proxyDevKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    private var proxyUserId: String {
        if let id = KeychainHelper.read("proxy_user_id") { return id }
        let id = UUID().uuidString
        KeychainHelper.save(id, account: "proxy_user_id")
        return id
    }

    private func currentEntitlementJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  transaction.productType == .autoRenewable else { continue }
            if transaction.productID == AppConfig.monthlyProductId || transaction.productID == AppConfig.yearlyProductId {
                let jws = result.jwsRepresentation
                if !jws.isEmpty { return jws }
            }
        }
        return nil
    }

    private func sendWithFallback(payload: [String: Any]) async throws -> String {
        do {
            return try await send(url: proxyURL, payload: payload, authHeader: nil)
        } catch AIError.network {
            return try await send(url: proxyFallbackURL, payload: payload, authHeader: nil)
        }
    }

    private func send(url: URL, payload: [String: Any], authHeader: String?) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 40
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authHeader {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.network("Cloud connection failed. Check your network and try again.")
        }
        guard let http = response as? HTTPURLResponse else {
            throw AIError.network("Unexpected cloud response.")
        }
        switch http.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String,
                  !content.isEmpty else {
                throw AIError.emptyResponse
            }
            return content
        case 401:
            throw AIError.receiptRejected
        case 429:
            throw AIError.rateLimited
        default:
            let message = String(data: data.prefix(160), encoding: .utf8) ?? ""
            throw AIError.network("Cloud service error (\(http.statusCode)). \(message)")
        }
    }
}
