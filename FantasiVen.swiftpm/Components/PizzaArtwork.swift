import SwiftUI

struct PizzaKitchenBackdrop:View {
    var body:some View {PaintedPizzaKitchen()}
}
struct PizzaIllustration:View {
    let recipe:PizzaRecipe
    var baked=0.0
    var board=true
    var serving=false
    var eaten=0
    var landingID:UUID?
    var sliceIndex:Int?
    var fragment:PizzaBite?
    var elastic=0.0
    var body:some View {
        Canvas(rendersAsynchronously:true) {c,size in
            c.scaleBy(x:size.width/CGFloat(300),y:size.height/CGFloat(320))
            if serving {
                c.draw(VillageArtwork.image("PizzaPlatePainted"),in:CGRect(x:0,y:10,width:300,height:300))
            } else if board {
                let wood=Path(roundedRect:CGRect(x:8,y:15,width:284,height:289),cornerRadius:38)
                var shadow=c;shadow.addFilter(.blur(radius:7))
                shadow.fill(wood.applying(CGAffineTransform(translationX:0,y:6)),with:.color(GameStyle.ink.opacity(0.24)))
                ToyFinish.paint(c,path:wood,color:Color(red:0.84,green:0.61,blue:0.36),edge:2)
                c.stroke(Path(roundedRect:CGRect(x:13,y:20,width:274,height:279),cornerRadius:34),with:.color(Color(red:1,green:0.86,blue:0.58).opacity(0.65)),lineWidth:2)
                for knot in 0..<3 {
                    let x=CGFloat(knot)*93+36,y=CGFloat(knot%2)*245+36
                    c.stroke(Path(ellipseIn:CGRect(x:x,y:y,width:22,height:7)),with:.color(Color(red:0.49,green:0.26,blue:0.15).opacity(0.15)),lineWidth:1)
                }
                for i in 0..<8 {
                    let y=CGFloat(i)*33+31
                    var grain=Path();grain.move(to:CGPoint(x:22,y:y));grain.addQuadCurve(to:CGPoint(x:278,y:y+7),control:CGPoint(x:130,y:y-8))
                    c.stroke(grain,with:.color(.white.opacity(0.10)),lineWidth:1)
                }
                for i in 0..<22 {
                    let x=CGFloat((i*71)%270)+15,y=CGFloat((i*43)%280)+18
                    c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:2,height:2)),with:.color(.white.opacity(0.27)))
                }
            }
            var pizza=c
            if elastic != 0 && fragment == nil {
                pizza.translateBy(x:150,y:160)
                pizza.scaleBy(x:1+elastic*0.045,y:1-elastic*0.035)
                pizza.rotate(by:.degrees(elastic*0.7))
                pizza.translateBy(x:-150,y:-160)
            }
            if let fragment=fragment {
                pizza.translateBy(x:150-fragment.point.x*300,y:160-fragment.point.y*320)
                pizza.clip(to:PizzaGeometry.bite(fragment))
            }
            if let bites=recipe.bites,!bites.isEmpty {
                var holes=Path()
                for bite in bites {holes.addPath(PizzaGeometry.bite(bite))}
                pizza.clip(to:holes,options:.inverse)
            }
            let eaten=max(self.eaten,recipe.legacySlices ?? 0)
            if let index=sliceIndex {
                pizza.translateBy(x:-43,y:53)
                pizza.translateBy(x:150,y:154)
                pizza.rotate(by:.degrees(-Double(index)*45))
                pizza.translateBy(x:-150,y:-154)
                var wedge=Path();wedge.move(to:CGPoint(x:150,y:154))
                wedge.addArc(center:CGPoint(x:150,y:154),radius:135,
                    startAngle:.degrees(Double(index)*45-89),endAngle:.degrees(Double(index)*45-46),clockwise:false)
                wedge.closeSubpath();pizza.clip(to:wedge)
            }
            if eaten>0 {
                var remaining=Path()
                for i in min(8,eaten)..<8 {
                    let a=Double(i)*45-90
                    var wedge=Path();wedge.move(to:CGPoint(x:150,y:154))
                    wedge.addArc(center:CGPoint(x:150,y:154),radius:135,startAngle:.degrees(a+1),endAngle:.degrees(a+44),clockwise:false)
                    wedge.closeSubpath();remaining.addPath(wedge)
                }
                pizza.clip(to:remaining)
            }
            draw(pizza)
            if !serving && baked>=1 && eaten<8 && sliceIndex == nil && fragment == nil && (recipe.bites?.isEmpty ?? true) {
                for i in 0..<4 {
                    let x=CGFloat(i)*33+95
                    var steam=Path();steam.move(to:CGPoint(x:x,y:54))
                    steam.addCurve(to:CGPoint(x:x+4,y:20),control1:CGPoint(x:x-10,y:43),control2:CGPoint(x:x+15,y:34))
                    c.stroke(steam,with:.color(.white.opacity(0.4)),style:StrokeStyle(lineWidth:3,lineCap:.round))
                }
            }
        }.overlay {
            GeometryReader {frame in
                if let id=landingID,let item=recipe.toppings.first(where:{$0.id == id}) {
                    PizzaLandingSprite(kind:item.kind)
                        .frame(width:frame.size.width*29/CGFloat(300),height:frame.size.height*29/CGFloat(320))
                        .rotationEffect(.degrees(item.angle))
                        .position(x:item.point.x*frame.size.width,y:item.point.y*frame.size.height)
                }
            }.allowsHitTesting(false)
        }.aspectRatio(CGFloat(300)/CGFloat(320),contentMode:.fit).accessibilityHidden(true)
    }
    private func draw(_ c:GraphicsContext) {
        let dough=PizzaGeometry.outline(recipe)
        let crust=GameStyle.mixed(Color(red:1,green:0.88,blue:0.6),with:Color(red:0.8,green:0.39,blue:0.12),amount:baked*0.7)
        var cast=c;cast.addFilter(.blur(radius:4))
        cast.fill(dough.applying(CGAffineTransform(translationX:1,y:5)),with:.color(Color(red:0.33,green:0.15,blue:0.08).opacity(0.3)))
        PizzaMaterialPainter.base(c,path:dough,color:crust,baked:baked)
        PizzaMaterialPainter.dough(c,recipe:recipe,baked:baked)
        let inside=PizzaGeometry.outline(recipe,inset:0.89)
        c.stroke(inside,with:.color(Color(red:0.76,green:0.42,blue:0.15).opacity(0.23)),lineWidth:2)
        var topping=c;topping.clip(to:PizzaGeometry.outline(recipe,inset:0.97))
        for stroke in recipe.sauce {
            guard let first=stroke.points.first else {continue}
            var path=Path();path.move(to:CGPoint(x:first.x*300,y:first.y*320))
            for index in stroke.points.indices.dropFirst() {
                let previous=stroke.points[index-1],point=stroke.points[index]
                path.addQuadCurve(to:CGPoint(x:(previous.x+point.x)*150,y:(previous.y+point.y)*160),
                    control:CGPoint(x:previous.x*300,y:previous.y*320))
            }
            if let last=stroke.points.last {path.addLine(to:CGPoint(x:last.x*300,y:last.y*320))}
            if stroke.points.count == 1 {path.addLine(to:CGPoint(x:first.x*300+0.1,y:first.y*320))}
            PizzaMaterialPainter.sauce(topping,path:path)
        }
        // A small spatial neighbourhood keeps cheese connections linear as toppings grow.
        if baked>0 {
            var cells:[Int:[CGPoint]]=[:]
            let color=Color(red:1,green:0.88,blue:0.43).opacity(baked*0.9)
            for item in recipe.toppings where item.kind == .cheese {
                let point=CGPoint(x:item.point.x*300,y:item.point.y*320)
                let gx=Int(point.x/CGFloat(36)),gy=Int(point.y/CGFloat(36))
                for dx in -1...1 {
                    for dy in -1...1 {
                        for other in cells[(gx+dx)*1000+gy+dy] ?? [] {
                            if hypot(point.x-other.x,point.y-other.y)<36*baked {
                                var bridge=Path();bridge.move(to:point);bridge.addLine(to:other)
                                topping.stroke(bridge,with:.color(color),style:StrokeStyle(lineWidth:18*baked,lineCap:.round))
                                topping.stroke(bridge.applying(CGAffineTransform(translationX:-1,y:-2)),
                                    with:.color(Color(red:1,green:0.97,blue:0.76).opacity(baked*0.5)),
                                    style:StrokeStyle(lineWidth:3*baked,lineCap:.round))
                            }
                        }
                    }
                }
                let key=gx*1000+gy
                var neighbours=cells[key] ?? []
                if neighbours.count>=6 {neighbours.removeFirst()}
                neighbours.append(point);cells[key]=neighbours
            }
        }
        for item in recipe.toppings where item.id != landingID {
            var piece=topping
            piece.translateBy(x:item.point.x*300,y:item.point.y*320)
            piece.rotate(by:.degrees(item.angle))
            PizzaToppingPainter.paint(piece,kind:item.kind,baked:baked)
        }
        for item in recipe.spices {
            var sprinkle=topping
            sprinkle.translateBy(x:item.point.x*300,y:item.point.y*320)
            sprinkle.rotate(by:.degrees(item.angle))
            if item.kind == 3 {
                let cheese=Path(roundedRect:CGRect(x:-6,y:-1.5,width:12,height:3),cornerRadius:1.5)
                sprinkle.fill(cheese,with:.color(GameStyle.mixed(.yellow,with:Color(red:1,green:0.96,blue:0.72),amount:0.65-baked*0.2)))
            } else if item.kind == 2 {
                sprinkle.fill(Path(ellipseIn:CGRect(x:-1,y:-1,width:2,height:2)),with:.color(.white))
            } else {
                var leaf=Path();leaf.move(to:CGPoint(x:-4,y:0));leaf.addQuadCurve(to:CGPoint(x:4,y:0),control:CGPoint(x:0,y:-4))
                leaf.addQuadCurve(to:CGPoint(x:-4,y:0),control:CGPoint(x:0,y:4))
                sprinkle.fill(leaf,with:.color(item.kind == 0 ? Color(red:0.2,green:0.39,blue:0.12) : Color(red:0.19,green:0.61,blue:0.23)))
            }
        }
        var crustContext=c;crustContext.clip(to:dough)
        let edgePoints=recipe.outline(inset:0.97)
        for i in stride(from:0,to:edgePoints.count,by:2) {
            let point=edgePoints[i],r=CGFloat(1.5+Double(i%3))
            crustContext.fill(Path(ellipseIn:CGRect(x:point.x*300,y:point.y*320,width:r*2,height:r)),
                with:.color(Color(red:0.58,green:0.26,blue:0.08).opacity(0.12+baked*0.35)))
        }
        for point in recipe.dents ?? [] {
            var dentContext=c;dentContext.clip(to:inside)
            let rect=CGRect(x:point.x*300-7,y:point.y*320-5,width:14,height:10)
            dentContext.fill(Path(ellipseIn:rect),with:.radialGradient(Gradient(colors:[
                Color(red:0.68,green:0.38,blue:0.16).opacity(0.25*(1-baked)),.clear]),
                center:CGPoint(x:rect.midX,y:rect.midY),startRadius:0,endRadius:8))
        }
    }
}
/// Coordinates match the inner rim of PizzaBowlPainted, drawn in a 300 x 320 canvas.
enum PizzaBowlLayout {
    static let opening=CGRect(x:24,y:85,width:252,height:60)
    static let contents=CGRect(x:43,y:106,width:214,height:43)
    static var frontMask:Path {
        let r=opening
        var p=Path();p.move(to:CGPoint(x:0,y:r.midY))
        p.addLine(to:CGPoint(x:r.minX,y:r.midY))
        p.addCurve(to:CGPoint(x:r.midX,y:r.maxY),
            control1:CGPoint(x:r.minX,y:r.midY+r.height*0.276),
            control2:CGPoint(x:r.midX-r.width*0.276,y:r.maxY))
        p.addCurve(to:CGPoint(x:r.maxX,y:r.midY),
            control1:CGPoint(x:r.midX+r.width*0.276,y:r.maxY),
            control2:CGPoint(x:r.maxX,y:r.midY+r.height*0.276))
        p.addLine(to:CGPoint(x:300,y:r.midY));p.addLine(to:CGPoint(x:300,y:320))
        p.addLine(to:CGPoint(x:0,y:320));p.closeSubpath();return p
    }
}
struct PizzaMixingBowl:View {
    let recipe:PizzaRecipe
    var turn=0.0
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/CGFloat(300),y:s.height/CGFloat(320))
            let bowlRect=CGRect(x:0,y:10,width:300,height:300)
            c.draw(VillageArtwork.image("PizzaBowlPainted"),in:bowlRect)
            var fill=c;fill.clip(to:Path(ellipseIn:PizzaBowlLayout.opening))
            let contents=Path(ellipseIn:PizzaBowlLayout.contents)
            if !recipe.ingredients.isEmpty {
                // The surface is below the rim, with a soft contact shadow on the inner wall.
                var shadow=fill;shadow.addFilter(.blur(radius:3))
                shadow.fill(contents.applying(CGAffineTransform(translationX:0,y:3)),
                    with:.color(StorybookStyle.plum.opacity(0.22)))
                if recipe.ingredients.contains(1) {
                    fill.fill(contents,with:.linearGradient(Gradient(colors:[
                        Color(red:0.65,green:0.92,blue:0.98),Color(red:0.24,green:0.69,blue:0.82)]),
                        startPoint:CGPoint(x:150,y:107),endPoint:CGPoint(x:150,y:147)))
                }
                if recipe.ingredients.contains(0) {
                    let flour=Path(ellipseIn:CGRect(x:57,y:108,width:190,height:39))
                    fill.fill(flour,with:.radialGradient(Gradient(colors:[.white,Color(red:1,green:0.87,blue:0.62)]),
                        center:CGPoint(x:140,y:116),startRadius:0,endRadius:105))
                }
                if recipe.ingredients.contains(2) {
                    for i in 0..<7 {
                        let x=CGFloat((i*29)%140)+78,y=CGFloat((i*11)%17)+116
                        let oil=Path(ellipseIn:CGRect(x:x,y:y,width:15,height:5))
                        fill.fill(oil,with:.color(Color(red:1,green:0.76,blue:0.12).opacity(0.85*(1-recipe.mixed))))
                        fill.stroke(oil,with:.color(.white.opacity(0.35*(1-recipe.mixed))),lineWidth:0.8)
                    }
                }
                fill.fill(contents,with:.radialGradient(Gradient(colors:[
                    Color(red:1,green:0.95,blue:0.78).opacity(recipe.mixed),
                    Color(red:0.93,green:0.76,blue:0.46).opacity(recipe.mixed)]),
                    center:CGPoint(x:137,y:118),startRadius:0,endRadius:110))
                var surface=fill;surface.clip(to:contents)
                for i in 0..<12 {
                    let a=Double(i)*2.4+turn*0.017,r=Double(i%5)*16
                    let x=150+cos(a)*r,y=127+sin(a)*r*0.20
                    surface.fill(Path(ellipseIn:CGRect(x:x,y:y,width:6,height:2.5)),
                        with:.color(.white.opacity(0.16+0.32*(1-recipe.mixed))))
                }
                // Elliptical ridges follow the spoon's stirring direction even after mixing is ready.
                for i in 0..<3 {
                    let a=turn*0.017+Double(i)*2.1
                    let x=150+cos(a)*Double(20+i*15),y=125+sin(a)*Double(3+i*2)
                    var ridge=Path();ridge.move(to:CGPoint(x:x-14,y:y))
                    ridge.addQuadCurve(to:CGPoint(x:x+13,y:y+2),control:CGPoint(x:x,y:y-4))
                    surface.stroke(ridge,with:.color(.white.opacity(0.32)),
                        style:StrokeStyle(lineWidth:1.5,lineCap:.round))
                }
            }
            // Pivot at the spoon head; the handle rises above the bowl instead of sweeping through its rim.
            var spoon=c
            spoon.translateBy(x:150+sin(turn*0.017)*35,y:123+cos(turn*0.017)*8)
            spoon.rotate(by:.degrees(-18+sin(turn*0.017)*14))
            spoon.draw(VillageArtwork.image("PizzaSpoonPainted"),in:CGRect(x:-70,y:-108,width:140,height:140))
            // Redraw the actual painted front rim over both contents and the submerged spoon tip.
            var front=c;front.clip(to:PizzaBowlLayout.frontMask)
            front.draw(VillageArtwork.image("PizzaBowlPainted"),in:bowlRect)
        }.aspectRatio(CGFloat(300)/CGFloat(320),contentMode:.fit).accessibilityHidden(true)
    }
}
struct PizzaOvenArtwork:View {
    var heat=0.0
    var active=true
    var body:some View {PaintedPizzaOven(heat:heat,active:active)}
}

