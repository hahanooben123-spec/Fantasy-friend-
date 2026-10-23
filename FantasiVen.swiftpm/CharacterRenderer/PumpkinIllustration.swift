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
        lightSpill(context,rect:r,glow:glow,power:power)
        var hollow=context;hollow.clip(to:shape)
        for cut in lantern.cuts {
            let path=PumpkinGeometry.cut(cut,form:lantern.form)
            interior(hollow,path:path,glow:glow,power:power)
        }
        context.drawLayer {layer in
            surface(layer,rect:r,shape:shape,skin:skin)
            var punch=layer;punch.clip(to:shape);punch.blendMode = .destinationOut
            for cut in lantern.cuts {punch.fill(PumpkinGeometry.cut(cut,form:lantern.form),with:.color(.white))}
        }
        var edges=context;edges.clip(to:shape)
        for cut in lantern.cuts {
            let path=PumpkinGeometry.cut(cut,form:lantern.form)
            edges.stroke(path,with:.linearGradient(Gradient(colors:[Color(red:0.42,green:0.17,blue:0.045),Color(red:1,green:0.62,blue:0.16)]),
                startPoint:CGPoint(x:0,y:r.minY),endPoint:CGPoint(x:0,y:r.maxY)),style:StrokeStyle(lineWidth:6,lineJoin:.round))
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
        lid.fill(leaf,with:.linearGradient(Gradient(colors:[Color(red:0.67,green:0.81,blue:0.22),Color(red:0.19,green:0.43,blue:0.17)]),
            startPoint:CGPoint(x:r.midX,y:r.minY-30),endPoint:CGPoint(x:r.midX+38,y:r.minY)))
        var vein=Path();vein.move(to:CGPoint(x:r.midX+8,y:r.minY-5));vein.addQuadCurve(to:CGPoint(x:r.midX+42,y:r.minY-16),control:CGPoint(x:r.midX+27,y:r.minY-20))
        lid.stroke(vein,with:.color(PumpkinLook.cream.opacity(0.35)),lineWidth:1.5)
        var curl=Path();curl.move(to:CGPoint(x:r.midX-4,y:r.minY-7))
        curl.addCurve(to:CGPoint(x:r.midX-41,y:r.minY-12),control1:CGPoint(x:r.midX-38,y:r.minY-40),control2:CGPoint(x:r.midX-61,y:r.minY+1))
        curl.addCurve(to:CGPoint(x:r.midX-31,y:r.minY-16),control1:CGPoint(x:r.midX-20,y:r.minY-27),control2:CGPoint(x:r.midX-26,y:r.minY-4))
        lid.stroke(curl,with:.color(Color(red:0.42,green:0.62,blue:0.19)),style:StrokeStyle(lineWidth:2.5,lineCap:.round))
    }

    private func surface(_ context:GraphicsContext,rect r:CGRect,shape:Path,skin:Color) {
        context.fill(shape,with:.color(GameStyle.mixed(skin,with:PumpkinLook.ink,amount:0.32)))
        var c=context;c.clip(to:shape)
        // Back lobes first, then the central lobe, for a rounded toy-like volume.
        for index in [-2,2,-1,1,0] {
            let offset=CGFloat(index)*r.width*0.165
            let squash=CGFloat(abs(index))*r.height*0.022
            let lobe=CGRect(x:r.midX+offset-r.width*0.19,y:r.minY+squash,
                            width:r.width*0.38,height:r.height-squash*0.7)
            let colors=[
                GameStyle.mixed(skin,with:PumpkinLook.ink,amount:0.28),
                GameStyle.mixed(skin,with:Color(red:1,green:0.91,blue:0.62),amount:0.23),
                skin,GameStyle.mixed(skin,with:PumpkinLook.ink,amount:0.38)]
            c.fill(Path(ellipseIn:lobe),with:.linearGradient(Gradient(stops:[
                .init(color:colors[0],location:0),.init(color:colors[1],location:0.32),
                .init(color:colors[2],location:0.58),.init(color:colors[3],location:1)]),
                startPoint:CGPoint(x:lobe.minX,y:lobe.minY),endPoint:CGPoint(x:lobe.maxX,y:lobe.maxY*0.92)))
        }
        let key=CGPoint(x:r.minX+r.width*0.3,y:r.minY+r.height*0.23)
        c.fill(shape,with:.radialGradient(Gradient(colors:[Color.white.opacity(0.15),.clear,PumpkinLook.ink.opacity(0.24)]),
            center:key,startRadius:0,endRadius:r.width*0.84))
        for i in 0..<36 {
            let x=r.minX+CGFloat((i*61+13)%229)/229*r.width
            let y=r.minY+CGFloat((i*43+23)%193)/193*r.height
            let dot=CGRect(x:x,y:y,width:i%3 == 0 ? 1.7 : 0.9,height:1.3)
            c.fill(Path(ellipseIn:dot),with:.color(i%2 == 0 ? .white.opacity(0.11) : PumpkinLook.ink.opacity(0.07)))
        }
        var shine=Path()
        shine.move(to:CGPoint(x:r.minX+r.width*0.23,y:r.minY+r.height*0.22))
        shine.addQuadCurve(to:CGPoint(x:r.minX+r.width*0.17,y:r.minY+r.height*0.48),
            control:CGPoint(x:r.minX+r.width*0.13,y:r.minY+r.height*0.27))
        c.stroke(shine,with:.color(.white.opacity(0.24)),style:StrokeStyle(lineWidth:7,lineCap:.round))
        context.stroke(shape,with:.color(GameStyle.mixed(skin,with:PumpkinLook.ink,amount:0.66)),lineWidth:2.5)
    }
    private func interior(_ c:GraphicsContext,path:Path,glow:Color,power:Double) {
        let r=path.boundingRect
        let center=CGPoint(x:r.midX,y:r.minY+r.height*0.74)
        let dark=Color(red:0.12,green:0.045,blue:0.035)
        let hot=GameStyle.mixed(dark,with:PumpkinLook.cream,amount:power)
        let lit=GameStyle.mixed(dark,with:glow,amount:power*0.96)
        let edge=GameStyle.mixed(dark,with:glow,amount:power*0.45)
        c.fill(path,with:.radialGradient(Gradient(colors:[hot,lit,edge]),center:center,
            startRadius:0,endRadius:max(8,max(r.width,r.height)*0.72)))
        var inset=c;inset.clip(to:path)
        inset.stroke(path.applying(CGAffineTransform(translationX:0,y:3)),with:.color(.black.opacity(0.25)),lineWidth:5)
    }
    private func lightSpill(_ c:GraphicsContext,rect r:CGRect,glow:Color,power:Double) {
        guard power>0,lantern.darkness>0.05,!lantern.cuts.isEmpty else {return}
        let strength=power*lantern.darkness
        let floor=CGRect(x:r.minX-10,y:276,width:r.width+20,height:32)
        c.fill(Path(ellipseIn:floor),with:.radialGradient(Gradient(colors:[glow.opacity(strength*0.55),.clear]),
            center:CGPoint(x:150,y:292),startRadius:0,endRadius:r.width*0.58))
        for cut in lantern.cuts.prefix(10) {
            let bounds=PumpkinGeometry.cut(cut,form:lantern.form).boundingRect
            let center=CGPoint(x:bounds.midX,y:bounds.midY)
            let endX=150+(center.x-150)*1.45
            var ray=Path();ray.move(to:center)
            ray.addLine(to:CGPoint(x:endX-18,y:306))
            ray.addQuadCurve(to:CGPoint(x:endX+18,y:306),control:CGPoint(x:endX,y:313))
            ray.closeSubpath()
            c.fill(ray,with:.linearGradient(Gradient(colors:[glow.opacity(strength*0.035),glow.opacity(strength*0.08),.clear]),
                startPoint:center,endPoint:CGPoint(x:endX,y:310)))
        }
    }
}
