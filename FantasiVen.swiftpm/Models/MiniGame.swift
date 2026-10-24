import Foundation

enum MiniGameKind: String, CaseIterable, Identifiable {
    case apples, bubbles, hide, slide, trampoline, kitchen, orchestra, path
    static let menuGames:[MiniGameKind] = [.apples,.bubbles,.kitchen,.orchestra]
    static let playgroundToys:[MiniGameKind] = [.slide,.trampoline]
    var id: String { rawValue }
    var titleKey: String { "game_" + rawValue }
    var hintKey: String { "hint_" + rawValue }
}

/// Short-lived play state. It never changes the child's saved character or collection.
struct AppleDrop: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var fruit = 0
    var golden = false
    var anchorX = 0.5
    var born = 0.0
    var drifting = false
}

struct OrchardFlower:Identifiable {
    let id=UUID()
    let x:Double
    let variant:Int
}
struct AppleRain {
    private(set) var drops: [AppleDrop] = []
    private(set) var flowers: [Double] = []
    private(set) var garden:[OrchardFlower]=[]
    private var flowerSequence=0
    private(set) var caught = 0
    private(set) var streak = 0
    private(set) var goldenCaught = 0
    private(set) var fruitBasket: [Int] = []
    private var spawnSequence = 0
    private(set) var time = 0.0
    private var weatherChoice:FruitWeather?
    var weather:FruitWeather {weatherChoice ?? FruitWeather(rawValue:Int(time/14)%3) ?? .orchard}
    mutating func chooseNextWeather() {
        weatherChoice=FruitWeather(rawValue:(weather.rawValue+1)%3) ?? .orchard
    }
    mutating func shake() {
        for i in 0..<3 where drops.count<5 {
            let x=min(0.85,max(0.15,playerX+Double(i-1)*0.15))
            drops.append(AppleDrop(x:x,y:0.14-Double(i)*0.06,fruit:spawnSequence%3,
                golden:spawnSequence%7 == 6,anchorX:x,born:time,drifting:weather == .breeze))
            spawnSequence+=1
        }
    }
    private(set) var lastCatches:[AppleDrop]=[]
    mutating func calmOrchard() {weatherChoice = .orchard}
    mutating func setOrchardWind(_ enabled:Bool) {weatherChoice=enabled ? .breeze : .orchard}
    mutating func shareFruit(at index:Int)->Int? {
        guard fruitBasket.indices.contains(index) else {return nil}
        return fruitBasket.remove(at:index)
    }
    private(set) var lastFruit = 0
    private(set) var playerX = 0.5
    private var spawnClock = 1.3

    mutating func move(to x: Double) {
        guard x.isFinite else { return }
        playerX = min(0.86, max(0.14, x))
    }

    /// Clamping prevents a background pause from advancing the whole game at once.
    @discardableResult
    mutating func step(_ delta: Double, spawnX: Double, catchRadius: Double = 0.15, level:Int = 1,adventurous:Bool = false,catchY:Double = 0.745,catchHalfHeight:Double = 0.045,relaxed:Bool = false) -> Bool {
        guard delta.isFinite, delta > 0 else { return false }
        let dt = min(delta, 0.08)
        lastCatches=[]
        time += dt
        spawnClock += dt
        let baseInterval = level == 1 ? 1.8 : level == 2 ? 1.6 : 1.3
        let interval = relaxed ? 2.8 : baseInterval * (adventurous ? (weather == .rainbow ? 0.6 : 0.9) : 1)
        if spawnClock >= interval && drops.count < (relaxed ? 2 : 5) {
            spawnClock = 0
            var x = spawnX.isFinite ? min(0.83,max(0.17,spawnX)) : 0.5
            if relaxed {
                let spread=min(0.28,max(0.16,catchRadius*1.35))
                x=min(0.83,max(0.17,playerX+(spawnSequence.isMultiple(of:2) ? spread : -spread)))
            }
            if adventurous && weather == .orchard {x=[0.28,0.5,0.72][(spawnSequence/3)%3]}
            if adventurous && weather == .rainbow {x=0.18+Double(spawnSequence%5)*0.16}
            drops.append(AppleDrop(x:x,y:relaxed ? 0.25 : adventurous ? 0.12 : -0.06,fruit:spawnSequence%3,
                                   golden:!relaxed && spawnSequence%7 == 6,anchorX:x,born:time,drifting:adventurous && weather == .breeze))
            spawnSequence += 1
        }
        var collected = false
        let speed = relaxed ? 0.12 : (level == 1 ? 0.16 : level == 2 ? 0.18 : 0.22) * (adventurous ? 1.1 : 1)
        for index in drops.indices {
            drops[index].y += dt * speed
            if drops[index].drifting {
                drops[index].x=min(0.86,max(0.14,drops[index].anchorX+sin((time-drops[index].born)*2.2)*0.07))
            }
        }
        var remaining: [AppleDrop] = []
        for apple in drops {
            if abs(apple.y-catchY) <= catchHalfHeight && abs(apple.x - playerX) <= catchRadius {
                lastCatches.append(apple)
                caught += 1; streak += 1; lastFruit=apple.fruit
                if apple.golden {goldenCaught += 1}
                fruitBasket.append(apple.fruit)
                if !relaxed && fruitBasket.count > 12 {fruitBasket.removeFirst()}
                collected = true
                continue
            }
            if apple.y > 0.94 {
                streak = 0
                flowers.append(apple.x)
                garden.append(OrchardFlower(x:apple.x,variant:flowerSequence%7));flowerSequence+=1
                if flowers.count>8 {flowers.removeFirst()}
                if garden.count>8 {garden.removeFirst()}
                continue
            }
            remaining.append(apple)
        }
        drops = remaining
        return collected
    }
}

struct BubbleGarden {
    private(set) var popped = 0
    private(set) var generations = Array(repeating: 0, count: 6)

    /// A generation identifies a specific bubble; repeated input cannot pop it twice.
    @discardableResult
    mutating func pop(slot: Int, generation: Int) -> Bool {
        guard generations.indices.contains(slot), generations[slot] == generation else { return false }
        generations[slot] += 1
        popped += 1
        return true
    }
}

struct HideAndSeek {
    private(set) var hiding: Set<Int>
    private(set) var opened: Set<Int> = []
    var found: Int { hiding.intersection(opened).count }
    var complete: Bool { found == hiding.count }

    init(spots: [Int] = Array(0..<6).shuffled()) {
        let valid = Array(Set(spots.filter { (0..<6).contains($0) })).sorted()
        hiding = Set(valid.prefix(3))
        if hiding.count != 3 { hiding = [0, 2, 4] }
        // Retain a random order supplied by the caller rather than bias toward low indices.
        let unique = spots.reduce(into: [Int]()) { result, spot in
            if (0..<6).contains(spot) && !result.contains(spot) { result.append(spot) }
        }
        if unique.count >= 3 { hiding = Set(unique.prefix(3)) }
    }

    @discardableResult
    mutating func reveal(_ spot: Int) -> Bool {
        guard (0..<6).contains(spot), !opened.contains(spot) else { return false }
        opened.insert(spot)
        return hiding.contains(spot)
    }
}