struct PizzaIngredientArt:View {
    let kind:Int
    var spice=false
    var fillLevel=1.0
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/CGFloat(60),y:s.height/CGFloat(70))
            if spice {
                let colors:[Color]=[Color(red:0.24,green:0.42,blue:0.15),.green,.white,.yellow]
                let jar=Path(roundedRect:CGRect(x:12,y:17,width:36,height:44),cornerRadius:9)
                ToyFinish.paint(c,path:jar,color:Color(red:1,green:0.94,blue:0.76),edge:1.5)
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:10,y:9,width:40,height:13),cornerRadius:5),color:colors[kind],edge:1)
                for i in 0..<7 {
                    c.fill(Path(ellipseIn:CGRect(x:19+CGFloat((i*13)%22),y:31+CGFloat((i*11)%19),width:kind == 3 ? 8 : 3,height:3)),
                        with:.color(colors[kind]))
                }
            } else {
                let level=min(1,max(0,fillLevel))
                if kind == 1 {
                    var water=c
                    var interior=Path();interior.move(to:CGPoint(x:20,y:21))
                    interior.addQuadCurve(to:CGPoint(x:12,y:42),control:CGPoint(x:24,y:31))
                    interior.addCurve(to:CGPoint(x:44,y:56),control1:CGPoint(x:4,y:63),control2:CGPoint(x:43,y:65))
                    interior.addQuadCurve(to:CGPoint(x:38,y:21),control:CGPoint(x:53,y:41))
                    interior.closeSubpath();water.clip(to:interior)
                    water.fill(Path(CGRect(x:8,y:59-level*37,width:43,height:max(0.1,level*37))),
                        with:.linearGradient(Gradient(colors:[Color.cyan.opacity(0.55),Color(red:0.06,green:0.51,blue:0.75).opacity(0.8)]),
                            startPoint:CGPoint(x:20,y:22),endPoint:CGPoint(x:30,y:60)))
                    water.stroke(Path(ellipseIn:CGRect(x:9,y:56-level*34,width:39,height:5)),
                        with:.color(.white.opacity(level*0.75)),lineWidth:1)
                }
                let name=kind == 0 ? "PizzaFlourPainted" : kind == 1 ? "PizzaWaterPainted" : "PizzaOilPainted"
                c.draw(VillageArtwork.image(name),in:CGRect(x:0,y:5,width:60,height:60))
            }
        }.accessibilityHidden(true)
    }
}


