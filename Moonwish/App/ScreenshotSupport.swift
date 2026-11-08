import SwiftData
import SwiftUI
import UIKit

enum ScreenshotScene: String {
    case tonight
    case channel
    case board
    case journal
    case paywall

    static var current: ScreenshotScene? {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-screenshotMode"),
              let index = args.firstIndex(of: "-scene"),
              index + 1 < args.count else { return nil }
        return ScreenshotScene(rawValue: args[index + 1])
    }
}

enum ScreenshotMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMode")
    }
}

struct ScreenshotRootView: View {
    let scene: ScreenshotScene

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            StarField().ignoresSafeArea()
            switch scene {
            case .tonight:
                TonightView(showComposer: .constant(false))
            case .channel:
                ChannelView()
            case .board:
                BoardView()
            case .journal:
                JournalView()
            case .paywall:
                PaywallView()
            }
        }
    }
}

enum ScreenshotSeeder {
    static func seed(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Wish>()).count) ?? 0
        guard existing == 0 else { return }

        let calm = Wish(text: "I want to feel calm and confident before my next chapter", category: .myself, answers: ["Tonight", "Softness"])
        let career = Wish(text: "I want my work to feel steady and chosen", category: .career, answers: ["This week", "A new role"])
        let love = Wish(text: "I want to feel loved without chasing", category: .love, answers: ["No deadline", "Calm"])
        context.insert(calm)
        context.insert(career)
        context.insert(love)

        let sessions: [(Wish, String, String, Double)] = [
            (calm, "Myself Wish", "preset-deep-sleep.caf", 480),
            (calm, "Calm Reset", "preset-release.caf", 380),
            (career, "Career Flow", "preset-career-flow.caf", 430),
            (love, "Easy Love", "preset-easy-love.caf", 480)
        ]
        for (wish, title, file, duration) in sessions {
            let session = AudioSession(title: title, scriptJSON: "", fileName: file, voiceId: "", soundscape: "Theta Waves", duration: duration, engineUsed: "apple", qualityPassed: true)
            session.wish = wish
            context.insert(session)
        }

        let entries: [(JournalMethod, String, Double)] = [
            (.threeSixNine, "I feel calm and confident. I feel calm and confident. I feel calm and confident. My next chapter meets me with ease.", 0),
            (.scripting, "I am already living the version of my life where my work feels steady, chosen, and unhurried. I wake up without bracing.", -86400),
            (.gratitude, "Tonight I am grateful for the quiet hour before bed, the warm light in my room, and the courage to want more.", -3 * 86400)
        ]
        for (method, text, offset) in entries {
            let entry = JournalEntry(date: Date().addingTimeInterval(offset), method: method, text: text)
            context.insert(entry)
        }

        let state = StreakState(currentStreak: 12, bestStreak: 21, graceRemaining: 1, lastUpdated: Date())
        context.insert(state)

        for index in 0..<6 {
            let fileName = "screenshot-board-\(index).jpg"
            if let data = makeBoardImage(index: index) {
                try? data.write(to: AppConfig.boardDirectory.appendingPathComponent(fileName))
                let item = BoardItem(caption: "", imageFileName: fileName, orderIndex: index)
                context.insert(item)
            }
        }

        for dayOffset in 0..<7 {
            let record = DailyRecord(day: Date().addingTimeInterval(TimeInterval(-dayOffset * 86400)), listened: true, journaled: dayOffset % 2 == 0)
            context.insert(record)
        }

        try? context.save()
    }

    private static func makeBoardImage(index: Int) -> Data? {
        let palettes: [[UIColor]] = [
            [UIColor(red: 0.27, green: 0.20, blue: 0.46, alpha: 1), UIColor(red: 0.08, green: 0.09, blue: 0.20, alpha: 1)],
            [UIColor(red: 0.85, green: 0.67, blue: 0.43, alpha: 1), UIColor(red: 0.20, green: 0.12, blue: 0.10, alpha: 1)],
            [UIColor(red: 0.16, green: 0.38, blue: 0.40, alpha: 1), UIColor(red: 0.05, green: 0.10, blue: 0.14, alpha: 1)],
            [UIColor(red: 0.56, green: 0.30, blue: 0.28, alpha: 1), UIColor(red: 0.13, green: 0.06, blue: 0.08, alpha: 1)],
            [UIColor(red: 0.34, green: 0.35, blue: 0.56, alpha: 1), UIColor(red: 0.09, green: 0.10, blue: 0.22, alpha: 1)],
            [UIColor(red: 0.60, green: 0.56, blue: 0.44, alpha: 1), UIColor(red: 0.15, green: 0.14, blue: 0.11, alpha: 1)]
        ]
        let colors = palettes[index % palettes.count]
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            let circle = UIBezierPath(ovalIn: CGRect(x: 380, y: 80, width: 120, height: 120))
            UIColor.white.withAlphaComponent(0.18).setFill()
            circle.fill()
            let line = UIBezierPath()
            line.move(to: CGPoint(x: 80, y: 460))
            line.addLine(to: CGPoint(x: 520, y: 520))
            UIColor.white.withAlphaComponent(0.10).setStroke()
            line.lineWidth = 10
            line.stroke()
        }
        return image.jpegData(compressionQuality: 0.82)
    }
}
