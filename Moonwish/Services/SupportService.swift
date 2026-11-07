import Foundation

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

struct FeedbackResponse: Codable {
    let success: Bool?
    let error: String?
}

enum SupportService {
    static func submit(name: String, email: String, subject: String, message: String) async throws {
        var request = URLRequest(url: AppConfig.feedbackURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = FeedbackRequest(
            name: name,
            email: email,
            subject: subject,
            message: message,
            app_name: AppConfig.appName
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupportError.message("Unexpected response. Please try again.")
        }
        if http.statusCode >= 200 && http.statusCode < 300 {
            return
        }
        if let decoded = try? JSONDecoder().decode(FeedbackResponse.self, from: data),
           let message = decoded.error, !message.isEmpty {
            throw SupportError.message(message)
        }
        throw SupportError.message("Something went wrong. Please try again.")
    }
}

enum SupportError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}
