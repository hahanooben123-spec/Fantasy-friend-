import SwiftUI
import UniformTypeIdentifiers

struct CreatorStage: View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    @Binding var friend: FantasyFriend
    @Binding var selection: CreatorSelection?
    @Binding var incoming: CreatorPick?
    let part: Part
    let brush: PaintTool?
    let revision: Int
    let onBegin: () -> Void
    let onEnd: () -> Void
    let onDrop: (CreatorPick, CGPoint) -> Void
    @State private var pinchOrigin:FantasyFriend?
    @State private var reactingParts=false
    @State private var origin: FantasyFriend?
    @State private var movingSelection: CreatorSelection?
    @State private var handleOrigin: FantasyFriend?
    @State private var draft: DoodleStroke?
    @State private var rigStarted=Date.distantPast
    @State private var blink = false
    @State private var gaze = CGPoint.zero
    @State private var lean = 0.0
    @State private var interactionRevision=0
    @State private var expression=CreatureExpression.normal
    private let zoom: CGFloat = 1.1

    private func editorPose(time:Double,clock:Double)->CreaturePose {
        let motion:CreatureMotion=part == .legs ? .walk : part == .arms ? .hug : .jump
        var rig=CreatureRig.sample(reactingParts ? motion : .idle,time:time,clock:clock,reduced:reduced)
        // Hands and handles must coincide while a child positions a part.
        if origin != nil || handleOrigin != nil || pinchOrigin != nil || (selection != nil && !reactingParts) {
            rig.x=0;rig.y=0;rig.roll=0;rig.scaleX=1;rig.scaleY=1;rig.headTilt=0;rig.headY=0;rig.joints=[:]
        }
        return rig
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(1,min(geometry.size.width - 12,geometry.size.height * 300 / 320))
            let height = width * 320 / 300
            let size = CGSize(width:width,height:height)
            ZStack {
                Ellipse().fill(WorkshopLook.sea.opacity(0.18)).frame(width:width*0.57,height:height*0.055)
                    .position(x:width/2,y:height*0.94)
                TimelineView(.animation(minimumInterval:1.0/30,
                    paused:reduced || phase != .active || origin != nil || handleOrigin != nil || pinchOrigin != nil)) {frame in
                    let time=max(0,frame.date.timeIntervalSince(rigStarted))
                    let rig=editorPose(time:time,clock:frame.date.timeIntervalSinceReferenceDate)
                    CharacterView(friend:displayed,blink:blink,happy:false,
                        gaze:gaze,zoom:zoom,expression:expression,pose:rig)
                }
                    .rotationEffect(.degrees(reduced ? 0 : lean),anchor:.bottom)
                    .animation(reduced ? nil : .spring(response:0.32,dampingFraction:0.65),value:lean)
                    .allowsHitTesting(false)
                if brush == nil && part == .body && !reactingParts, let selected = selection, selected == .body {
                    selectionFrame(selected,size:size)
                }
                StudioBurst(revision:revision).allowsHitTesting(false)
                if incoming != nil {
                    RoundedRectangle(cornerRadius:40).stroke(WorkshopLook.yellow,lineWidth:4)
                        .padding(12).allowsHitTesting(false)
                }
                GestureLesson(activity:revision+interactionRevision+(incoming == nil ? 0 : 1),from:UnitPoint(x:0.28,y:0.62),to:UnitPoint(x:0.42,y:0.45))
            }.frame(width:width,height:height)
                .background(GeometryReader {proxy in
                    Color.clear.preference(key:CreatorStageFrameKey.self,value:proxy.frame(in:.named("creatorWorkshop")))
                }).coordinateSpace(name:"creatorStage").contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("creatorStage"))
                    .onChanged { value in
                        guard pinchOrigin == nil,brush != nil || part == .body else {return}
                        reactingParts=false
                        let point = canonical(value.location,size:size)
                        gaze = CGPoint(x:min(1,max(-1,(point.x-150)/80)),y:min(1,max(-1,(point.y-157)/80)))
                        if let brush = brush {
                            if origin == nil { origin=friend;onBegin() }
                            appendPaint(point,brush:brush); return
                        }
                        if origin == nil {
                            origin=friend;interactionRevision+=1
                            let start=canonical(value.startLocation,size:size)
                            movingSelection=part == .body && CreatorGeometry.bounds(.body,friend:friend).contains(start) ? .body :
                                CreatorGeometry.hit(start,friend:friend,margin:7,minimumTouchSize:48*300/width/zoom)
                            selection=movingSelection
                            onBegin()
                        }
                        guard let source=origin,let selected=movingSelection else { return }
                        if selected == .body {
                            if part == .body {
                                friend=CreatorClay.pull(source,from:canonical(value.startLocation,size:size),to:point)
                            } else {lean=min(5,max(-5,Double(value.translation.width/35)))}
                        }
                    }
                    .onEnded { _ in
                        if pinchOrigin != nil {origin=nil;return}
                        if let stroke=draft,stroke.isValid {
                            var strokes=friend.doodles ?? [];strokes.append(stroke);friend.doodles=strokes
                        }
                        draft=nil;origin=nil;movingSelection=nil;lean=0;gaze = .zero
                        onEnd()
                    })
                .simultaneousGesture(MagnificationGesture().onChanged {scale in
                    guard part == .body,brush == nil else {return}
                    reactingParts=false
                    if pinchOrigin == nil {pinchOrigin=origin ?? friend;onBegin()}
                    if let base=pinchOrigin {friend=CreatorClay.pinch(base,scale:Double(scale))}
                }.onEnded {_ in
                    guard pinchOrigin != nil else {return}
                    pinchOrigin=nil;origin=nil;onEnd()
                })
                .accessibilityAction(named:Text(store.t("creatorMakeBigger"))) {
                    onBegin();friend=CreatorClay.pinch(friend,scale:1.08);onEnd()
                }
                .position(x:geometry.size.width/2,y:geometry.size.height/2)
        }
        .onChange(of:phase) {value in
            guard value != .active else {return}
            let held=origin != nil || handleOrigin != nil || pinchOrigin != nil
            origin=nil;handleOrigin=nil;pinchOrigin=nil;draft=nil;reactingParts=false
            if held {onEnd()}
        }
        .onChange(of:part) { _ in draft=nil;origin=nil;handleOrigin=nil;pinchOrigin=nil;reactingParts=false;lean=0 }
        .task(id:revision) {
            guard revision>0 else {return}
            reactingParts=true;rigStarted=Date()
            expression=part == .extras || part == .color ? .wonder : .wink
            gaze=part == .legs ? CGPoint(x:0,y:0.7) : part == .extras ? CGPoint(x:0,y:-0.7) : .zero
            do {
                try await Task.sleep(nanoseconds:950_000_000)
                reactingParts=false;expression = .normal;gaze = .zero
            } catch {reactingParts=false;expression = .normal}
        }
        .task(id:phase) {
            guard phase == .active else { return }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds:3_800_000_000);blink=true
                    try await Task.sleep(nanoseconds:140_000_000);blink=false
                }
            } catch { blink=false }
        }
        .onDisappear {draft=nil;origin=nil;handleOrigin=nil;pinchOrigin=nil;reactingParts=false}
    }
    private var displayed: FantasyFriend {
        var copy=friend
        if let draft=draft { var strokes=copy.doodles ?? [];strokes.append(draft);copy.doodles=strokes }
        return copy
    }
    private func canonical(_ point: CGPoint,size:CGSize)->CGPoint {
        CGPoint(x:((point.x/size.width-0.5)/zoom+0.5)*300,y:((point.y/size.height-0.5)/zoom+0.5)*320)
    }
    private func screen(_ point:CGPoint,size:CGSize)->CGPoint {
        CGPoint(x:((point.x/300-0.5)*zoom+0.5)*size.width,y:((point.y/320-0.5)*zoom+0.5)*size.height)
    }
    @ViewBuilder private func selectionFrame(_ selected:CreatorSelection,size:CGSize)->some View {
        let rect=CreatorGeometry.bounds(selected,friend:friend)
        let center=screen(CGPoint(x:rect.midX,y:rect.midY),size:size)
        if selected == .body {
            bodyHandle(horizontal:true,size:size).position(screen(CGPoint(x:rect.maxX+14,y:rect.midY),size:size))
            bodyHandle(horizontal:false,size:size).position(screen(CGPoint(x:rect.midX,y:rect.maxY+12),size:size))
        }
    }
    private func bodyHandle(horizontal:Bool,size:CGSize)->some View {
        CreatorLineIcon(mark:.resize,color:.white).frame(width:29,height:29).rotationEffect(.degrees(horizontal ? 45 : -45))
            .frame(width:56,height:56).background(Circle().fill(WorkshopLook.blue)).overlay(Circle().stroke(.white,lineWidth:3))
            .highPriorityGesture(DragGesture(coordinateSpace:.named("creatorStage")).onChanged { value in
                if handleOrigin == nil { handleOrigin=friend;onBegin() }
                guard let source=handleOrigin else { return }
                if horizontal { friend.bodyWidth=min(1.2,max(0.75,source.widthFactor+value.translation.width/size.width*1.2)) }
                else { friend.bodyHeight=min(1.2,max(0.75,source.heightFactor+value.translation.height/size.height*1.2)) }
            }.onEnded { _ in handleOrigin=nil;onEnd() })
    }
    private func appendPaint(_ point:CGPoint,brush:PaintTool) {
        let p=DoodlePoint(x:min(1,max(0,(150+(point.x-150)/friend.widthFactor)/300)),y:min(1,max(0,(175+(point.y-175)/friend.heightFactor)/320)))
        var stroke=draft ?? DoodleStroke(points:[p],color:brush.color,width:brush.width)
        if let last=stroke.points.last,hypot(last.x-p.x,last.y-p.y)>0.006 {
            if stroke.points.count>=600 { stroke.points=stroke.points.enumerated().filter { $0.offset.isMultiple(of:2) }.map(\.element) }
            stroke.points.append(p)
        }
        draft=stroke
    }
}


struct CreatorStageFrameKey:PreferenceKey {
    static let defaultValue=CGRect.zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect) {
        let next=nextValue();if next.width>0 && next.height>0 {value=next}
    }
}
