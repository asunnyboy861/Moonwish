import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleIntelligenceService {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            default:
                return false
            }
        }
        #endif
        return false
    }

    static func generate(input: WishInput) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: ScriptPrompts.system)
            let response = try await session.respond(to: ScriptPrompts.user(input))
            return response.content
        }
        #endif
        throw AIError.engineUnavailable
    }
}

enum AIError: LocalizedError {
    case engineUnavailable
    case emptyResponse
    case invalidFormat
    case network(String)
    case receiptRejected
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .engineUnavailable: return "The on-device engine is not available right now."
        case .emptyResponse: return "The engine returned an empty response."
        case .invalidFormat: return "The generated script did not match the expected format."
        case .network(let message): return message
        case .receiptRejected: return "This is a Plus feature. Restore your purchase or subscribe to continue."
        case .rateLimited: return "Too many cloud requests right now. Please try again later."
        }
    }
}
