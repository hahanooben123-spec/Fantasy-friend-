import SwiftUI
import UniformTypeIdentifiers

struct RoomScene:View {
    let friend:FantasyFriend
    let layout:RoomLayout
    let editing:Bool
    let selected:UUID?
    let moving:RoomObject?
    let friendPreview:CGPoint?
    let action:PlayAction
    let signal:Int
    let activeID:UUID?
    let pulse:Int
    let pending:RoomItem?
    let onSelect:(UUID?)->Void
    let onTap:(RoomObject)->Void
    let onMove:(RoomObject,Bool)->Void
    let onFriendMove:(CGPoint,Bool)->Void
    let onDropItem:(RoomItem,CGPoint)->Void
    let toyPreview:RoomPlaything?
    let onSpawnToy:(RoomToyKind,CGPoint)->Void
    let onMoveToy:(RoomPlaything,Bool)->Void
    let onUseToy:(RoomPlaything)->Void
    let onCover:(Double)->Void
    @StateObject private var pumpkins=PumpkinStore()
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var blanketPreview:Double?
    @State private var blanketOrigin:Double?
    @State private var toyPick:RoomToyKind?
    @State private var toyPoint=CGPoint.zero
    @State private var toyDragged=false
    @State private var bubbleRevision=0
    @State private var friendOrigin:CGPoint?
    var body:some View {
        GeometryReader {proxy in
            let size=proxy.size
            ZStack {
                RoomInterior(design:layout.design)
                Color.clear.contentShape(Rectangle()).onTapGesture {onSelect(nil)}
                ForEach(layout.objects) {value in
                    let shown=moving?.id == value.id ? moving! : value
                    RoomPlacedObject(object:shown,roomSize:size,editing:editing,selected:selected == value.id,
                        night:layout.design.night,curtainsClosed:layout.design.curtainsClosed ?? false,
                        showQuilt:editing || layout.design.sleepingBed != value.id,doodles:friend.doodles ?? [],pulse:activeID == value.id ? pulse : 0,
                        onTap:{onTap(value)},onMove:onMove)
                        .zIndex(editing && selected == value.id ? 4000 : Double(shown.level)*1000+shown.y*100)
                }
                if !editing {
                    ForEach(layout.design.playthings ?? []) {toy in
                        RoomPlaythingView(toy:toyPreview?.id == toy.id ? toyPreview! : toy,size:size,
                            move:onMoveToy,use:{
                                if toy.kind == .bubbles {bubbleRevision += 1;SoundService.shared.play(.bubble)}
                                onUseToy(toy)
                            }).zIndex(2100+toy.y*100)
                    }
                    if let bed=layout.objects.first(where:{$0.id == layout.design.sleepingBed}) {
                        sleepingFriend(bed,size:size).zIndex(2300)
                    }
                }
                ForEach(Array(pumpkins.lanterns.prefix(2).enumerated()),id:\.element.id) {i,lantern in
                    PumpkinIllustration(lantern:lantern,animated:false).frame(width:48,height:52)
                        .position(x:size.width*(0.90-Double(i)*0.075),y:size.height*0.62)
                        .allowsHitTesting(false).zIndex(100)
                }
                GestureLesson(activity:pulse+(selected == nil ? 0 : 1),from:UnitPoint(x:0.25,y:0.65),to:UnitPoint(x:0.4,y:0.6)).zIndex(4500)
                if editing || layout.design.sleepingBed == nil ||
                    !layout.objects.contains(where:{$0.id == layout.design.sleepingBed}) {
                companion(size)
                    .zIndex(1000+Double(friendPreview?.y ?? CGFloat(layout.design.friendY))*100)
                }
                if layout.design.night || layout.design.curtainsClosed == true {
                    Color(red:0.08,green:0.06,blue:0.22).opacity(layout.design.night ? 0.43 : 0.13).allowsHitTesting(false).zIndex(5000)
                    lamplight(size).allowsHitTesting(false).zIndex(5001)
                }
                if !editing {
                    flashlight(size).allowsHitTesting(false).zIndex(5002)
                    RoomBubblePuff(revision:bubbleRevision).zIndex(5100)
                    if let cabinet=layout.objects.first(where:{$0.kind == RoomItem.toybox.rawValue && $0.isOn}) {
                        cabinetToys(cabinet,size:size).zIndex(5500)
                    }
                    if let kind=toyPick {
                        RoomToyArtwork(kind:kind).frame(width:64,height:64)
                            .position(toyPoint).allowsHitTesting(false).zIndex(6000)
                    }
                }
            }.frame(width:size.width,height:size.height)
                .coordinateSpace(name:"friendRoomScene").clipped()
                .onAppear {pumpkins.reload()}
                .task(id:toyPick == nil && toyDragged) {
                    guard toyPick == nil,toyDragged else {return}
                    do {try await Task.sleep(nanoseconds:220_000_000)} catch {return}
                    toyDragged=false
                }
                .onDrop(of:[UTType.text.identifier],isTargeted:nil) {_,point in
                    guard editing,let item=pending else {return false}
                    onDropItem(item,CGPoint(x:point.x/max(1,size.width),y:point.y/max(1,size.height)));return true
                }
        }
    }
    private func sleepingFriend(_ bed:RoomObject,size:CGSize)->some View {
        let width=min(155,max(76,size.width*0.2))*RoomItem.bed.widthFactor*bed.sizeFactor
        let cover=blanketPreview ?? layout.design.blanket ?? 0.25
        return ZStack {
            LivingFriend(friend:friend,action:.sleep,signal:max(1,signal),audible:false)
                .frame(width:width*0.60,height:width*0.64).rotationEffect(.degrees(-8))
                .offset(y:-width*0.08).allowsHitTesting(false)
            VillageArtwork.image("RoomQuiltPainted").resizable().scaledToFit()
                .frame(width:width*0.90,height:width*0.90)
                .offset(y:width*(0.32-cover*0.28))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:2).onChanged {value in
                    if blanketOrigin == nil {blanketOrigin=cover}
                    blanketPreview=min(1,max(0,(blanketOrigin ?? cover)-value.translation.height/max(30,width*0.35)))
                }.onEnded {_ in
                    onCover(blanketPreview ?? cover);blanketPreview=nil;blanketOrigin=nil
                })
                .accessibilityLabel(store.t("roomPullQuilt"))
                .accessibilityAdjustableAction {direction in onCover(min(1,max(0,cover+(direction == .increment ? 0.2 : -0.2))))}
        }.frame(width:width,height:width*1.1)
            .rotationEffect(.degrees(bed.angle))
            .position(x:bed.x*size.width,y:bed.y*size.height)
    }
    private func cabinetToys(_ cabinet:RoomObject,size:CGSize)->some View {
        HStack(spacing:8) {
            ForEach(RoomToyKind.allCases) {kind in
                Button {if !toyDragged {onSpawnToy(kind,CGPoint(x:cabinet.x,y:min(0.88,cabinet.y+0.12)))}} label:{
                    VStack(spacing:2) {
                        RoomToyArtwork(kind:kind).frame(width:48,height:48)
                        Text(store.t(kind.key)).font(.system(size:10,weight:.heavy,design:.rounded)).lineLimit(1)
                    }.frame(width:68,height:70).background(StorybookPanel(cornerRadius:18))
                }.buttonStyle(SquishStyle())
                    .simultaneousGesture(DragGesture(minimumDistance:8,coordinateSpace:.named("friendRoomScene")).onChanged {value in
                        toyDragged=true;toyPick=kind;toyPoint=value.location
                    }.onEnded {value in
                        guard toyPick != nil else {return}
                        toyPick=nil
                        onSpawnToy(kind,CGPoint(x:value.location.x/max(1,size.width),y:value.location.y/max(1,size.height)))
                    })
            }
        }.position(x:min(size.width-116,max(116,cabinet.x*size.width)),
            y:min(size.height-42,max(65,cabinet.y*size.height-90)))
    }
    private func flashlight(_ size:CGSize)->some View {
        Canvas {c,_ in
            for original in layout.design.playthings ?? [] where original.kind == .flashlight && original.on {
                let toy=toyPreview?.id == original.id ? toyPreview! : original
                let point=CGPoint(x:toy.x*size.width,y:toy.y*size.height)
                let target=CGPoint(x:point.x+85,y:point.y-135)
                var beam=Path();beam.move(to:point)
                beam.addLine(to:CGPoint(x:target.x-65,y:target.y-30))
                beam.addQuadCurve(to:CGPoint(x:target.x+65,y:target.y+30),control:CGPoint(x:target.x+90,y:target.y-60))
                beam.closeSubpath()
                c.fill(beam,with:.linearGradient(Gradient(colors:[StorybookStyle.cream.opacity(0.45),.yellow.opacity(0.03)]),
                    startPoint:point,endPoint:target))
                c.fill(Path(ellipseIn:CGRect(x:target.x-70,y:target.y-60,width:140,height:120)),
                    with:.radialGradient(Gradient(colors:[StorybookStyle.cream.opacity(0.36),.clear]),
                        center:target,startRadius:0,endRadius:70))
            }
        }.blendMode(.screen)
    }
    private func companion(_ size:CGSize)->some View {
        let point=friendPreview ?? CGPoint(x:layout.design.friendX,y:layout.design.friendY)
        let width=min(205,max(100,size.width*0.27))
        return LivingFriend(friend:friend,action:action,signal:signal,locomotion:friendPreview == nil ? 0 : 0.65)
            .frame(width:width,height:width*320/300)
            .position(x:point.x*size.width,y:point.y*size.height)
            .simultaneousGesture(DragGesture(minimumDistance:5,coordinateSpace:.named("friendRoomScene")).onChanged {value in
                onSelect(nil)
                if friendOrigin == nil {friendOrigin=point}
                guard let start=friendOrigin else {return}
                let moved=CGPoint(x:min(0.9,max(0.1,start.x+value.translation.width/max(1,size.width))),
                    y:min(0.9,max(0.2,start.y+value.translation.height/max(1,size.height))))
                onFriendMove(moved,false)
            }.onEnded {value in
                let start=friendOrigin ?? point
                let moved=CGPoint(x:min(0.9,max(0.1,start.x+value.translation.width/max(1,size.width))),
                    y:min(0.9,max(0.2,start.y+value.translation.height/max(1,size.height))))
                onFriendMove(moved,true);friendOrigin=nil
            })
    }
    private func lamplight(_ size:CGSize)->some View {
        Canvas {c,_ in
            for item in layout.objects where item.kind == RoomItem.lamp.rawValue && item.isOn {
                let center=CGPoint(x:item.x*size.width,y:item.y*size.height-20)
                let radius=min(180,max(80,size.width*0.25))*item.sizeFactor
                c.fill(Path(ellipseIn:CGRect(x:center.x-radius,y:center.y-radius,width:radius*2,height:radius*2)),
                    with:.radialGradient(Gradient(colors:[Color(red:1,green:0.81,blue:0.39).opacity(0.37),.clear]),
                    center:center,startRadius:0,endRadius:radius))
            }
        }.blendMode(.screen)
    }
}
private struct RoomPlacedObject:View {
    let object:RoomObject
    let roomSize:CGSize
    let editing:Bool
    let selected:Bool
    let night:Bool
    var curtainsClosed=false
    var showQuilt=true
    var doodles:[DoodleStroke]=[]
    let pulse:Int
    let onTap:()->Void
    let onMove:(RoomObject,Bool)->Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @EnvironmentObject private var words:FriendStore
    @State private var origin:RoomObject?
    @State private var gestureValue:RoomObject?
    @State private var lifted=false
    private var width:CGFloat {
        let ratio=RoomItem(rawValue:object.kind)?.widthFactor ?? 1
        return min(155,max(76,roomSize.width*0.2))*ratio*object.sizeFactor
    }
    var body:some View {
        ZStack {
            if RoomItem(rawValue:object.kind)?.isWall != true && object.kind != 4 {
                Ellipse().fill(GameStyle.ink.opacity(0.14))
                    .frame(width:width*0.75,height:width*0.10).blur(radius:3).offset(y:width*0.43)
                    .allowsHitTesting(false)
            }
            RoomFurniture(kind:object.kind,tint:object.color,isOn:object.isOn,night:night,
                curtainsClosed:curtainsClosed,showQuilt:showQuilt)
                .overlay {
                    if object.kind == RoomItem.picture.rawValue && !doodles.isEmpty {
                        Canvas {c,s in
                            for stroke in doodles {
                                guard let first=stroke.points.first else {continue}
                                var line=Path();line.move(to:CGPoint(x:first.x*s.width,y:first.y*s.height))
                                for p in stroke.points.dropFirst() {line.addLine(to:CGPoint(x:p.x*s.width,y:p.y*s.height))}
                                c.stroke(line,with:.color(GameStyle.palette[stroke.color]),
                                    style:StrokeStyle(lineWidth:max(1,stroke.width*s.width/300),lineCap:.round))
                            }
                        }.padding(width*0.20).allowsHitTesting(false)
                    }
                }
                .scaleEffect(x:object.mirrored == true ? -1 : 1,y:1)
                .offset(y:lifted && !reduced ? (object.kind == 13 ? -28 : -5) : 0)
                .rotationEffect(.degrees(lifted && !reduced && object.kind != 13 ? 5 : 0))
            if editing && selected {
                RoundedRectangle(cornerRadius:18).stroke(.white,style:StrokeStyle(lineWidth:2.5,dash:[6,4]))
                    .shadow(color:GameStyle.purple,radius:1).allowsHitTesting(false)
            }
        }.frame(width:width,height:width*1.1)
            .rotationEffect(.degrees(object.angle))
            .contentShape(Rectangle())
            .position(x:object.x*roomSize.width,y:object.y*roomSize.height)
            .onTapGesture(perform:onTap)
            .gesture(DragGesture(minimumDistance:5,coordinateSpace:.named("friendRoomScene")).onChanged {event in
                guard editing || object.kind == RoomItem.ball.rawValue else {return}
                if origin == nil {origin=object}
                guard var next=origin else {return}
                next.move(x:next.x+Double(event.translation.width/max(1,roomSize.width)),
                    y:next.y+Double(event.translation.height/max(1,roomSize.height)))
                gestureValue=next;onMove(next,false)
            }.onEnded {event in
                if var next=gestureValue {
                    if object.kind == RoomItem.ball.rawValue {
                        let dx=Double((event.predictedEndTranslation.width-event.translation.width)/max(1,roomSize.width))*0.45
                        let dy=Double((event.predictedEndTranslation.height-event.translation.height)/max(1,roomSize.height))*0.45
                        next.move(x:next.x+dx,y:next.y+dy)
                        withAnimation(reduced ? nil : .interpolatingSpring(stiffness:130,damping:11)) {onMove(next,true)}
                        SoundService.shared.play(.bounce)
                    } else {onMove(next,true)}
                }
                origin=nil;gestureValue=nil
            })
            .accessibilityElement(children:.ignore)
            .accessibilityLabel(words.t("furniture_\(object.kind)"))
            .accessibilityAction {onTap()}
            .accessibilityAdjustableAction {direction in
                guard editing else {return}
                var next=object;next.scale=min(1.6,max(0.6,next.sizeFactor+(direction == .increment ? 0.1 : -0.1)))
                onMove(next,true)
            }
            .task(id:pulse) {
                guard pulse>0,!reduced else {return}
                withAnimation(.spring(response:0.3,dampingFraction:0.5)) {lifted=true}
                do {try await Task.sleep(nanoseconds:260_000_000)} catch {lifted=false;return}
                withAnimation(.spring(response:0.5,dampingFraction:0.45)) {lifted=false}
            }
    }

}

struct RoomSurfaceFrameKey:PreferenceKey {
    static let defaultValue=CGRect.zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect) {
        let next=nextValue();if next.width>0 && next.height>0 {value=next}
    }
}