struct PizzaToppingArt:View {
    let kind:PizzaToppingKind
    var body:some View {
        Canvas {c,s in
            c.translateBy(x:s.width/CGFloat(2),y:s.height/CGFloat(2))
            let scale=min(s.width,s.height)/CGFloat(29)
            c.scaleBy(x:scale,y:scale)
            PizzaToppingPainter.paint(c,kind:kind,baked:0)
        }.accessibilityHidden(true)
    }
}
enum PizzaToppingPainter {
    static func paint(_ c:GraphicsContext,kind:PizzaToppingKind,baked:Double) {
        let cream=Color(red:1,green:0.94,blue:0.73)
        let shadow=Path(ellipseIn:CGRect(x:-10,y:3,width:21,height:10))
        c.fill(shadow,with:.color(Color(red:0.3,green:0.09,blue:0.04).opacity(0.16)))
        switch kind {
        case .cheese:
            if baked>0.05 {
                let melt=min(1,baked)
                var pool=Path()
                pool.move(to:CGPoint(x:-15*melt,y:-5))
                pool.addCurve(to:CGPoint(x:8+7*melt,y:-6),control1:CGPoint(x:-13,y:-17*melt),control2:CGPoint(x:10,y:-15*melt))
                pool.addCurve(to:CGPoint(x:9,y:11*melt),control1:CGPoint(x:24*melt,y:2),control2:CGPoint(x:15,y:12*melt))
                pool.addCurve(to:CGPoint(x:-14*melt,y:7),control1:CGPoint(x:-2,y:7+8*melt),control2:CGPoint(x:-15,y:14*melt))
                pool.addQuadCurve(to:CGPoint(x:-15*melt,y:-5),control:CGPoint(x:-22*melt,y:0))
                pool.closeSubpath()
                c.fill(pool,with:.radialGradient(Gradient(colors:[cream,Color(red:1,green:0.81,blue:0.31)]),
                    center:CGPoint(x:-3,y:-4),startRadius:0,endRadius:22))
                c.stroke(pool,with:.color(Color.orange.opacity(0.3*melt)),lineWidth:0.7)
                for i in 0..<5 {
                    let x=CGFloat((i*11)%21-10),y=CGFloat((i*7)%15-7)
                    c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:3+Double(i%2),height:2)),
                        with:.color(Color(red:0.69,green:0.31,blue:0.08).opacity(max(0,melt-0.35)*0.8)))
                    c.fill(Path(ellipseIn:CGRect(x:x-1,y:y-2,width:4,height:1.5)),with:.color(.white.opacity(0.5*melt)))
                }
            }
            for i in 0..<7 {
                var piece=c
                piece.translateBy(x:CGFloat((i*7)%17-8),y:CGFloat((i*11)%15-7))
                piece.rotate(by:.degrees(Double(i*49)))
                let r=CGRect(x:-6,y:-1.8,width:12,height:3.6)
                piece.fill(Path(roundedRect:r,cornerRadius:1.8),
                    with:.color(cream.opacity(1-baked)))
            }
        case .pepperoni:
            var shape=Path()
            for i in 0..<16 {
                let a=Double(i)*Double.pi/Double(8),r:CGFloat=i%2 == 0 ? 10 : 9.3
                let point=CGPoint(x:CGFloat(cos(a))*r,y:CGFloat(sin(a))*r)
                if i == 0 {shape.move(to:point)} else {shape.addLine(to:point)}
            }
            shape.closeSubpath()
            ToyFinish.paint(c,path:shape,color:Color(red:0.88-baked*0.08,green:0.18,blue:0.12),edge:0.8)
            for i in 0..<7 {
                let x=CGFloat((i*11)%14-7),y=CGFloat((i*7)%13-6)
                c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:2.5,height:1.8)),with:.color(cream.opacity(0.7)))
            }
        case .ham:
            var shape=Path();shape.move(to:CGPoint(x:-10,y:-6))
            shape.addQuadCurve(to:CGPoint(x:8,y:-8),control:CGPoint(x:0,y:-12))
            shape.addLine(to:CGPoint(x:11,y:6));shape.addQuadCurve(to:CGPoint(x:-7,y:9),control:CGPoint(x:0,y:5));shape.closeSubpath()
            ToyFinish.paint(c,path:shape,color:Color(red:0.98,green:0.53-baked*0.06,blue:0.59),edge:0.7)
            var fold=Path();fold.move(to:CGPoint(x:-5,y:-5));fold.addQuadCurve(to:CGPoint(x:5,y:6),control:CGPoint(x:-1,y:3))
            c.stroke(fold,with:.color(cream.opacity(0.6)),style:StrokeStyle(lineWidth:1.5,lineCap:.round))
        case .mushroom:
            ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:-3.5,y:0,width:7,height:11),cornerRadius:2),
                color:cream,edge:0.6)
            var cap=Path();cap.move(to:CGPoint(x:-12,y:2))
            cap.addCurve(to:CGPoint(x:12,y:2),control1:CGPoint(x:-10,y:-16),control2:CGPoint(x:9,y:-16))
            cap.addQuadCurve(to:CGPoint(x:-12,y:2),control:CGPoint(x:0,y:6));cap.closeSubpath()
            ToyFinish.paint(c,path:cap,color:Color(red:0.81-baked*0.06,green:0.63-baked*0.06,blue:0.43),edge:0.7)
            var gill=Path();gill.move(to:CGPoint(x:-8,y:1));gill.addQuadCurve(to:CGPoint(x:8,y:1),control:CGPoint(x:0,y:4))
            c.stroke(gill,with:.color(Color(red:0.43,green:0.26,blue:0.19)),lineWidth:1)
        case .pepper:
            var ring=Path()
            ring.move(to:CGPoint(x:-9,y:7))
            ring.addCurve(to:CGPoint(x:-5,y:-8),control1:CGPoint(x:-14,y:0),control2:CGPoint(x:-14,y:-10))
            ring.addCurve(to:CGPoint(x:9,y:-5),control1:CGPoint(x:0,y:-15),control2:CGPoint(x:13,y:-13))
            ring.addCurve(to:CGPoint(x:7,y:9),control1:CGPoint(x:16,y:0),control2:CGPoint(x:15,y:12))
            c.stroke(ring,with:.color(Color(red:0.09,green:0.39,blue:0.14)),style:StrokeStyle(lineWidth:5,lineCap:.round))
            c.stroke(ring,with:.color(Color(red:0.48,green:0.78-baked*0.08,blue:0.15)),style:StrokeStyle(lineWidth:2.7,lineCap:.round))
        case .olive:
            let ring=Path(ellipseIn:CGRect(x:-8,y:-10,width:16,height:20))
            c.stroke(ring,with:.color(Color(red:0.13,green:0.18,blue:0.12)),lineWidth:5)
            var shine=Path();shine.move(to:CGPoint(x:-5,y:-6));shine.addQuadCurve(to:CGPoint(x:1,y:-8),control:CGPoint(x:-4,y:-10))
            c.stroke(shine,with:.color(Color(red:0.65,green:0.69,blue:0.42)),style:StrokeStyle(lineWidth:1.6,lineCap:.round))
        case .pineapple:
            var chunk=Path();chunk.move(to:CGPoint(x:-10,y:6))
            chunk.addQuadCurve(to:CGPoint(x:-5,y:-9),control:CGPoint(x:-12,y:-7))
            chunk.addLine(to:CGPoint(x:10,y:-2));chunk.addQuadCurve(to:CGPoint(x:6,y:10),control:CGPoint(x:15,y:8));chunk.closeSubpath()
            ToyFinish.paint(c,path:chunk,color:Color(red:1,green:0.82-baked*0.08,blue:0.16),edge:0.7)
            for i in 0..<3 {
                let x=CGFloat(i)*4-5
                var fibre=Path();fibre.move(to:CGPoint(x:x,y:-3));fibre.addLine(to:CGPoint(x:x+2,y:6))
                c.stroke(fibre,with:.color(cream.opacity(0.5)),lineWidth:0.8)
            }
        }
    }
}


