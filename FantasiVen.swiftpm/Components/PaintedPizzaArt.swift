import SwiftUI

struct PaintedPizzaKitchen: View {
    var body: some View {
        GeometryReader { proxy in
            VillageArtwork.image("PizzaKitchenPainted").resizable().interpolation(.high).scaledToFill()
                .frame(width:proxy.size.width,height:proxy.size.height).clipped()
                .overlay(LinearGradient(colors:[.clear,StorybookStyle.plum.opacity(0.10)],
                    startPoint:.center,endPoint:.bottom))
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct PaintedPizzaOven: View {
    var heat=0.0
    var active=true
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        TimelineView(.animation(minimumInterval:1.0/24,paused:reduced || !active || phase != .active)) { frame in
            Canvas { c,s in
                c.scaleBy(x:s.width/300,y:s.height/320)
                c.draw(VillageArtwork.image("PizzaOvenPainted"),in:CGRect(x:0,y:10,width:300,height:300))
                var chamber=c
                chamber.clip(to:Path(roundedRect:CGRect(x:61,y:116,width:178,height:104),cornerRadius:40))
                let time=reduced ? 0 : frame.date.timeIntervalSinceReferenceDate
                let key=CGPoint(x:150,y:208)
                chamber.fill(Path(CGRect(x:55,y:105,width:190,height:120)),with:.radialGradient(
                    Gradient(colors:[Color.orange.opacity(0.38+heat*0.15),.clear]),
                    center:key,startRadius:5,endRadius:115))
                for i in 0..<6 {
                    let x=CGFloat(i)*25+84
                    let rise=CGFloat(20+sin(time*4+Double(i)*1.8)*8+heat*8)
                    var flame=Path();flame.move(to:CGPoint(x:x-8,y:218))
                    flame.addCurve(to:CGPoint(x:x+2,y:218-rise),
                        control1:CGPoint(x:x-14,y:204),control2:CGPoint(x:x+7,y:205-rise))
                    flame.addCurve(to:CGPoint(x:x+10,y:218),
                        control1:CGPoint(x:x+3,y:208),control2:CGPoint(x:x+16,y:209))
                    flame.closeSubpath()
                    chamber.fill(flame,with:.linearGradient(Gradient(colors:[.yellow,.orange,.red.opacity(0.25)]),
                        startPoint:CGPoint(x:x,y:218-rise),endPoint:CGPoint(x:x,y:220)))
                }
                // Reflected firelight softens the join between the illustration and live flame.
                var glow=c;glow.blendMode = .screen
                glow.fill(Path(ellipseIn:CGRect(x:65,y:205,width:170,height:28)),
                    with:.radialGradient(Gradient(colors:[StorybookStyle.honey.opacity(0.23),.clear]),
                        center:CGPoint(x:150,y:218),startRadius:0,endRadius:90))
            }
        }.aspectRatio(300.0/320,contentMode:.fit).allowsHitTesting(false).accessibilityHidden(true)
    }
}

enum PizzaMaterialPainter {
    static func base(_ c:GraphicsContext,path:Path,color:Color,baked:Double) {
        let bounds=path.boundingRect
        let light=GameStyle.mixed(color,with:Color(red:1,green:0.97,blue:0.82),amount:0.44)
        let shade=GameStyle.mixed(color,with:Color(red:0.62,green:0.30,blue:0.09),amount:0.23+baked*0.12)
        c.fill(path,with:.radialGradient(Gradient(stops:[
            .init(color:light,location:0),.init(color:color,location:0.65),.init(color:shade,location:1)]),
            center:CGPoint(x:bounds.minX+bounds.width*0.35,y:bounds.minY+bounds.height*0.26),
            startRadius:0,endRadius:max(bounds.width,bounds.height)*0.8))
        c.stroke(path,with:.color(Color(red:0.63,green:0.37,blue:0.17).opacity(0.55)),lineWidth:1.4)
    }
    static func dough(_ c:GraphicsContext,recipe:PizzaRecipe,baked:Double) {
        var paint=c
        paint.clip(to:PizzaGeometry.outline(recipe))
        let warm=Color(red:0.75,green:0.39,blue:0.13)
        for i in 0..<90 {
            let x=CGFloat((i*73+19)%281)+10,y=CGFloat((i*47+23)%283)+14
            let radius:CGFloat=i%4 == 0 ? 3.2 : 1.3
            let r=CGRect(x:x,y:y,width:radius*2,height:radius*1.4)
            paint.fill(Path(ellipseIn:r),with:.radialGradient(
                Gradient(colors:[warm.opacity(0.06+baked*0.10),.clear]),
                center:CGPoint(x:r.midX,y:r.midY),startRadius:0,endRadius:radius))
            if i%3 == 0 {
                paint.fill(Path(ellipseIn:r.offsetBy(dx:-1,dy:-1)),
                    with:.color(StorybookStyle.cream.opacity(0.16)))
            }
        }
    }
    static func sauce(_ c:GraphicsContext,path:Path) {
        c.stroke(path,with:.color(Color(red:0.44,green:0.07,blue:0.025).opacity(0.30)),
            style:StrokeStyle(lineWidth:34,lineCap:.round,lineJoin:.round))
        c.stroke(path,with:.linearGradient(Gradient(colors:[
            Color(red:1,green:0.35,blue:0.13),Color(red:0.83,green:0.13,blue:0.045),
            Color(red:0.59,green:0.07,blue:0.025)]),
            startPoint:CGPoint(x:65,y:60),endPoint:CGPoint(x:220,y:265)),
            style:StrokeStyle(lineWidth:32,lineCap:.round,lineJoin:.round))
        c.stroke(path.applying(CGAffineTransform(translationX:-3,y:-4)),
            with:.color(Color(red:1,green:0.75,blue:0.42).opacity(0.18)),
            style:StrokeStyle(lineWidth:2,lineCap:.round,lineJoin:.round))
    }
}

/// Continuous steam stays above the actual pizza; finger bites still use the recipe geometry.
struct PizzaServingSteam: View {
    var active=true
    var visible=true
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        TimelineView(.animation(minimumInterval:1.0/18,paused:reduced || !active || !visible || phase != .active)) { frame in
            Canvas { c,s in
                guard visible else {return}
                let t=reduced ? 0.3 : frame.date.timeIntervalSinceReferenceDate
                for i in 0..<4 {
                    let progress=(t*0.3+Double(i)*0.23).truncatingRemainder(dividingBy:1)
                    let x=s.width*(0.32+CGFloat(i)*0.12)
                    let y=s.height*(0.34-CGFloat(progress)*0.18)
                    var curl=Path();curl.move(to:CGPoint(x:x,y:y))
                    curl.addCurve(to:CGPoint(x:x+CGFloat(sin(t+Double(i))*9),y:y-35),
                        control1:CGPoint(x:x-12,y:y-9),control2:CGPoint(x:x+16,y:y-23))
                    c.stroke(curl,with:.color(.white.opacity((1-progress)*0.52)),
                        style:StrokeStyle(lineWidth:2.5,lineCap:.round))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
