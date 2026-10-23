import SwiftUI

struct PizzaKitchenBackdrop:View {
    var body:some View {
        Canvas {c,s in
            c.fill(Path(CGRect(origin:.zero,size:s)),with:.linearGradient(Gradient(colors:[
                Color(red:0.17,green:0.56,blue:0.6),Color(red:0.67,green:0.85,blue:0.76)]),startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)))
            let counter=s.height*0.5
            for row in 0..<6 {
                for col in 0..<12 {
                    let rect=CGRect(x:CGFloat(col)*70-CGFloat(row%2)*35,y:CGFloat(row)*44+60,width:67,height:41)
                    c.fill(Path(roundedRect:rect,cornerRadius:5),with:.color(Color(red:1,green:0.91,blue:0.72).opacity(0.25)))
                }
            }
            for i in 0..<14 {
                let x=CGFloat(i)*s.width/13
                let r=CGRect(x:x,y:0,width:s.width/13+1,height:53)
                c.fill(Path(roundedRect:r,cornerRadius:12),with:.color(i%2 == 0 ? Color(red:0.88,green:0.23,blue:0.23) : Color(red:1,green:0.94,blue:0.8)))
            }
            for side in 0..<2 {
                let x=side == 0 ? s.width*0.08 : s.width*0.9
                let pan=Path(ellipseIn:CGRect(x:x-20,y:s.height*0.24,width:40,height:43))
                ToyFinish.paint(c,path:pan,color:Color(red:0.72,green:0.37,blue:0.2),edge:1.5)
                var handle=Path();handle.move(to:CGPoint(x:x,y:s.height*0.24))
                handle.addLine(to:CGPoint(x:x,y:s.height*0.24-30))
                c.stroke(handle,with:.color(GameStyle.ink),style:StrokeStyle(lineWidth:6,lineCap:.round))
            }
            c.fill(Path(CGRect(x:0,y:counter,width:s.width,height:s.height-counter)),with:.linearGradient(Gradient(colors:[
                Color(red:0.86,green:0.59,blue:0.33),Color(red:0.52,green:0.29,blue:0.22)]),
                startPoint:CGPoint(x:0,y:counter),endPoint:CGPoint(x:0,y:s.height)))
            for i in 0..<15 {
                let y=counter+CGFloat(i)*46
                var plank=Path();plank.move(to:CGPoint(x:0,y:y));plank.addLine(to:CGPoint(x:s.width,y:y))
                c.stroke(plank,with:.color(GameStyle.ink.opacity(0.15)),lineWidth:2)
                for j in 0..<3 {
                    let x=CGFloat((i*59+j*91)%293)/293*s.width
                    var grain=Path();grain.move(to:CGPoint(x:x,y:y+19));grain.addQuadCurve(to:CGPoint(x:x+62,y:y+23),control:CGPoint(x:x+25,y:y+12))
                    c.stroke(grain,with:.color(.white.opacity(0.09)),lineWidth:1)
                }
            }
            c.fill(Path(CGRect(x:0,y:counter,width:s.width,height:8)),with:.color(Color(red:1,green:0.84,blue:0.54)))
            let key=CGPoint(x:s.width*0.7,y:s.height*0.22)
            c.fill(Path(CGRect(origin:.zero,size:s)),with:.radialGradient(Gradient(colors:[
                Color(red:1,green:0.88,blue:0.56).opacity(0.18),.clear,GameStyle.ink.opacity(0.12)]),
                center:key,startRadius:0,endRadius:max(s.width,s.height)))
            for i in 0..<8 {
                let x=CGFloat(i+1)*s.width/9,y=s.height*0.10+sin(Double(i)*0.5)*14
                c.fill(Path(ellipseIn:CGRect(x:x-15,y:y-15,width:30,height:30)),with:.radialGradient(
                    Gradient(colors:[Color.yellow.opacity(0.3),.clear]),center:CGPoint(x:x,y:y),startRadius:0,endRadius:15))
                c.fill(Path(ellipseIn:CGRect(x:x-3,y:y-3,width:6,height:8)),with:.color(Color(red:1,green:0.91,blue:0.54)))
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}
struct PizzaIllustration:View {
    let recipe:PizzaRecipe
    var baked=0.0
    var board=true
    var eaten=0
    var landingID:UUID?
    var sliceIndex:Int?
    var body:some View {
        Canvas {c,size in
            c.scaleBy(x:size.width/300,y:size.height/320)
            if board {
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
            if baked>=1 && eaten<8 && sliceIndex == nil {
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
                        .frame(width:frame.size.width*29/300,height:frame.size.height*29/320)
                        .rotationEffect(.degrees(item.angle))
                        .position(x:item.point.x*frame.size.width,y:item.point.y*frame.size.height)
                }
            }.allowsHitTesting(false)
        }.aspectRatio(300.0/320,contentMode:.fit).accessibilityHidden(true)
    }
    private func draw(_ c:GraphicsContext) {
        let spread=0.63+recipe.formed*0.37
        let radius=CGFloat(115*spread)
        let center=CGPoint(x:150,y:154)
        let dough=Path(ellipseIn:CGRect(x:150-radius,y:154-radius*0.96,width:radius*2,height:radius*1.92))
        let crust=GameStyle.mixed(Color(red:1,green:0.88,blue:0.6),with:Color(red:0.8,green:0.39,blue:0.12),amount:baked*0.7)
        var cast=c;cast.addFilter(.blur(radius:4))
        cast.fill(dough.applying(CGAffineTransform(translationX:1,y:5)),with:.color(Color(red:0.33,green:0.15,blue:0.08).opacity(0.3)))
        ToyFinish.paint(c,path:dough,color:crust,edge:1.8)
        let inside=Path(ellipseIn:CGRect(x:150-radius+13,y:154-radius*0.96+13,width:radius*2-26,height:radius*1.92-26))
        c.stroke(inside,with:.color(Color(red:0.76,green:0.42,blue:0.15).opacity(0.23)),lineWidth:2)
        var topping=c;topping.clip(to:inside)
        for stroke in recipe.sauce {
            guard let first=stroke.points.first else {continue}
            var path=Path();path.move(to:CGPoint(x:first.x*300,y:first.y*320))
            for point in stroke.points.dropFirst() {path.addLine(to:CGPoint(x:point.x*300,y:point.y*320))}
            if stroke.points.count == 1 {path.addLine(to:CGPoint(x:first.x*300+0.1,y:first.y*320))}
            topping.stroke(path,with:.linearGradient(Gradient(colors:[
                Color(red:0.97,green:0.24,blue:0.12),Color(red:0.65,green:0.08,blue:0.06)]),
                startPoint:CGPoint(x:70,y:80),endPoint:CGPoint(x:230,y:250)),
                style:StrokeStyle(lineWidth:32,lineCap:.round,lineJoin:.round))
            topping.stroke(path,with:.color(Color(red:1,green:0.62,blue:0.25).opacity(0.1)),
                style:StrokeStyle(lineWidth:1.2,lineCap:.round,lineJoin:.round))
        }
        // Cheese pools grow and connect only where the child placed cheese.
        if baked>0 {
            let cheeses=recipe.toppings.filter {$0.kind == .cheese}
            let color=Color(red:1,green:0.88,blue:0.43).opacity(baked*0.9)
            for (index,item) in cheeses.enumerated() {
                let a=CGPoint(x:item.point.x*300,y:item.point.y*320)
                for other in cheeses.dropFirst(index+1) {
                    let b=CGPoint(x:other.point.x*300,y:other.point.y*320)
                    if hypot(a.x-b.x,a.y-b.y)<36*baked {
                        var bridge=Path();bridge.move(to:a);bridge.addLine(to:b)
                        topping.stroke(bridge,with:.color(color),style:StrokeStyle(lineWidth:15*baked,lineCap:.round))
                    }
                }
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
        for i in 0..<27 {
            let a=Double(i)*Double.pi*2/27
            let p=CGPoint(x:center.x+CGFloat(cos(a))*(radius-6),y:center.y+CGFloat(sin(a))*(radius*0.96-6))
            let r=CGFloat(1.5+Double(i%3))
            c.fill(Path(ellipseIn:CGRect(x:p.x,y:p.y,width:r*2,height:r)),with:.color(Color(red:0.58,green:0.26,blue:0.08).opacity(0.12+baked*0.35)))
        }
    }
}
struct PizzaMixingBowl:View {
    let recipe:PizzaRecipe
    var turn=0.0
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/300,y:s.height/320)
            ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:30,y:137,width:240,height:136),cornerRadius:70),
                color:Color(red:0.14,green:0.65,blue:0.72),edge:2.5)
            let opening=Path(ellipseIn:CGRect(x:30,y:103,width:240,height:80))
            c.fill(opening,with:.linearGradient(Gradient(colors:[Color(red:0.08,green:0.33,blue:0.4),Color(red:0.4,green:0.77,blue:0.78)]),
                startPoint:CGPoint(x:0,y:100),endPoint:CGPoint(x:0,y:184)))
            var fill=c;fill.clip(to:opening)
            if !recipe.ingredients.isEmpty {
                let contents=Path(ellipseIn:CGRect(x:47,y:131,width:208,height:57))
                if recipe.ingredients.contains(1) {
                    fill.fill(contents,with:.linearGradient(Gradient(colors:[Color(red:0.55,green:0.88,blue:0.96),Color(red:0.22,green:0.66,blue:0.81)]),
                        startPoint:CGPoint(x:0,y:130),endPoint:CGPoint(x:0,y:180)))
                    for i in 0..<3 {
                        fill.stroke(Path(ellipseIn:CGRect(x:88+CGFloat(i)*13,y:142+CGFloat(i)*3,width:74,height:18)),
                            with:.color(.white.opacity(0.45*(1-recipe.mixed))),lineWidth:1.5)
                    }
                }
                if recipe.ingredients.contains(0) {
                    var mound=Path();mound.move(to:CGPoint(x:71,y:175))
                    mound.addQuadCurve(to:CGPoint(x:151,y:126),control:CGPoint(x:109,y:139))
                    mound.addQuadCurve(to:CGPoint(x:231,y:175),control:CGPoint(x:187,y:133))
                    mound.closeSubpath()
                    fill.fill(mound,with:.linearGradient(Gradient(colors:[.white,Color(red:1,green:0.89,blue:0.67)]),
                        startPoint:CGPoint(x:110,y:136),endPoint:CGPoint(x:160,y:178)))
                }
                if recipe.ingredients.contains(2) {
                    for i in 0..<7 {
                        let x=CGFloat((i*29)%140)+78,y=CGFloat((i*11)%23)+149
                        let oil=Path(ellipseIn:CGRect(x:x,y:y,width:17,height:7))
                        fill.fill(oil,with:.color(Color(red:1,green:0.76,blue:0.12).opacity(0.85*(1-recipe.mixed))))
                        fill.stroke(oil,with:.color(.white.opacity(0.35*(1-recipe.mixed))),lineWidth:0.8)
                    }
                }
                fill.fill(contents,with:.color(Color(red:1,green:0.91,blue:0.69).opacity(recipe.mixed)))
                if recipe.mixed<1 {
                    for i in 0..<18 {
                        let a=Double(i)*2.4+turn*0.01,r=Double(i%5)*17
                        let x=150+cos(a)*r,y=150+sin(a)*r*0.28
                        fill.fill(Path(ellipseIn:CGRect(x:x,y:y,width:8,height:5)),with:.color(i%3 == 0 && recipe.ingredients.contains(1) ? .cyan.opacity(0.5) : .white.opacity(0.65)))
                    }
                }
            }
            c.stroke(opening,with:.color(Color(red:0.62,green:0.93,blue:0.88)),lineWidth:5)
            var spoon=c;spoon.translateBy(x:155,y:145);spoon.rotate(by:.degrees(-25+sin(turn*0.02)*24))
            var handle=Path();handle.move(to:CGPoint(x:0,y:0));handle.addLine(to:CGPoint(x:42,y:-100))
            spoon.stroke(handle,with:.color(Color(red:0.61,green:0.36,blue:0.21)),style:StrokeStyle(lineWidth:12,lineCap:.round))
            ToyFinish.paint(spoon,path:Path(ellipseIn:CGRect(x:-14,y:-7,width:30,height:40)),color:Color(red:0.82,green:0.56,blue:0.29))
        }.aspectRatio(300.0/320,contentMode:.fit).accessibilityHidden(true)
    }
}
struct PizzaOvenArtwork:View {
    var heat=0.0
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/300,y:s.height/320)
            let shell=Path(roundedRect:CGRect(x:27,y:24,width:246,height:262),cornerRadius:36)
            ToyFinish.paint(c,path:shell,color:Color(red:0.88,green:0.34,blue:0.22),edge:3)
            for row in 0..<6 {
                for col in 0..<5 {
                    let x=CGFloat(col)*48+30-CGFloat(row%2)*24,y=CGFloat(row)*35+38
                    c.stroke(Path(roundedRect:CGRect(x:x,y:y,width:44,height:31),cornerRadius:6),with:.color(Color.white.opacity(0.12)),lineWidth:2)
                }
            }
            let opening=Path(roundedRect:CGRect(x:57,y:87,width:186,height:149),cornerRadius:58)
            c.fill(opening,with:.radialGradient(Gradient(colors:[Color(red:0.71,green:0.26,blue:0.06),Color(red:0.13,green:0.07,blue:0.06)]),
                center:CGPoint(x:150,y:209),startRadius:0,endRadius:130))
            c.stroke(opening,with:.color(Color(red:1,green:0.76,blue:0.4)),lineWidth:10)
            for i in 0..<5 {
                let x=CGFloat(i)*27+92
                var flame=Path();flame.move(to:CGPoint(x:x-9,y:209))
                flame.addQuadCurve(to:CGPoint(x:x+2,y:170-CGFloat(sin(heat*18+Double(i))*7)),control:CGPoint(x:x-18,y:186))
                flame.addQuadCurve(to:CGPoint(x:x+12,y:209),control:CGPoint(x:x+18,y:190));flame.closeSubpath()
                c.fill(flame,with:.linearGradient(Gradient(colors:[.yellow,Color.orange,.red.opacity(0.4)]),startPoint:CGPoint(x:0,y:175),endPoint:CGPoint(x:0,y:215)))
            }
            ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:40,y:234,width:220,height:22),cornerRadius:8),color:Color(red:0.47,green:0.3,blue:0.27))
            for x in [CGFloat(81),CGFloat(219)] {
                ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:x-10,y:49,width:20,height:20)),color:Color(red:1,green:0.82,blue:0.42))
            }
        }.aspectRatio(300.0/320,contentMode:.fit).accessibilityHidden(true)
    }
}