enum PizzaDragItem:Equatable {
    case ingredient(Int),topping(PizzaToppingKind),herb(Int)
}
struct PizzaSurfaceFrameKey:PreferenceKey {
    static let defaultValue=CGRect.zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect) {
        let next=nextValue()
        if next.width>0 && next.height>0 {value=next}
    }
}
struct PizzaDragArtwork:View {
    let item:PizzaDragItem
    var body:some View {
        Group {
            switch item {
            case .ingredient(let index):PizzaIngredientArt(kind:index)
            case .topping(let kind):PizzaToppingArt(kind:kind)
            case .herb(let index):PizzaIngredientArt(kind:index,spice:true)
            }
        }
    }
}
struct PizzaServingDish:View {
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                Ellipse().fill(Color(red:0.41,green:0.25,blue:0.19).opacity(0.18)).offset(y:4).blur(radius:2)
                Ellipse().fill(LinearGradient(colors:[.white,Color(red:0.88,green:0.93,blue:0.91)],
                    startPoint:.topLeading,endPoint:.bottomTrailing))
                    .overlay(Ellipse().stroke(.white,lineWidth:2))
                Ellipse().fill(RadialGradient(colors:[Color(red:0.82,green:0.87,blue:0.83),.white],
                    center:.center,startRadius:0,endRadius:proxy.size.width*0.4)).padding(5)
                    .overlay(Ellipse().stroke(Color(red:0.18,green:0.57,blue:0.58).opacity(0.4),lineWidth:1).padding(4))
            }
        }.allowsHitTesting(false)
    }
}
struct PizzaLandingSprite:View {
    let kind:PizzaToppingKind
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var landed=false
    var body:some View {
        PizzaToppingArt(kind:kind)
            .scaleEffect(reduced || landed ? 1 : 1.35)
            .offset(y:reduced || landed ? 0 : -16)
            .task {
                await Task.yield()
                withAnimation(reduced ? nil : .spring(response:0.34,dampingFraction:0.48)) {landed=true}
            }
    }
}
struct PizzaLandingSpark:View {
    let revision:Int
    let reduced:Bool
    @State private var finished=false
    var body:some View {
        Canvas {c,s in
            for i in 0..<6 {
                let angle=Double(i)*Double.pi/Double(3)
                let center=CGPoint(x:s.width/CGFloat(2)+CGFloat(cos(angle))*s.width*0.27,
                    y:s.height/CGFloat(2)+CGFloat(sin(angle))*s.height*0.27)
                var ray=Path();ray.move(to:center)
                ray.addLine(to:CGPoint(x:center.x+CGFloat(cos(angle))*6,y:center.y+CGFloat(sin(angle))*6))
                c.stroke(ray,with:.color(i%2 == 0 ? .white : Color(red:1,green:0.83,blue:0.25)),
                    style:StrokeStyle(lineWidth:2.5,lineCap:.round))
            }
        }.scaleEffect(reduced ? 1 : finished ? 1.3 : 0.55)
            .opacity(finished ? 0 : 0.9)
            .task(id:revision) {
                finished=false
                await Task.yield()
                withAnimation(.easeOut(duration:reduced ? 0.2 : 0.48)) {finished=true}
            }
    }
}


