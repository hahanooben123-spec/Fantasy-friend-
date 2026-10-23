import SwiftUI

struct WorldBackdrop: View {
    var world: World = .forest
    var immersive = true
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var drift = false

    var body: some View {
        Group {
            if immersive { artwork.ignoresSafeArea() }
            else { artwork }
        }
        .accessibilityHidden(true)
        .onAppear { if immersive { SoundService.shared.setWorld(world) } }
        .onChange(of: world) { value in if immersive { SoundService.shared.setWorld(value) } }
        .task(id: "\(scenePhase)-\(reducedMotion)-\(animated)") {
            drift = false
            guard animated && !reducedMotion && scenePhase == .active else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private var artwork: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                Canvas { context, size in
                    StorybookWorldPainter(context:context,size:size,world:world).draw()
                }
                cloudRibbon.frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: drift ? 8 : -8, y: drift ? -3 : 3)
            }
        }
    }

    private var cloudRibbon: some View {
        Canvas {context,size in
            guard world != .stars else {return}
            for index in 0..<3 {
                let x=CGFloat(index)*size.width*0.43-25
                let y=size.height*(index == 1 ? 0.07 : 0.16)
                var cloud=Path()
                for rect in [CGRect(x:x,y:y,width:99,height:25),
                             CGRect(x:x+18,y:y-19,width:48,height:40),
                             CGRect(x:x+51,y:y-8,width:33,height:29)] {cloud.addEllipse(in:rect)}
                context.fill(cloud,with:.linearGradient(Gradient(colors:[
                    .white,Color(red:0.93,green:0.97,blue:1),Color(red:0.70,green:0.83,blue:0.91)]),
                    startPoint:CGPoint(x:x,y:y-19),endPoint:CGPoint(x:x,y:y+29)))
            }
        }
    }

    private var colors: [Color] {
        switch world {
        case .forest: return [Color(red: 0.12, green: 0.64, blue: 0.76), Color(red: 0.91, green: 0.94, blue: 0.63)]
        case .rainbow: return [Color(red: 0.53, green: 0.38, blue: 0.82), Color(red: 1, green: 0.72, blue: 0.64)]
        case .stars: return [Color(red: 0.07, green: 0.08, blue: 0.24), Color(red: 0.34, green: 0.23, blue: 0.57)]
        case .clouds: return [Color(red: 0.18, green: 0.69, blue: 1), Color(red: 0.77, green: 0.90, blue: 1)]
        case .meadow: return [Color(red: 0.59, green: 0.87, blue: 1), Color(red: 0.66, green: 0.88, blue: 0.28)]
        case .castle: return [Color(red: 0.12, green: 0.55, blue: 0.69), Color(red: 1, green: 0.77, blue: 0.56)]
        }
    }
}

