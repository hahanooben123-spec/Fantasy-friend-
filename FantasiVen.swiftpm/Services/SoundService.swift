import AVFoundation
import Foundation

@MainActor
final class SoundService {
    enum Cue: String { case click, reaction, complete }
    static let shared = SoundService()
    private var settings = GameSettings()
    private var effects: [AVAudioPlayer] = []
    private var music: AVAudioPlayer?
    private let speech = AVSpeechSynthesizer()
    private var speechTask: Task<Void, Never>?
    private var cache: [String: Data] = [:]
    private var active = true
    private var performing = false
    private var world = World.forest

    func configure(_ settings: GameSettings) {
        self.settings = settings
        if !settings.sound { effects.forEach { $0.stop() }; effects.removeAll() }
        if !settings.speechEnabled { stopSpeech() }
        updateMusic()
    }
    func setActive(_ value: Bool) {
        active = value
        if !value { effects.forEach { $0.stop() }; stopSpeech() }
        updateMusic()
    }
    func setWorld(_ value: World) {
        guard world != value else { return }
        world = value
        let outgoing = music
        outgoing?.setVolume(0, fadeDuration: 0.3)
        music = nil
        updateMusic()
        if settings.music && active && !performing { music?.volume = 0; music?.setVolume(speech.isSpeaking ? 0.025 : 0.11, fadeDuration: 0.4) }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            outgoing?.stop()
        }
    }
    func setPerformance(_ value: Bool) { performing = value; updateMusic() }
    private func updateMusic() {
        guard settings.music && active && !performing else { music?.pause(); return }
        if music == nil {
            let root: Double = world == .stars ? 220 : world == .castle ? 293.66 : 261.63
            let notes = [1.0, 1.25, 1.5, 0, 1.125, 1.3333, 1.5, 0].map { $0 * root }
            music = try? AVAudioPlayer(data: Self.wave(notes: notes, noteDuration: 0.55, timbre: world.rawValue % 3))
            music?.numberOfLoops = -1
        }
        music?.volume = speech.isSpeaking ? 0.025 : 0.11
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        music?.play()
    }
    func play(_ cue: Cue) {
        let notes: [Double]
        switch cue {
        case .click: notes = [660]
        case .reaction: notes = [[523.25, 659.25], [659.25, 783.99], [392, 523.25]][Int.random(in: 0..<3)]
        case .complete: notes = [523.25, 659.25, 783.99, 1046.5]
        }
        playNotes(notes, duration: cue == .click ? 0.055 : 0.12, timbre: 0)
    }
    func react(voice: Int) {
        let root = [523.25, 880, 261.63][min(2, max(0, voice))]
        playNotes([root, root * [1.25, 1.5, 0.75].randomElement()!], duration: 0.13, timbre: voice)
    }
    func instrument(_ row: Int, beat: Int) {
        let roots: [Double] = [130.81, 329.63, 523.25]
        playNotes([roots[min(2, max(0, row))] * (beat.isMultiple(of: 4) ? 1.25 : 1)], duration: 0.18, timbre: row)
    }
    private func playNotes(_ notes: [Double], duration: Double, timbre: Int) {
        guard settings.sound && active else { return }
        effects.removeAll { !$0.isPlaying }
        guard effects.count < 12 else { return }
        let key = "\(notes)-\(duration)-\(timbre)"
        let data: Data
        if let stored = cache[key] { data = stored }
        else {
            data = Self.wave(notes: notes, noteDuration: duration, timbre: timbre)
            if cache.count < 64 { cache[key] = data }
        }
        guard let player = try? AVAudioPlayer(data: data) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        player.volume = 0.25; effects.append(player); player.play()
    }
    func speak(_ text: String, language: Language) {
        guard settings.speechEnabled && active else { return }
        stopSpeech()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language == .da ? "da-DK" : "en-GB")
        utterance.rate = 0.43; utterance.volume = 0.7
        music?.volume = 0.025
        speech.speak(utterance)
        speechTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                while self?.speech.isSpeaking == true {
                    try await Task.sleep(nanoseconds: 200_000_000)
                }
                self?.updateMusic()
            } catch { return }
        }
    }
    func stopSpeech() {
        speechTask?.cancel(); speechTask = nil
        speech.stopSpeaking(at: .immediate)
        music?.volume = 0.11
    }
    private static func wave(notes: [Double], noteDuration: Double, timbre: Int) -> Data {
        let sampleRate = 22050
        let samplesPerNote = Int(Double(sampleRate) * noteDuration)
        var samples = Data()
        func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        for frequency in notes {
            for index in 0..<samplesPerNote {
                let t = Double(index) / Double(sampleRate)
                let envelope = min(1, t / 0.008) * pow(max(0, 1 - t / noteDuration), timbre == 0 ? 2 : 1)
                let base = sin(2 * .pi * frequency * t)
                let tone = base + (timbre == 1 ? 0.35 : 0.15) * sin(2 * .pi * frequency * 2 * t)
                append(Int16(tone * envelope * 7500), to: &samples)
            }
        }
        var data = Data("RIFF".utf8)
        append(UInt32(36 + samples.count), to: &data)
        data.append(Data("WAVEfmt ".utf8)); append(UInt32(16), to: &data)
        append(UInt16(1), to: &data); append(UInt16(1), to: &data)
        append(UInt32(sampleRate), to: &data); append(UInt32(sampleRate * 2), to: &data)
        append(UInt16(2), to: &data); append(UInt16(16), to: &data)
        data.append(Data("data".utf8)); append(UInt32(samples.count), to: &data); data.append(samples)
        return data
    }
}