/// Short-lived effects only redraw while pouring, baking or serving.
struct PizzaPourEffect:View {
    let kind:Int
    let reduced:Bool
    @State private var started=Date()
    var body:some View {
        TimelineView(.animation(minimumInterval:Double(1)/Double(30),paused:reduced)) {timeline in
            let time=reduced ? 0.45 : min(1,timeline.date.timeIntervalSince(started))
            GeometryReader {proxy in
                let size=proxy.size
                ZStack {
                    Canvas {c,s in
                        let spout=CGPoint(x:s.width*0.48,y:s.height*0.30)
                        let bottom=s.height*0.80
                        let color:Color=kind == 0 ? Color(red:1,green:0.96,blue:0.81) : kind == 1 ? .cyan : Color(red:1,green:0.75,blue:0.12)
                        if kind != 0 && time>0.18 && time<0.82 {
                            var stream=Path();stream.move(to:spout)
                            stream.addQuadCurve(to:CGPoint(x:s.width*0.51,y:bottom),
                                control:CGPoint(x:s.width*(0.46+sin(time*12)*0.025),y:s.height*0.56))
                            c.stroke(stream,with:.color(color.opacity(0.82)),
                                style:StrokeStyle(lineWidth:kind == 1 ? 8 : 5,lineCap:.round))
                            c.stroke(stream,with:.color(.white.opacity(0.6)),
                                style:StrokeStyle(lineWidth:2,lineCap:.round))
                        }
                        for i in 0..<(kind == 0 ? 42 : 20) {
                            let phase=(time*1.8+Double(i)*0.071).truncatingRemainder(dividingBy:1)
                            let spread=kind == 0 ? 24.0 : 8.0
                            let x=spout.x+CGFloat(sin(Double(i)*2.4)*spread*phase)
                            let y=spout.y+CGFloat(phase)*(bottom-spout.y)
                            let radius:CGFloat=kind == 0 ? CGFloat(2+i%4) : 2
                            if time>0.18 && time<0.89 {
                                c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:radius*2,height:kind == 0 ? radius*1.3 : 7)),
                                    with:.color(color.opacity(time>0.8 ? max(0,(0.9-time)*8) : 0.85)))
                            }
                        }
                        if kind != 0 && time>0.2 {
                            for i in 0..<3 {
                                let ripple=(time*3+Double(i)/Double(3)).truncatingRemainder(dividingBy:1)
                                let radius:CGFloat=CGFloat(12+ripple*36)
                                c.stroke(Path(ellipseIn:CGRect(x:s.width*0.51-radius,y:bottom-radius*0.22,
                                    width:radius*2,height:radius*0.44)),
                                    with:.color(color.opacity((1-ripple)*max(0,1-time)*0.75)),lineWidth:1.5)
                            }
                        }
                        for i in 0..<12 {
                            let a=Double(i)*Double.pi/Double(6)
                            let radius=CGFloat(12+time*35)
                            let x=s.width*0.51+CGFloat(cos(a))*radius
                            let y=bottom+CGFloat(sin(a))*radius*0.28
                            c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:kind == 0 ? 13 : 5,height:kind == 0 ? 8 : 3)),
                                with:.color(color.opacity((1-time)*0.65)))
                        }
                    }
                    PizzaIngredientArt(kind:kind,fillLevel:reduced ? 0.5 : max(0,1-(time-0.18)/Double(0.62)))
                        .frame(width:min(90,size.width*0.34),height:min(100,size.height*0.52))
                        .rotationEffect(
                            .degrees(pourAngle(at:time)),
                            anchor:.bottomTrailing
                        )
                        .offset(y:reduced ? 0 : CreatureRig.key(time,[(0,18),(0.2,0),(0.75,0),(1,12)]))
                        .position(x:size.width*0.35,y:size.height*0.18)
                }
            }
        }.accessibilityHidden(true)
    }
    private func pourAngle(at time:Double)->Double {
        guard !reduced else {return 60}
        let tilt=CreatureRig.key(time,[
            (0,0),
            (0.2,65),
            (0.72,65),
            (0.95,0)
        ])
        let shake=kind == 0 && time>0.22 && time<0.72 ? sin(time*55)*5 : 0
        return tilt+shake
    }

}

