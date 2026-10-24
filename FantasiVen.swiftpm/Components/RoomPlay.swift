import SwiftUI

enum RoomToyKind:String,Codable,CaseIterable,Identifiable {
    case blocks,bubbles,flashlight
    var id:String {rawValue}
    var key:String {"roomToy_"+rawValue}
}
struct RoomPlaything:Identifiable,Codable,Equatable {
    var id=UUID()
    var kind:RoomToyKind
    var x=0.5
    var y=0.78
    var on=true
    var color=0
    var isValid:Bool {x.isFinite && y.isFinite && (0.08...0.92).contains(x) &&
        (0.30...0.92).contains(y) && (0..<16).contains(color)}
    mutating func move(x:Double,y:Double) {
        self.x=min(0.92,max(0.08,x));self.y=min(0.92,max(0.30,y))
    }
}

struct PaintedRoomFurniture:View {
    let kind:Int
    var tint:Int?
    var isOn=true
    var showQuilt=true
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body:some View {
        ZStack {
            if kind == RoomItem.toybox.rawValue {
                RoomCabinetSprite(open:isOn ? 1 : 0)
                    .animation(reduced ? nil : .easeInOut(duration:0.32),value:isOn)
            } else {
                if kind == RoomItem.lamp.rawValue && isOn {
                    Ellipse().fill(RadialGradient(colors:[StorybookStyle.honey.opacity(0.55),.clear],
                        center:.center,startRadius:0,endRadius:65)).offset(y:-13)
                }
                VillageArtwork.image(kind == RoomItem.bed.rawValue ? "RoomBedPainted" : "RoomLampPainted")
                    .resizable().interpolation(.high).scaledToFit()
                if kind == RoomItem.bed.rawValue && showQuilt {
                    GeometryReader {proxy in
                        VillageArtwork.image("RoomQuiltPainted").resizable().scaledToFit()
                            .frame(width:proxy.size.width*0.88,height:proxy.size.height*0.75)
                            .position(x:proxy.size.width*0.5,y:proxy.size.height*0.66)
                    }
                }
            }
        }.colorMultiply(tint.map {GameStyle.mixed(.white,with:GameStyle.palette[$0],amount:0.24)} ?? .white)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct RoomCabinetSprite:View,Animatable {
    var open:Double
    var animatableData:Double {get {open} set {open=newValue}}
    private let doors=[CGRect(x:0.123,y:0.282,width:0.370,height:0.466),
                       CGRect(x:0.506,y:0.282,width:0.370,height:0.466)]
    var body:some View {
        GeometryReader {proxy in
            let s=proxy.size
            ZStack(alignment:.topLeading) {
                RoundedRectangle(cornerRadius:12).fill(StorybookStyle.teal)
                    .frame(width:s.width*0.76,height:s.height*0.48)
                    .position(x:s.width*0.5,y:s.height*0.515)
                VillageArtwork.image("RoomToyCabinetPainted").resizable()
                    .frame(width:s.width,height:s.height)
                    .mask(CabinetMask(doors:doors).fill(style:FillStyle(eoFill:true)))
                ForEach(0..<2) {i in
                    let r=CGRect(x:doors[i].minX*s.width,y:doors[i].minY*s.height,
                        width:doors[i].width*s.width,height:doors[i].height*s.height)
                    VillageArtwork.image("RoomToyCabinetPainted").resizable()
                        .frame(width:s.width,height:s.height).offset(x:-r.minX,y:-r.minY)
                        .frame(width:r.width,height:r.height,alignment:.topLeading).clipped()
                        .rotation3DEffect(.degrees(open*(i == 0 ? -78 : 78)),axis:(x:0,y:1,z:0),
                            anchor:i == 0 ? .leading : .trailing,perspective:0.65)
                        .position(x:r.midX,y:r.midY)
                }
            }
        }
    }
}
private struct CabinetMask:Shape {
    var doors:[CGRect]
    func path(in r:CGRect)->Path {
        var p=Path(r)
        for door in doors {
            p.addRect(CGRect(x:door.minX*r.width,y:door.minY*r.height,
                width:door.width*r.width,height:door.height*r.height))
        }
        return p
    }
}

struct RoomCurtains:View,Animatable {
    var amount:Double
    var animatableData:Double {get {amount} set {amount=newValue}}
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/100,y:s.height/110)
            for side in 0..<2 {
                let width=12+amount*22
                let x:Double=side == 0 ? 17 : 83-width
                let r=CGRect(x:x,y:17,width:width,height:74)
                var p=Path(roundedRect:r,cornerRadius:4)
                p.addEllipse(in:CGRect(x:x,y:80,width:width,height:14))
                c.fill(p,with:.linearGradient(Gradient(colors:[Color(red:0.06,green:0.42,blue:0.43),
                    Color(red:0.36,green:0.72,blue:0.69),StorybookStyle.teal]),
                    startPoint:CGPoint(x:x,y:0),endPoint:CGPoint(x:x+width,y:0)))
                for i in 0..<4 {
                    let xx=x+Double(i+1)*width/5
                    var fold=Path();fold.move(to:CGPoint(x:xx,y:20));fold.addLine(to:CGPoint(x:xx-1,y:89))
                    c.stroke(fold,with:.color(StorybookStyle.cream.opacity(0.2)),lineWidth:1)
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct RoomToyArtwork:View {
    let kind:RoomToyKind
    var color=0
    var body:some View {
        Canvas {c,s in
            c.scaleBy(x:s.width/100,y:s.height/100)
            switch kind {
            case .blocks:
                let box=Path(roundedRect:CGRect(x:20,y:27,width:62,height:62),cornerRadius:10)
                ToyFinish.paint(c,path:box,color:GameStyle.palette[color%16],edge:2)
                c.stroke(Path(roundedRect:CGRect(x:26,y:33,width:50,height:50),cornerRadius:7),
                    with:.color(StorybookStyle.cream.opacity(0.6)),lineWidth:2)
                c.draw(Text("✦").font(.system(size:32,weight:.bold)).foregroundColor(StorybookStyle.cream),
                    at:CGPoint(x:51,y:58))
            case .bubbles:
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:18,y:49,width:35,height:42),cornerRadius:9),
                    color:Color(red:0.92,green:0.35,blue:0.47),edge:2)
                var wand=Path();wand.move(to:CGPoint(x:60,y:88));wand.addLine(to:CGPoint(x:72,y:36))
                c.stroke(wand,with:.color(StorybookStyle.honey),style:StrokeStyle(lineWidth:6,lineCap:.round))
                c.stroke(Path(ellipseIn:CGRect(x:59,y:13,width:28,height:31)),with:.color(StorybookStyle.honey),lineWidth:5)
            case .flashlight:
                var torch=c;torch.translateBy(x:50,y:50);torch.rotate(by:.degrees(-38))
                ToyFinish.paint(torch,path:Path(roundedRect:CGRect(x:-15,y:-9,width:30,height:53),cornerRadius:9),
                    color:StorybookStyle.teal,edge:2)
                ToyFinish.paint(torch,path:Path(roundedRect:CGRect(x:-23,y:-34,width:46,height:32),cornerRadius:9),
                    color:StorybookStyle.honey,edge:2)
                ToyFinish.paint(torch,path:Path(ellipseIn:CGRect(x:-17,y:-36,width:34,height:13)),
                    color:StorybookStyle.cream,edge:1)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct RoomBubblePuff:View {
    let revision:Int
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var started=Date.distantPast
    @State private var visible=false
    var body:some View {
        TimelineView(.animation(minimumInterval:1.0/24,paused:!visible || phase != .active || reduced)) {frame in
            Canvas {c,s in
                let t=reduced ? 0.4 : frame.date.timeIntervalSince(started)
                guard visible,t<2.2 else {return}
                for i in 0..<7 {
                    let x=s.width*(0.2+CGFloat(i%4)*0.18)+CGFloat(sin(t*2+Double(i))*12)
                    let y=s.height*(0.83-CGFloat(t)*0.29)-CGFloat(i%3)*12
                    let radius=CGFloat(7+i%4*4)
                    let r=CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2)
                    c.fill(Path(ellipseIn:r),with:.radialGradient(Gradient(colors:[.clear,.cyan.opacity(0.08),
                        Color.pink.opacity(0.25*(1-t/2.2))]),center:CGPoint(x:x,y:y),startRadius:0,endRadius:radius))
                    c.stroke(Path(ellipseIn:r),with:.color(.white.opacity(0.75*(1-t/2.2))),lineWidth:1.2)
                    c.fill(Path(ellipseIn:CGRect(x:x-radius*0.5,y:y-radius*0.6,width:4,height:3)),with:.color(.white.opacity(0.8)))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
            .task(id:revision) {
                guard revision>0 else {return}
                started=Date();visible=true
                do {try await Task.sleep(nanoseconds:2_250_000_000)} catch {return}
                visible=false
            }
    }
}

struct RoomPlaythingView:View {
    @EnvironmentObject private var store:FriendStore
    let toy:RoomPlaything
    let size:CGSize
    let move:(RoomPlaything,Bool)->Void
    let use:()->Void
    @State private var origin:RoomPlaything?
    @State private var last:RoomPlaything?
    var body:some View {
        RoomToyArtwork(kind:toy.kind,color:toy.color)
            .frame(width:64,height:64).contentShape(Rectangle())
            .position(x:toy.x*size.width,y:toy.y*size.height)
            .onTapGesture(perform:use)
            .gesture(DragGesture(minimumDistance:5,coordinateSpace:.named("friendRoomScene")).onChanged {value in
                if origin == nil {origin=toy}
                guard var changed=origin else {return}
                changed.move(x:changed.x+value.translation.width/max(1,size.width),
                    y:changed.y+value.translation.height/max(1,size.height))
                last=changed;move(changed,false)
            }.onEnded {_ in
                if let last=last {move(last,true)}
                origin=nil;last=nil
            })
            .accessibilityElement(children:.ignore).accessibilityLabel(store.t(toy.kind.key))
            .accessibilityAction {use()}
    }
}
