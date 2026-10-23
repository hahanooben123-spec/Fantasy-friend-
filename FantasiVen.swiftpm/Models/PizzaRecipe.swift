import Foundation

struct PizzaPoint:Codable,Equatable {
    var x:Double
    var y:Double
    var onDough:Bool {x.isFinite && y.isFinite && hypot(x-0.5,y-0.48)<0.37}
}
struct PizzaSauceStroke:Identifiable,Codable,Equatable {
    var id=UUID()
    var points:[PizzaPoint]
}
struct PizzaSprinkle:Identifiable,Codable,Equatable {
    var id=UUID()
    var kind:Int
    var point:PizzaPoint
    var angle:Double
}
struct PizzaRecipe:Codable,Equatable {
    var ingredients:Set<Int> = []
    var mixed=0.0
    var formed=0.0
    var sauce:[PizzaSauceStroke]=[]
    var spices:[PizzaSprinkle]=[]
    var toppings:[PizzaTopping]=[]
    var isValid:Bool {
        ingredients.allSatisfy {(0..<3).contains($0)} &&
        mixed.isFinite && formed.isFinite && (0...1).contains(mixed) && (0...1).contains(formed) &&
        sauce.count<=60 && sauce.allSatisfy {!$0.points.isEmpty && $0.points.count<=300 && $0.points.allSatisfy {$0.x.isFinite && $0.y.isFinite && (-0.1...1.1).contains($0.x) && (-0.1...1.1).contains($0.y)}} &&
        toppings.count<=120 && toppings.allSatisfy {$0.point.onDough && $0.angle.isFinite} &&
        spices.count<=360 && spices.allSatisfy {(0...3).contains($0.kind) && $0.point.onDough && $0.angle.isFinite}
    }
    var readyToShape:Bool {ingredients.count == 3 && mixed>=1}
    var readyForSauce:Bool {readyToShape && formed>=0.7}
    mutating func sprinkle(_ kind:Int,at point:PizzaPoint) {
        guard point.onDough,spices.count<360 else {return}
        for i in 0..<3 {
            let offset=Double(spices.count+i)
            let p=PizzaPoint(x:point.x+sin(offset*2.4)*0.025,y:point.y+cos(offset*1.9)*0.025)
            if p.onDough {spices.append(PizzaSprinkle(kind:kind,point:p,angle:offset*47))}
        }
    }
    mutating func place(_ kind:PizzaToppingKind,at point:PizzaPoint) {
        guard point.onDough,toppings.count<120 else {return}
        toppings.append(PizzaTopping(kind:kind,point:point,angle:Double(toppings.count)*47))
    }
    mutating func spreadSauce() {
        var points:[PizzaPoint]=[]
        for i in 0..<110 {
            let a=Double(i)*0.22,r=Double(i)/110*0.28
            points.append(PizzaPoint(x:0.5+cos(a)*r,y:0.48+sin(a)*r))
        }
        if sauce.count<60 {sauce.append(PizzaSauceStroke(points:points))}
    }
    static var sample:PizzaRecipe {
        var p=PizzaRecipe();p.ingredients=[0,1,2];p.mixed=1;p.formed=1;p.spreadSauce()
        for i in 0..<40 {
            let angle=Double(i)*2.4,r=sqrt(Double(i)/40)*0.26
            p.sprinkle(i%3,at:PizzaPoint(x:0.5+cos(angle)*r,y:0.48+sin(angle)*r))
        }
        for i in 0..<19 {
            let a=Double(i)*2.4,r=sqrt(Double(i)/19)*0.27
            p.place(PizzaToppingKind(rawValue:i%7) ?? .cheese,at:PizzaPoint(x:0.5+cos(a)*r,y:0.48+sin(a)*r))
        }
        return p
    }
}

enum PizzaToppingKind:Int,Codable,CaseIterable {
    case cheese,pepperoni,ham,mushroom,pepper,olive,pineapple
    var key:String {"pizzaTopping\(rawValue)"}
}
struct PizzaTopping:Identifiable,Codable,Equatable {
    var id=UUID()
    var kind:PizzaToppingKind
    var point:PizzaPoint
    var angle:Double
}
