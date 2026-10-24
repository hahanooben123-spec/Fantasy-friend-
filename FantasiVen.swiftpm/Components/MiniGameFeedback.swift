import SwiftUI

struct OrchardCatchBurst:View {
    let revision:Int
    let fruit:Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var expanded=false
    @State private var visible=false
    var body:some View {
        ZStack {
            ForEach(0..<7) {i in
                Group {
                    if i == 0 {FruitArtwork(kind:fruit)}
                    else {StarArtwork()}
                }.frame(width:i == 0 ? 36 : 13,height:i == 0 ? 36 : 13)
                    .offset(x:reduced ? 0 : CGFloat(cos(Double(i)*Double.pi*2/7))*(expanded ? 68 : 8),
                            y:reduced ? -20 : CGFloat(sin(Double(i)*Double.pi*2/7))*(expanded ? 58 : 8)-20)
                    .rotationEffect(.degrees(reduced ? 0 : expanded ? Double(i)*19 : 0))
            }
        }.opacity(visible && !expanded ? 1 : 0).allowsHitTesting(false).accessibilityHidden(true)
            .task(id:revision) {
                var transaction=Transaction();transaction.disablesAnimations=true
                withTransaction(transaction) {expanded=false;visible=revision>0}
                guard revision>0 else {return}
                await Task.yield()
                withAnimation(.easeOut(duration:reduced ? 0.25 : 0.65)) {expanded=true}
                do {try await Task.sleep(nanoseconds:700_000_000)} catch {return}
                visible=false
            }
    }
}
struct ShakingFruitCanopy:View {
    let weather:FruitWeather
    let onShake:()->Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @EnvironmentObject private var store:FriendStore
    @State private var shake=0
    @State private var angle=0.0
    var body:some View {
        ZStack {
            FruitCanopy(weather:weather).rotationEffect(.degrees(reduced ? 0 : angle),anchor:.top)
            Color.clear.contentShape(Rectangle())
        }.frame(height:155)
            .contentShape(Rectangle()).onTapGesture {shake+=1;onShake()}
            .accessibilityElement(children:.ignore).accessibilityLabel(store.t("shakeFruitTree"))
            .accessibilityAction {shake+=1;onShake()}
            .task(id:shake) {
                guard shake>0,!reduced else {return}
                for i in 0..<4 {
                    withAnimation(.easeInOut(duration:0.10)) {angle=i.isMultiple(of:2) ? 2 : -2}
                    do {try await Task.sleep(nanoseconds:100_000_000)} catch {angle=0;return}
                }
                withAnimation(.spring(response:0.3,dampingFraction:0.5)) {angle=0}
            }
    }
}
struct MusicalNoteTrail:View {
    let revision:Int
    let row:Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var lifted=false
    var body:some View {
        ZStack {
            ForEach(0..<3) {i in
                ToyGlyph(kind:.music).frame(width:22,height:27)
                    .rotationEffect(.degrees(Double(i-1)*18))
                    .offset(x:CGFloat(i-1)*(lifted ? 30 : 12),y:lifted && !reduced ? -85-CGFloat(i)*12 : -16)
            }
        }.opacity(revision>0 && !lifted ? 1 : 0)
            .allowsHitTesting(false).accessibilityHidden(true)
            .task(id:revision) {
                var transaction=Transaction();transaction.disablesAnimations=true
                withTransaction(transaction) {lifted=false}
                guard revision>0 else {return}
                await Task.yield()
                withAnimation(.easeOut(duration:reduced ? 0.2 : 0.7)) {lifted=true}
            }
    }
}


