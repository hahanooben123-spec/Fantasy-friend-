import SwiftUI

enum PlayAction: String, CaseIterable { case tickle, feed, jump, dance, sleep, hug }

enum CompanionMoment {case curious,proud,welcome
    var motion:CreatureMotion {
        switch self {case .curious:return .curious;case .proud:return .proud;case .welcome:return .wave}
    }
}

struct LivingFriend: View {
    let friend: FantasyFriend
    var action: PlayAction = .jump
    var signal = 0
    var audible = true
    var feedingFood: String? = "🍓"
    var onTouch: (() -> Void)?
    var locomotion = 0.0
    var active = true
    var greetOnArrival=false
    var focus:CGPoint?
    var moment=CompanionMoment.curious
    var momentSignal=0
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    @Environment(\.locale) private var locale
    @State private var started = Date()
    @State private var epoch = Date()
    @State private var pausedAt: Date?
    @State private var motion = CreatureMotion.idle
    @State private var localSignal = 0
    @State private var touchMotion = CreatureMotion.jump
    @State private var lastRequest = ""
    @State private var finger: CGPoint?

    private var running: Bool { active && phase == .active }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0/30, paused: !running || reduced)) { frame in
                let date = pausedAt ?? frame.date
                let elapsed = max(0,date.timeIntervalSince(started))
                let clock = max(0,date.timeIntervalSince(epoch))
                let playing = elapsed < motion.duration ? motion : .idle
                let selected = abs(locomotion)>0.02 && playing == .idle ? CreatureMotion.walk : playing
                let pose = animatedPose(selected, elapsed: elapsed, clock: clock)
                ZStack {
                    Ellipse().fill(GameStyle.ink.opacity(0.16))
                        .frame(width: max(85,150+pose.y*0.65),height:17)
                        .offset(y:128).opacity(max(0.3,1+pose.y/110))
                    CharacterView(friend: friend, happy: pose.happy, asleep: pose.asleep,
                                  gaze: gaze(at:clock), expression: pose.expression, pose: pose)
                    if feedingFood != nil && selected == .eat {
                        FruitArtwork(kind:0)
                            .frame(width:38,height:42)
                            .scaleEffect(CreatureRig.key(elapsed,[(0,0.8),(0.72,1),(1.02,0.1),(1.1,0)]))
                            .offset(x:CreatureRig.key(elapsed,[(0,-80),(0.48,-16),(0.9,0),(1.1,0)]),
                                    y:CreatureRig.key(elapsed,[(0,65),(0.48,42),(0.9,26),(1.1,26)]))
                            .opacity(elapsed<1.1 ? 1 : 0)
                    }
                    CreatureReactionParticles(motion:selected,time:elapsed,strength:pose.particle)
                    if pose.asleep {
                        Text("z Z").font(.system(size:24,weight:.bold,design:.rounded))
                            .foregroundColor(GameStyle.purple)
                            .offset(x:86+sin(clock)*4,y:-85-sin(clock*1.2)*7)
                    }
                }
            }.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0).onChanged { value in
                    finger=CGPoint(x:min(1,max(-1,(value.location.x/max(1,proxy.size.width)-0.5)*2.4)),
                                   y:min(1,max(-1,(value.location.y/max(1,proxy.size.height)-0.46)*2.4)))
                }.onEnded { value in
                    finger=nil
                    if let onTouch=onTouch {onTouch()}
                    else {
                        if hypot(value.translation.width,value.translation.height)>12 {touchMotion = .laugh}
                        else if value.location.y<proxy.size.height*0.48 {touchMotion = .boop}
                        else {touchMotion = [CreatureMotion.wave,.proud,.hug,.jump,.curious].filter {$0 != touchMotion}.randomElement() ?? .hug}
                        localSignal += 1
                    }
                })
        }.aspectRatio(300.0/320,contentMode:.fit)
            .accessibilityElement(children:.ignore)
            .accessibilityLabel(friend.name.isEmpty ? "FantasiVen" : friend.name)
            .accessibilityHint(Words.text("tap",locale.identifier.hasPrefix("en") ? .en : .da))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {if let onTouch=onTouch {onTouch()} else {touchMotion = .hug;localSignal += 1}}
            .onAppear {
                if signal == 0 && running && abs(locomotion)<0.02 {
                    if momentSignal>0 {started=Date();motion=moment.motion}
                    else if greetOnArrival {started=Date();motion = .wave}
                }
            }
            .onChange(of:momentSignal) {_ in
                guard running else {return}
                // Finishing a bite takes priority over a decorative reaction.
                guard motion != .eat || Date().timeIntervalSince(started)>=2.0 else {return}
                started=Date();motion=moment.motion
            }
            .onChange(of:signal) {value in localSignal=0;if value == 0 {motion = .idle;lastRequest=""}}
            .onChange(of:running) { playing in
                if !playing {pausedAt=Date();finger=nil}
                else if let pause=pausedAt {
                    let delay=Date().timeIntervalSince(pause)
                    started=started.addingTimeInterval(delay);epoch=epoch.addingTimeInterval(delay)
                    pausedAt=nil
                }
            }
            .task(id:"\(signal)-\(localSignal)-\(running)") {
                guard running,signal+localSignal>0 else {return}
                let key="\(signal)-\(localSignal)"
                guard key != lastRequest else {return}
                lastRequest=key
                let chosen=localSignal>0 ? touchMotion : CreatureMotion(action)
                // Continuous finger-eating must let the reach/bite/chew sequence finish.
                if chosen == .eat,motion == .eat,Date().timeIntervalSince(started)<2.0 {return}
                started=Date();motion=chosen
                if audible {
                    if chosen == .sleep {SoundService.shared.play(.click)}
                    else {SoundService.shared.react(voice:friend.voice?.rawValue ?? 0)}
                }
            }
    }

    private func animatedPose(_ selected:CreatureMotion,elapsed:Double,clock:Double) -> CreaturePose {
        var pose=CreatureRig.sample(selected,time:selected == .walk ? clock : elapsed,clock:clock,
                                    energy:locomotion == 0 ? 1 : locomotion,reduced:reduced)
        if !reduced && !pose.asleep {
            let cycle=(clock+Double(friend.eyes)*0.17).truncatingRemainder(dividingBy:4.3)
            pose.eyelid=CreatureRig.key(cycle,[(0,0),(3.92,0),(4.02,1),(4.10,1),(4.26,0)])
        }
        return pose
    }

    private func gaze(at clock:Double) -> CGPoint {
        if let finger=finger {return finger}
        if let focus=focus {return CGPoint(x:min(1,max(-1,focus.x)),y:min(1,max(-1,focus.y)))}
        if reduced {return .zero}
        return CGPoint(x:sin(clock*0.65)*0.32,y:sin(clock*0.37)*0.14)
    }
}

