import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var player: SpeechPlayer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AuroraBackground(intensity: player.isPlaying ? 1 : 0.55)
                .animation(.easeInOut(duration: 1.2), value: player.isPlaying)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar

                    OrbView(
                        isPlaying: player.isPlaying,
                        lastPulse: player.lastPulse,
                        stateChanged: player.stateChanged
                    )
                    .frame(maxWidth: 300)
                    .padding(.top, 8)
                    .onTapGesture { player.toggle() }

                    nowReading
                        .padding(.top, 14)

                    VStack(spacing: 10) {
                        SegmentedProgress(player: player)
                        HStack {
                            Text(Format.clock(player.elapsed))
                            Spacer()
                            Text("-" + Format.clock(max(0, player.duration - player.elapsed)))
                        }
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundStyle(Theme.cream.opacity(0.55))
                    }
                    .padding(.top, 26)

                    controls
                        .padding(.top, 18)

                    chapters
                        .padding(.top, 34)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Onderdelen

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.cream)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.10)))
            }
            .accessibilityLabel("Sluiten")

            Spacer()

            VStack(spacing: 3) {
                Eyebrow(text: "AI Journaal")
                Text(Format.longDate(player.episode?.date ?? ""))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.75))
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, 8)
    }

    private var nowReading: some View {
        VStack(spacing: 12) {
            Eyebrow(text: segmentLabel)

            Text(player.currentSegment?.headline ?? "")
                .font(Theme.serif(25))
                .foregroundStyle(Theme.cream)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .id(player.currentSegmentIndex)
                .transition(.opacity.combined(with: .offset(y: 8)))

            sentence
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .top)
                .id(player.chunkIndex)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.35), value: player.chunkIndex)
        .animation(.easeInOut(duration: 0.45), value: player.currentSegmentIndex)
    }

    /// De huidige zin; het reeds uitgesproken deel licht op.
    private var sentence: Text {
        let full = player.currentSentence as NSString
        let cut = min(max(player.spokenLength, 0), full.length)
        let spoken = Text(full.substring(to: cut)).foregroundColor(Theme.cream)
        let upcoming = Text(full.substring(from: cut)).foregroundColor(Theme.cream.opacity(0.40))
        return spoken + upcoming
    }

    private var segmentLabel: String {
        guard let episode = player.episode, let segment = player.currentSegment else { return "" }
        guard segment.isNews else { return segment.headline }
        let news = episode.segments.enumerated().filter { $0.element.isNews }
        let position = (news.firstIndex { $0.offset == player.currentSegmentIndex } ?? 0) + 1
        return "Bericht \(position) van \(news.count)"
    }

    private var controls: some View {
        HStack(spacing: 44) {
            Button {
                player.previousSegment()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.cream.opacity(0.9))
                    .frame(width: 52, height: 52)
            }
            .accessibilityLabel("Vorig onderwerp")

            Button {
                player.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.warm)
                        .shadow(color: Theme.amber.opacity(0.55), radius: 22, y: 8)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .offset(x: player.isPlaying ? 0 : 2)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 78, height: 78)
            }
            .buttonStyle(PressScale())
            .accessibilityLabel(player.isPlaying ? "Pauzeren" : "Afspelen")

            Button {
                player.nextSegment()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.cream.opacity(0.9))
                    .frame(width: 52, height: 52)
            }
            .accessibilityLabel("Volgend onderwerp")
        }
    }

    private var chapters: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "In deze uitzending", color: Theme.cream.opacity(0.6))

            VStack(spacing: 0) {
                let segments = Array((player.episode?.segments ?? []).enumerated())
                ForEach(segments, id: \.offset) { index, segment in
                    chapterRow(index: index, segment: segment)
                    if index < segments.count - 1 {
                        Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 52)
                    }
                }
            }
            .glassCard(cornerRadius: 24)
        }
    }

    private func chapterRow(index: Int, segment: Segment) -> some View {
        let isCurrent = index == player.currentSegmentIndex
        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                if isCurrent {
                    Image(systemName: "waveform")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                        .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.cream.opacity(0.45))
                }
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(segment.headline)
                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Theme.cream : Theme.cream.opacity(0.78))
                    .multilineTextAlignment(.leading)
                if let source = segment.source {
                    Text(source)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.cream.opacity(0.45))
                }
            }

            Spacer(minLength: 8)

            if let link = segment.url, let url = URL(string: link) {
                Button {
                    openURL(url)
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.apricot)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .accessibilityLabel("Bron openen: \(segment.source ?? "artikel")")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .onTapGesture {
            player.jump(toSegment: index)
            if !player.isPlaying { player.play() }
        }
    }
}

/// Knop die licht indrukt bij aanraking.
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
