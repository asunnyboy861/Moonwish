import Foundation

struct WishInput {
    let wish: String
    let category: String
    let answers: [String]
    let targetDate: Date?
}

struct ManifestationScript: Codable, Hashable {
    var title: String
    var opening: String
    var lines: [String]
    var closing: String
    var minutes: Int

    var segments: [String] {
        var parts: [String] = [opening]
        parts.append(contentsOf: lines)
        parts.append(closing)
        return parts
    }

    var plainText: String {
        segments.joined(separator: "\n")
    }
}

enum ScriptPrompts {
    static let system = """
    You are Moonwish, a calm manifestation audio writer for a bedtime app. Write a soothing guided affirmation script in second person, present tense, American English. Keep every sentence short and speakable. Refer to the user's wish naturally, at most four times. Never promise a specific outcome, never mention health, therapy, diagnosis, law, or money guarantees, never mention AI or that you are a model. Return ONLY valid JSON with these keys: title (string, max 40 characters), opening (string, one sentence), lines (array of 12 to 24 short sentences), closing (string, one sentence), minutes (integer 8).
    """

    static func user(_ input: WishInput) -> String {
        var parts: [String] = []
        parts.append("Wish: \(input.wish)")
        parts.append("Life area: \(input.category)")
        if !input.answers.isEmpty {
            parts.append("Answers: \(input.answers.joined(separator: " | "))")
        }
        if let targetDate = input.targetDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append("Time capsule date: \(formatter.string(from: targetDate))")
        }
        parts.append("Write the script now.")
        return parts.joined(separator: "\n")
    }
}

enum ScriptValidator {
    static func parse(_ raw: String) -> ManifestationScript? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let script = try? JSONDecoder().decode(ManifestationScript.self, from: data) {
            return sanitize(script)
        }
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            let substring = String(trimmed[start...end])
            if let data = substring.data(using: .utf8),
               let script = try? JSONDecoder().decode(ManifestationScript.self, from: data) {
                return sanitize(script)
            }
        }
        let lines = trimmed
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"'-*•0123456789.")) }
            .filter { !$0.isEmpty && $0.count > 8 && !$0.contains("{") }
        guard lines.count >= 6 else { return nil }
        return ManifestationScript(
            title: "Tonight's Letter",
            opening: lines.first ?? "",
            lines: Array(lines.dropFirst().dropLast()),
            closing: lines.last ?? "",
            minutes: 8
        )
    }

    static func sanitize(_ script: ManifestationScript) -> ManifestationScript? {
        var cleaned = script
        cleaned.title = script.title.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned.lines = script.lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if cleaned.title.isEmpty { cleaned.title = "Tonight's Letter" }
        if cleaned.lines.count < 6 { return nil }
        if cleaned.minutes < 5 || cleaned.minutes > 20 { cleaned.minutes = 8 }
        return cleaned
    }
}

enum LocalScriptComposer {
    static func make(input: WishInput) -> ManifestationScript {
        let wish = normalizedWish(input.wish)
        let domain = WishDomain(rawValue: input.category) ?? .myself
        let tone = input.answers.last ?? ""
        let themeLines = lines(for: domain)
        var body: [String] = []

        body.append("Tonight, you give yourself permission to want this.")
        body.append("Your wish is simple and true: \(wish).")
        body.append("You do not need to force it. You only need to feel it.")
        body.append(contentsOf: themeLines)
        body.append("Notice your shoulders softening as you listen.")
        body.append("Notice the quiet space around your breath.")
        body.append("You are allowed to rest inside this feeling.")
        if !tone.isEmpty {
            body.append("You chose \(tone.lowercased()), and that is exactly enough.")
        }
        body.append("The moon keeps this wish with you all night.")
        body.append("You can let go of the how, and keep the what.")
        body.append("Every slow breath makes this feel more familiar.")
        body.append("It is already taking shape in the quiet parts of you.")
        body.append("You are safe to want what you want.")
        body.append("You are safe to receive it in its own perfect time.")

        return ManifestationScript(
            title: "\(domain.rawValue) Wish",
            opening: "Take one slow breath in, and let the day fall away.",
            lines: body,
            closing: "Sleep well. Your wish is held until morning.",
            minutes: 8
        )
    }

    static func normalizedWish(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["i want to ", "i want ", "i wish ", "i hope ", "i would love to ", "i would love "]
        for prefix in prefixes where value.lowercased().hasPrefix(prefix) {
            value = String(value.dropFirst(prefix.count))
        }
        while value.hasSuffix(".") || value.hasSuffix("!") || value.hasSuffix("?") {
            value.removeLast()
        }
        if value.isEmpty { return "welcome more of what matters to me" }
        return value
    }

    static func lines(for domain: WishDomain) -> [String] {
        switch domain {
        case .love:
            return [
                "You are easy to love, and you are easy to choose.",
                "Warmth moves toward you without effort.",
                "You speak kindly to yourself first, and love follows.",
                "The right connection feels calm, not confusing.",
                "You are open, and you are not chasing.",
                "Your heart knows how to receive affection.",
                "You let love be simple tonight.",
                "You are worthy of steady, gentle connection."
            ]
        case .money:
            return [
                "Money is a calm guest in your life, not a fearful one.",
                "You are open to steady streams of support.",
                "You trust yourself with the resources that arrive.",
                "Abundance can be quiet, ordinary, and real.",
                "You make room for more without gripping it.",
                "You are allowed to be paid well for what you give.",
                "Your generosity and your safety can live together.",
                "You welcome what sustains you."
            ]
        case .career:
            return [
                "Your work is finding its right shape around you.",
                "The next door opens when your hands are free.",
                "You trust the pace of your becoming.",
                "You bring real value wherever you place your attention.",
                "Clarity arrives in small, usable pieces.",
                "You are allowed to begin before you feel ready.",
                "The path reveals itself one honest step at a time.",
                "You are building something that fits your life."
            ]
        case .myself:
            return [
                "You are becoming someone you genuinely respect.",
                "Your peace is not a reward. It is a practice.",
                "You meet yourself with patience, not pressure.",
                "Your body is allowed to slow down tonight.",
                "You are proud of the quiet work no one sees.",
                "You choose yourself without guilt.",
                "You are soft and steady at the same time.",
                "You belong to your own life."
            ]
        }
    }
}