struct PizzaHeatEffects:View {
    let progress:Double
    let reduced:Bool
    var body:some View {
        TimelineView(.animation(minimumInterval:Double(1)/Double(24),paused:reduced || progress>=1)) {timeline in
            let time=reduced ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas {c,s in
                let center=CGPoint(x:s.width*0.5,y:s.height*0.60)
                let ready=progress>=1
                let pulse=ready ? 0.5 : 0.45+sin(time*3)*0.08
                c.fill(Path(ellipseIn:CGRect(x:0,y:s.height*0.12,width:s.width,height:s.height*0.85)),
                    with:.radialGradient(Gradient(colors:[Color.yellow.opacity(pulse),.orange.opacity(0.18),.clear]),
                        center:center,startRadius:0,endRadius:s.width*0.6))
                for i in 0..<9 {
                    let phase=(time*0.20+Double(i)*0.117).truncatingRemainder(dividingBy:1)
                    let x=s.width*(0.30+CGFloat(i%4)*0.12)+CGFloat(sin(time+Double(i))*5)
                    let y=s.height*(0.64-CGFloat(phase)*0.38)
                    let opacity=(1-phase)*(ready ? 0.2 : 0.65)
                    c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:3,height:5)),with:.color(.yellow.opacity(opacity)))
                }
                if ready {
                    for i in 0..<12 {
                        let a=Double(i)*Double.pi/Double(6)
                        let from=CGPoint(x:center.x+CGFloat(cos(a))*s.width*0.36,y:center.y+CGFloat(sin(a))*s.height*0.34)
                        let to=CGPoint(x:center.x+CGFloat(cos(a))*s.width*0.44,y:center.y+CGFloat(sin(a))*s.height*0.42)
                        var ray=Path();ray.move(to:from);ray.addLine(to:to)
                        c.stroke(ray,with:.color(.yellow.opacity(0.8)),style:StrokeStyle(lineWidth:4,lineCap:.round))
                    }
                }
            }
        }.accessibilityHidden(true)
    }
}

