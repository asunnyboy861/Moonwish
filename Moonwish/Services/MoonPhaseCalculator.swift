import Foundation

enum MoonPhaseCalculator {
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947182440)
    private static let synodicMonth: Double = 29.530588853

    static func phase(for date: Date = Date()) -> Double {
        let days = date.timeIntervalSince(referenceNewMoon) / 86400
        let cycles = days / synodicMonth
        let fraction = cycles - floor(cycles)
        return fraction < 0 ? fraction + 1 : fraction
    }

    static func illumination(for date: Date = Date()) -> Double {
        0.5 * (1 - cos(2 * .pi * phase(for: date)))
    }

    static func name(for date: Date = Date()) -> String {
        let value = phase(for: date)
        switch value {
        case 0..<0.06, 0.94...1: return "New Moon"
        case 0.06..<0.19: return "Waxing Crescent"
        case 0.19..<0.31: return "First Quarter"
        case 0.31..<0.44: return "Waxing Gibbous"
        case 0.44..<0.56: return "Full Moon"
        case 0.56..<0.69: return "Waning Gibbous"
        case 0.69..<0.81: return "Last Quarter"
        default: return "Waning Crescent"
        }
    }

    static func daysUntilFullMoon(from date: Date = Date()) -> Int {
        let current = phase(for: date)
        let target = 0.5
        var delta = target - current
        if delta < 0 { delta += 1 }
        return Int(delta * synodicMonth)
    }
}

enum DailyAffirmation {
    static let affirmations: [String] = [
        "What I want is already learning my name.",
        "I do not need to rush what is meant for me.",
        "My calm is the strongest thing about me.",
        "I am allowed to receive without earning it first.",
        "The version of me I am becoming is already here.",
        "I release the need to explain my timing.",
        "Softness is not weakness. It is my signal.",
        "Today, I choose the feeling before the proof.",
        "I make room for what I have been asking for.",
        "My wish is safe in the quiet.",
        "I am exactly where my next step begins.",
        "I trust the slow unfolding.",
        "There is nothing wrong with wanting more.",
        "I let the moon hold what I cannot yet see.",
        "I speak to myself like someone I love.",
        "What is mine will not require me to shrink.",
        "I am open, and I am steady.",
        "I give my future permission to surprise me.",
        "My breath is proof that I am here.",
        "I choose peace over proving.",
        "I am becoming easier to be.",
        "I release what I have outgrown with grace.",
        "My life is allowed to feel good.",
        "I keep the promise I made to myself.",
        "There is time for the things I care about.",
        "I welcome the ordinary magic of today.",
        "I am not behind. I am in my own rhythm.",
        "I let good things find me.",
        "My heart knows the way before my mind does.",
        "Tonight, I rest inside what I believe."
    ]

    static func today() -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return affirmations[(day - 1) % affirmations.count]
    }
}
