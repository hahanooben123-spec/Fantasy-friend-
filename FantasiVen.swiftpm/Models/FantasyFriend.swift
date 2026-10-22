import Foundation

enum BodyKind: Int, Codable, CaseIterable { case round, oval, pear, cushion, drop, cloud, bean, chubby }
enum World: Int, Codable, CaseIterable { case forest, rainbow, stars, clouds, meadow, castle }
enum Part: Int, CaseIterable { case body, color, accent, eyes, mouth, arms, legs, extras, paint }

struct FantasyFriend: Identifiable, Codable, Equatable {
    var id = UUID()
    var name = ""
    var body: BodyKind = .pear
    var color = 0
    var accent = 5
    var eyes = 0
    var mouth = 0
    var arms = 0
    var legs = 0
    var accessories: Set<Int> = [1]
    var world: World = .forest
    // Optional so friends saved before free placement still decode unchanged.
    var placements: [String: PartPlacement]?
    var doodles: [DoodleStroke]?
    var pieces: [CreativePiece]?
    var partColors: [String: Int]?
    var bodyWidth: Double?
    var bodyHeight: Double?
    var voice: VoiceKind?
    var gait: GaitKind?
    var room: [RoomObject]?
    var track: SlideTrack?
    var song: OrchestraPattern?

    var widthFactor: Double { bodyWidth ?? 1 }
    var heightFactor: Double { bodyHeight ?? 1 }
    func sibling() -> FantasyFriend {
        var copy = self; copy.id = UUID(); copy.name = ""; return copy
    }

    func placement(for attachment: Attachment) -> PartPlacement {
        placements?[attachment.rawValue] ?? PartPlacement()
    }

    mutating func setPlacement(_ placement: PartPlacement, for attachment: Attachment) {
        var values = placements ?? [:]
        if placement == PartPlacement() { values.removeValue(forKey: attachment.rawValue) }
        else { values[attachment.rawValue] = placement }
        placements = values.isEmpty ? nil : values
    }

    static func random() -> FantasyFriend {
        var friend = FantasyFriend()
        friend.body = BodyKind.allCases.randomElement() ?? .round
        friend.color = Int.random(in: 0..<16)
        friend.accent = Int.random(in: 0..<16)
        friend.eyes = Int.random(in: 0..<12)
        friend.mouth = Int.random(in: 0..<10)
        friend.arms = Int.random(in: 0..<8)
        friend.legs = Int.random(in: 0..<8)
        friend.accessories = Set((0..<15).shuffled().prefix(Int.random(in: 0...3)))
        return friend
    }

    var isValid: Bool {
        (0..<16).contains(color) && (0..<16).contains(accent) &&
        (0..<12).contains(eyes) && (0..<10).contains(mouth) &&
        (0..<8).contains(arms) && (0..<8).contains(legs) &&
        accessories.allSatisfy { (0..<15).contains($0) } && name.count <= 30 &&
        (placements ?? [:]).allSatisfy { Attachment(rawValue: $0.key) != nil && $0.value.isValid } &&
        (doodles ?? []).allSatisfy(\.isValid) &&
        (partColors ?? [:]).allSatisfy { Attachment(rawValue: $0.key) != nil && (0..<16).contains($0.value) } &&
        (pieces ?? []).count <= 64 && (pieces ?? []).allSatisfy(\.isValid) &&
        Set((pieces ?? []).map(\.id)).count == (pieces ?? []).count &&
        widthFactor.isFinite && heightFactor.isFinite &&
        (0.75...1.2).contains(widthFactor) && (0.75...1.2).contains(heightFactor) &&
        (room ?? []).count <= 32 && (room ?? []).allSatisfy(\.isValid) &&
        (track?.isValid ?? true) && (song?.isValid ?? true)
    }
}

enum Language: String, Codable, CaseIterable { case da, en }
struct GameSettings: Codable {
    var language: Language = .da
    var sound = true
    var music = false
    var speech: Bool?
    var challenge: Int?
    var speechEnabled: Bool { speech ?? true }
    var challengeLevel: Int { min(3, max(1, challenge ?? 1)) }
}
