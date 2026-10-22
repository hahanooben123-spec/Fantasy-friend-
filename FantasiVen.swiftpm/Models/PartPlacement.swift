import Foundation

enum Attachment: String, Codable, CaseIterable, Identifiable {
    case leftArm, rightArm, leftLeg, rightLeg
    case horns, ears, antennae, wings, tail, hat, bow, glasses, crown
    case spots, stripes, spikes, flower, scarf, freckles

    var id: String { rawValue }
    var extraIndex: Int? {
        guard let index = Self.allCases.firstIndex(of: self), index >= 4 else { return nil }
        return index - 4
    }
    static func extra(_ index: Int) -> Attachment {
        allCases[min(14, max(0, index)) + 4]
    }
    var category: Part {
        switch self {
        case .leftArm, .rightArm: return .arms
        case .leftLeg, .rightLeg: return .legs
        default: return .extras
        }
    }
}

struct PartPlacement: Codable, Equatable {
    // Offsets relative to the 300 × 320 drawing, independent of screen size.
    var x: Double = 0
    var y: Double = 0
    var rotation: Double = 0
    var scale: Double = 1

    var isValid: Bool {
        x.isFinite && y.isFinite && rotation.isFinite && scale.isFinite &&
        abs(x) <= 1 && abs(y) <= 1 && abs(rotation) <= 180 && (0.5...1.5).contains(scale)
    }
}