/// Rendering and catching share these exact scene measurements.
enum OrchardMetrics {
    static func basketWidth(_ size:CGSize)->CGFloat {min(190,max(122,size.width*0.20))}
    static func fruitSize(_ size:CGSize)->CGFloat {min(82,max(52,size.width*0.08))}
    static func friendWidth(_ size:CGSize)->CGFloat {min(285,min(max(145,size.width*0.29),size.height*0.30))}
    static func basketY(_ size:CGSize)->CGFloat {size.height*0.79}
    static func openingY(_ size:CGSize)->CGFloat {basketY(size)-basketWidth(size)*0.07}
}
struct OrchardLanding:Identifiable {
    let id=UUID()
    let drop:AppleDrop
    let born:Double
}
struct OrchardLandingArt:View {
    let landing:OrchardLanding
    let time:Double
    let size:CGSize
    let playerX:Double
    let reduced:Bool
    var body:some View {
        let raw=min(1,max(0,(time-landing.born)/0.42))
        let t=reduced ? 1 : raw*raw*(3-2*raw)
        let start=CGPoint(x:CGFloat(landing.drop.x)*size.width,y:CGFloat(landing.drop.y)*size.height)
        let end=CGPoint(x:CGFloat(playerX)*size.width,y:OrchardMetrics.openingY(size)+12)
        FruitArtwork(kind:landing.drop.fruit)
            .frame(width:OrchardMetrics.fruitSize(size),height:OrchardMetrics.fruitSize(size))
            .scaleEffect(1-CGFloat(t)*0.48)
            .rotationEffect(.degrees(reduced ? 0 : t*20))
            .position(x:start.x+(end.x-start.x)*CGFloat(t),
                y:start.y+(end.y-start.y)*CGFloat(t)-(reduced ? 0 : sin(CGFloat(t)*CGFloat.pi)*16))
            .opacity(raw<1 ? 1 : 0).allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// An original toy basket with a real opening and fruit tucked behind its front lip.
struct OrchardBasket:View {
    var fruits:[Int]=[]
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                Canvas {c,s in
                    c.scaleBy(x:s.width/160,y:s.height/110)
                    var handle=Path();handle.move(to:CGPoint(x:36,y:47))
                    handle.addCurve(to:CGPoint(x:125,y:47),control1:CGPoint(x:25,y:-1),control2:CGPoint(x:134,y:-1))
                    c.stroke(handle,with:.color(Color(red:0.61,green:0.31,blue:0.18)),style:StrokeStyle(lineWidth:10,lineCap:.round))
                    c.stroke(handle.applying(CGAffineTransform(translationX:0,y:-2)),
                        with:.color(StorybookStyle.honey),style:StrokeStyle(lineWidth:4,lineCap:.round))
                    ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:10,y:28,width:140,height:32)),
                        color:Color(red:0.63,green:0.32,blue:0.17),edge:2)
                }
                HStack(spacing:-7) {
                    ForEach(Array(fruits.suffix(5).enumerated()),id:\.offset) {index,fruit in
                        FruitArtwork(kind:fruit).frame(width:proxy.size.width*0.23,height:proxy.size.width*0.23)
                            .rotationEffect(.degrees(Double(index%3-1)*12))
                    }
                }.position(x:proxy.size.width*0.5,y:proxy.size.height*0.39)
                Canvas {c,s in
                    c.scaleBy(x:s.width/160,y:s.height/110)
                    var cup=Path();cup.move(to:CGPoint(x:12,y:44))
                    cup.addQuadCurve(to:CGPoint(x:148,y:44),control:CGPoint(x:80,y:77))
                    cup.addLine(to:CGPoint(x:134,y:94))
                    cup.addQuadCurve(to:CGPoint(x:26,y:94),control:CGPoint(x:80,y:112))
                    cup.closeSubpath()
                    ToyFinish.paint(c,path:cup,color:Color(red:1,green:0.70,blue:0.28),edge:2)
                    var clipped=c;clipped.clip(to:cup)
                    for i in 0..<7 {
                        let x=CGFloat(i)*22+12
                        var weave=Path();weave.move(to:CGPoint(x:x,y:43));weave.addLine(to:CGPoint(x:x+9,y:107))
                        clipped.stroke(weave,with:.color(Color(red:0.70,green:0.36,blue:0.17).opacity(0.3)),lineWidth:4)
                    }
                    for y in [CGFloat(69),84,98] {
                        var weave=Path();weave.move(to:CGPoint(x:15,y:y));weave.addQuadCurve(to:CGPoint(x:145,y:y),control:CGPoint(x:80,y:y+10))
                        clipped.stroke(weave,with:.color(.white.opacity(0.25)),lineWidth:3)
                    }
                    var lip=Path();lip.move(to:CGPoint(x:12,y:44));lip.addQuadCurve(to:CGPoint(x:148,y:44),control:CGPoint(x:80,y:77))
                    c.stroke(lip,with:.color(Color(red:1,green:0.86,blue:0.47)),style:StrokeStyle(lineWidth:7,lineCap:.round))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct OrchardBloom:View {
    let index:Int
    let time:Double
    let active:Bool
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var opened=false
    var body:some View {
        ZStack {
            FlowerArtwork(index:index).frame(width:54,height:65)
                .scaleEffect(opened || reduced ? 1 : 0.12,anchor:.bottom)
                .offset(y:12)
            TimelineView(.animation(minimumInterval:1.0/18,paused:reduced || !active || !index.isMultiple(of:3))) {frame in
                Canvas {c,s in
                    guard index.isMultiple(of:3) else {return}
                    let t=reduced ? 0 : frame.date.timeIntervalSinceReferenceDate+Double(index)*0.7
                    let flutter=reduced ? 1 : 0.55+abs(sin(t*7))*0.45
                    let x=s.width*(0.48+CGFloat(sin(t*0.6))*0.13)
                    let y=s.height*(0.18+CGFloat(sin(t*0.9))*0.04)
                    let color=GameStyle.palette[[1,6,8,3][index%4]]
                    for side in [-1.0,1.0] {
                        var wing=c;wing.translateBy(x:x,y:y);wing.scaleBy(x:CGFloat(side)*CGFloat(flutter),y:1)
                        ToyFinish.paint(wing,path:Path(ellipseIn:CGRect(x:0,y:-9,width:12,height:15)),color:color,edge:0.8)
                        ToyFinish.paint(wing,path:Path(ellipseIn:CGRect(x:0,y:1,width:9,height:10)),color:color,edge:0.8)
                    }
                    c.fill(Path(roundedRect:CGRect(x:x-1,y:y-6,width:2,height:14),cornerRadius:1),with:.color(GameStyle.ink))
                }
            }.opacity(opened ? 1 : 0)
        }.onAppear {withAnimation(reduced ? nil : .spring(response:0.75,dampingFraction:0.6)) {opened=true}}
            .accessibilityHidden(true)
    }
}
