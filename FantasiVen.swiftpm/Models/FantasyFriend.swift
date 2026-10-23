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
    var hiddenParts: Set<String>?
    var mirroredParts: Set<String>?
    var facePlacements: [String: PartPlacement]?

    func isHidden(_ key: String) -> Bool { hiddenParts?.contains(key) ?? false }
    mutating func show(_ key: String) { hiddenParts?.remove(key) }
    mutating func hide(_ key: String) { var values = hiddenParts ?? []; values.insert(key); hiddenParts = values }

    var bodyWidth: Double?
    var bodyHeight: Double?
    var voice: VoiceKind?
    var gait: GaitKind?
    var room: [RoomObject]?
    var roomDesign:RoomDesign?
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

    static func studioStarter() -> FantasyFriend {FriendSeed.bimse.make()}

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
        (partColors ?? [:]).allSatisfy { (Attachment(rawValue: $0.key) != nil || ["eyes", "mouth"].contains($0.key)) && (0..<16).contains($0.value) } &&
        (hiddenParts ?? []).allSatisfy { Set(Attachment.allCases.map(\.rawValue) + ["eyes", "mouth"]).contains($0) } &&
        (mirroredParts ?? []).allSatisfy { Set(Attachment.allCases.map(\.rawValue) + ["eyes", "mouth"]).contains($0) } &&
        (facePlacements ?? [:]).allSatisfy { ["eyes", "mouth"].contains($0.key) && $0.value.isValid } &&
        (pieces ?? []).count <= 64 && (pieces ?? []).allSatisfy(\.isValid) &&
        Set((pieces ?? []).map(\.id)).count == (pieces ?? []).count &&
        widthFactor.isFinite && heightFactor.isFinite &&
        (0.75...1.2).contains(widthFactor) && (0.75...1.2).contains(heightFactor) &&
        (roomDesign?.isValid ?? true) &&
        Set((room ?? []).map(\.id)).count == (room ?? []).count &&
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


/// Art-directed starting points. Each selection creates a fresh, fully editable friend.
enum FriendSeed:Int,CaseIterable {
    case bimse,pjuske,lumi
    var title:String {
        switch self {case .bimse:return "Bimse";case .pjuske:return "Pjuske";case .lumi:return "Lumi"}
    }
    var hintKey:String {"starterHint\(rawValue)"}
    func make()->FantasyFriend {
        var f=FantasyFriend()
        f.name=title
        switch self {
        case .bimse:
            f.body = .round;f.color=6;f.accent=3;f.eyes=0;f.mouth=1
            f.arms=5;f.legs=0;f.accessories=[0,14]
            f.voice = .squeak;f.gait = .bounce
            f.facePlacements=["eyes":PartPlacement(x:0,y:-0.015,rotation:0,scale:1.06)]
        case .pjuske:
            f.body = .cloud;f.color=9;f.accent=8;f.eyes=11;f.mouth=2
            f.arms=1;f.legs=4;f.accessories=[1]
            f.voice = .hum;f.gait = .waddle
            f.facePlacements=["eyes":PartPlacement(x:0,y:0.015,rotation:0,scale:0.92),
                              "mouth":PartPlacement(x:0,y:0.01,rotation:0,scale:0.9)]
        case .lumi:
            f.body = .drop;f.color=11;f.accent=3;f.eyes=9;f.mouth=6
            f.arms=2;f.legs=2;f.accessories=[2,3]
            f.bodyWidth=0.9;f.bodyHeight=1.08
            f.voice = .bell;f.gait = .glide
            f.facePlacements=["mouth":PartPlacement(x:0,y:0.005,rotation:-5,scale:0.9)]
        }
        return f
    }
}
