import SwiftUI
import UniformTypeIdentifiers

struct CreatorStage: View {
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
    @State private var origin: FantasyFriend?
    @State private var movingSelection: CreatorSelection?
    @State private var handleOrigin: FantasyFriend?
    @State private var draft: DoodleStroke?
    @State private var blink = false
    @State private var gaze = CGPoint.zero
    @State private var lean = 0.0
    @State private var breathing=false
    @State private var delighted=false
    @State private var interactionRevision=0
    @State private var reactionLift:CGFloat=0
    @State private var reactionSquash:CGFloat=1
    @State private var expression=CreatureExpression.normal
    private let zoom: CGFloat = 1.1

    var body: some View {
        GeometryReader { geometry in
            let width = max(1,min(geometry.size.width - 12,geometry.size.height * 300 / 320))
            let height = width * 320 / 300
            let size = CGSize(width:width,height:height)
            ZStack {
                Ellipse().fill(WorkshopLook.sea.opacity(0.18)).frame(width:width*0.57,height:height*0.055)
                    .position(x:width/2,y:height*0.94)
                CharacterView(friend:displayed,blink:blink,happy:delighted && expression != .wink,gaze:gaze,zoom:zoom,expression:expression)
                    .scaleEffect(x:breathing && origin == nil && !reduced ? 1.006 : 1,
                                 y:breathing && origin == nil && !reduced ? 1.015 : 1,anchor:.bottom)
                    .scaleEffect(x:reactionSquash,y:1/reactionSquash,anchor:.bottom)
                    .offset(y:reactionLift)
                    .rotationEffect(.degrees(reduced ? 0 : lean),anchor:.bottom)
                    .animation(reduced ? nil : .spring(response:0.32,dampingFraction:0.65),value:lean)
                    .allowsHitTesting(false)
                if brush == nil, let selected = selection {
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
                        let point = canonical(value.location,size:size)
                        gaze = CGPoint(x:min(1,max(-1,(point.x-150)/80)),y:min(1,max(-1,(point.y-157)/80)))
                        if let brush = brush {
                            if origin == nil { origin=friend;onBegin() }
                            appendPaint(point,brush:brush); return
                        }
                        if origin == nil {
                            origin=friend;interactionRevision+=1
                            movingSelection=CreatorGeometry.hit(canonical(value.startLocation,size:size),friend:friend,margin:7,minimumTouchSize:48*300/width/zoom)
                            selection=movingSelection
                            onBegin()
                        }
                        guard let source=origin,let selected=movingSelection else { return }
                        if selected == .body {
                            lean = min(5,max(-5,Double(value.translation.width/35)))
                        } else {
                            friend=CreatorGeometry.moved(selected,original:source,delta:CGSize(width:value.translation.width/width*300/zoom,height:value.translation.height/height*320/zoom))
                        }
                    }
                    .onEnded { _ in
                        if let stroke=draft,stroke.isValid {
                            var strokes=friend.doodles ?? [];strokes.append(stroke);friend.doodles=strokes
                        }
                        draft=nil;origin=nil;movingSelection=nil;lean=0;gaze = .zero
                        onEnd()
                    })
                .onDrop(of:[UTType.text.identifier],isTargeted:nil) { _,point in
                    guard let choice=incoming else { return false }
                    onDrop(choice,canonical(point,size:size));incoming=nil;return true
                }
                .position(x:geometry.size.width/2,y:geometry.size.height/2)
        }
        .onChange(of:part) { _ in draft=nil;origin=nil;handleOrigin=nil;lean=0 }
        .task(id:"\(phase)-\(reduced)") {
            breathing=false
            guard phase == .active,!reduced else {return}
            withAnimation(.easeInOut(duration:2.2).repeatForever(autoreverses:true)) {breathing=true}
        }
        .task(id:revision) {
            guard revision>0 else {return}
            delighted=false;reactionLift=0;reactionSquash=1
            expression=part == .extras || part == .color ? .wonder : .wink
            gaze=part == .legs ? CGPoint(x:0,y:0.7) : part == .extras ? CGPoint(x:0,y:-0.7) : .zero
            do {
                if !reduced {
                    withAnimation(.spring(response:0.24,dampingFraction:0.55)) {reactionSquash=0.92;reactionLift = -12}
                }
                try await Task.sleep(nanoseconds:270_000_000)
                expression = .normal;delighted=true
                withAnimation(reduced ? nil : .spring(response:0.4,dampingFraction:0.55)) {reactionSquash=1;reactionLift=0}
                try await Task.sleep(nanoseconds:420_000_000)
                delighted=false;gaze = .zero
            } catch {delighted=false;reactionLift=0;reactionSquash=1;expression = .normal}
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
        .onDisappear { draft=nil;origin=nil;handleOrigin=nil }
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
        } else {
            RoundedRectangle(cornerRadius:14)
                .stroke(.white,style:StrokeStyle(lineWidth:3,dash:[6,5]))
                .shadow(color:WorkshopLook.blue,radius:1)
                .frame(width:rect.width/300*size.width*zoom+12,height:rect.height/320*size.height*zoom+12)
                .position(center).allowsHitTesting(false)
            transformHandle(selected,rotating:true,size:size).position(screen(CGPoint(x:min(275,rect.maxX+5),y:max(24,rect.minY-10)),size:size))
            transformHandle(selected,rotating:false,size:size).position(screen(CGPoint(x:min(275,rect.maxX+6),y:min(294,rect.maxY+6)),size:size))
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
    private func transformHandle(_ selected:CreatorSelection,rotating:Bool,size:CGSize)->some View {
        CreatorLineIcon(mark:rotating ? .rotate : .resize,color:.white).frame(width:27,height:27)
            .frame(width:56,height:56).background(Circle().fill(WorkshopLook.blue)).overlay(Circle().stroke(.white,lineWidth:3))
            .highPriorityGesture(DragGesture(coordinateSpace:.named("creatorStage")).onChanged { value in
                if handleOrigin == nil { handleOrigin=friend;onBegin() }
                guard let source=handleOrigin else { return }
                let rect=CreatorGeometry.bounds(selected,friend:source)
                let start=canonical(value.startLocation,size:size),point=canonical(value.location,size:size)
                let pose=CreatorGeometry.pose(selected,friend:source)
                let angle=(atan2(point.y-rect.midY,point.x-rect.midX)-atan2(start.y-rect.midY,start.x-rect.midX))*180 / .pi
                let distance=hypot(point.x-rect.midX,point.y-rect.midY)/max(12,hypot(start.x-rect.midX,start.y-rect.midY))
                friend=CreatorGeometry.transformed(selected,original:source,rotation:pose.rotation+(rotating ? angle : 0),scale:pose.scale*(rotating ? 1 : distance))
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