struct CreatureReactionParticles:View {
    let motion:CreatureMotion
    let time:Double
    let strength:Double
    var body:some View {
        Canvas {c,s in
            guard strength>0.01 else {return}
            for i in 0..<7 {
                let angle=Double(i)*Double.pi*2/7
                let radius=0.28+min(1,time)*0.12
                let x=s.width*(0.5+cos(angle)*radius)
                let y=s.height*(0.46+sin(angle)*radius)-time*5
                let r=CGFloat(3+i%3*2)*strength
                var shape=Path()
                if motion == .hug {
                    shape.move(to:CGPoint(x:x,y:y+r))
                    shape.addCurve(to:CGPoint(x:x-r,y:y-r*0.25),control1:CGPoint(x:x-r*2,y:y),control2:CGPoint(x:x-r*2,y:y-r*2))
                    shape.addCurve(to:CGPoint(x:x+r,y:y-r*0.25),control1:CGPoint(x:x,y:y-r*2),control2:CGPoint(x:x+r*2,y:y-r*2))
                    shape.addCurve(to:CGPoint(x:x,y:y+r),control1:CGPoint(x:x+r*2,y:y),control2:CGPoint(x:x+r,y:y+r*0.5))
                } else {
                    for j in 0..<8 {
                        let a=Double(j)*Double.pi/4
                        let point=CGPoint(x:x+cos(a)*(j%2 == 0 ? r : r*0.3),y:y+sin(a)*(j%2 == 0 ? r : r*0.3))
                        if j == 0 {shape.move(to:point)} else {shape.addLine(to:point)}
                    }
                }
                shape.closeSubpath()
                c.fill(shape,with:.color(GameStyle.palette[(i+2)%16].opacity(strength*0.8)))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
