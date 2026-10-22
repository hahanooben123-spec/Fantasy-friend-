import Foundation

enum PieceKind: String, Codable, CaseIterable, Identifiable {
    case eye, arm, leg, extra
    var id: String { rawValue }
    var key: String { "piece_" + rawValue }
}
struct CreativePiece: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: PieceKind
    var variant = 0
    var x = 0.5
    var y = 0.5
    var scale = 1.0
    var rotation = 0.0
    var mirrored = false
    var color = 0
    var accent = 3
    var isValid: Bool {
        x.isFinite && y.isFinite && scale.isFinite && rotation.isFinite &&
        (0.08...0.92).contains(x) && (0.08...0.92).contains(y) &&
        (0.5...1.5).contains(scale) && abs(rotation) <= 180 &&
        (0..<16).contains(color) && (0..<16).contains(accent) &&
        (0..<(kind == .extra ? 15 : kind == .eye ? 12 : 8)).contains(variant)
    }
    mutating func move(x: Double, y: Double, snap: Bool) {
        let step = 0.05
        self.x = min(0.92, max(0.08, snap ? (x / step).rounded() * step : x))
        self.y = min(0.92, max(0.08, snap ? (y / step).rounded() * step : y))
    }
}
enum VoiceKind: Int, CaseIterable, Codable { case bell, squeak, hum }
enum GaitKind: Int, CaseIterable, Codable { case bounce, waddle, glide }

struct RoomObject: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: Int
    var x: Double
    var y: Double
    var isValid: Bool { (0..<6).contains(kind) && x.isFinite && y.isFinite && (0.1...0.9).contains(x) && (0.2...0.9).contains(y) }
}

struct KitchenRecipe {
    private(set) var ingredients: [Int] = []
    var flavor: Int { ingredients.reduce(0, +) % 3 }
    mutating func add(_ ingredient: Int) {
        guard (0..<6).contains(ingredient), ingredients.count < 5 else { return }
        ingredients.append(ingredient)
    }
    mutating func clear() { ingredients.removeAll() }
}
struct PathPuzzle {
    private(set) var tiles: [Int]
    let target: [Int]
    init(level: Int) {
        target = (0..<4).map { level == 1 ? 0 : ($0 + level) % 3 }
        tiles = target.map { ($0 + 1) % 3 }
    }
    var complete: Bool { tiles == target }
    mutating func turn(_ index: Int) {
        guard tiles.indices.contains(index) else { return }
        tiles[index] = (tiles[index] + 1) % 3
    }
}
struct SlideTrack: Codable, Equatable {
    var heights: [Double] = [0.18, 0.4, 0.35, 0.66, 0.8]
    var isValid: Bool { heights.count == 5 && heights.allSatisfy { $0.isFinite && (0.12...0.86).contains($0) } }
    mutating func set(_ index: Int, y: Double) {
        guard heights.indices.contains(index), y.isFinite else { return }
        heights[index] = min(0.86, max(0.12, y))
    }
    func height(at progress: Double) -> Double {
        let p = min(0.999999, max(0, progress)) * 4
        let i = Int(p)
        return heights[i] + (heights[i+1] - heights[i]) * (p - Double(i))
    }
}
struct OrchestraPattern: Codable, Equatable {
    var rows: [[Bool]] = Array(repeating: Array(repeating: false, count: 8), count: 3)
    var isValid: Bool { rows.count == 3 && rows.allSatisfy { $0.count == 8 } }
    mutating func toggle(row: Int, beat: Int) {
        guard rows.indices.contains(row), rows[row].indices.contains(beat) else { return }
        rows[row][beat].toggle()
    }
}