struct PizzaIngredientArt:View {
    let kind:Int
    var spice=false
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/60,y:s.height/70)
            if spice {
                let colors:[Color]=[Color(red:0.24,green:0.42,blue:0.15),.green,.white,.yellow]
                let jar=Path(roundedRect:CGRect(x:12,y:17,width:36,height:44),cornerRadius:9)
                ToyFinish.paint(c,path:jar,color:Color(red:1,green:0.94,blue:0.76),edge:1.5)
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:10,y:9,width:40,height:13),cornerRadius:5),color:colors[kind],edge:1)
                for i in 0..<7 {
                    c.fill(Path(ellipseIn:CGRect(x:19+CGFloat((i*13)%22),y:31+CGFloat((i*11)%19),width:kind == 3 ? 8 : 3,height:3)),
                        with:.color(colors[kind]))
                }
            } else if kind == 0 {
                var bag=Path();bag.move(to:CGPoint(x:13,y:11));bag.addLine(to:CGPoint(x:47,y:11))
                bag.addCurve(to:CGPoint(x:48,y:61),control1:CGPoint(x:42,y:26),control2:CGPoint(x:55,y:50))
                bag.addQuadCurve(to:CGPoint(x:12,y:61),control:CGPoint(x:30,y:67))
                bag.addCurve(to:CGPoint(x:13,y:11),control1:CGPoint(x:3,y:45),control2:CGPoint(x:18,y:25));bag.closeSubpath()
                ToyFinish.paint(c,path:bag,color:Color(red:1,green:0.88,blue:0.6),edge:1.5)
                c.fill(Path(ellipseIn:CGRect(x:19,y:29,width:22,height:24)),with:.color(.white.opacity(0.8)))
                var wheat=Path();wheat.move(to:CGPoint(x:30,y:47));wheat.addLine(to:CGPoint(x:30,y:34))
                c.stroke(wheat,with:.color(.orange),lineWidth:2)
                for i in 0..<3 {c.fill(Path(ellipseIn:CGRect(x:25+CGFloat(i%2)*5,y:34+CGFloat(i)*4,width:6,height:3)),with:.color(.orange))}
            } else if kind == 1 {
                let body=Path(roundedRect:CGRect(x:8,y:20,width:34,height:40),cornerRadius:9)
                ToyFinish.paint(c,path:body,color:Color(red:0.49,green:0.84,blue:0.95),edge:1.5)
                c.stroke(Path(ellipseIn:CGRect(x:34,y:27,width:19,height:23)),with:.color(Color.cyan),lineWidth:5)
                c.fill(Path(ellipseIn:CGRect(x:9,y:17,width:32,height:10)),with:.color(Color(red:0.16,green:0.59,blue:0.78)))
                c.fill(Path(roundedRect:CGRect(x:14,y:38,width:20,height:12),cornerRadius:5),with:.color(Color.cyan.opacity(0.65)))
            } else {
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:15,y:24,width:30,height:39),cornerRadius:10),color:Color(red:0.48,green:0.67,blue:0.22),edge:1.5)
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:23,y:9,width:14,height:23),cornerRadius:4),color:Color(red:0.35,green:0.53,blue:0.2),edge:1)
                c.fill(Path(roundedRect:CGRect(x:20,y:38,width:20,height:14),cornerRadius:4),with:.color(Color(red:1,green:0.88,blue:0.42)))
            }
        }.accessibilityHidden(true)
    }
}


