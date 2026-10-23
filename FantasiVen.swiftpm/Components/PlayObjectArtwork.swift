import SwiftUI

struct FruitArtwork:View {
    var kind=0
    var golden=false
    var body:some View {
        Group {
            if golden {StarArtwork()}
            else if kind == 0 {AppleToy()}
            else {
                Canvas {c,s in
                    c.scaleBy(x:s.width/100,y:s.height/100)
                    if kind == 1 {
                        var peel=Path();peel.move(to:CGPoint(x:20,y:23))
                        peel.addCurve(to:CGPoint(x:81,y:29),control1:CGPoint(x:20,y:76),control2:CGPoint(x:70,y:79))
                        peel.addCurve(to:CGPoint(x:16,y:82),control1:CGPoint(x:99,y:82),control2:CGPoint(x:40,y:107))
                        peel.addQuadCurve(to:CGPoint(x:20,y:23),control:CGPoint(x:3,y:55));peel.closeSubpath()
                        ToyFinish.paint(c,path:peel,color:Color(red:1,green:0.8,blue:0.12),edge:2)
                        var seam=Path();seam.move(to:CGPoint(x:20,y:37))
                        seam.addQuadCurve(to:CGPoint(x:73,y:51),control:CGPoint(x:29,y:85))
                        c.stroke(seam,with:.color(Color(red:0.78,green:0.46,blue:0.10)),style:StrokeStyle(lineWidth:2,lineCap:.round))
                        ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:14,y:16,width:10,height:13),cornerRadius:3),color:Color(red:0.47,green:0.31,blue:0.18))
                    } else {
                        for i in 0..<4 {
                            let x=CGFloat([20,49,13,48][i]),y=CGFloat([20,23,48,52][i])
                            ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:x,y:y,width:37,height:36)),
                                color:Color(red:0.28+Double(i%2)*0.10,green:0.32,blue:0.79),edge:1.3)
                            var crown=Path();crown.move(to:CGPoint(x:x+12,y:y+12))
                            for j in 0..<10 {
                                let a=Double(j)*Double.pi/5,r:CGFloat=j%2 == 0 ? 6 : 3
                                crown.addLine(to:CGPoint(x:x+18+CGFloat(cos(a))*r,y:y+12+CGFloat(sin(a))*r))
                            }
                            crown.closeSubpath();c.fill(crown,with:.color(Color(red:0.14,green:0.18,blue:0.46)))
                            c.fill(Path(ellipseIn:CGRect(x:x+7,y:y+8,width:7,height:4)),with:.color(.white.opacity(0.5)))
                        }
                    }
                }
            }
        }.aspectRatio(1,contentMode:.fit).accessibilityHidden(true)
    }
}
struct StarArtwork:View {
    var body:some View {
        Canvas {c,s in
            let scale=min(s.width,s.height)/100
            c.translateBy(x:s.width/2,y:s.height/2);c.scaleBy(x:scale,y:scale)
            var star=Path()
            for i in 0..<10 {
                let a=Double(i)*Double.pi/5-Double.pi/2,r:CGFloat=i%2 == 0 ? 44 : 23
                let p=CGPoint(x:CGFloat(cos(a))*r,y:CGFloat(sin(a))*r)
                if i == 0 {star.move(to:p)} else {star.addLine(to:p)}
            }
            star.closeSubpath()
            ToyFinish.paint(c,path:star,color:Color(red:1,green:0.78,blue:0.1),edge:2)
            c.fill(Path(ellipseIn:CGRect(x:-15,y:-23,width:13,height:7)),with:.color(.white.opacity(0.65)))
        }.accessibilityHidden(true)
    }
}
struct FlowerArtwork:View {
    var index=0
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/80,y:s.height/90)
            var stem=Path();stem.move(to:CGPoint(x:40,y:78));stem.addQuadCurve(to:CGPoint(x:40,y:36),control:CGPoint(x:47,y:57))
            c.stroke(stem,with:.color(Color(red:0.2,green:0.55,blue:0.15)),style:StrokeStyle(lineWidth:5,lineCap:.round))
            for i in 0..<6 {
                let a=Double(i)*Double.pi/3
                ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:29+cos(a)*17,y:22+sin(a)*17,width:23,height:24)),
                    color:GameStyle.palette[[1,3,8][index%3]],edge:0.8)
            }
            ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:30,y:23,width:22,height:22)),color:.yellow,edge:1)
        }.accessibilityHidden(true)
    }
}

