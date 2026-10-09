import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: EpisodeStore
    @EnvironmentObject private var player: SpeechPlayer

    @State private var showPlayer = false
    @State private var loadingDate: String?
    @State private var showLoadError = false
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AuroraBackground(intensity: 0.35)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    content
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 130)
            }
            .refreshable { await store.refresh() }

            if player.episode != nil {
                MiniPlayer { showPlayer = true }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: player.episode?.date)
        .task {
            await store.refresh()
            #if DEBUG
            // Voor automatische schermafbeeldingen: start direct de laatste aflevering.
            if ProcessInfo.processInfo.arguments.contains("-demoPlayer"), let latest = store.episodes.first {
                open(latest)
            }
            #endif
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView()
                .environmentObject(player)
                .preferredColorScheme(.dark)
        }
        .alert("Aflevering niet beschikbaar", isPresented: $showLoadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Deze aflevering kon niet worden opgehaald. Controleer uw verbinding en probeer het opnieuw.")
        }
    }

    // MARK: - Onderdelen

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Dagelijks om acht uur")
            Text("AI Journaal")
                .font(Theme.serif(40, weight: .bold))
                .foregroundStyle(Theme.cream)
            Text("Het nieuws over kunstmatige intelligentie, in vijf minuten.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.cream.opacity(0.65))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle, .loading:
            HStack {
                Spacer()
                ProgressView().tint(Theme.apricot)
                Spacer()
            }
            .padding(.top, 80)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 14) {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.cream.opacity(0.8))
                Button("Opnieuw proberen") {
                    Task { await store.refresh() }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.amber)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        case .loaded:
            if let latest = store.episodes.first {
                hero(latest)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                if player.usesBasicVoice {
                    voiceHint
                }
                if store.episodes.count > 1 {
                    archive(Array(store.episodes.dropFirst()))
                }
            } else {
                Text("Er staat nog geen aflevering klaar. De eerste verschijnt morgenochtend om acht uur.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.cream.opacity(0.8))
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            }
        }
    }

    private func hero(_ summary: EpisodeSummary) -> some View {
        let isCurrent = player.episode?.date == summary.date
        let isActive = isCurrent && player.isPlaying
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: Format.isToday(summary.date) ? "Vandaag" : "Laatste aflevering")
                    Text(Format.longDate(summary.date))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.cream.opacity(0.7))
                }
                Spacer()
                OrbView(
                    isPlaying: isActive,
                    lastPulse: player.lastPulse,
                    stateChanged: isCurrent ? player.stateChanged : .distantPast,
                    barCount: 40,
                    showsRipples: false
                )
                .frame(width: 84, height: 84)
                .padding(.top, -10)
                .padding(.trailing, -8)
            }

            Text(summary.title)
                .font(Theme.serif(28))
                .foregroundStyle(Theme.cream)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            Text(summary.summary)
                .font(.system(size: 15))
                .lineSpacing(3)
                .foregroundStyle(Theme.cream.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            HStack(spacing: 14) {
                Button {
                    open(summary)
                } label: {
                    HStack(spacing: 10) {
                        if loadingDate == summary.date {
                            ProgressView().tint(Theme.ink)
                        } else {
                            Image(systemName: isActive ? "waveform" : "play.fill")
                                .font(.system(size: 15, weight: .bold))
                                .symbolEffect(.variableColor.iterative, isActive: isActive)
                        }
                        Text(isActive ? "Nu te horen" : (isCurrent ? "Verder luisteren" : "Beluister"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 24)
                    .frame(height: 52)
                    .background(Capsule().fill(Theme.warm))
                    .shadow(color: Theme.amber.opacity(0.45), radius: 18, y: 8)
                }
                .buttonStyle(PressScale())

                Label(Format.minutes(summary.durationSeconds), systemImage: "clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.6))
            }
            .padding(.top, 22)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 32)
    }

    private var voiceHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.wave.2")
                .font(.system(size: 15))
                .foregroundStyle(Theme.apricot)
                .padding(.top, 1)
            Text("Voor een natuurlijkere nieuwslezer: download een verbeterde of premium Nederlandse stem via Instellingen › Toegankelijkheid › Gesproken materiaal › Stemmen.")
                .font(.system(size: 13))
                .lineSpacing(2)
                .foregroundStyle(Theme.cream.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
    }

    private func archive(_ list: [EpisodeSummary]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Eerdere afleveringen", color: Theme.cream.opacity(0.6))
            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.id) { index, summary in
                    Button {
                        open(summary)
                    } label: {
                        archiveRow(summary)
                    }
                    .buttonStyle(.plain)
                    if index < list.count - 1 {
                        Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 74)
                    }
                }
            }
            .glassCard(cornerRadius: 24)
        }
    }

    private func archiveRow(_ summary: EpisodeSummary) -> some View {
        let isCurrent = player.episode?.date == summary.date
        return HStack(spacing: 14) {
            VStack(spacing: 1) {
                Text(String(Format.weekday(summary.date).prefix(2)).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.apricot)
                Text(Format.shortDate(summary.date))
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.cream)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(Format.minutes(summary.durationSeconds))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.cream.opacity(0.5))
            }

            Spacer(minLength: 8)

            if loadingDate == summary.date {
                ProgressView().tint(Theme.apricot)
            } else {
                Image(systemName: isCurrent && player.isPlaying ? "waveform" : "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                    .symbolEffect(.variableColor.iterative, isActive: isCurrent && player.isPlaying)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Acties

    @MainActor
    private func open(_ summary: EpisodeSummary) {
        if player.episode?.date == summary.date {
            if !player.isPlaying { player.play() }
            showPlayer = true
            return
        }
        guard loadingDate == nil else { return }
        loadingDate = summary.date
        Task { @MainActor in
            do {
                let episode = try await store.episode(for: summary)
                player.load(episode, autoplay: true)
                showPlayer = true
            } catch {
                showLoadError = true
            }
            loadingDate = nil
        }
    }
}
