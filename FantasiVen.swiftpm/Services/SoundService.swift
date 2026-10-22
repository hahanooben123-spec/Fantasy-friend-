import AVFoundation
import Foundation

@MainActor
final class SoundService {
    enum Cue: String { case click, reaction, complete }
    static let shared = SoundService()
    private var settings = GameSettings()
    private var effects: [AVAudioPlayer] = []
    private var music: AVAudioPlayer?
    private var active = true

    func configure(_ settings: GameSettings) {
        self.settings = settings
        if !settings.sound { effects.forEach { $0.stop() }; effects.removeAll() }
        updateMusic()
    }
    func setActive(_ value: Bool) {
        active = value
        if !value { effects.forEach { $0.stop() } }
        updateMusic()
    }
    private func updateMusic() {
        guard settings.music && active else { music?.pause(); return }
        if music == nil {
            music = player(resource: "music", fallback: [261.63, 329.63, 392, 329.63, 293.66, 349.23, 440, 349.23], noteDuration: 0.7)
            music?.numberOfLoops = -1
            music?.volume = 0.13
        }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        music?.play()
    }
    func play(_ cue: Cue) {
        guard settings.sound && active else { return }
        effects.removeAll { !$0.isPlaying }
        guard effects.count < 6 else { return }
        let notes: [Double]
        switch cue { case .click: notes = [660]; case .reaction: notes = [523.25, 659.25, 783.99]; case .complete: notes = [523.25, 659.25, 783.99, 1046.5] }
        guard let sound = player(resource: cue.rawValue, fallback: notes, noteDuration: cue == .click ? 0.055 : 0.12) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        sound.volume = 0.35
        effects.append(sound); sound.play()
    }
    private func player(resource: String, fallback: [Double], noteDuration: Double) -> AVAudioPlayer? {
        if let url = Bundle.main.url(forResource: resource, withExtension: "wav"), let player = try? AVAudioPlayer(contentsOf: url) { return player }
        return try? AVAudioPlayer(data: Self.wave(notes: fallback, noteDuration: noteDuration))
    }
    // Small, original bell tones. No downloaded assets or audio permissions.
    private static func wave(notes: [Double], noteDuration: Double) -> Data {
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
                let envelope = min(1, t / 0.008) * pow(max(0, 1 - t / noteDuration), 2)
                let wave = sin(2 * .pi * frequency * t) + 0.2 * sin(2 * .pi * frequency * 2 * t)
                append(Int16(wave * envelope * 9000), to: &samples)
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
