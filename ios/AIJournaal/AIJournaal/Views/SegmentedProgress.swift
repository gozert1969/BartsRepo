import SwiftUI

/// Voortgangsbalk met één blokje per onderwerp, in verhouding tot de lengte ervan.
struct SegmentedProgress: View {
    @ObservedObject var player: SpeechPlayer

    private let spacing: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            let weights = player.segmentWeights
            let available = max(0, proxy.size.width - spacing * CGFloat(max(weights.count - 1, 0)))
            HStack(spacing: spacing) {
                ForEach(Array(weights.enumerated()), id: \.offset) { index, weight in
                    let width = max(3, available * CGFloat(weight))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule()
                            .fill(Theme.duotone)
                            .frame(width: width * CGFloat(player.fill(forSegment: index)))
                    }
                    .frame(width: width)
                    .clipShape(Capsule())
                    .contentShape(Rectangle().inset(by: -10))
                    .onTapGesture { player.jump(toSegment: index) }
                }
            }
        }
        .frame(height: 5)
        .animation(.linear(duration: 0.25), value: player.progress)
        .accessibilityElement()
        .accessibilityLabel("Voortgang")
        .accessibilityValue("\(Int(player.progress * 100)) procent")
    }
}
