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
                        night:layout.design.night,pulse:activeID == value.id ? pulse : 0,
                        onTap:{onTap(value)},onMove:onMove)
                        .zIndex(editing && selected == value.id ? 4000 : Double(shown.level)*1000+shown.y*100)
                }
                companion(size)
                    .zIndex(1000+Double(friendPreview?.y ?? CGFloat(layout.design.friendY))*100)
                if layout.design.night {
                    Color(red:0.08,green:0.06,blue:0.22).opacity(0.43).allowsHitTesting(false).zIndex(5000)
                    lamplight(size).allowsHitTesting(false).zIndex(5001)
                }
            }.frame(width:size.width,height:size.height)
                .coordinateSpace(name:"friendRoomScene").clipped()
                .onDrop(of:[UTType.text.identifier],isTargeted:nil) {_,point in
                    guard editing,let item=pending else {return false}
                    onDropItem(item,CGPoint(x:point.x/max(1,size.width),y:point.y/max(1,size.height)));return true
                }
        }
    }
    private func companion(_ size:CGSize)->some View {
        let point=friendPreview ?? CGPoint(x:layout.design.friendX,y:layout.design.friendY)
        let width=min(205,max(100,size.width*0.27))
        return LivingFriend(friend:friend,action:action,signal:signal)
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
    let pulse:Int
    let onTap:()->Void
    let onMove:(RoomObject,Bool)->Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @EnvironmentObject private var words:FriendStore
    @State private var origin:RoomObject?
    @State private var gestureValue:RoomObject?
    @State private var lifted=false
    @State private var resizeOrigin:RoomObject?
    @State private var resizeWidth:CGFloat=1
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
            RoomFurniture(kind:object.kind,tint:object.color,isOn:object.isOn,night:night)
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
            .overlay(alignment:.bottomTrailing) {
                if editing && selected {resizeHandle.offset(x:6,y:6)}
            }
            .overlay(alignment:.topTrailing) {
                if editing && selected {turnHandle.offset(x:6,y:-6)}
            }
            .position(x:object.x*roomSize.width,y:object.y*roomSize.height)
            .onTapGesture(perform:onTap)
            .gesture(DragGesture(minimumDistance:5,coordinateSpace:.named("friendRoomScene")).onChanged {event in
                guard editing else {return}
                if origin == nil {origin=object}
                guard var next=origin else {return}
                next.move(x:next.x+Double(event.translation.width/max(1,roomSize.width)),
                    y:next.y+Double(event.translation.height/max(1,roomSize.height)))
                gestureValue=next;onMove(next,false)
            }.onEnded {_ in
                if let next=gestureValue {onMove(next,true)}
                origin=nil;gestureValue=nil
            })
            .simultaneousGesture(MagnificationGesture().onChanged {factor in
                guard editing else {return}
                if origin == nil {origin=object}
                guard var next=origin else {return}
                next.scale=min(1.6,max(0.6,next.sizeFactor*Double(factor)))
                gestureValue=next;onMove(next,false)
            }.onEnded {_ in
                if let next=gestureValue {onMove(next,true)}
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

    private var resizeHandle:some View {
        Image(systemName:"arrow.up.left.and.arrow.down.right").font(.system(size:21,weight:.heavy))
            .foregroundColor(GameStyle.ink).frame(width:48,height:48)
            .background(Circle().fill(WorkshopLook.yellow)).overlay(Circle().stroke(.white,lineWidth:3))
            .shadow(color:GameStyle.ink.opacity(0.2),radius:4,y:3)
            .highPriorityGesture(DragGesture().onChanged {value in
                if resizeOrigin == nil {resizeOrigin=object;resizeWidth=width}
                guard var next=resizeOrigin else {return}
                let delta=Double((value.translation.width+value.translation.height)/max(50,resizeWidth))
                next.scale=min(1.6,max(0.6,next.sizeFactor*(1+delta)))
                gestureValue=next;onMove(next,false)
            }.onEnded {_ in
                if let next=gestureValue {onMove(next,true)}
                resizeOrigin=nil;gestureValue=nil
            })
            .accessibilityLabel(words.t("roomResizeHandle"))
            .accessibilityAdjustableAction {direction in
                var next=object;next.scale=min(1.6,max(0.6,next.sizeFactor+(direction == .increment ? 0.15 : -0.15)))
                onMove(next,true)
            }
    }
    private var turnHandle:some View {
        Button {
            var next=object;next.rotation=next.angle>=150 ? -180 : next.angle+30;onMove(next,true)
        } label:{
            Image(systemName:"rotate.right").font(.system(size:21,weight:.heavy))
                .foregroundColor(GameStyle.ink).frame(width:48,height:48)
                .background(Circle().fill(WorkshopLook.cream)).overlay(Circle().stroke(.white,lineWidth:3))
                .shadow(color:GameStyle.ink.opacity(0.2),radius:4,y:3)
        }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("roomRotate"))
    }
}

struct RoomSurfaceFrameKey:PreferenceKey {
    static let defaultValue=CGRect.zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect) {
        let next=nextValue();if next.width>0 && next.height>0 {value=next}
    }
}
