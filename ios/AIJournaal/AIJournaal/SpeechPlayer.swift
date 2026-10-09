import AVFoundation
import MediaPlayer
import SwiftUI

/// Leest een aflevering zin voor zin voor met de Nederlandse stem van iOS.
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    struct Chunk {
        let segmentIndex: Int
        let text: String
        /// Positie van deze zin binnen de hele aflevering, in tekens.
        let offset: Int
        let length: Int
        let endsSegment: Bool
    }

    @Published private(set) var episode: Episode?
    @Published private(set) var isPlaying = false
    @Published private(set) var finished = false
    @Published private(set) var chunkIndex = 0
    /// Aantal reeds uitgesproken tekens van de huidige zin.
    @Published private(set) var spokenLength = 0
    /// Moment van het laatst uitgesproken woord; stuurt de animatie aan.
    @Published private(set) var lastPulse = Date.distantPast
    /// Moment waarop afspelen of pauzeren voor het laatst wisselde.
    @Published private(set) var stateChanged = Date.distantPast

    let voice: AVSpeechSynthesisVoice?

    private let synthesizer = AVSpeechSynthesizer()
    private var chunks: [Chunk] = []
    private var segmentStarts: [Int] = []
    private var segmentLengths: [Int] = []
    private var totalLength = 1
    private var currentUtterance: AVSpeechUtterance?

    override init() {
        voice = SpeechPlayer.bestDutchVoice()
        super.init()
        synthesizer.delegate = self
        configureRemoteCommands()
    }

    // MARK: - Afgeleide waarden

    var currentSegmentIndex: Int {
        chunks.indices.contains(chunkIndex) ? chunks[chunkIndex].segmentIndex : 0
    }

    var currentSegment: Segment? {
        guard let episode, episode.segments.indices.contains(currentSegmentIndex) else { return nil }
        return episode.segments[currentSegmentIndex]
    }

    var currentSentence: String {
        chunks.indices.contains(chunkIndex) ? chunks[chunkIndex].text : ""
    }

    /// Voortgang door de hele aflevering, 0…1.
    var progress: Double {
        guard chunks.indices.contains(chunkIndex) else { return 0 }
        if finished { return 1 }
        let chunk = chunks[chunkIndex]
        let spoken = min(max(spokenLength, 0), chunk.length)
        return Double(chunk.offset + spoken) / Double(totalLength)
    }

    var duration: Double { Double(episode?.durationSeconds ?? 0) }
    var elapsed: Double { progress * duration }

    /// Aandeel van elk onderwerp in de totale lengte; samen 1.
    var segmentWeights: [Double] {
        segmentLengths.map { Double($0) / Double(totalLength) }
    }

    /// Hoe ver het opgegeven onderwerp is voorgelezen, 0…1.
    func fill(forSegment index: Int) -> Double {
        guard segmentLengths.indices.contains(index), segmentStarts.indices.contains(index) else { return 0 }
        let start = Double(segmentStarts[index])
        let length = Double(max(segmentLengths[index], 1))
        let position = progress * Double(totalLength)
        return min(1, max(0, (position - start) / length))
    }

    var usesBasicVoice: Bool {
        guard let voice else { return true }
        return voice.quality == .default
    }

    // MARK: - Bediening

    func load(_ episode: Episode, autoplay: Bool) {
        currentUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)

        var built: [Chunk] = []
        var starts: [Int] = []
        var lengths: [Int] = []
        var offset = 0
        for (index, segment) in episode.segments.enumerated() {
            let sentences = SpeechPlayer.sentences(in: segment.text)
            starts.append(offset)
            for (position, sentence) in sentences.enumerated() {
                let length = (sentence as NSString).length
                built.append(
                    Chunk(
                        segmentIndex: index,
                        text: sentence,
                        offset: offset,
                        length: length,
                        endsSegment: position == sentences.count - 1
                    )
                )
                offset += length
            }
            lengths.append(offset - (starts.last ?? 0))
        }

        chunks = built
        segmentStarts = starts
        segmentLengths = lengths
        totalLength = max(offset, 1)
        chunkIndex = 0
        spokenLength = 0
        finished = false
        self.episode = episode
        setPlaying(false)

        if autoplay { play() }
    }

    func play() {
        guard !chunks.isEmpty else { return }
        activateAudioSession()
        if finished {
            chunkIndex = 0
            spokenLength = 0
            finished = false
        }
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        } else if !synthesizer.isSpeaking {
            speakCurrent()
        }
        setPlaying(true)
    }

    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
        setPlaying(false)
    }

    func toggle() {
        if isPlaying { pause() } else { play() }
    }

    func jump(toSegment index: Int) {
        guard let target = chunks.firstIndex(where: { $0.segmentIndex == index }) else { return }
        jump(toChunk: target)
    }

    func nextSegment() {
        let current = currentSegmentIndex
        guard let target = chunks.firstIndex(where: { $0.segmentIndex > current }) else { return }
        jump(toChunk: target)
    }

    /// Terug naar het begin van dit onderwerp, of naar het vorige als we er net aan begonnen zijn.
    func previousSegment() {
        let current = currentSegmentIndex
        let startOfCurrent = chunks.firstIndex(where: { $0.segmentIndex == current }) ?? 0
        if chunkIndex > startOfCurrent || current == 0 {
            jump(toChunk: startOfCurrent)
        } else {
            jump(toSegment: current - 1)
        }
    }

    private func jump(toChunk index: Int) {
        guard chunks.indices.contains(index) else { return }
        currentUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        chunkIndex = index
        spokenLength = 0
        finished = false
        if isPlaying {
            speakCurrent()
        }
        updateNowPlaying()
    }

    // MARK: - Spraak

    private func speakCurrent() {
        guard chunks.indices.contains(chunkIndex) else { return }
        let chunk = chunks[chunkIndex]
        let utterance = AVSpeechUtterance(string: chunk.text)
        utterance.voice = voice
        // Rustig en zakelijk: het tempo van een nieuwslezer, met een iets lagere toon.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.98
        utterance.pitchMultiplier = 0.96
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = chunk.endsSegment ? 0.75 : 0.12
        currentUtterance = utterance
        synthesizer.speak(utterance)
    }

    private func advance() {
        if chunkIndex + 1 < chunks.count {
            chunkIndex += 1
            spokenLength = 0
            speakCurrent()
            updateNowPlaying()
        } else {
            finished = true
            currentUtterance = nil
            setPlaying(false)
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            guard utterance === self.currentUtterance else { return }
            self.spokenLength = characterRange.location + characterRange.length
            self.lastPulse = Date()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            guard utterance === self.currentUtterance else { return }
            self.advance()
        }
    }

    private func setPlaying(_ playing: Bool) {
        if isPlaying != playing {
            isPlaying = playing
            stateChanged = Date()
        }
        updateNowPlaying()
    }

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            // Zonder audiosessie speelt de stem nog steeds af zolang de app in beeld is.
        }
    }

    private static func sentences(in text: String) -> [String] {
        var result: [String] = []
        let source = text as NSString
        source.enumerateSubstrings(
            in: NSRange(location: 0, length: source.length),
            options: .bySentences
        ) { substring, _, _, _ in
            guard let substring else { return }
            let trimmed = substring.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(trimmed) }
        }
        return result.isEmpty ? [text] : result
    }

    /// De beste Nederlandse stem op dit toestel: premium boven verbeterd boven standaard.
    private static func bestDutchVoice() -> AVSpeechSynthesisVoice? {
        let dutch = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("nl") }
        let ranked = dutch.sorted { first, second in
            if first.quality.rawValue != second.quality.rawValue {
                return first.quality.rawValue > second.quality.rawValue
            }
            return first.language == "nl-NL" && second.language != "nl-NL"
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: "nl-NL")
    }

    // MARK: - Vergrendelscherm en koptelefoon

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextSegment()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousSegment()
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let episode else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentSegment?.headline ?? episode.title
        info[MPMediaItemPropertyArtist] = "AI Journaal"
        info[MPMediaItemPropertyAlbumTitle] = Format.longDate(episode.date)
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
