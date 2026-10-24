import SwiftUI

/// Optional, bounded shape data keeps all earlier saved friends readable.
struct BodySculpt: Codable, Equatable {
    var upper=1.0
    var middle=1.0
    var lower=1.0
    var lean=0.0
    var isValid:Bool {
        [upper,middle,lower,lean].allSatisfy(\.isFinite) &&
        (0.72...1.25).contains(upper) && (0.72...1.25).contains(middle) &&
        (0.72...1.25).contains(lower) && (-16...16).contains(lean)
    }
    func limbShift(_ part:Attachment,friend:FantasyFriend)->CGPoint {
        let shoulder:Double
        switch friend.body {
        case .oval:shoulder=82
        case .pear:shoulder=88
        case .drop:shoulder=79
        case .cloud:shoulder=49
        case .bean:shoulder=89
        default:shoulder=65
        }
        let anchor:CGPoint
        switch part {
        case .leftArm:anchor=CGPoint(x:shoulder+6,y:179)
        case .rightArm:anchor=CGPoint(x:294-shoulder,y:179)
        case .leftLeg:anchor=CGPoint(x:110,y:237)
        case .rightLeg:anchor=CGPoint(x:180,y:237)
        default:return .zero
        }
        let molded=point(anchor)
        return CGPoint(x:150+(molded.x-150)*friend.widthFactor-anchor.x,
                       y:175+(molded.y-175)*friend.heightFactor-anchor.y)
    }
    func width(at y:Double)->Double {
        let t=min(1,max(0,(y-90)/170))
        if t<0.5 {return upper+(middle-upper)*t*2}
        return middle+(lower-middle)*(t-0.5)*2
    }
    func point(_ p:CGPoint)->CGPoint {
        CGPoint(x:150+(p.x-150)*width(at:p.y)+lean*(p.y-175)/110,y:p.y)
    }
}
enum CreatureSilhouette {
    static func path(for friend:FantasyFriend)->Path {
        let source=CreatureShape(kind:friend.body).path(in:CGRect(x:0,y:0,width:300,height:320))
        guard let sculpt=friend.bodySculpt else {return source}
        var path=Path()
        source.forEach { element in
            switch element {
            case .move(to:let p): path.move(to:sculpt.point(p))
            case .line(to:let p): path.addLine(to:sculpt.point(p))
            case .quadCurve(to:let p,control:let c): path.addQuadCurve(to:sculpt.point(p),control:sculpt.point(c))
            case .curve(to:let p,control1:let a,control2:let b):
                path.addCurve(to:sculpt.point(p),control1:sculpt.point(a),control2:sculpt.point(b))
            case .closeSubpath: path.closeSubpath()
            }
        }
        return path
    }
}

/// Pull one band of the silhouette; pinch changes the whole body.
enum CreatorClay {
    static func pull(_ friend:FantasyFriend,from start:CGPoint,to end:CGPoint)->FantasyFriend {
        var copy=friend
        var clay=copy.bodySculpt ?? BodySculpt()
        let dx=Double(end.x-start.x)*(start.x<150 ? -1 : 1)/135
        let y=(Double(start.y)-175)/friend.heightFactor+175
        if abs(start.x-150)<35 {clay.lean=min(16,max(-16,clay.lean+Double(end.x-start.x)/5))}
        else if y<140 {clay.upper=min(1.25,max(0.72,clay.upper+dx))}
        else if y<207 {clay.middle=min(1.25,max(0.72,clay.middle+dx))}
        else {clay.lower=min(1.25,max(0.72,clay.lower+dx))}
        copy.bodyHeight=min(1.2,max(0.75,friend.heightFactor+Double(end.y-start.y)/350))
        copy.bodySculpt=clay
        return copy
    }
    static func pinch(_ friend:FantasyFriend,scale:Double)->FantasyFriend {
        var copy=friend
        copy.bodySculpt=friend.bodySculpt ?? BodySculpt()
        copy.bodyWidth=min(1.2,max(0.75,friend.widthFactor*scale))
        copy.bodyHeight=min(1.2,max(0.75,friend.heightFactor*scale))
        return copy
    }
}

struct CreatorTryRoom:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend:FantasyFriend
    let onReturn:()->Void
    @State private var x=0.5
    @State private var walking=0.0
    @State private var walkDuration=0.9
    @State private var stageWidth=390.0
    @State private var walkRevision=0
    @State private var action=PlayAction.jump
    @State private var signal=0
    var body:some View {
        GeometryReader { proxy in
            ZStack {
                WorldBackdrop(world:friend.world)
                Color.clear.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance:0).onEnded {walk(to:Double($0.location.x/max(1,proxy.size.width)))})
                LivingFriend(friend:friend,action:action,signal:signal,feedingFood:nil,
                    locomotion:walking,active:phase == .active)
                    .frame(width:min(320,proxy.size.width*0.63),height:min(350,proxy.size.height*0.53))
                    .position(x:proxy.size.width*x,y:proxy.size.height*0.44)
                VStack(spacing:12) {
                    HStack {
                        RoundButton(icon:"chevron.left",label:store.t("creatorBackToMaking"),action:onReturn)
                        Text(store.t("creatorTryTitle")).font(.system(size:22,weight:.heavy,design:.rounded))
                        Spacer()
                    }.padding(12).background(StorybookPanel(cornerRadius:26))
                    Spacer().allowsHitTesting(false)
                    Text(store.t("creatorTryHint")).font(.system(size:15,weight:.bold,design:.rounded))
                        .padding(12).background(StorybookPanel(cornerRadius:22)).allowsHitTesting(false)
                    HStack(spacing:12) {
                        control("creatorTryWalk","figure.walk") {walk(to:x>0.5 ? 0.23 : 0.77)}
                        control("jump","arrow.up") {react(.jump)}
                        control("dance","music.note") {react(.dance)}
                    }
                    CandyButton(title:store.t("creatorBackToMaking"),icon:"paintbrush.fill",color:StorybookStyle.teal,action:onReturn)
                }.padding(16).frame(maxWidth:850).frame(maxWidth:.infinity)
            }.onAppear {stageWidth=proxy.size.width}
                .onChange(of:proxy.size.width) {stageWidth=$0}
        }.foregroundColor(GameStyle.ink)
            .task(id:walkRevision) {
                guard walking != 0 else {return}
                do {try await Task.sleep(nanoseconds:UInt64(walkDuration*1_000_000_000))} catch {return}
                walking=0
            }
            .onChange(of:phase) {if $0 != .active {walking=0}}
    }
    private func control(_ title:String,_ icon:String,action:@escaping()->Void)->some View {
        Button(action:action) {
            VStack(spacing:7) {
                Image(systemName:icon).font(.system(size:27,weight:.heavy))
                Text(store.t(title)).font(.system(size:14,weight:.heavy,design:.rounded))
            }.frame(maxWidth:.infinity,minHeight:79).background(CandySurface(color:StorybookStyle.honey,cornerRadius:24))
        }.buttonStyle(SquishStyle())
    }
    private func walk(to target:Double) {
        let margin=min(320,stageWidth*0.63)/max(1,stageWidth)*0.5+0.025
        let target=min(1-margin,max(margin,target))
        walkDuration=min(2.3,max(0.55,abs(target-x)*stageWidth/(min(320,stageWidth*0.63)*0.65)))
        walking=reduced ? 0 : target>x ? 1 : -1
        withAnimation(reduced ? nil : .linear(duration:walkDuration)) {x=target}
        walkRevision += 1
    }
    private func react(_ value:PlayAction) {
        walking=0;action=value;signal += 1
    }
}
