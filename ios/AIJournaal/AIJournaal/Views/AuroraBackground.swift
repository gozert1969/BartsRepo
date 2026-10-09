import SwiftUI

/// Traag bewegende wolken van paars en oranje op een donkere ondergrond.
struct AuroraBackground: View {
    /// 0 = ingetogen (overzicht), 1 = vol (speler).
    var intensity: Double = 1

    private struct Blob {
        let color: Color
        let x: Double
        let y: Double
        let radius: Double
        let speed: Double
        let phase: Double
        let opacity: Double
    }

    private static let blobs: [Blob] = [
        Blob(color: Theme.violet, x: 0.18, y: 0.14, radius: 0.62, speed: 0.11, phase: 0.0, opacity: 0.70),
        Blob(color: Theme.amber, x: 0.88, y: 0.40, radius: 0.48, speed: 0.09, phase: 1.7, opacity: 0.52),
        Blob(color: Theme.plum, x: 0.50, y: 0.66, radius: 0.74, speed: 0.07, phase: 3.1, opacity: 0.85),
        Blob(color: Theme.orchid, x: 0.10, y: 0.86, radius: 0.40, speed: 0.13, phase: 4.4, opacity: 0.34),
        Blob(color: Theme.amber, x: 0.80, y: 0.98, radius: 0.44, speed: 0.08, phase: 5.6, opacity: 0.40)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.ink))

                var layer = context
                layer.addFilter(.blur(radius: size.width * 0.20))
                for blob in Self.blobs {
                    let driftX = 0.10 * sin(time * blob.speed + blob.phase)
                    let driftY = 0.07 * cos(time * blob.speed * 0.8 + blob.phase * 1.3)
                    let radius = size.width * blob.radius * (1 + 0.08 * sin(time * blob.speed * 1.7 + blob.phase))
                    let center = CGPoint(
                        x: size.width * (blob.x + driftX),
                        y: size.height * (blob.y + driftY)
                    )
                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    let strength = blob.opacity * (0.55 + 0.45 * intensity)
                    layer.fill(Path(ellipseIn: rect), with: .color(blob.color.opacity(strength)))
                }
            }
        }
        .overlay {
            // Donkert de randen af, zodat tekst overal leesbaar blijft.
            LinearGradient(
                colors: [Theme.ink.opacity(0.55), Theme.ink.opacity(0.10), Theme.ink.opacity(0.70)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
