import SwiftUI

enum RoomPalette {
    static let walls:[Color]=[
        Color(red:0.29,green:0.84,blue:0.84),Color(red:1,green:0.8,blue:0.59),
        Color(red:0.76,green:0.65,blue:0.98),Color(red:0.98,green:0.67,blue:0.75),
        Color(red:0.66,green:0.88,blue:0.33),Color(red:0.53,green:0.72,blue:0.91)]
    static let floors:[Color]=[
        Color(red:1,green:0.78,blue:0.52),Color(red:0.93,green:0.74,blue:0.47),
        Color(red:0.79,green:0.71,blue:0.93),Color(red:0.59,green:0.73,blue:0.69)]
}
struct RoomInterior:View {
    let design:RoomDesign
    var body:some View {
        Canvas {c,size in
            let w=size.width,h=size.height,wall=RoomPalette.walls[design.wallpaper]
            c.fill(Path(CGRect(origin:.zero,size:size)),with:.linearGradient(Gradient(colors:[
                GameStyle.mixed(wall,with:.white,amount:0.22),wall,GameStyle.mixed(wall,with:GameStyle.ink,amount:0.16)]),
                startPoint:.zero,endPoint:CGPoint(x:w,y:h)))
            for row in 0..<5 {
                for col in 0..<7 {
                    let x=CGFloat(col)*w/6+CGFloat(row%2)*w/12,y=CGFloat(row)*h*0.13
                    let rect=CGRect(x:x,y:y,width:9,height:9)
                    if design.wallpaper%3 == 0 {
                        c.fill(Path(ellipseIn:rect),with:.color(.white.opacity(0.22)))
                    } else if design.wallpaper%3 == 1 {
                        var diamond=Path();diamond.move(to:CGPoint(x:x,y:y-5))
                        diamond.addLine(to:CGPoint(x:x+4,y:y));diamond.addLine(to:CGPoint(x:x,y:y+5))
                        diamond.addLine(to:CGPoint(x:x-4,y:y));diamond.closeSubpath()
                        c.fill(diamond,with:.color(.white.opacity(0.17)))
                    } else {
                        c.fill(Path(roundedRect:CGRect(x:x,y:y,width:2,height:h*0.065),cornerRadius:1),with:.color(.white.opacity(0.13)))
                    }
                }
            }
            let floorY=h*0.58,wood=RoomPalette.floors[design.floor]
            c.fill(Path(CGRect(x:0,y:floorY,width:w,height:h-floorY)),with:.linearGradient(Gradient(colors:[
                GameStyle.mixed(wood,with:.white,amount:0.16),wood,GameStyle.mixed(wood,with:GameStyle.ink,amount:0.10)]),
                startPoint:CGPoint(x:0,y:floorY),endPoint:CGPoint(x:0,y:h)))
            for i in 0..<6 {
                let x=CGFloat(i)*w/5
                var seam=Path();seam.move(to:CGPoint(x:w/2+(x-w/2)*0.55,y:floorY))
                seam.addLine(to:CGPoint(x:x,y:h))
                c.stroke(seam,with:.color(GameStyle.ink.opacity(0.05)),lineWidth:1.5)
            }
            for row in 1..<6 {
                let y=floorY+CGFloat(row*row)/36*(h-floorY)
                var seam=Path();seam.move(to:CGPoint(x:0,y:y));seam.addLine(to:CGPoint(x:w,y:y))
                c.stroke(seam,with:.color(GameStyle.ink.opacity(0.04)),lineWidth:1.5)
            }
            c.fill(Path(CGRect(x:0,y:floorY-9,width:w,height:12)),with:.color(Color(red:1,green:0.91,blue:0.7)))
            c.fill(Path(CGRect(x:0,y:floorY+3,width:w,height:3)),with:.color(GameStyle.ink.opacity(0.15)))
            let door=CGRect(x:w*0.84,y:floorY-min(160,h*0.29),width:w*0.12,height:min(160,h*0.29))
            ToyFinish.paint(c,path:Path(roundedRect:door,cornerRadius:door.width*0.4),
                color:StorybookStyle.teal,edge:2)
            c.fill(Path(ellipseIn:CGRect(x:door.minX+door.width*0.17,y:door.midY,width:5,height:5)),
                with:.color(StorybookStyle.honey))
            let light=CGPoint(x:w*0.48,y:h*0.16)
            c.fill(Path(CGRect(origin:.zero,size:size)),with:.radialGradient(
                Gradient(colors:[.white.opacity(0.18),.clear]),center:light,startRadius:0,endRadius:w*0.65))
        }.storybookScene(lamps:true).allowsHitTesting(false).accessibilityHidden(true)
    }
}
struct RoomFurniture:View {
    let kind:Int
    var tint:Int?
    var isOn=true
    var night=false
    var curtainsClosed=false
    var showQuilt=true
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body:some View {
        ZStack {
        if [0,2,12].contains(kind) {
            PaintedRoomFurniture(kind:kind,tint:tint,isOn:isOn,showQuilt:showQuilt)
        } else {
        Canvas {c,size in
            c.scaleBy(x:size.width/100,y:size.height/110)
            RoomPropPainter(c:c,kind:kind,tint:tint,isOn:isOn,night:night).draw()
        }
        if kind == RoomItem.window.rawValue {
            RoomCurtains(amount:curtainsClosed ? 1 : 0)
                .animation(reduced ? nil : .easeInOut(duration:0.35),value:curtainsClosed)
        }
        }
        }.accessibilityHidden(true)
    }
}
private struct RoomPropPainter {
    let c:GraphicsContext
    let kind:Int
    let tint:Int?
    let isOn:Bool
    let night:Bool
    private var color:Color {GameStyle.palette[tint ?? [8,5,3,13,9,15,6,13,1,2,3,3,2,6,10,8,13,9][min(17,max(0,kind))]]}
    private var wood:Color {Color(red:0.69,green:0.4,blue:0.25)}
    private func box(_ r:CGRect,_ color:Color,_ radius:CGFloat=8) {ToyFinish.paint(c,path:Path(roundedRect:r,cornerRadius:radius),color:color,edge:1.5)}
    private func oval(_ r:CGRect,_ color:Color) {ToyFinish.paint(c,path:Path(ellipseIn:r),color:color,edge:1)}
    private func line(_ a:CGPoint,_ b:CGPoint,_ color:Color,_ width:CGFloat=3) {
        var p=Path();p.move(to:a);p.addLine(to:b)
        c.stroke(p,with:.color(color),style:StrokeStyle(lineWidth:width,lineCap:.round))
    }
    func draw() {
        switch kind {
        case 0: bed()
        case 1: plant()
        case 2: lamp()
        case 3: shelf()
        case 4:
            oval(CGRect(x:4,y:48,width:92,height:43),color)
            c.stroke(Path(ellipseIn:CGRect(x:10,y:53,width:80,height:32)),with:.color(.white.opacity(0.65)),lineWidth:2)
            for i in 0..<9 {
                line(CGPoint(x:9+CGFloat(i)*10,y:85),CGPoint(x:7+CGFloat(i)*10,y:92),color,2)
            }
        case 5: window()
        case 6: sofa()
        case 7:
            for x in [CGFloat(24),CGFloat(76)] {box(CGRect(x:x-4,y:56,width:8,height:43),wood,3)}
            box(CGRect(x:10,y:42,width:80,height:20),color,12)
            line(CGPoint(x:20,y:48),CGPoint(x:79,y:48),.white.opacity(0.35),2)
        case 8:
            var p=Path();p.move(to:CGPoint(x:14,y:52))
            p.addCurve(to:CGPoint(x:86,y:52),control1:CGPoint(x:16,y:28),control2:CGPoint(x:82,y:30))
            p.addCurve(to:CGPoint(x:83,y:89),control1:CGPoint(x:98,y:61),control2:CGPoint(x:94,y:80))
            p.addQuadCurve(to:CGPoint(x:14,y:89),control:CGPoint(x:48,y:102))
            p.addQuadCurve(to:CGPoint(x:14,y:52),control:CGPoint(x:2,y:73));p.closeSubpath()
            ToyFinish.paint(c,path:p,color:color)
            for x in [CGFloat(30),CGFloat(70)] {oval(CGRect(x:x,y:63,width:4,height:4),GameStyle.mixed(color,with:GameStyle.ink,amount:0.3))}
        case 9:
            box(CGRect(x:13,y:14,width:74,height:77),wood,7)
            box(CGRect(x:19,y:20,width:62,height:65),color,3)
            oval(CGRect(x:53,y:27,width:18,height:18),Color(red:1,green:0.9,blue:0.48))
            var hill=Path();hill.move(to:CGPoint(x:22,y:77));hill.addQuadCurve(to:CGPoint(x:78,y:77),control:CGPoint(x:36,y:34));hill.closeSubpath()
            ToyFinish.paint(c,path:hill,color:GameStyle.palette[11],edge:0.8)
        case 10:
            var cord=Path();cord.move(to:CGPoint(x:2,y:25));cord.addQuadCurve(to:CGPoint(x:98,y:25),control:CGPoint(x:50,y:67))
            c.stroke(cord,with:.color(wood),lineWidth:2)
            for i in 0..<5 {
                let x=CGFloat(i)*19+12,y=35+CGFloat(2-abs(i-2))*4
                var flag=Path();flag.move(to:CGPoint(x:x-8,y:y));flag.addLine(to:CGPoint(x:x+8,y:y));flag.addLine(to:CGPoint(x:x,y:y+24));flag.closeSubpath()
                ToyFinish.paint(c,path:flag,color:i%2 == 0 ? color : GameStyle.palette[(i*3)%16],edge:1)
            }
        case 11:
            line(CGPoint(x:50,y:3),CGPoint(x:50,y:25),wood,2)
            var arc=Path();arc.addArc(center:CGPoint(x:50,y:49),radius:33,startAngle:.degrees(210),endAngle:.degrees(330),clockwise:false)
            c.stroke(arc,with:.color(wood),lineWidth:4)
            for i in 0..<3 {
                let x=CGFloat(i)*27+23,y=CGFloat(i%2)*16+65
                line(CGPoint(x:x,y:25),CGPoint(x:x,y:y-10),wood,1.5);star(x,y,11,i == 1 ? color : .yellow)
            }
        case 12:
            box(CGRect(x:12,y:47,width:76,height:49),color,10)
            box(CGRect(x:8,y:isOn ? 34 : 42,width:84,height:13),wood,5)
            if isOn {oval(CGRect(x:20,y:31,width:21,height:21),.pink);star(63,39,13,.yellow)}
            star(50,74,13,.white.opacity(0.8))
        case 13:
            oval(CGRect(x:16,y:29,width:68,height:68),color)
            var band=Path();band.move(to:CGPoint(x:24,y:45));band.addQuadCurve(to:CGPoint(x:77,y:85),control:CGPoint(x:73,y:38))
            c.stroke(band,with:.color(.white.opacity(0.7)),lineWidth:7)
            oval(CGRect(x:31,y:38,width:12,height:9),.white.opacity(0.7))
        case 14:
            oval(CGRect(x:8,y:66,width:84,height:30),Color(red:1,green:0.94,blue:0.8))
            oval(CGRect(x:22,y:53,width:27,height:28),color)
            oval(CGRect(x:49,y:55,width:30,height:24),.orange)
            var leaf=Path();leaf.move(to:CGPoint(x:32,y:55));leaf.addQuadCurve(to:CGPoint(x:48,y:40),control:CGPoint(x:29,y:39));leaf.addQuadCurve(to:CGPoint(x:32,y:55),control:CGPoint(x:51,y:54))
            ToyFinish.paint(c,path:leaf,color:.green,edge:1)
        case 15:
            box(CGRect(x:14,y:36,width:72,height:58),color,14)
            box(CGRect(x:31,y:24,width:38,height:16),wood,8)
            for i in 0..<3 {line(CGPoint(x:25,y:51+CGFloat(i)*9),CGPoint(x:48,y:51+CGFloat(i)*9),GameStyle.ink.opacity(0.4),3)}
            oval(CGRect(x:60,y:53,width:16,height:16),.yellow)
            oval(CGRect(x:61,y:77,width:8,height:8),.white)
        case 16:
            for x in [CGFloat(28),CGFloat(70)] {box(CGRect(x:x-4,y:67,width:8,height:33),wood,3)}
            oval(CGRect(x:14,y:49,width:72,height:27),color)
        default:
            for i in 0..<5 {
                var arc=Path();arc.addArc(center:CGPoint(x:50,y:72),radius:38-CGFloat(i)*6,startAngle:.degrees(185),endAngle:.degrees(355),clockwise:false)
                c.stroke(arc,with:.color(i == 0 ? color : GameStyle.palette[(i*3)%16]),style:StrokeStyle(lineWidth:6,lineCap:.round))
            }
            oval(CGRect(x:4,y:63,width:25,height:18),.white);oval(CGRect(x:71,y:63,width:25,height:18),.white)
        }
    }
    private func bed() {
        box(CGRect(x:7,y:36,width:9,height:60),wood,5)
        box(CGRect(x:84,y:55,width:9,height:41),wood,5)
        box(CGRect(x:11,y:55,width:78,height:30),color,10)
        box(CGRect(x:13,y:48,width:73,height:18),Color(red:1,green:0.94,blue:0.83),8)
        box(CGRect(x:19,y:45,width:26,height:16),.white,7)
        box(CGRect(x:43,y:49,width:40,height:29),color,7)
        for i in 0..<3 {star(52+CGFloat(i)*11,61+CGFloat(i%2)*8,3.5,.white.opacity(0.55))}
    }
    private func plant() {
        box(CGRect(x:31,y:68,width:38,height:31),color,10)
        line(CGPoint(x:50,y:72),CGPoint(x:50,y:28),Color(red:0.23,green:0.43,blue:0.19),4)
        for i in 0..<5 {
            let left=i%2 == 0,x:CGFloat=left ? 20 : 47,y=27+CGFloat(i)*8
            var leaf=Path();leaf.move(to:CGPoint(x:50,y:y+18))
            leaf.addQuadCurve(to:CGPoint(x:left ? 15 : 84,y:y-6),control:CGPoint(x:x,y:y-18))
            leaf.addQuadCurve(to:CGPoint(x:50,y:y+18),control:CGPoint(x:left ? 12 : 88,y:y+18));leaf.closeSubpath()
            ToyFinish.paint(c,path:leaf,color:GameStyle.palette[i%2 == 0 ? 5 : 4],edge:0.8)
        }
    }
    private func lamp() {
        if isOn {
            c.fill(Path(ellipseIn:CGRect(x:1,y:4,width:98,height:98)),with:.radialGradient(Gradient(colors:[
                Color.yellow.opacity(0.4),.clear]),center:CGPoint(x:50,y:48),startRadius:0,endRadius:49))
        }
        box(CGRect(x:46,y:42,width:8,height:51),wood,4)
        var shade=Path();shade.move(to:CGPoint(x:32,y:15));shade.addQuadCurve(to:CGPoint(x:68,y:15),control:CGPoint(x:50,y:7))
        shade.addLine(to:CGPoint(x:82,y:54));shade.addQuadCurve(to:CGPoint(x:18,y:54),control:CGPoint(x:50,y:66));shade.closeSubpath()
        ToyFinish.paint(c,path:shade,color:isOn ? GameStyle.mixed(color,with:.yellow,amount:0.3) : color)
        oval(CGRect(x:28,y:90,width:44,height:10),color)
    }
    private func shelf() {
        box(CGRect(x:13,y:13,width:74,height:85),wood,5)
        for row in 0..<3 {
            let y=CGFloat(row)*25+20
            box(CGRect(x:19,y:y,width:62,height:19),Color(red:0.36,green:0.22,blue:0.24),2)
            for col in 0..<4 {box(CGRect(x:23+CGFloat(col)*13,y:y+2,width:9,height:16),col%2 == 0 ? color : GameStyle.palette[(row+col+2)%16],1.5)}
            line(CGPoint(x:19,y:y+20),CGPoint(x:81,y:y+20),Color(red:1,green:0.79,blue:0.49),2)
        }
    }
    private func window() {
        box(CGRect(x:12,y:8,width:76,height:90),wood,30)
        let pane=Path(roundedRect:CGRect(x:19,y:15,width:62,height:75),cornerRadius:25)
        c.fill(pane,with:.linearGradient(Gradient(colors:night ? [Color.indigo,Color(red:0.4,green:0.27,blue:0.59)] : [Color.cyan,Color(red:0.85,green:0.96,blue:0.78)]),
            startPoint:CGPoint(x:0,y:15),endPoint:CGPoint(x:0,y:90)))
        var clipped=c;clipped.clip(to:pane)
        clipped.fill(Path(ellipseIn:CGRect(x:58,y:26,width:16,height:16)),with:.color(night ? .white : .yellow))
        clipped.fill(Path(ellipseIn:CGRect(x:7,y:68,width:96,height:38)),with:.color(Color(red:0.25,green:0.59,blue:0.39)))
        box(CGRect(x:47,y:14,width:6,height:77),Color(red:1,green:0.91,blue:0.73),2)
        box(CGRect(x:19,y:53,width:62,height:5),Color(red:1,green:0.91,blue:0.73),2)
        box(CGRect(x:8,y:92,width:84,height:10),wood,4)
    }
    private func sofa() {
        box(CGRect(x:14,y:31,width:72,height:47),color,18)
        box(CGRect(x:14,y:61,width:72,height:28),color,10)
        box(CGRect(x:5,y:48,width:19,height:40),color,10);box(CGRect(x:76,y:48,width:19,height:40),color,10)
        for x in [CGFloat(21),CGFloat(69)] {box(CGRect(x:x,y:85,width:10,height:12),wood,3)}
        box(CGRect(x:24,y:48,width:23,height:22),GameStyle.mixed(color,with:.white,amount:0.4),7)
        box(CGRect(x:52,y:47,width:21,height:23),GameStyle.palette[3],7)
    }
    private func star(_ x:CGFloat,_ y:CGFloat,_ radius:CGFloat,_ color:Color) {
        var p=Path()
        for i in 0..<10 {
            let a=Double(i)*Double.pi/5-Double.pi/2,r=i%2 == 0 ? radius : radius*0.47
            let q=CGPoint(x:x+CGFloat(cos(a))*r,y:y+CGFloat(sin(a))*r)
            if i == 0 {p.move(to:q)} else {p.addLine(to:q)}
        }
        p.closeSubpath();ToyFinish.paint(c,path:p,color:color,edge:0.8)
    }
}


/// One scale and placement rule shared by room furniture and its interaction bounds.
enum RoomPlacement {
    static func baseSize(in size:CGSize)->CGFloat {
        min(155,min(max(58,size.width*0.18),size.height*0.34))
    }
    static func constrain(_ object:RoomObject,in size:CGSize)->RoomObject {
        guard size.width>0,size.height>0 else {return object}
        var copy=object
        let kind=RoomItem(rawValue:object.kind)
        let width=baseSize(in:size)*CGFloat(kind?.widthFactor ?? 1)*CGFloat(object.sizeFactor)
        let halfX=min(0.4,Double(width/size.width/2)+0.02)
        let halfY=min(0.25,Double(width*1.1/size.height/2))
        let lowY=kind?.isWall == true ? max(0.2,halfY+0.02) : min(0.82,0.58+halfY*0.4)
        let highY=kind?.isWall == true ? max(lowY,0.57-halfY*0.6) : max(lowY,min(0.9,0.98-halfY))
        copy.move(x:min(1-halfX,max(halfX,object.x)),y:min(highY,max(lowY,object.y)))
        return copy
    }
}