struct InstrumentArtwork:View {
    let row:Int
    var lit=false
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/180,y:s.height/130)
            if row == 0 {
                for x in [CGFloat(40),140] {
                    var leg=Path();leg.move(to:CGPoint(x:x,y:81));leg.addLine(to:CGPoint(x:x-8,y:119))
                    c.stroke(leg,with:.color(WorkshopLook.sea),style:StrokeStyle(lineWidth:7,lineCap:.round))
                }
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:25,y:42,width:130,height:61),cornerRadius:20),
                    color:Color(red:0.92,green:0.28,blue:0.23),edge:2)
                for i in 0..<5 {
                    var rope=Path();rope.move(to:CGPoint(x:35+CGFloat(i)*26,y:52))
                    rope.addLine(to:CGPoint(x:48+CGFloat(i)*24,y:91))
                    c.stroke(rope,with:.color(WorkshopLook.cream),lineWidth:3)
                }
                ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:21,y:22,width:138,height:51)),
                    color:lit ? .white : Color(red:1,green:0.88,blue:0.57),edge:2)
                c.stroke(Path(ellipseIn:CGRect(x:29,y:29,width:122,height:36)),with:.color(Color.orange.opacity(0.4)),lineWidth:2)
                for i in 0..<2 {
                    var stick=Path();stick.move(to:CGPoint(x:18+CGFloat(i)*141,y:11));stick.addLine(to:CGPoint(x:67+CGFloat(i)*46,y:42))
                    c.stroke(stick,with:.color(Color(red:0.58,green:0.30,blue:0.15)),style:StrokeStyle(lineWidth:7,lineCap:.round))
                }
            } else if row == 1 {
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:10,y:38,width:160,height:72),cornerRadius:16),color:WorkshopLook.sea,edge:2)
                for i in 0..<5 {
                    let h=CGFloat(71-i*7),x=CGFloat(i)*29+17
                    ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:x,y:63-h/2,width:25,height:h),cornerRadius:7),
                        color:GameStyle.palette[[1,3,5,6,8][i]],edge:1)
                    c.fill(Path(ellipseIn:CGRect(x:x+10,y:58,width:5,height:5)),with:.color(.white.opacity(0.8)))
                }
            } else {
                ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:50,y:108,width:80,height:14)),color:WorkshopLook.sea,edge:1)
                var stand=Path();stand.move(to:CGPoint(x:90,y:116));stand.addLine(to:CGPoint(x:90,y:61))
                c.stroke(stand,with:.color(WorkshopLook.sea),style:StrokeStyle(lineWidth:9,lineCap:.round))
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:65,y:15,width:50,height:66),cornerRadius:24),
                    color:lit ? .yellow : Color(red:0.16,green:0.72,blue:0.79),edge:2)
                for i in 0..<5 {
                    var grill=Path();grill.move(to:CGPoint(x:74,y:28+CGFloat(i)*8));grill.addLine(to:CGPoint(x:106,y:28+CGFloat(i)*8))
                    c.stroke(grill,with:.color(WorkshopLook.sea.opacity(0.5)),style:StrokeStyle(lineWidth:2,lineCap:.round))
                }
                var cradle=Path();cradle.move(to:CGPoint(x:55,y:48));cradle.addCurve(to:CGPoint(x:125,y:48),
                    control1:CGPoint(x:48,y:102),control2:CGPoint(x:130,y:102))
                c.stroke(cradle,with:.color(Color(red:1,green:0.77,blue:0.12)),style:StrokeStyle(lineWidth:6,lineCap:.round))
            }
        }.accessibilityHidden(true)
    }
}
struct PlayableInstrument:View {
    @EnvironmentObject private var store:FriendStore
    let row:Int
    let signal:Int
    var strike:(Int)->Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var lastNote:Int?
    @State private var lastStroke=0.0
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                InstrumentArtwork(row:row,lit:!signal.isMultiple(of:2))
                    .scaleEffect(reduced || signal.isMultiple(of:2) ? 1 : 1.045)
                    .animation(reduced ? nil : .spring(response:0.2,dampingFraction:0.5),value:signal)
                    .allowsHitTesting(false)
                HStack(spacing:0) {
                    ForEach(0..<(row == 1 ? 5 : 1),id:\.self) {note in
                        Button {strike(note)} label:{
                            Color.clear.frame(maxWidth:.infinity,maxHeight:.infinity).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .accessibilityLabel(store.t("instrument_\(row)")+" \(note+1)")
                    }
                }
            }.contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance:7).onChanged {value in
                    let now=ProcessInfo.processInfo.systemUptime
                    let note=min(4,max(0,Int(value.location.x/max(1,proxy.size.width)*5)))
                    guard now-lastStroke>0.09,(row == 0 || note != lastNote) else {return}
                    lastStroke=now;lastNote=note;strike(row == 0 ? 0 : note)
                }.onEnded {_ in lastNote=nil})
        }.frame(height:140)
    }
}
struct PicnicBlanket:View {
    var body:some View {
        Canvas {c,s in
            let cloth=Path(roundedRect:CGRect(origin:.zero,size:s),cornerRadius:28)
            c.fill(cloth,with:.color(WorkshopLook.cream));c.clip(to:cloth)
            for row in 0..<12 {
                for col in 0..<14 where (row+col)%2 == 0 {
                    c.fill(Path(CGRect(x:CGFloat(col)*30,y:CGFloat(row)*30,width:30,height:30)),
                        with:.color(Color(red:0.96,green:0.35,blue:0.3).opacity(0.28)))
                }
            }
            c.stroke(cloth,with:.color(.white.opacity(0.8)),lineWidth:5)
        }.allowsHitTesting(false)
    }
}
struct FruitDelivery:View {
    let kind:Int
    let revision:Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var arrived=false
    @State private var visible=true
    var body:some View {
        GeometryReader {proxy in
            FruitArtwork(kind:kind).frame(width:65,height:65)
                .scaleEffect(reduced ? 1 : arrived ? 0.15 : 1)
                .position(x:proxy.size.width/2,y:proxy.size.height*(arrived ? 0.25 : 0.68))
                .opacity(visible ? 1 : 0)
        }.task(id:revision) {
            var transaction=Transaction();transaction.disablesAnimations=true
            withTransaction(transaction) {arrived=false;visible=true}
            await Task.yield()
            withAnimation(reduced ? nil : .easeInOut(duration:0.6)) {arrived=true}
            do {try await Task.sleep(nanoseconds:600_000_000)} catch {return}
            visible=false
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}


struct ConcertBackdrop:View {
    var body:some View {
        Canvas {c,s in
            c.fill(Path(CGRect(origin:.zero,size:s)),with:.linearGradient(Gradient(colors:[
                Color(red:0.13,green:0.12,blue:0.35),Color(red:0.43,green:0.22,blue:0.64)]),startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)))
            for i in 0..<3 {
                let x=s.width*(0.18+CGFloat(i)*0.32)
                var beam=Path();beam.move(to:CGPoint(x:x,y:0))
                beam.addLine(to:CGPoint(x:x-s.width*0.19,y:s.height*0.8))
                beam.addLine(to:CGPoint(x:x+s.width*0.19,y:s.height*0.8));beam.closeSubpath()
                c.fill(beam,with:.linearGradient(Gradient(colors:[GameStyle.palette[[3,6,1][i]].opacity(0.28),.clear]),
                    startPoint:CGPoint(x:x,y:0),endPoint:CGPoint(x:x,y:s.height*0.8)))
            }
            for i in 0..<24 {
                let x=CGFloat((i*71)%997)/997*s.width,y=CGFloat((i*47)%491)/491*s.height*0.65
                c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:3,height:3)),with:.color(.white.opacity(0.55)))
            }
            let stage=CGRect(x:-20,y:s.height*0.65,width:s.width+40,height:s.height*0.5)
            c.fill(Path(stage),with:.linearGradient(Gradient(colors:[Color(red:0.48,green:0.31,blue:0.55),Color(red:0.17,green:0.15,blue:0.30)]),
                startPoint:CGPoint(x:0,y:stage.minY),endPoint:CGPoint(x:0,y:s.height)))
            for i in 0..<12 {
                let x=CGFloat(i)*s.width/11
                var plank=Path();plank.move(to:CGPoint(x:s.width/2+(x-s.width/2)*0.6,y:stage.minY))
                plank.addLine(to:CGPoint(x:x,y:s.height))
                c.stroke(plank,with:.color(.white.opacity(0.12)),lineWidth:2)
            }
        }.storybookScene(night:true,lamps:true).ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}


