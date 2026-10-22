import Foundation

struct DoodlePoint: Codable, Equatable {
    var x: Double
    var y: Double
    var isValid: Bool { x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y) }
}

struct DoodleStroke: Codable, Equatable {
    var points: [DoodlePoint]
    var color: Int
    var width: Double
    var isValid: Bool {
        !points.isEmpty && points.count <= 600 && points.allSatisfy(\.isValid) &&
        (0..<16).contains(color) && width.isFinite && (2...20).contains(width)
    }
}

struct PaintTool: Equatable {
    var color: Int
    var width: Double
}
