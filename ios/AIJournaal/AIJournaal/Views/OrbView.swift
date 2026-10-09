import SwiftUI

/// Het hart van de speler: een gloeiende schijf met een krans van staafjes
/// die meebeweegt op het ritme van de voorgelezen woorden.
struct OrbView: View {
    var isPlaying: Bool
    var lastPulse: Date
    var stateChanged: Date
    /// Aantal staafjes in de krans; minder voor kleine weergaven.
    var barCount: Int = 72
    var showsRipples: Bool = true

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, now: timeline.date)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, now: Date) {
        let time = now.timeIntervalSinceReferenceDate
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = min(size.width, size.height) / 2

        // Vloeiende overgang tussen stilstaan en afspelen.
        let ramp = min(1, max(0, now.timeIntervalSince(stateChanged) / 0.7))
        let eased = ramp * ramp * (3 - 2 * ramp)
        let activity = isPlaying ? eased : 1 - eased
        // Korte uitslag bij elk uitgesproken woord.
        let sincePulse = max(0, now.timeIntervalSince(lastPulse))
        let pulse = exp(-sincePulse * 5) * activity

        let breathing = 0.012 * sin(time * 1.2)
        let core = outer * (0.40 + breathing + 0.028 * pulse)

        // 1. Gloed
        let haloRect = CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)
        context.fill(
            Path(ellipseIn: haloRect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Theme.amber.opacity(0.16 + 0.22 * activity), location: 0.30),
                    .init(color: Theme.violet.opacity(0.10 + 0.10 * activity), location: 0.62),
                    .init(color: .clear, location: 1)
                ]),
                center: center,
                startRadius: 0,
                endRadius: outer
            )
        )

        // 2. Uitdijende ringen
        if showsRipples && activity > 0.01 {
            for ring in 0..<3 {
                let cycle = (time / 3.4 + Double(ring) / 3).truncatingRemainder(dividingBy: 1)
                let radius = core + (outer * 0.98 - core) * cycle
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                let alpha = (1 - cycle) * 0.30 * activity
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Theme.blend(cycle).opacity(alpha)),
                    lineWidth: 1.2
                )
            }
        }

        // 3. Krans van staafjes
        let inner = core + outer * 0.07
        let barWidth = max(1.5, outer * 0.020)
        let style = StrokeStyle(lineWidth: barWidth, lineCap: .round)
        for index in 0..<barCount {
            let step = Double(index)
            let angle = step / Double(barCount) * 2 * Double.pi - Double.pi / 2
            let wave = 0.5 + 0.5 * sin(time * 2.3 + step * 0.55) * sin(time * 1.4 + step * 0.21)
            let shimmer = 0.5 + 0.5 * sin(time * 5.1 + step * 1.9)
            let level = 0.030
                + 0.020 * (0.5 + 0.5 * sin(time * 0.9 + step * 0.35))
                + activity * (0.050 + 0.150 * wave + 0.110 * pulse * shimmer)
            let length = outer * level
            let directionX = cos(angle)
            let directionY = sin(angle)
            var bar = Path()
            bar.move(to: CGPoint(x: center.x + inner * directionX, y: center.y + inner * directionY))
            bar.addLine(
                to: CGPoint(
                    x: center.x + (inner + length) * directionX,
                    y: center.y + (inner + length) * directionY
                )
            )
            let tint = 0.5 + 0.5 * cos(angle - time * 0.22)
            context.stroke(bar, with: .color(Theme.blend(tint).opacity(0.55 + 0.45 * activity)), style: style)
        }

        // 4. Kern
        let coreRect = CGRect(x: center.x - core, y: center.y - core, width: core * 2, height: core * 2)
        let corePath = Path(ellipseIn: coreRect)
        context.fill(
            corePath,
            with: .conicGradient(
                Gradient(colors: [Theme.violet, Theme.orchid, Theme.apricot, Theme.amber, Theme.violet]),
                center: center,
                angle: .radians(time * 0.28)
            )
        )
        context.fill(
            corePath,
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0)]),
                center: CGPoint(x: center.x - core * 0.35, y: center.y - core * 0.40),
                startRadius: 0,
                endRadius: core * 1.1
            )
        )
        context.stroke(corePath, with: .color(Color.white.opacity(0.22)), lineWidth: 1)

        // 5. Stem-icoon in de kern
        let glyphCount = 5
        let spacing = core * 0.26
        let glyphWidth = core * 0.13
        let resting: [Double] = [0.18, 0.34, 0.50, 0.30, 0.16]
        for index in 0..<glyphCount {
            let step = Double(index)
            let motion = 0.5 + 0.5 * sin(time * 6.0 + step * 1.3)
            let height = core * (resting[index] + activity * (0.10 + 0.42 * pulse) * motion)
            let x = center.x + (step - 2) * spacing
            let rect = CGRect(x: x - glyphWidth / 2, y: center.y - height / 2, width: glyphWidth, height: height)
            context.fill(
                Path(roundedRect: rect, cornerRadius: glyphWidth / 2),
                with: .color(Theme.ink.opacity(0.88))
            )
        }
    }
}
