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
    var erasing=false
}


extension DoodleStroke {
    /// Split painted lines at the eraser, retaining their colors and widths.
    static func erasing(_ strokes:[Self],at point:DoodlePoint,radius:Double)->[Self] {
        let px=point.x*300,py=point.y*320
        var result:[Self]=[]
        for stroke in strokes {
            let reach=radius+stroke.width/2
            func near(_ p:DoodlePoint)->Bool {hypot(p.x*300-px,p.y*320-py)<=reach}
            var touches=stroke.points.contains(where:near)
            if !touches {
                for pair in zip(stroke.points,stroke.points.dropFirst()) {
                    let ax=pair.0.x*300,ay=pair.0.y*320
                    let dx=(pair.1.x-pair.0.x)*300,dy=(pair.1.y-pair.0.y)*320
                    let t=min(1,max(0,((px-ax)*dx+(py-ay)*dy)/max(0.001,dx*dx+dy*dy)))
                    if hypot(ax+t*dx-px,ay+t*dy-py)<=reach {touches=true;break}
                }
            }
            guard touches else {result.append(stroke);continue}
            var chunk:[DoodlePoint]=[]
            func flush() {
                if !chunk.isEmpty {result.append(Self(points:chunk,color:stroke.color,width:stroke.width));chunk=[]}
            }
            func accept(_ p:DoodlePoint) {
                if near(p) {flush()}
                else {
                    if chunk.count>=600 {let last=chunk.last;flush();if let last=last {chunk.append(last)}}
                    chunk.append(p)
                }
            }
            if let first=stroke.points.first {accept(first)}
            for pair in zip(stroke.points,stroke.points.dropFirst()) {
                let distance=hypot((pair.1.x-pair.0.x)*300,(pair.1.y-pair.0.y)*320)
                let count=max(1,Int(ceil(distance/4)))
                for i in 1...count {
                    let t=Double(i)/Double(count)
                    accept(DoodlePoint(x:pair.0.x+(pair.1.x-pair.0.x)*t,y:pair.0.y+(pair.1.y-pair.0.y)*t))
                }
            }
            flush()
        }
        return result
    }
}