struct PlayControlArtwork:View {
    let symbol:String
    var body:some View {
        Group {
            switch symbol {
            case "🧺":BasketToy().scaleEffect(0.34).frame(width:38,height:38)
            case "🫧":BubbleToy(color:.cyan).padding(3)
            case "🌼","🌸","🌷":FlowerArtwork()
            case "⭐️","🌟","✨","💡":StarArtwork().padding(3)
            case "🎵","🎶","🎼":ToyGlyph(kind:.music)
            case "❤️","♥","♡":ToyGlyph(kind:.heart)
            case "🌙":ToyGlyph(kind:.moon)
            case "🖌️","✏️","🛠️":ToyGlyph(kind:.brush)
            case "⚽️":RoomFurniture(kind:RoomItem.ball.rawValue)
            case "🧊":RoomFurniture(kind:RoomItem.toybox.rawValue)
            case "🎈":BalloonArtwork()
            case "☁️":CloudArtwork()
            case "🍊":PumpkinIllustration(lantern:PumpkinDoor.sample,animated:false)
            default:
                Image(systemName:systemIcon).font(.system(size:29,weight:.heavy))
                    .foregroundColor(WorkshopLook.sea)
            }
        }.accessibilityHidden(true)
    }
    private var systemIcon:String {
        switch symbol {
        case "▶️":return "play.fill"
        case "⏸️":return "pause.fill"
        case "🔴":return "record.circle.fill"
        case "🎲":return "shuffle"
        case "🌈":return "arrow.triangle.merge"
        case "🚀":return "arrow.up"
        case "↔️":return "arrow.up.left.and.arrow.down.right"
        case "✂️":return "scissors"
        case "🥄":return "drop.fill"
        case "🕯️":return "flame.fill"
        case "✋":return "hand.draw.fill"
        case "🔺":return "triangle.fill"
        case "😊":return "face.smiling.fill"
        case "🗺️":return "map.fill"
        case "🙈":return "eye.slash.fill"
        default:return "sparkles"
        }
    }
}
struct BalloonArtwork:View {
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/80,y:s.height/100)
            var string=Path();string.move(to:CGPoint(x:40,y:65))
            string.addCurve(to:CGPoint(x:38,y:97),control1:CGPoint(x:59,y:77),control2:CGPoint(x:23,y:87))
            c.stroke(string,with:.color(WorkshopLook.sea.opacity(0.6)),lineWidth:2)
            ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:14,y:5,width:52,height:63)),color:GameStyle.palette[1],edge:1.5)
            c.fill(Path(ellipseIn:CGRect(x:25,y:16,width:9,height:17)),with:.color(.white.opacity(0.7)))
        }.accessibilityHidden(true)
    }
}
struct CloudArtwork:View {
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/100,y:s.height/80)
            var cloud=Path()
            cloud.addEllipse(in:CGRect(x:9,y:29,width:42,height:35))
            cloud.addEllipse(in:CGRect(x:29,y:14,width:45,height:50))
            cloud.addEllipse(in:CGRect(x:57,y:30,width:35,height:34))
            ToyFinish.paint(c,path:cloud,color:Color(red:0.91,green:0.96,blue:1),edge:1)
        }.accessibilityHidden(true)
    }
}
