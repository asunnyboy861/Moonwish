import SwiftUI

enum Theme {
    static let midnightDeep = Color(red: 0.024, green: 0.035, blue: 0.094)
    static let midnight = Color(red: 0.043, green: 0.063, blue: 0.149)
    static let dusk = Color(red: 0.102, green: 0.122, blue: 0.239)
    static let gold = Color(red: 0.961, green: 0.851, blue: 0.659)
    static let halo = Color(red: 0.933, green: 0.949, blue: 1.0)
    static let mist = Color(red: 0.70, green: 0.74, blue: 0.86)
    static let cardFill = Color.white.opacity(0.07)
    static let cardStroke = Color.white.opacity(0.13)
    static let success = Color(red: 0.62, green: 0.85, blue: 0.72)
    static let danger = Color(red: 0.94, green: 0.52, blue: 0.52)

    static var background: LinearGradient {
        LinearGradient(colors: [midnightDeep, midnight, dusk], startPoint: .top, endPoint: .bottom)
    }

    static func title(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .serif, weight: .semibold)
    }

    static func body(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .default)
    }
}

struct MoonCardModifier: ViewModifier {
    var padding: CGFloat
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func moonCard(padding: CGFloat = 16, fill: Color = Theme.cardFill) -> some View {
        modifier(MoonCardModifier(padding: padding, fill: fill))
    }
}

struct GoldButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(compact ? .subheadline : .headline, design: .default, weight: .semibold))
            .foregroundStyle(Theme.midnightDeep)
            .padding(.vertical, compact ? 10 : 16)
            .padding(.horizontal, compact ? 18 : 24)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(
                Capsule().fill(Theme.gold)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .default, weight: .medium))
            .foregroundStyle(Theme.halo)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(
                Capsule().stroke(Theme.cardStroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .default, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(Theme.mist)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(Theme.halo)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Capsule().fill(Theme.cardFill))
        .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
    }
}

struct StatusBanner: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            Text(text)
                .font(.footnote)
        }
        .foregroundStyle(isError ? Theme.danger : Theme.success)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.cardFill)
        )
    }
}
