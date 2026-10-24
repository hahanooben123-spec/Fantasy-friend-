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

struct RoomObject:Identifiable,Codable,Equatable {
    var id=UUID()
    var kind:Int
    var x:Double
    var y:Double
    var color:Int?
    var scale:Double?
    var rotation:Double?
    var mirrored:Bool?
    var on:Bool?
    var layer:Int?
    var sizeFactor:Double {scale ?? 1}
    var angle:Double {rotation ?? 0}
    var isOn:Bool {on ?? (kind != RoomItem.toybox.rawValue)}
    var level:Int {layer ?? (kind == 4 ? -1 : RoomItem(rawValue:kind)?.isWall == true ? 0 : 1)}
    var isValid:Bool {
        (0..<18).contains(kind) && x.isFinite && y.isFinite &&
        (0.1...0.9).contains(x) && (0.2...0.9).contains(y) &&
        (color.map {(0..<16).contains($0)} ?? true) &&
        sizeFactor.isFinite && (0.6...1.6).contains(sizeFactor) &&
        angle.isFinite && abs(angle)<=180 && (-1...2).contains(level)
    }
    mutating func move(x:Double,y:Double) {
        guard x.isFinite,y.isFinite else {return}
        self.x=min(0.9,max(0.1,x));self.y=min(0.9,max(0.2,y))
    }
}
enum RoomItem:Int,CaseIterable {
    case bed,plant,lamp,shelf,rug,window,sofa,table,cushion,picture,bunting,mobile,toybox,ball,snack,music,stool,rainbow
    var key:String {"furniture_\(rawValue)"}
    var isWall:Bool {[5,9,10,11,17].contains(rawValue)}
    var category:Int {
        if [0,6,7,8,16].contains(rawValue) {return 0}
        return [3,12,13,14,15].contains(rawValue) ? 2 : 1
    }
    var widthFactor:Double {[0,4,6,10,17].contains(rawValue) ? 1.35 : [8,13,14,16].contains(rawValue) ? 0.78 : 1}
}
struct RoomDesign:Codable,Equatable {
    var wallpaper=0
    var floor=0
    var night=false
    var sleepingBed:UUID?
    var blanket:Double?
    var curtainsClosed:Bool?
    var playthings:[RoomPlaything]?
    var friendX=0.52
    var friendY=0.72
    var isValid:Bool {
        (0..<6).contains(wallpaper) && (0..<4).contains(floor) &&
        (blanket.map {$0.isFinite && (0...1).contains($0)} ?? true) &&
        (playthings ?? []).count<=24 && (playthings ?? []).allSatisfy(\.isValid) &&
        Set((playthings ?? []).map(\.id)).count == (playthings ?? []).count &&

        friendX.isFinite && friendY.isFinite && (0.1...0.9).contains(friendX) && (0.2...0.9).contains(friendY)
    }
}
struct RoomLayout:Equatable {
    var objects:[RoomObject]=[]
    var design=RoomDesign()
    static func starter(_ style:Int)->RoomLayout {
        var value=RoomLayout()
        value.design.wallpaper=[0,2,4][min(2,max(0,style))]
        value.design.floor=style == 1 ? 1 : 0
        let beds=[0,0,0],toys=[12,12,12]
        value.objects=[
            RoomObject(kind:5,x:0.5,y:0.28),
            RoomObject(kind:4,x:0.5,y:0.79,color:style == 0 ? 9 : 11,scale:1.3),
            RoomObject(kind:beds[min(2,max(0,style))],x:0.25,y:0.70),
            RoomObject(kind:2,x:0.78,y:0.60),
            RoomObject(kind:toys[min(2,max(0,style))],x:0.83,y:0.76),
            RoomObject(kind:9,x:0.22,y:0.33,color:style*3+1)]
        return value
    }
}

// Stable furniture anchors remove placement, size and rotation decisions for small children.
extension RoomLayout {
    func forLittleHands()->RoomLayout {
        var next=self
        let anchors:[(Double,Double)]=[
            (0.22,0.69),(0.12,0.49),(0.84,0.54),(0.15,0.42),(0.51,0.84),(0.57,0.28),
            (0.29,0.70),(0.69,0.72),(0.39,0.81),(0.22,0.29),(0.50,0.20),(0.74,0.32),
            (0.83,0.77),(0.54,0.87),(0.69,0.67),(0.88,0.42),(0.59,0.78),(0.47,0.36)]
        for kind in [RoomItem.bed,.rug,.lamp,.toybox,.picture,.window] where
            !next.objects.contains(where:{$0.kind == kind.rawValue}) && next.objects.count<32 {
            next.objects.append(RoomObject(kind:kind.rawValue,x:0.5,y:0.5))
        }
        var seen:[Int:Int]=[:]
        for i in next.objects.indices {
            let kind=next.objects[i].kind
            guard anchors.indices.contains(kind) else {continue}
            let duplicate=seen[kind,default:0];seen[kind]=duplicate+1
            let anchor=anchors[kind]
            next.objects[i].move(x:anchor.0+Double(duplicate%2)*0.05,y:anchor.1-Double(duplicate)*0.035)
            next.objects[i].rotation=0;next.objects[i].scale=kind == RoomItem.rug.rawValue ? 1.2 : 1
        }
        return next
    }
}

struct KitchenRecipe {
    private(set) var ingredients: [Int] = []
    var flavor: Int { ingredients.reduce(0, +) % 3 }
    mutating func add(_ ingredient: Int) {
        guard (0..<6).contains(ingredient) else { return }
        if ingredients.count == 5 {ingredients.removeFirst()}
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
    var notes:[[Int]]?
    func note(row:Int,beat:Int)->Int {
        guard let notes=notes,notes.indices.contains(row),notes[row].indices.contains(beat) else {return beat}
        return notes[row][beat]
    }
    mutating func record(row:Int,beat:Int,note:Int) {
        guard rows.indices.contains(row),rows[row].indices.contains(beat) else {return}
        rows[row][beat]=true
        var pitches=notes ?? Array(repeating:Array(0..<8),count:3)
        pitches[row][beat]=min(7,max(0,note));notes=pitches
    }
    var isValid: Bool { rows.count == 3 && rows.allSatisfy { $0.count == 8 } && (notes.map {$0.count == 3 && $0.allSatisfy {$0.count == 8 && $0.allSatisfy {(0..<8).contains($0)}}} ?? true) }
    mutating func toggle(row: Int, beat: Int) {
        guard rows.indices.contains(row), rows[row].indices.contains(beat) else { return }
        rows[row][beat].toggle()
    }
}
