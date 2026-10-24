import AVFoundation
import Foundation

@MainActor
final class SoundService {
    enum Cue: String { case click,reaction,complete,pourFlour,pourWater,pourOil,mix,oven,munch,bubble,catchFruit,bounce }
    static let shared = SoundService()
    private var settings = GameSettings()
    private var effects: [AVAudioPlayer] = []
    private var music: AVAudioPlayer?
    private var fadingMusic: [AVAudioPlayer] = []
    private var cache: [String: Data] = [:]
    private var active = true
    private var performing = false
    private var world = World.forest
    private var lastCue: [Cue: TimeInterval] = [:]

    private var theme: String {
        switch world {
        case .stars, .clouds: return "music_dream"
        case .castle: return "music_workshop"
        default: return "music_garden"
        }
    }
    private var musicLevel: Float {
        Float(settings.musicLevel) * 0.32
    }

    func configure(_ settings: GameSettings) {
        self.settings = settings
        if !settings.sound { effects.forEach { $0.stop() }; effects.removeAll() }
        updateMusic()
    }
    func setActive(_ value: Bool) {
        active = value
        if !value {
            effects.forEach { $0.stop() }; effects.removeAll()
        }
        updateMusic()
    }
    func setWorld(_ value: World) {
        let previous = theme
        world = value
        guard previous != theme else { return }
        if let outgoing = music {
            fadingMusic.append(outgoing)
            outgoing.setVolume(0, fadeDuration: 0.8)
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 850_000_000)
                outgoing.stop()
                self?.fadingMusic.removeAll { $0 === outgoing }
            }
        }
        music = nil
        updateMusic()
    }
    func setPerformance(_ value: Bool) { performing = value; updateMusic() }
    private static func audioURL(_ name: String) -> URL? {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        return bundle.url(forResource: name, withExtension: "wav")
            ?? bundle.url(forResource: name, withExtension: "wav", subdirectory: "Audio")
    }
    private func updateMusic() {
        guard settings.music && active && !performing else {
            music?.pause()
            fadingMusic.forEach { $0.stop() }; fadingMusic.removeAll()
            return
        }
        if music == nil {
            if let url = Self.audioURL(theme) { music = try? AVAudioPlayer(contentsOf: url) }
            if music == nil {
                music = try? AVAudioPlayer(data: Self.wave(notes: [261.63, 329.63, 392, 0, 329.63, 293.66, 261.63, 0], noteDuration: 0.65, timbre: 0))
            }
            music?.numberOfLoops = -1
            music?.volume = 0
            music?.prepareToPlay()
        }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        if music?.isPlaying == false { music?.play() }
        music?.setVolume(musicLevel, fadeDuration: 0.7)
    }
    func play(_ cue: Cue) {
        guard settings.sound && active else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let interval:Double = cue == .click ? 0.075 : cue == .mix ? 0.20 : cue == .oven ? 0.85 : 0.16
        if let previous = lastCue[cue], now - previous < interval { return }
        lastCue[cue] = now
        let name: String
        switch cue {
        case .click: name = ["kenney_click_001", "kenney_click_002", "kenney_click_003"].randomElement()!
        case .reaction: name = ["kenney_pluck_001", "kenney_pluck_002", "kenney_drop_001"].randomElement()!
        case .complete: name = "kenney_confirmation_001"
        case .pourFlour:name="foley_pour_flour"
        case .pourWater:name="foley_pour_water"
        case .pourOil:name="foley_pour_oil"
        case .mix:name="foley_mix"
        case .oven:name="foley_oven"
        case .munch:name="foley_munch"
        case .bubble:name="foley_bubble"
        case .catchFruit:name="foley_catch"
        case .bounce:name="foley_bounce"
        }
        if let url = Self.audioURL(name), let player = try? AVAudioPlayer(contentsOf: url) {
            startEffect(player, gain: cue == .click ? 0.28 : cue == .oven ? 0.3 : 0.55, varied: cue != .complete)
        } else {
            playNotes(cue == .click ? [660] : [523.25, 659.25, 783.99], duration: cue == .click ? 0.055 : 0.14, timbre: 0)
        }
    }
    func react(voice: Int) {
        let root = [523.25, 880, 261.63][min(2, max(0, voice))]
        playNotes([root, root * [1.25, 1.5, 0.75].randomElement()!], duration: 0.13, timbre: voice)
    }
    func instrument(_ row: Int, beat: Int, voice: Int = 0) {
        guard settings.sound && active else { return }
        let key = "instrument-\(min(2,max(0,row)))-\(beat%8)-\(min(2,max(0,voice)))"
        let data: Data
        if let existing = cache[key] { data = existing }
        else {
            data = InstrumentSynth.render(row: row, beat: beat, voice: voice)
            if cache.count < 64 { cache[key] = data }
        }
        playData(data)
    }
    private func startEffect(_ player: AVAudioPlayer, gain: Float, varied: Bool = false) {
        guard settings.sound && active else { return }
        effects.removeAll { !$0.isPlaying }
        guard effects.count < 8 else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        player.volume = Float(settings.effectsLevel) * gain
        if varied {
            player.enableRate = true
            player.rate = Float.random(in: 0.96...1.04)
        }
        effects.append(player)
        player.play()
    }
    private func playData(_ data: Data) {
        guard settings.sound && active, let player = try? AVAudioPlayer(data: data) else { return }
        startEffect(player, gain: 0.55)
    }
    private func playNotes(_ notes: [Double], duration: Double, timbre: Int) {
        guard settings.sound && active else { return }
        let key = "\(notes)-\(duration)-\(timbre)"
        let data: Data
        if let stored = cache[key] { data = stored }
        else {
            data = Self.wave(notes: notes, noteDuration: duration, timbre: timbre)
            if cache.count < 64 { cache[key] = data }
        }
        playData(data)
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
