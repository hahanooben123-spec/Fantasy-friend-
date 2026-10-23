import SwiftUI

enum PumpkinLook {
    static let ink=Color(red:0.20,green:0.13,blue:0.22)
    static let cream=Color(red:1,green:0.94,blue:0.76)
    static let skin:[Color]=[
        Color(red:1,green:0.41,blue:0.07),Color(red:1,green:0.66,blue:0.29),
        Color(red:0.94,green:0.9,blue:0.70),Color(red:0.48,green:0.75,blue:0.23),
        Color(red:0.58,green:0.31,blue:0.83),Color(red:0.10,green:0.68,blue:0.63)]
    static func light(_ kind:PumpkinLight,time:Double)->Color {
        switch kind {
        case .candle:return Color(red:1,green:0.74,blue:0.23)
        case .pink:return Color(red:1,green:0.32,blue:0.66)
        case .green:return Color(red:0.5,green:1,blue:0.3)
        case .blue:return Color(red:0.3,green:0.75,blue:1)
        case .purple:return Color(red:0.79,green:0.43,blue:1)
        case .rainbow:return Color(hue:(time/12).truncatingRemainder(dividingBy:1),saturation:0.72,brightness:1)
        case .fireflies:return Color(red:0.85,green:1,blue:0.3)
        }
    }
}
struct PumpkinIllustration:View {
    let lantern:PumpkinLantern
    var animated=true
    var opened=false
    var lidLift:CGFloat=0
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    var body:some View {
        TimelineView(.animation(minimumInterval:1.0/20,paused:!animated || !lantern.lit || reduced || phase != .active)) {timeline in
            let time=reduced || !animated ? 2 : timeline.date.timeIntervalSinceReferenceDate
            Canvas {context,size in
                context.scaleBy(x:size.width/300,y:size.height/320)
                paint(context,time:time)
            }
        }.aspectRatio(300.0/320,contentMode:.fit).accessibilityHidden(true)
    }
    private func paint(_ context:GraphicsContext,time:Double) {
        let r=PumpkinGeometry.rect(lantern.form),shape=PumpkinGeometry.body(lantern.form)
        let skin=GameStyle.mixed(PumpkinLook.skin[lantern.color],with:.black,amount:lantern.darkness*0.42)
        let glow=PumpkinLook.light(lantern.light,time:time)
        let flicker=lantern.light == .candle ? 0.90+sin(time*2.2)*0.06+sin(time*4.1)*0.025 : 1
        let power=lantern.lit ? lantern.brightness*flicker : 0
        let night=lantern.darkness
        context.fill(Path(ellipseIn:CGRect(x:r.minX-6,y:284,width:r.width+12,height:23)),with:.color(.black.opacity(0.16)))
        if power>0 && night>0 {
            var floor=context;floor.addFilter(.blur(radius:12))
            floor.fill(Path(ellipseIn:CGRect(x:r.minX-14,y:277,width:r.width+28,height:35)),with:.color(glow.opacity(power*night*0.48)))
        }
        var hollow=context;hollow.clip(to:shape)
        for cut in lantern.cuts {
            let path=PumpkinGeometry.cut(cut,form:lantern.form)
            hollow.fill(path,with:.linearGradient(Gradient(colors:[Color(red:0.20,green:0.08,blue:0.05),GameStyle.mixed(Color(red:0.12,green:0.05,blue:0.04),with:glow,amount:power)]),
                startPoint:CGPoint(x:150,y:r.minY),endPoint:CGPoint(x:150,y:r.maxY)))
        }
        context.drawLayer {layer in
            layer.fill(shape,with:.linearGradient(Gradient(colors:[
                GameStyle.mixed(skin,with:.white,amount:0.27),skin,GameStyle.mixed(skin,with:PumpkinLook.ink,amount:0.38)]),
                startPoint:CGPoint(x:r.minX,y:r.minY),endPoint:CGPoint(x:r.maxX,y:r.maxY)))
            layer.stroke(shape,with:.color(GameStyle.mixed(skin,with:PumpkinLook.ink,amount:0.7)),lineWidth:3)
            var ribs=layer;ribs.clip(to:shape)
            for i in 0..<5 {
                let shift=CGFloat(i-2)*r.width*0.14
                var line=Path();line.move(to:CGPoint(x:r.midX+shift*0.45,y:r.minY))
                line.addCurve(to:CGPoint(x:r.midX+shift*0.65,y:r.maxY+5),
                    control1:CGPoint(x:r.midX+shift*1.6,y:r.minY+r.height*0.25),
                    control2:CGPoint(x:r.midX+shift*1.6,y:r.minY+r.height*0.8))
                ribs.stroke(line,with:.color(PumpkinLook.ink.opacity(lantern.form == .bumpy ? 0.22 : 0.13)),style:StrokeStyle(lineWidth:4,lineCap:.round))
            }
            ribs.fill(Path(ellipseIn:CGRect(x:r.minX+r.width*0.12,y:r.minY+r.height*0.19,width:r.width*0.10,height:r.height*0.3)),with:.color(.white.opacity(0.28)))
            ribs.fill(Path(ellipseIn:CGRect(x:r.minX+r.width*0.24,y:r.minY+r.height*0.13,width:8,height:12)),with:.color(.white.opacity(0.5)))
            var punch=layer;punch.clip(to:shape);punch.blendMode = .destinationOut
            for cut in lantern.cuts {punch.fill(PumpkinGeometry.cut(cut,form:lantern.form),with:.color(.white))}
        }
        var edges=context;edges.clip(to:shape)
        for cut in lantern.cuts {
            let path=PumpkinGeometry.cut(cut,form:lantern.form)
            edges.stroke(path,with:.color(Color(red:0.44,green:0.20,blue:0.06)),style:StrokeStyle(lineWidth:5,lineJoin:.round))
            edges.stroke(path,with:.color(Color(red:1,green:0.72,blue:0.3).opacity(0.8)),lineWidth:1.3)
            if power>0 {
                var bloom=edges;bloom.addFilter(.blur(radius:5))
                bloom.stroke(path,with:.color(glow.opacity(power*0.6)),lineWidth:4)
            }
        }
        if lantern.light == .fireflies && power>0 {
            for i in 0..<6 {
                let x=r.midX+CGFloat(sin(time*0.7+Double(i)*2))*r.width*0.3
                let y=r.midY+CGFloat(cos(time*0.9+Double(i)))*r.height*0.25
                var flies=edges
                var holes=Path()
                for cut in lantern.cuts {holes.addPath(PumpkinGeometry.cut(cut,form:lantern.form))}
                flies.clip(to:holes)
                flies.fill(Path(ellipseIn:CGRect(x:x,y:y,width:4,height:4)),with:.color(.white))
            }
        }
        if opened {
            let cavity=CGRect(x:r.minX+r.width*0.22,y:r.minY+r.height*0.04,width:r.width*0.56,height:r.height*0.16)
            context.fill(Path(ellipseIn:cavity),with:.color(Color(red:0.45,green:0.22,blue:0.07)))
            context.stroke(Path(ellipseIn:cavity),with:.color(Color(red:1,green:0.75,blue:0.31)),lineWidth:7)
            for i in 0..<12 where Double(i)/12 >= lantern.scooped {
                context.fill(Path(ellipseIn:CGRect(x:cavity.minX+CGFloat(i%6)*cavity.width/7,y:cavity.midY+CGFloat(i%2)*4-5,width:12,height:5)),with:.color(PumpkinLook.cream))
            }
        }
        var lid=context;lid.translateBy(x:0,y:opened ? -min(49,max(14,r.minY-35)) : -lidLift)
        let lidWidth=r.width*0.43
        var cap=Path()
        cap.move(to:CGPoint(x:r.midX-lidWidth/2,y:r.minY+r.height*0.12))
        cap.addQuadCurve(to:CGPoint(x:r.midX+lidWidth/2,y:r.minY+r.height*0.12),control:CGPoint(x:r.midX,y:r.minY-r.height*0.09))
        cap.addQuadCurve(to:CGPoint(x:r.midX-lidWidth/2,y:r.minY+r.height*0.12),control:CGPoint(x:r.midX,y:r.minY+r.height*0.16))
        lid.fill(cap,with:.color(skin));lid.stroke(cap,with:.color(PumpkinLook.ink.opacity(0.55)),lineWidth:2)
        var stem=Path();stem.move(to:CGPoint(x:r.midX,y:r.minY+7))
        stem.addCurve(to:CGPoint(x:r.midX+15,y:r.minY-29),control1:CGPoint(x:r.midX-13,y:r.minY-23),control2:CGPoint(x:r.midX+25,y:r.minY-37))
        lid.stroke(stem,with:.color(Color(red:0.28,green:0.38,blue:0.12)),style:StrokeStyle(lineWidth:15,lineCap:.round))
        lid.stroke(stem,with:.color(Color(red:0.64,green:0.72,blue:0.28)),style:StrokeStyle(lineWidth:4,lineCap:.round))
        var leaf=Path();leaf.move(to:CGPoint(x:r.midX+4,y:r.minY-4))
        leaf.addQuadCurve(to:CGPoint(x:r.midX+47,y:r.minY-15),control:CGPoint(x:r.midX+31,y:r.minY-44))
        leaf.addQuadCurve(to:CGPoint(x:r.midX+4,y:r.minY-4),control:CGPoint(x:r.midX+36,y:r.minY+4))
        lid.fill(leaf,with:.color(Color(red:0.39,green:0.65,blue:0.16)))
    }
}