struct PizzaToppingArt:View {
    let kind:PizzaToppingKind
    var body:some View {
        Canvas {c,s in
            c.translateBy(x:s.width/2,y:s.height/2)
            let scale=min(s.width,s.height)/29
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
                let a=Double(i)*Double.pi/8,r:CGFloat=i%2 == 0 ? 10 : 9.3
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
                let angle=Double(i)*Double.pi/3
                let center=CGPoint(x:s.width/2+CGFloat(cos(angle))*s.width*0.27,
                    y:s.height/2+CGFloat(sin(angle))*s.height*0.27)
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
        TimelineView(.animation(minimumInterval:1.0/30,paused:reduced)) {timeline in
            let time=reduced ? 0.45 : min(1,timeline.date.timeIntervalSince(started))
            GeometryReader {proxy in
                let size=proxy.size
                ZStack {
                    Canvas {c,s in
                        let spout=CGPoint(x:s.width*0.48,y:s.height*0.30)
                        let bottom=s.height*0.80
                        let color:Color=kind == 0 ? Color(red:1,green:0.96,blue:0.81) : kind == 1 ? .cyan : Color(red:1,green:0.75,blue:0.12)
                        if kind != 0 && time<0.88 {
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
                            c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:radius*2,height:kind == 0 ? radius*1.3 : 7)),
                                with:.color(color.opacity(time>0.85 ? max(0,(1-time)*6) : 0.85)))
                        }
                        for i in 0..<12 {
                            let a=Double(i)*Double.pi/6
                            let radius=CGFloat(12+time*35)
                            let x=s.width*0.51+CGFloat(cos(a))*radius
                            let y=bottom+CGFloat(sin(a))*radius*0.28
                            c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:kind == 0 ? 13 : 5,height:kind == 0 ? 8 : 3)),
                                with:.color(color.opacity((1-time)*0.65)))
                        }
                    }
                    PizzaIngredientArt(kind:kind)
                        .frame(width:min(90,size.width*0.34),height:min(100,size.height*0.52))
                        .rotationEffect(.degrees(reduced ? 35 : 25+min(1,time*4)*40))
                        .position(x:size.width*0.35,y:size.height*0.18)
                }
            }
        }.accessibilityHidden(true)
    }
}

struct PizzaHeatEffects:View {
    let progress:Double
    let reduced:Bool
    var body:some View {
        TimelineView(.animation(minimumInterval:1.0/24,paused:reduced || progress>=1)) {timeline in
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
                        let a=Double(i)*Double.pi/6
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
