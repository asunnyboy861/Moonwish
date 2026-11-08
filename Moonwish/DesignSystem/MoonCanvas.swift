import SwiftUI

struct MoonCanvas: View {
    var phase: Double
    var glow: Double

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let radius = side * 0.30
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let moonRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

            let glowRadius = min(side * 0.48, radius * (1.55 + 0.35 * glow))
            let glowRect = CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)
            context.drawLayer { layer in
                layer.clip(to: Path(ellipseIn: glowRect))
                layer.fill(Path(glowRect), with: .radialGradient(
                    Gradient(colors: [Theme.gold.opacity(0.24 + 0.2 * glow), Theme.gold.opacity(0.0)]),
                    center: center,
                    startRadius: radius * 0.7,
                    endRadius: glowRadius
                ))
            }

            context.fill(Path(ellipseIn: moonRect), with: .color(Theme.gold))

            let illumination = max(0, min(1, 0.5 * (1 - cos(2 * .pi * phase))))
            let shadowCenter = CGPoint(x: center.x + radius * 2 * illumination, y: center.y)
            let shadowRect = CGRect(x: shadowCenter.x - radius, y: shadowCenter.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: shadowRect), with: .color(Theme.midnightDeep.opacity(0.94)))

            context.fill(Path(ellipseIn: moonRect), with: .linearGradient(
                Gradient(colors: [Color.white.opacity(0.18), Color.clear]),
                startPoint: CGPoint(x: moonRect.minX, y: moonRect.minY),
                endPoint: CGPoint(x: moonRect.maxX, y: moonRect.maxY)
            ))
        }
        .accessibilityHidden(true)
    }
}

struct StarField: View {
    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: 42)
            for _ in 0..<90 {
                let x = Double.random(in: 0...1, using: &generator) * size.width
                let y = Double.random(in: 0...1, using: &generator) * size.height * 0.7
                let r = Double.random(in: 0.4...1.4, using: &generator)
                let opacity = Double.random(in: 0.15...0.65, using: &generator)
                let rect = CGRect(x: x, y: y, width: r, height: r)
                context.fill(Path(ellipseIn: rect), with: .color(Theme.halo.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct BreathingMoon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var phase: Double
    var glow: Double

    var body: some View {
        MoonCanvas(phase: phase, glow: glow)
            .scaleEffect(reduceMotion ? 1 : (expanded ? 1.03 : 0.97))
            .animation(reduceMotion ? nil : .easeInOut(duration: 7).repeatForever(autoreverses: true), value: expanded)
            .onAppear { expanded = true }
            .frame(height: 260)
    }
}
