import SwiftUI

struct PumpkinBackdrop:View {
    var darkness=0.0
    var garden=false
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                Canvas {context,size in
                    sky(context,size:size)
                    landscape(context,size:size)
                    garland(context,size:size)
                    timber(context,size:size)
                    foliage(context,size:size)
                }
                TimelineView(.animation(minimumInterval:1.0/12,paused:darkness<0.1 || reduced || phase != .active)) {frame in
                    Canvas {context,size in
                        fireflies(context,size:size,time:reduced ? 0 : frame.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
    private func mix(_ day:Color,_ night:Color)->Color {GameStyle.mixed(day,with:night,amount:darkness)}
    private func sky(_ c:GraphicsContext,size:CGSize) {
        let bounds=Path(CGRect(origin:.zero,size:size))
        c.fill(bounds,with:.linearGradient(Gradient(colors:[
            mix(Color(red:0.12,green:0.66,blue:0.82),Color(red:0.055,green:0.045,blue:0.19)),
            mix(Color(red:0.66,green:0.86,blue:0.85),Color(red:0.24,green:0.12,blue:0.38)),
            mix(Color(red:1,green:0.7,blue:0.35),Color(red:0.48,green:0.23,blue:0.38))]),
            startPoint:.zero,endPoint:CGPoint(x:0,y:size.height*0.85)))
        let moon=CGPoint(x:size.width*0.81,y:size.height*0.15)
        c.fill(bounds,with:.radialGradient(Gradient(colors:[PumpkinLook.cream.opacity(0.17*darkness),.clear]),
            center:moon,startRadius:18,endRadius:180))
        for i in 0..<34 {
            let x=CGFloat((i*71+19)%283)/283*size.width
            let y=CGFloat((i*37+11)%193)/290*size.height
            let radius:CGFloat=i%5 == 0 ? 2.2 : 1
            c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:radius*2,height:radius*2)),with:.color(PumpkinLook.cream.opacity(darkness*0.8)))
            if i%5 == 0 {
                var cross=Path()
                cross.move(to:CGPoint(x:x+radius,y:y-3));cross.addLine(to:CGPoint(x:x+radius,y:y+7))
                cross.move(to:CGPoint(x:x-3,y:y+radius));cross.addLine(to:CGPoint(x:x+7,y:y+radius))
                c.stroke(cross,with:.color(PumpkinLook.cream.opacity(darkness*0.5)),lineWidth:1)
            }
        }
        let disc=CGRect(x:moon.x-25,y:moon.y-25,width:50,height:50)
        c.fill(Path(ellipseIn:disc),with:.linearGradient(Gradient(colors:[
            Color.white.opacity(darkness),PumpkinLook.cream.opacity(darkness)]),startPoint:disc.origin,endPoint:CGPoint(x:disc.maxX,y:disc.maxY)))
        for i in 0..<4 {
            let crater=CGRect(x:moon.x-14+CGFloat(i%2)*19,y:moon.y-14+CGFloat(i/2)*17,width:7,height:5)
            c.fill(Path(ellipseIn:crater),with:.color(Color.orange.opacity(0.09*darkness)))
        }
    }
    private func landscape(_ c:GraphicsContext,size:CGSize) {
        let horizon=size.height*(garden ? 0.36 : 0.70)
        for layer in 0..<3 {
            let level=horizon-CGFloat(2-layer)*size.height*0.055
            var hill=Path()
            hill.move(to:CGPoint(x:-20,y:level+40))
            hill.addCurve(to:CGPoint(x:size.width+20,y:level+10),
                control1:CGPoint(x:size.width*0.25,y:level-100+CGFloat(layer*20)),
                control2:CGPoint(x:size.width*0.65,y:level+110-CGFloat(layer*24)))
            hill.addLine(to:CGPoint(x:size.width+20,y:size.height))
            hill.addLine(to:CGPoint(x:-20,y:size.height));hill.closeSubpath()
            let day=[Color(red:0.42,green:0.66,blue:0.48),Color(red:0.25,green:0.54,blue:0.4),Color(red:0.13,green:0.39,blue:0.31)][layer]
            let night=[Color(red:0.22,green:0.18,blue:0.35),Color(red:0.15,green:0.15,blue:0.29),Color(red:0.09,green:0.12,blue:0.23)][layer]
            c.fill(hill,with:.color(mix(day,night)))
        }
        // Small, friendly cottages sit behind the work area.
        for i in 0..<3 {
            let w=min(54,size.width*0.10),x=size.width*(0.13+CGFloat(i)*0.35),y=horizon-32-CGFloat(i%2)*16
            let house=CGRect(x:x,y:y,width:w,height:37)
            c.fill(Path(roundedRect:house,cornerRadius:5),with:.color(mix(Color(red:0.92,green:0.55,blue:0.31),Color(red:0.22,green:0.16,blue:0.28))))
            var roof=Path();roof.move(to:CGPoint(x:x-6,y:y+2));roof.addQuadCurve(to:CGPoint(x:x+w+6,y:y+2),control:CGPoint(x:x+w*0.5,y:y-37));roof.closeSubpath()
            c.fill(roof,with:.color(mix(Color(red:0.47,green:0.22,blue:0.36),Color(red:0.12,green:0.10,blue:0.22))))
            c.fill(Path(roundedRect:CGRect(x:x+w*0.35,y:y+11,width:w*0.3,height:17),cornerRadius:4),
                with:.color(Color(red:1,green:0.76,blue:0.29).opacity(0.55+0.45*darkness)))
        }
        if garden {
            let y=horizon+12
            for i in 0..<14 {
                let x=CGFloat(i)*size.width/13
                let post=CGRect(x:x-7,y:y-27,width:14,height:55)
                c.fill(Path(roundedRect:post,cornerRadius:6),with:.color(mix(Color(red:0.72,green:0.43,blue:0.26),Color(red:0.32,green:0.23,blue:0.32))))
            }
            for offset in [CGFloat(0),CGFloat(19)] {
                let rail=CGRect(x:0,y:y+offset,width:size.width,height:9)
                c.fill(Path(rail),with:.color(mix(Color(red:0.85,green:0.58,blue:0.33),Color(red:0.4,green:0.27,blue:0.34))))
            }
        }
    }
    private func garland(_ c:GraphicsContext,size:CGSize) {
        StorybookScenery.garland(c,size:size,darkness:darkness)
    }
    private func timber(_ c:GraphicsContext,size:CGSize) {
        let floorY=size.height*(garden ? 0.43 : 0.76)
        let floor=CGRect(x:0,y:floorY,width:size.width,height:size.height-floorY)
        c.fill(Path(floor),with:.linearGradient(Gradient(colors:[
            mix(Color(red:0.82,green:0.5,blue:0.26),Color(red:0.29,green:0.18,blue:0.28)),
            mix(Color(red:0.46,green:0.23,blue:0.16),Color(red:0.12,green:0.08,blue:0.18))]),
            startPoint:CGPoint(x:0,y:floorY),endPoint:CGPoint(x:0,y:size.height)))
        let spacing:CGFloat=garden ? 70 : 43
        for row in 0..<18 {
            let y=floorY+CGFloat(row)*spacing
            if y>size.height {continue}
            var seam=Path();seam.move(to:CGPoint(x:0,y:y));seam.addLine(to:CGPoint(x:size.width,y:y))
            c.stroke(seam,with:.color(PumpkinLook.ink.opacity(0.35)),lineWidth:3)
            c.stroke(seam.applying(CGAffineTransform(translationX:0,y:3)),with:.color(PumpkinLook.cream.opacity(0.09)),lineWidth:1)
            let join=size.width*(row%2 == 0 ? 0.32 : 0.72)
            c.stroke(Path(CGRect(x:join,y:y,width:1,height:spacing)),with:.color(PumpkinLook.ink.opacity(0.25)),lineWidth:1)
            for grain in 0..<4 {
                let gx=CGFloat((row*91+grain*73)%271)/271*size.width
                var line=Path();line.move(to:CGPoint(x:gx,y:y+12+CGFloat(grain)*5))
                line.addQuadCurve(to:CGPoint(x:gx+65,y:y+15+CGFloat(grain)*5),control:CGPoint(x:gx+30,y:y+6+CGFloat(grain)*5))
                c.stroke(line,with:.color(PumpkinLook.cream.opacity(0.065)),style:StrokeStyle(lineWidth:1,lineCap:.round))
            }
        }
        c.fill(Path(CGRect(x:0,y:floorY,width:size.width,height:7)),with:.color(PumpkinLook.cream.opacity(0.16)))
        if !garden {
            let front=CGRect(x:0,y:floorY+17,width:size.width,height:14)
            c.fill(Path(front),with:.color(PumpkinLook.ink.opacity(0.2)))
        }
    }
    private func foliage(_ c:GraphicsContext,size:CGSize) {
        for side in 0..<2 {
            var edge=c
            edge.translateBy(x:side == 0 ? 0 : size.width,y:size.height*(garden ? 0.45 : 0.75))
            edge.scaleBy(x:side == 0 ? 1 : -1,y:1)
            var vine=Path();vine.move(to:CGPoint(x:-12,y:160))
            vine.addCurve(to:CGPoint(x:35,y:-50),control1:CGPoint(x:65,y:110),control2:CGPoint(x:-20,y:15))
            edge.stroke(vine,with:.color(mix(Color(red:0.23,green:0.44,blue:0.22),Color(red:0.12,green:0.22,blue:0.23))),style:StrokeStyle(lineWidth:6,lineCap:.round))
            for i in 0..<5 {
                let x:CGFloat=i%2 == 0 ? 13 : 30,y=CGFloat(i)*39-30
                var leaf=Path();leaf.move(to:CGPoint(x:x,y:y))
                leaf.addQuadCurve(to:CGPoint(x:x+34,y:y-24),control:CGPoint(x:x-5,y:y-39))
                leaf.addQuadCurve(to:CGPoint(x:x,y:y),control:CGPoint(x:x+37,y:y+8))
                edge.fill(leaf,with:.linearGradient(Gradient(colors:[
                    mix(Color(red:0.58,green:0.7,blue:0.23),Color(red:0.26,green:0.37,blue:0.27)),
                    mix(Color(red:0.22,green:0.43,blue:0.22),Color(red:0.12,green:0.23,blue:0.25))]),startPoint:CGPoint(x:x,y:y-25),endPoint:CGPoint(x:x,y:y)))
            }
        }
    }
    private func fireflies(_ c:GraphicsContext,size:CGSize,time:Double) {
        guard darkness>0.1 else {return}
        for i in 0..<8 {
            let seed=Double(i)
            let x=(0.08+Double((i*31)%87)/100)*size.width+sin(time*0.4+seed)*9
            let y=size.height*(garden ? 0.27 : 0.62)+cos(time*0.33+seed*2)*26
            let alpha=(0.45+sin(time*1.1+seed)*0.25)*darkness
            let center=CGPoint(x:x,y:y)
            c.fill(Path(ellipseIn:CGRect(x:x-9,y:y-9,width:18,height:18)),with:.radialGradient(
                Gradient(colors:[PumpkinLook.cream.opacity(alpha),.clear]),center:center,startRadius:0,endRadius:9))
            c.fill(Path(ellipseIn:CGRect(x:x-1.5,y:y-1.5,width:3,height:3)),with:.color(PumpkinLook.cream.opacity(alpha)))
        }
    }
}

