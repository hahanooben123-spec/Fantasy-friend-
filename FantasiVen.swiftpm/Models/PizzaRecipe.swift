import Foundation

struct PizzaPoint:Equatable {
    var x:Double
    var y:Double
    var onDough:Bool {x.isFinite && y.isFinite && hypot(x-0.5,y-0.48)<0.37}
}
struct PizzaSauceStroke:Identifiable,Equatable {
    var id=UUID()
    var points:[PizzaPoint]
}
struct PizzaSprinkle:Identifiable,Equatable {
    var id=UUID()
    var kind:Int
    var point:PizzaPoint
    var angle:Double
}
struct PizzaRecipe:Equatable {
    var ingredients:Set<Int> = []
    var mixed=0.0
    var formed=0.0
    var sauce:[PizzaSauceStroke]=[]
    var spices:[PizzaSprinkle]=[]
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
            p.sprinkle(i%4,at:PizzaPoint(x:0.5+cos(angle)*r,y:0.48+sin(angle)*r))
        }
        return p
    }
}
