import Foundation

struct PizzaPoint:Codable,Equatable {
    var x:Double
    var y:Double
    var onDough:Bool {x.isFinite && y.isFinite && hypot(x-0.5,y-0.48)<0.37}
    var isFinite:Bool {x.isFinite && y.isFinite}
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
enum PizzaDoughForm:Int,Codable,CaseIterable {case round,heart,star,cloud,oval,square}
enum PizzaWorkTool:Int,CaseIterable {case shape,sauce,toppings,herbs}
struct PizzaBite:Identifiable,Codable,Equatable {
    var id=UUID()
    var point:PizzaPoint
    var radius=0.082
}
struct PizzaRecipe:Codable,Equatable {
    var ingredients:Set<Int>=[]
    var mixed=0.0
    var formed=0.0
    var sauce:[PizzaSauceStroke]=[]
    var spices:[PizzaSprinkle]=[]
    var toppings:[PizzaTopping]=[]
    // Optional fields preserve recipes saved before free dough and finger bites.
    var doughForm:PizzaDoughForm?
    var doughStretch:[Double]?
    var dents:[PizzaPoint]?
    var bites:[PizzaBite]?
    var legacySlices:Int?
    var isValid:Bool {
        ingredients.allSatisfy {(0..<3).contains($0)} &&
        mixed.isFinite && formed.isFinite && (0...1).contains(mixed) && (0...1).contains(formed) &&
        sauce.allSatisfy {!$0.points.isEmpty && $0.points.allSatisfy {Self.validPoint($0)}} &&
        toppings.allSatisfy {Self.validPoint($0.point) && $0.angle.isFinite} &&
        spices.allSatisfy {(0...3).contains($0.kind) && Self.validPoint($0.point) && $0.angle.isFinite} &&
        (doughStretch.map {$0.count == 64 && $0.allSatisfy {$0.isFinite && (0.60...1.18).contains($0)}} ?? true) &&
        (dents ?? []).allSatisfy {Self.validPoint($0)} &&
        (bites ?? []).allSatisfy {Self.validPoint($0.point) && $0.radius.isFinite && (0.03...0.15).contains($0.radius)} &&
        (0...8).contains(legacySlices ?? 0)
    }
    private static func validPoint(_ p:PizzaPoint)->Bool {
        p.isFinite && (-0.1...1.1).contains(p.x) && (-0.1...1.1).contains(p.y)
    }
    var readyToShape:Bool {ingredients.count == 3 && mixed>=1}
    var readyForSauce:Bool {readyToShape && formed>=0.7}
    func outline(inset:Double=1)->[PizzaPoint] {
        let spread=(0.63+formed*0.37)*inset
        return (0..<64).map {i in
            let a=Double(i)*Double.pi/32
            var x=cos(a),y=sin(a)
            switch doughForm ?? .round {
            case .round:break
            case .heart:
                let t=a+Double.pi/2
                x=pow(sin(t),3)
                y = -(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))/16+0.08
            case .star:
                let r=0.79+0.19*cos(5*(a+Double.pi/2));x*=r;y*=r
            case .cloud:
                let r=0.91+0.09*cos(6*a);x*=r;y*=r
            case .oval:x*=0.84;y*=1.05
            case .square:
                let r=0.84/pow(pow(abs(cos(a)),4)+pow(abs(sin(a)),4),0.25);x*=r;y*=r
            }
            let stretch=doughStretch?[i] ?? 1
            return PizzaPoint(x:0.5+x*0.36*spread*stretch,y:0.48+y*0.34*spread*stretch)
        }
    }
    func contains(_ point:PizzaPoint,inset:Double=1)->Bool {
        guard point.isFinite else {return false}
        let polygon=outline(inset:inset)
        var inside=false
        var previous=polygon.count-1
        for i in polygon.indices {
            let a=polygon[i],b=polygon[previous]
            if (a.y>point.y) != (b.y>point.y),
               point.x < (b.x-a.x)*(point.y-a.y)/(b.y-a.y)+a.x {inside.toggle()}
            previous=i
        }
        return inside
    }
    mutating func deform(from start:PizzaPoint,to end:PizzaPoint) {
        guard start.isFinite,end.isFinite else {return}
        let points=outline()
        let dx=end.x-start.x,dy=end.y-start.y
        var values=doughStretch ?? Array(repeating:1.0,count:64)
        for i in values.indices {
            let p=points[i],distance=hypot(p.x-start.x,p.y-start.y)
            let weight=exp(-distance*distance/0.035)
            let radial=hypot(p.x-0.5,p.y-0.48)
            let projection=(dx*(p.x-0.5)+dy*(p.y-0.48))/max(0.05,radial)
            values[i]=min(1.18,max(0.60,values[i]+projection*weight*2.3))
        }
        doughStretch=values;formed=min(1,max(0.35,formed))
    }
    mutating func press(at point:PizzaPoint) {
        guard contains(point) else {return}
        var values=dents ?? []
        // Old impressions soften as the dough is kneaded; input never stops.
        if values.count>=40 {values.removeFirst()}
        values.append(point);dents=values
    }
    mutating func sprinkle(_ kind:Int,at point:PizzaPoint) {
        guard contains(point) else {return}
        let first=spices.count
        for i in 0..<3 {
            let offset=Double(first+i)
            let p=PizzaPoint(x:point.x+sin(offset*2.4)*0.025,y:point.y+cos(offset*1.9)*0.025)
            if contains(p) {spices.append(PizzaSprinkle(kind:kind,point:p,angle:offset*47))}
        }
    }
    mutating func place(_ kind:PizzaToppingKind,at point:PizzaPoint) {
        guard contains(point) else {return}
        toppings.append(PizzaTopping(kind:kind,point:point,angle:Double(toppings.count)*47))
    }
    mutating func spreadSauce() {
        var points:[PizzaPoint]=[]
        for i in 0..<110 {
            let a=Double(i)*0.22,r=Double(i)/110*0.27
            let p=PizzaPoint(x:0.5+cos(a)*r,y:0.48+sin(a)*r)
            if contains(p,inset:0.90) {points.append(p)}
        }
        if !points.isEmpty {sauce.append(PizzaSauceStroke(points:points))}
    }
    var sauceCoverage:Double {
        var painted:Set<Int>=[]
        for stroke in sauce {
            for p in stroke.points {painted.insert(Int(p.x*10)+Int(p.y*10)*10)}
        }
        return min(1,Double(painted.count)/20)
    }
    private func foodAt(_ point:PizzaPoint,polygon:[PizzaPoint])->Bool {
        var inside=false
        var previous=polygon.count-1
        for i in polygon.indices {
            let a=polygon[i],b=polygon[previous]
            if (a.y>point.y) != (b.y>point.y),
               point.x < (b.x-a.x)*(point.y-a.y)/(b.y-a.y)+a.x {inside.toggle()}
            previous=i
        }
        guard inside else {return false}
        if let removed=legacySlices,removed>0 {
            let a=(atan2(point.y-0.48,point.x-0.5)*180/Double.pi+450).truncatingRemainder(dividingBy:360)
            if Int(a/45)<removed {return false}
        }
        return !(bites ?? []).contains {bite in
            let dx=(point.x-bite.point.x)*300,dy=(point.y-bite.point.y)*320
            let a=atan2(dy,dx)
            return hypot(dx,dy)<bite.radius*300*(1+0.065*cos(a*9))
        }
    }
    mutating func takeBite(at point:PizzaPoint)->PizzaBite? {
        guard point.isFinite,(0...1).contains(point.x),(0...1).contains(point.y) else {return nil}
        let bite=PizzaBite(point:point)
        let polygon=outline()
        let candidates=[point]+(0..<16).map {i in
            let a=Double(i)*Double.pi/8
            return PizzaPoint(x:point.x+cos(a)*bite.radius*0.84,y:point.y+sin(a)*bite.radius*0.79)
        }
        guard candidates.contains(where:{foodAt($0,polygon:polygon)}) else {return nil}
        var values=bites ?? [];values.append(bite);bites=values
        return bite
    }
    var nextBitePoint:PizzaPoint? {
        let polygon=outline()
        for y in 0..<25 {
            for x in 0..<25 {
                let point=PizzaPoint(x:0.07+Double(x)*0.036,y:0.06+Double(y)*0.035)
                if foodAt(point,polygon:polygon) {return point}
            }
        }
        return nil
    }
    var hasFood:Bool {nextBitePoint != nil}
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