struct PumpkinDoor:View {
    @EnvironmentObject private var store:FriendStore
    var body:some View {
        NavigationLink(destination:PumpkinGameView()) {
            HStack(spacing:12) {
                PumpkinIllustration(lantern:Self.sample,animated:false).frame(width:78,height:84)
                VStack(alignment:.leading,spacing:4) {
                    Text(store.t("pumpkinTitle")).font(.system(size:22,weight:.heavy,design:.rounded))
                    Text(store.t("pumpkinDoorHint")).font(.system(size:12,weight:.semibold,design:.rounded))
                }
                Spacer(minLength:0)
                Image(systemName:"chevron.right").font(.headline)
            }.foregroundColor(PumpkinLook.cream).padding(.horizontal,14).padding(.vertical,5)
                .background(RoundedRectangle(cornerRadius:30).fill(LinearGradient(colors:[
                    Color(red:0.40,green:0.17,blue:0.55),Color(red:0.16,green:0.10,blue:0.29)],
                    startPoint:.topLeading,endPoint:.bottomTrailing)))
                .overlay(RoundedRectangle(cornerRadius:30).stroke(LinearGradient(colors:[
                    Color(red:1,green:0.75,blue:0.34),Color.orange.opacity(0.35)],
                    startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2))
                .shadow(color:Color(red:0.32,green:0.12,blue:0.43).opacity(0.3),radius:10,x:0,y:6)
        }.buttonStyle(SquishStyle())
    }
    static var sample:PumpkinLantern {
        var p=PumpkinLantern();p.addFace();p.darkness=1;p.light = .candle;return p
    }
}