struct PizzaBiteFlight:View {
    let recipe:PizzaRecipe
    let revision:Int
    let reduced:Bool
    @State private var arrived=false
    @State private var visible=true
    var body:some View {
        GeometryReader {proxy in
            PizzaIllustration(recipe:recipe,baked:1,board:false,sliceIndex:(revision-1)%8)
                .frame(width:110,height:118)
                .scaleEffect(reduced ? 1 : arrived ? 0.35 : 1.7)
                .rotationEffect(.degrees(reduced ? 0 : arrived ? -15 : 12))
                .position(x:arrived ? min(75,proxy.size.width*0.17) : proxy.size.width*0.56,
                          y:arrived ? proxy.size.height-min(85,proxy.size.width*0.20) : proxy.size.height*0.45)
                .opacity(visible ? 1 : 0)
        }.task(id:revision) {
            var transaction=Transaction();transaction.disablesAnimations=true
            withTransaction(transaction) {arrived=false;visible=true}
            await Task.yield()
            withAnimation(reduced ? nil : .easeInOut(duration:0.65)) {arrived=true}
            do {try await Task.sleep(nanoseconds:650_000_000)} catch {return}
            withAnimation(.easeOut(duration:0.15)) {visible=false}
        }.accessibilityHidden(true)
    }
}


