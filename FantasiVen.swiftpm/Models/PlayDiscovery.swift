import Foundation

enum DishFeeling:String,CaseIterable {
    case berry,creamy,crunchy,fizzy,bouncy,rainbow
    var key:String {"dish_"+rawValue}
    var action:PlayAction {
        switch self {
        case .berry:return .hug
        case .creamy:return .feed
        case .crunchy:return .tickle
        case .fizzy:return .tickle
        case .bouncy:return .jump
        case .rainbow:return .dance
        }
    }
}
struct FantasyDish:Equatable {
    let red:Double
    let green:Double
    let blue:Double
    let feeling:DishFeeling
    let topping:Int
    static func make(_ ingredients:[Int])->FantasyDish {
        let valid=ingredients.filter {(0..<6).contains($0)}
        let colors:[(Double,Double,Double)]=[(1,0.23,0.43),(1,0.87,0.31),(1,0.47,0.12),(0.25,0.76,0.35),(0.36,0.28,0.88),(1,0.78,0.37)]
        let count=Double(max(1,valid.count))
        var r=0.0,g=0.0,b=0.0
        for ingredient in valid {r+=colors[ingredient].0;g+=colors[ingredient].1;b+=colors[ingredient].2}
        let types=Set(valid)
        let feeling:DishFeeling
        if types.count>=4 {feeling = .rainbow}
        else if types.contains(1) && types.contains(5) {feeling = .bouncy}
        else if types.contains(0) && types.contains(3) {feeling = .fizzy}
        else if types.contains(2) || types.contains(3) {feeling = .crunchy}
        else if types.contains(1) || types.contains(5) {feeling = .creamy}
        else {feeling = .berry}
        return FantasyDish(red:valid.isEmpty ? 1 : r/count,green:valid.isEmpty ? 0.9 : g/count,
                           blue:valid.isEmpty ? 0.65 : b/count,feeling:feeling,topping:valid.last ?? 0)
    }
}
enum FruitWeather:Int,CaseIterable {
    case orchard,breeze,rainbow
    var key:String {["fruitOrchard","fruitBreeze","fruitRainbow"][rawValue]}
}
enum BubbleSurpriseKind:Int,CaseIterable {
    case music,butterfly,littleFriend,paint
}
struct BubbleSurprise:Identifiable {
    let id=UUID()
    let kind:BubbleSurpriseKind
    let x:Double
    let y:Double
    let born:Double
    var lifetime:Double {kind == .littleFriend ? 3 : 1.8}
}
extension OrchestraPattern {
    static func preset(_ index:Int)->OrchestraPattern {
        let rhythms=[[[0,4],[2,6],[3,7]],[[0,3,4],[1,5],[2,6,7]],
                     [[0,2,4,6],[3,7],[1,5]],[[0,4,7],[1,2,5,6],[3]]]
        var pattern=OrchestraPattern()
        for (row,beats) in rhythms[((index%4)+4)%4].enumerated() {
            for beat in beats {pattern.toggle(row:row,beat:beat)}
        }
        return pattern
    }
}
