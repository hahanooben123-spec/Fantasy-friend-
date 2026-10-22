import Foundation

enum BodyKind: Int, Codable, CaseIterable { case round, oval, pear, cushion, drop, cloud, bean, chubby }
enum World: Int, Codable, CaseIterable { case forest, rainbow, stars, clouds, meadow, castle }
enum Part: Int, CaseIterable { case body, color, accent, eyes, mouth, arms, legs, extras }

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
        (placements ?? [:]).allSatisfy { Attachment(rawValue: $0.key) != nil && $0.value.isValid }
    }
}

enum Language: String, Codable, CaseIterable { case da, en }
struct GameSettings: Codable {
    var language: Language = .da
    var sound = true
    var music = false
}