enum PizzaGeometry {
    static func outline(_ recipe:PizzaRecipe,inset:Double=1)->Path {
        let points=recipe.outline(inset:inset).map {CGPoint(x:$0.x*300,y:$0.y*320)}
        guard let first=points.first,let last=points.last else {return Path()}
        var path=Path()
        path.move(to:CGPoint(x:(first.x+last.x)/CGFloat(2),y:(first.y+last.y)/CGFloat(2)))
        for i in points.indices {
            let current=points[i],next=points[(i+1)%points.count]
            path.addQuadCurve(to:CGPoint(x:(current.x+next.x)/CGFloat(2),y:(current.y+next.y)/CGFloat(2)),control:current)
        }
        path.closeSubpath();return path
    }
    static func bite(_ bite:PizzaBite)->Path {
        var path=Path()
        for i in 0..<72 {
            let a=Double(i)*Double.pi/Double(36)
            let radius=bite.radius*300*(1+0.065*cos(a*9))
            let point=CGPoint(x:bite.point.x*300+cos(a)*radius,y:bite.point.y*320+sin(a)*radius)
            if i == 0 {path.move(to:point)} else {path.addLine(to:point)}
        }
        path.closeSubpath();return path
    }
}
struct PizzaDoughSwatch:View {
    let form:PizzaDoughForm
    var body:some View {
        Canvas {c,s in
            var recipe=PizzaRecipe();recipe.formed=1;recipe.doughForm=form
            c.scaleBy(x:s.width/CGFloat(300),y:s.height/CGFloat(320))
            ToyFinish.paint(c,path:PizzaGeometry.outline(recipe),color:Color(red:1,green:0.85,blue:0.48),edge:3)
        }.accessibilityHidden(true)
    }
}
struct PizzaMouthfulFlight:View {
    @Environment(\.scenePhase) private var phase
    var active=true
    let recipe:PizzaRecipe
    let bite:PizzaBite
    let revision:Int
    let reduced:Bool
    @State private var arrived=false
    @State private var visible=true
    @State private var started=Date()
    private var fragmentRecipe:PizzaRecipe {
        var value=recipe
        value.bites=recipe.bites?.filter {$0.id != bite.id}
        return value
    }
    var body:some View {
        GeometryReader {proxy in
            let ratio:CGFloat=CGFloat(300)/CGFloat(320)
            let width:CGFloat=min(proxy.size.width,proxy.size.height*ratio)
            let height:CGFloat=width/ratio
            let x:CGFloat=(proxy.size.width-width)/CGFloat(2)+CGFloat(bite.point.x)*width
            let y:CGFloat=(proxy.size.height-height)/CGFloat(2)+CGFloat(bite.point.y)*height
            ZStack {
                TimelineView(.animation(minimumInterval:1.0/30,paused:reduced || !active || !visible || phase != .active)) {frame in
                    let elapsed=max(0,frame.date.timeIntervalSince(started))
                    Canvas {c,s in
                        guard !reduced,elapsed<0.36 else {return}
                        let raw=min(1,elapsed/0.48),t=raw*raw*(3-2*raw)
                        let end=CGPoint(x:x+(65-x)*CGFloat(t),y:y+(s.height-75-y)*CGFloat(t))
                        let cheeses=recipe.toppings.lazy.filter {
                            $0.kind == .cheese && hypot($0.point.x-bite.point.x,$0.point.y-bite.point.y)<bite.radius+0.045
                        }.prefix(3)
                        for item in cheeses {
                            let anchor=CGPoint(x:x+CGFloat(item.point.x-bite.point.x)*width,
                                               y:y+CGFloat(item.point.y-bite.point.y)*height)
                            var strand=Path();strand.move(to:anchor)
                            strand.addQuadCurve(to:end,control:CGPoint(x:(anchor.x+end.x)/2,
                                y:(anchor.y+end.y)/2+CGFloat(t)*35))
                            let opacity=min(1,max(0,(0.36-elapsed)/0.12))
                            c.stroke(strand,with:.color(Color(red:1,green:0.87,blue:0.43).opacity(opacity)),
                                style:StrokeStyle(lineWidth:3.5,lineCap:.round))
                            c.stroke(strand,with:.color(Color(red:1,green:0.98,blue:0.82).opacity(opacity*0.7)),
                                style:StrokeStyle(lineWidth:1,lineCap:.round))
                        }
                    }
                }
                Canvas {c,s in
                    for i in 0..<9 {
                        let a=Double(i)*Double.pi*2/Double(9)
                        let distance:CGFloat=arrived ? 32 : 7
                        let point=CGPoint(x:s.width/CGFloat(2)+CGFloat(cos(a))*distance,y:s.height/CGFloat(2)+CGFloat(sin(a))*distance)
                        c.fill(Path(ellipseIn:CGRect(x:point.x,y:point.y,width:4,height:3)),
                            with:.color(i%3 == 0 ? .white : Color(red:0.94,green:0.64,blue:0.23)))
                    }
                }.frame(width:80,height:80).position(x:x,y:y).opacity(arrived ? 0 : 1)
                PizzaIllustration(recipe:fragmentRecipe,baked:1,board:false,fragment:bite)
                    .frame(width:100,height:107)
                    .scaleEffect(reduced ? 1.5 : arrived ? 0.4 : 2.6)
                    .rotationEffect(.degrees(reduced ? 0 : arrived ? -12 : 8))
                    .position(x:arrived ? 65 : x,y:arrived ? proxy.size.height-75 : y)
                    .opacity(visible ? 1 : 0)
            }
        }.task(id:revision) {
            var transaction=Transaction();transaction.disablesAnimations=true
            withTransaction(transaction) {arrived=false;visible=true;started=Date()}
            await Task.yield()
            withAnimation(reduced ? nil : .easeInOut(duration:0.48)) {arrived=true}
            do {try await Task.sleep(nanoseconds:480_000_000)} catch {return}
            withAnimation(.easeOut(duration:0.1)) {visible=false}
        }.accessibilityHidden(true)
    }
}