private struct StorybookWorldPainter {
    let context:GraphicsContext
    let size:CGSize
    let world:World
    private var night:Bool {world == .stars}
    private var w:CGFloat {size.width}
    private var h:CGFloat {size.height}
    func draw() {
        atmosphere()
        hills()
        if world == .forest || world == .meadow {woods()}
        if world == .castle {village()}
        if world == .rainbow || world == .clouds {rainbow()}
        foreground()
    }
    private func atmosphere() {
        let center=CGPoint(x:w*0.73,y:h*0.16)
        let radius=min(w*0.24,145)
        context.fill(Path(CGRect(origin:.zero,size:size)),with:.radialGradient(
            Gradient(colors:[Color(red:1,green:0.9,blue:0.62).opacity(night ? 0.14 : 0.36),.clear]),
            center:center,startRadius:0,endRadius:radius*2.8))
        let disc=Path(ellipseIn:CGRect(x:center.x-radius*0.3,y:center.y-radius*0.3,width:radius*0.6,height:radius*0.6))
        context.fill(disc,with:.linearGradient(Gradient(colors:[.white,Color(red:1,green:0.85,blue:0.43)]),
            startPoint:CGPoint(x:center.x,y:center.y-radius),endPoint:CGPoint(x:center.x,y:center.y+radius)))
        if night {
            for i in 0..<35 {
                let x=CGFloat((i*67+23)%293)/300*w
                let y=CGFloat((i*97+31)%499)/650*h
                let r:CGFloat=i%6 == 0 ? 2.6 : 1.2
                context.fill(Path(ellipseIn:CGRect(x:x,y:y,width:r*2,height:r*2)),with:.color(.white.opacity(0.7)))
                if i%6 == 0 {
                    var sparkle=Path();sparkle.move(to:CGPoint(x:x+r,y:y-4));sparkle.addLine(to:CGPoint(x:x+r,y:y+8))
                    sparkle.move(to:CGPoint(x:x-4,y:y+r));sparkle.addLine(to:CGPoint(x:x+8,y:y+r))
                    context.stroke(sparkle,with:.color(.white.opacity(0.4)),lineWidth:1)
                }
            }
        }
    }
    private func hills() {
        for layer in 0..<3 {
            let y=h*(0.65+CGFloat(layer)*0.09)
            var hill=Path();hill.move(to:CGPoint(x:-20,y:y+30))
            hill.addCurve(to:CGPoint(x:w+20,y:y+10),
                control1:CGPoint(x:w*0.18,y:y-h*0.14),
                control2:CGPoint(x:w*0.67,y:y+h*0.12))
            hill.addLine(to:CGPoint(x:w+20,y:h+20));hill.addLine(to:CGPoint(x:-20,y:h+20));hill.closeSubpath()
            let colors:[Color]
            if night {colors=[Color(red:0.27,green:0.23,blue:0.51),Color(red:0.2,green:0.2,blue:0.4),Color(red:0.13,green:0.18,blue:0.32)]}
            else if world == .clouds {colors=[Color(red:0.73,green:0.76,blue:1),Color(red:0.83,green:0.88,blue:1),Color(red:0.94,green:0.96,blue:1)]}
            else {colors=[Color(red:0.33,green:0.65,blue:0.52),Color(red:0.28,green:0.65,blue:0.34),Color(red:0.45,green:0.73,blue:0.18)]}
            let color=colors[layer]
            context.fill(hill,with:.linearGradient(Gradient(colors:[GameStyle.mixed(color,with:.white,amount:0.18),color,
                GameStyle.mixed(color,with:GameStyle.ink,amount:0.23)]),startPoint:CGPoint(x:0,y:y),endPoint:CGPoint(x:0,y:h)))
            context.stroke(hill,with:.color(.white.opacity(0.12)),lineWidth:2)
        }
        guard world != .clouds && !night else {return}
        var road=Path();road.move(to:CGPoint(x:w*0.60,y:h*0.70))
        road.addCurve(to:CGPoint(x:w*0.29,y:h+10),control1:CGPoint(x:w*0.87,y:h*0.77),control2:CGPoint(x:w*0.38,y:h*0.84))
        road.addLine(to:CGPoint(x:w*0.81,y:h+10))
        road.addCurve(to:CGPoint(x:w*0.60,y:h*0.70),control1:CGPoint(x:w*0.49,y:h*0.84),control2:CGPoint(x:w*0.96,y:h*0.75))
        context.fill(road,with:.linearGradient(Gradient(colors:[Color(red:0.9,green:0.79,blue:0.54),Color(red:0.7,green:0.55,blue:0.39)]),
            startPoint:CGPoint(x:0,y:h*0.7),endPoint:CGPoint(x:0,y:h)))
        for i in 0..<9 {
            let y=h*(0.76+CGFloat(i)*0.035),x=w*(0.60+sin(Double(i)*0.8)*0.07)
            let scale=CGFloat(i+3)
            context.fill(Path(roundedRect:CGRect(x:x-scale*3,y:y,width:scale*6,height:scale*1.5),cornerRadius:scale),
                with:.color(Color(red:1,green:0.91,blue:0.7).opacity(0.4)))
        }
    }
    private func woods() {
        for side in 0..<2 {
            for i in 0..<3 {
                let x=side == 0 ? w*CGFloat(i)*0.09-20 : w-w*CGFloat(i)*0.08+10
                let y=h*(0.72+CGFloat(i)*0.055)
                tree(x:x,y:y,height:min(240,h*(0.22+CGFloat(i)*0.025)),variation:i+side)
            }
        }
    }
    private func tree(x:CGFloat,y:CGFloat,height:CGFloat,variation:Int) {
        let trunk=Path(roundedRect:CGRect(x:x-8,y:y-height*0.3,width:16,height:height*0.47),cornerRadius:7)
        ToyFinish.paint(context,path:trunk,color:Color(red:0.58,green:0.34,blue:0.23),edge:1)
        for i in 0..<3 {
            let branch=CGPoint(x:x+CGFloat(i-1)*height*0.12,y:y-height*(0.5+CGFloat(i%2)*0.2))
            let rect=CGRect(x:branch.x-height*0.23,y:branch.y-height*0.3,width:height*0.46,height:height*0.63)
            let color=variation%3 == 1 ? Color(red:0.53,green:0.37,blue:0.76) : Color(red:0.13+Double(i)*0.07,green:0.56+Double(i)*0.05,blue:0.38)
            ToyFinish.paint(context,path:Path(ellipseIn:rect),color:color,edge:1.2)
            var vein=Path();vein.move(to:CGPoint(x:branch.x,y:rect.maxY-9))
            vein.addQuadCurve(to:CGPoint(x:branch.x-8,y:rect.minY+15),control:CGPoint(x:branch.x+12,y:rect.midY))
            context.stroke(vein,with:.color(.white.opacity(0.12)),style:StrokeStyle(lineWidth:2,lineCap:.round))
        }
    }
    private func village() {
        for i in 0..<5 {
            let scale:CGFloat=i%2 == 0 ? 1 : 0.8
            let width=min(95,w*0.16)*scale
            let x=w*(CGFloat(i)*0.24-0.04),y=h*(0.73+CGFloat(i%2)*0.045)
            house(x:x,y:y,width:width,height:width*(i == 3 ? 2.0 : 1.45),variation:i)
        }
    }
    private func house(x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,variation:Int) {
        let color=[Color(red:1,green:0.73,blue:0.47),Color(red:0.61,green:0.79,blue:0.82),Color(red:0.91,green:0.58,blue:0.68)][variation%3]
        let wall=Path(roundedRect:CGRect(x:x,y:y-height,width:width,height:height),cornerRadius:width*0.09)
        ToyFinish.paint(context,path:wall,color:color,edge:1.8)
        for row in 0..<7 {
            let yy=y-height+CGFloat(row)*height/7
            var plank=Path();plank.move(to:CGPoint(x:x+3,y:yy));plank.addLine(to:CGPoint(x:x+width-3,y:yy))
            context.stroke(plank,with:.color(GameStyle.ink.opacity(0.08)),lineWidth:1)
        }
        var roof=Path();roof.move(to:CGPoint(x:x-8,y:y-height+7))
        roof.addQuadCurve(to:CGPoint(x:x+width*0.54,y:y-height-width*0.62),control:CGPoint(x:x+width*0.34,y:y-height-width*0.16))
        roof.addQuadCurve(to:CGPoint(x:x+width+8,y:y-height+7),control:CGPoint(x:x+width*0.72,y:y-height-width*0.19))
        roof.closeSubpath()
        ToyFinish.paint(context,path:roof,color:Color(red:0.4,green:0.22,blue:0.62),edge:2)
        var tiles=context;tiles.clip(to:roof)
        for row in 0..<4 {
            let yy=y-height-width*0.46+CGFloat(row)*width*0.15
            for col in 0..<5 {
                let xx=x+CGFloat(col)*width/4-CGFloat(row%2)*width/8
                var tile=Path();tile.move(to:CGPoint(x:xx,y:yy))
                tile.addQuadCurve(to:CGPoint(x:xx+width/4,y:yy),control:CGPoint(x:xx+width/8,y:yy+width*0.12))
                tiles.stroke(tile,with:.color(Color.white.opacity(0.13)),lineWidth:1.5)
            }
        }
        let window=CGRect(x:x+width*0.32,y:y-height*0.75,width:width*0.36,height:height*0.30)
        context.fill(Path(roundedRect:window,cornerRadius:width*0.18),with:.linearGradient(Gradient(colors:[
            Color(red:1,green:0.99,blue:0.66),Color(red:1,green:0.62,blue:0.16)]),startPoint:window.origin,endPoint:CGPoint(x:window.midX,y:window.maxY)))
        context.stroke(Path(roundedRect:window,cornerRadius:width*0.18),with:.color(GameStyle.mixed(color,with:GameStyle.ink,amount:0.55)),lineWidth:3)
        var muntin=Path();muntin.move(to:CGPoint(x:window.midX,y:window.minY));muntin.addLine(to:CGPoint(x:window.midX,y:window.maxY))
        muntin.move(to:CGPoint(x:window.minX,y:window.midY));muntin.addLine(to:CGPoint(x:window.maxX,y:window.midY))
        context.stroke(muntin,with:.color(color),lineWidth:2.5)
        let door=Path(roundedRect:CGRect(x:x+width*0.38,y:y-height*0.27,width:width*0.28,height:height*0.28),cornerRadius:width*0.12)
        ToyFinish.paint(context,path:door,color:Color(red:0.44,green:0.23,blue:0.4),edge:1)
    }
    private func rainbow() {
        let center=CGPoint(x:w*0.56,y:h*0.57),radius=min(w*0.67,h*0.44)
        for i in 0..<6 {
            var arc=Path();arc.addArc(center:center,radius:max(8,radius-CGFloat(i)*11),startAngle:.degrees(188),endAngle:.degrees(352),clockwise:false)
            context.stroke(arc,with:.color(StudioStyle.colors[i].opacity(world == .clouds ? 0.45 : 0.78)),
                style:StrokeStyle(lineWidth:11,lineCap:.round))
        }
    }
    private func foreground() {
        guard world != .clouds && !night else {return}
        for i in 0..<14 {
            let x=CGFloat(i)*w/13,y=h*0.96+CGFloat(i%3)*7
            var stem=Path();stem.move(to:CGPoint(x:x,y:y+20));stem.addQuadCurve(to:CGPoint(x:x+4,y:y-8),control:CGPoint(x:x-4,y:y))
            context.stroke(stem,with:.color(Color(red:0.18,green:0.43,blue:0.23)),style:StrokeStyle(lineWidth:3,lineCap:.round))
            for j in 0..<5 {
                let a=Double(j)*Double.pi*2/5
                let rect=CGRect(x:x+CGFloat(cos(a))*6-4,y:y+CGFloat(sin(a))*6-4,width:9,height:11)
                context.fill(Path(ellipseIn:rect),with:.color(GameStyle.palette[(i+1)%16]))
            }
            context.fill(Path(ellipseIn:CGRect(x:x-3,y:y-3,width:7,height:7)),with:.color(Color(red:1,green:0.9,blue:0.43)))
        }
    }
}
