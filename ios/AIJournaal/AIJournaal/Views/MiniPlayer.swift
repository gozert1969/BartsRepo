import SwiftUI

/// Compacte speler onderaan het overzicht; tik om de volledige speler te openen.
struct MiniPlayer: View {
    @EnvironmentObject private var player: SpeechPlayer
    var onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            OrbView(
                isPlaying: player.isPlaying,
                lastPulse: player.lastPulse,
                stateChanged: player.stateChanged,
                barCount: 28,
                showsRipples: false
            )
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentSegment?.headline ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                Text(Format.longDate(player.episode?.date ?? ""))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.cream.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                player.toggle()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.warm))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressScale())
            .accessibilityLabel(player.isPlaying ? "Pauzeren" : "Afspelen")
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            GeometryReader { proxy in
                Capsule()
                    .fill(Theme.duotone)
                    .frame(width: proxy.size.width * CGFloat(player.progress), height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.horizontal, 22)
            .allowsHitTesting(false)
        }
        .glassCard(cornerRadius: 30)
        .shadow(color: Color.black.opacity(0.35), radius: 20, y: 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}
