import Foundation

enum PumpkinForm:Int,Codable,CaseIterable {case round,tall,flat,wonky,bumpy,little}
enum PumpkinLight:Int,Codable,CaseIterable {
    case candle,pink,green,blue,purple,rainbow,fireflies
    var key:String {"lanternLight\(rawValue)"}
}
enum PumpkinCutKind:Int,Codable,CaseIterable {case triangle,circle,heart,star,smile,tooth,freehand}
enum PumpkinStep:Int,CaseIterable {case choose,scoop,carve,light}
enum PumpkinTool:Int,CaseIterable {case stamp,draw,move,fill}
struct PumpkinPoint:Codable,Equatable {
    var x:Double
    var y:Double
    var isValid:Bool {x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y)}
}
struct PumpkinCut:Identifiable,Codable,Equatable {
    var id=UUID()
    var kind:PumpkinCutKind
    var x=0.5
    var y=0.5
    var width=0.2
    var height=0.2
    var rotation=0.0
    var outline:[PumpkinPoint]=[]
    var isValid:Bool {
        [x,y,width,height,rotation].allSatisfy(\.isFinite) &&
        (0...1).contains(x) && (0...1).contains(y) &&
        (0.03...1).contains(width) && (0.03...1).contains(height) && abs(rotation)<=180 &&
        (kind == .freehand ? (4...240).contains(outline.count) && outline.allSatisfy(\.isValid) : outline.isEmpty)
    }
    mutating func move(x:Double,y:Double) {
        guard x.isFinite,y.isFinite else {return}
        self.x=min(0.95,max(0.05,x));self.y=min(0.95,max(0.05,y))
    }
    static func fromStroke(_ points:[PumpkinPoint])->PumpkinCut? {
        guard (4...240).contains(points.count),points.allSatisfy(\.isValid),
              let first=points.first,let last=points.last,
              hypot(first.x-last.x,first.y-last.y)<=0.12 else {return nil}
        let minX=points.map(\.x).min()!,maxX=points.map(\.x).max()!
        let minY=points.map(\.y).min()!,maxY=points.map(\.y).max()!
        let w=maxX-minX,h=maxY-minY
        guard w>=0.04,h>=0.04 else {return nil}
        return PumpkinCut(kind:.freehand,x:(minX+maxX)/2,y:(minY+maxY)/2,width:w,height:h,
            outline:points.map {PumpkinPoint(x:($0.x-minX)/w,y:($0.y-minY)/h)})
    }
}
struct PumpkinLantern:Identifiable,Codable,Equatable {
    var id=UUID()
    var form=PumpkinForm.round
    var color=0
    var cuts:[PumpkinCut]=[]
    var scooped=0.0
    var light=PumpkinLight.candle
    var brightness=0.85
    var darkness=0.0
    var lit=true
    var step=0
    var gardenX=0.5
    var gardenY=0.5
    var gardenScale=1.0
    var isValid:Bool {
        (0..<6).contains(color) && cuts.count<=80 && cuts.allSatisfy(\.isValid) &&
        Set(cuts.map(\.id)).count == cuts.count &&
        [scooped,brightness,darkness,gardenX,gardenY,gardenScale].allSatisfy(\.isFinite) &&
        (0...1).contains(scooped) && (0.2...1).contains(brightness) && (0...1).contains(darkness) &&
        (0...3).contains(step) && (0.08...0.92).contains(gardenX) && (0.12...0.85).contains(gardenY) &&
        (0.65...1.4).contains(gardenScale)
    }
    mutating func addFace() {
        guard cuts.count<=77 else {return}
        cuts += [
            PumpkinCut(kind:.triangle,x:0.32,y:0.35,width:0.2,height:0.23,rotation:-8),
            PumpkinCut(kind:.triangle,x:0.68,y:0.35,width:0.2,height:0.23,rotation:8),
            PumpkinCut(kind:.smile,x:0.5,y:0.67,width:0.57,height:0.28)]
    }
}
