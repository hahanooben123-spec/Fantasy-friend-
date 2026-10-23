import SwiftUI

enum PlayAction: String, CaseIterable { case tickle, feed, jump, dance, sleep, hug }

struct LivingFriend: View {
    let friend: FantasyFriend
    var action: PlayAction = .jump
    var signal = 0
    var audible = true
    var feedingFood: String? = "🍓"
    var onTouch:(()->Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var lookingAtFinger=false
    @State private var expression=CreatureExpression.normal
    @State private var armSwing=0.0
    @State private var lastReactionKey=""
    @State private var blink = false
    @State private var gaze = CGPoint.zero
    @State private var breathe = false
    @State private var happy = false
    @State private var sleeping = false
    @State private var lift: CGFloat = 0
    @State private var tilt: Double = 0
    @State private var squash: CGFloat = 1
    @State private var sparkle = false
    @State private var localSignal = 0
    @State private var tappedAction = PlayAction.jump
    @State private var currentAction = PlayAction.jump
    @Environment(\.locale) private var locale

    var body:some View {
        GeometryReader {proxy in
            creatureContent
                .simultaneousGesture(DragGesture(minimumDistance:0).onChanged {value in
                    lookingAtFinger=true
                    withAnimation(reduceMotion ? nil : .easeOut(duration:0.10)) {
                        gaze=CGPoint(x:min(1,max(-1,(value.location.x/max(1,proxy.size.width)-0.5)*2.4)),
                                     y:min(1,max(-1,(value.location.y/max(1,proxy.size.height)-0.46)*2.4)))
                    }
                }.onEnded {value in
                    lookingAtFinger=false
                    withAnimation(.easeOut(duration:0.3)) {gaze = .zero}
                    if onTouch == nil && hypot(value.translation.width,value.translation.height)>12 {
                        tappedAction = .tickle;localSignal+=1
                    }
                })
        }.aspectRatio(300.0/320,contentMode:.fit)
    }
    private var posingFriend:FantasyFriend {
        var value=friend
        guard !reduceMotion,armSwing != 0 else {return value}
        for attachment in [Attachment.leftArm,.rightArm] {
            var pose=value.placement(for:attachment)
            pose.rotation=min(180,max(-180,pose.rotation+armSwing*(attachment == .leftArm ? 1 : -0.6)))
            value.setPlacement(pose,for:attachment)
        }
        if var pieces=value.pieces {
            for i in pieces.indices where pieces[i].kind == .arm {
                pieces[i].rotation=min(180,max(-180,pieces[i].rotation+armSwing*(i.isMultiple(of:2) ? 1 : -1)))
            }
            value.pieces=pieces
        }
        return value
    }
    private var creatureContent: some View {
        Button {
            if let onTouch=onTouch {onTouch()}
            else {
                tappedAction = [PlayAction.tickle,.jump,.hug,.dance].filter {$0 != tappedAction}.randomElement() ?? .jump
                localSignal += 1
            }
        } label: {
            ZStack {
                Ellipse().fill(GameStyle.ink.opacity(0.09)).frame(width: 150, height: 17).offset(y: 128)
                CharacterView(friend:posingFriend,blink:blink,happy:happy && expression != .wink,asleep:sleeping,gaze:gaze,expression:expression)
                    .scaleEffect(x:squash*(lookingAtFinger && !reduceMotion ? 1.025 : 1),
                                 y:(breathe ? 1.018 : 1)/squash/(lookingAtFinger && !reduceMotion ? 1.025 : 1),anchor:.bottom)
                    .animation(reduceMotion ? nil : .spring(response:0.25,dampingFraction:0.65),value:lookingAtFinger)
                    .rotationEffect(.degrees(tilt), anchor: .bottom)
                    .offset(y: lift)
                if sparkle {
                    ForEach(0..<7) { index in
                        Image(systemName: currentAction == .hug ? "heart.fill" : "sparkle")
                            .font(.system(size: CGFloat(14 + index % 3 * 5), weight: .bold))
                            .foregroundColor(GameStyle.palette[(index + 2) % 16])
                            .offset(x: CGFloat(cos(Double(index) * .pi * 2 / 7)) * 115,
                                    y: CGFloat(sin(Double(index) * .pi * 2 / 7)) * 110 - 20)
                    }
                }
                if sleeping { Text("z Z").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(GameStyle.purple).offset(x: 90, y: -90) }
                if happy && currentAction == .feed, let food = feedingFood { Text(food).font(.system(size: 42)).offset(y: 30) }
            }.aspectRatio(300.0 / 320, contentMode: .fit).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(friend.name.isEmpty ? "FantasiVen" : friend.name)
        .accessibilityHint(Words.text("tap", locale.identifier.hasPrefix("en") ? .en : .da))
        .onChange(of: signal) { _ in localSignal = 0 }
        .task(id:"\(phase)-\(reduceMotion)") {
            breathe=false
            guard phase == .active else {return}
            if !reduceMotion {withAnimation(.easeInOut(duration:2.4).repeatForever(autoreverses:true)) {breathe=true}}
            do {
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds:UInt64.random(in:2_900_000_000...4_800_000_000))
                    guard !Task.isCancelled else {return}
                    blink=true
                    try await Task.sleep(nanoseconds:130_000_000)
                    blink=false
                    if !lookingAtFinger && !sleeping && !happy && !reduceMotion {
                        withAnimation(.easeInOut(duration:0.45)) {gaze=CGPoint(x:Double.random(in:-0.5...0.5),y:Double.random(in:-0.25...0.3))}
                        try await Task.sleep(nanoseconds:700_000_000)
                        if !lookingAtFinger {withAnimation(.easeInOut(duration:0.4)) {gaze = .zero}}
                    }
                }
            } catch {blink=false}
        }
        .task(id: "\(signal)-\(localSignal)-\(phase)") {
            guard phase == .active,signal + localSignal > 0 else {
                lift=0;tilt=0;squash=1;armSwing=0;expression = .normal;sparkle=false;happy=false
                return
            }
            let request="\(signal)-\(localSignal)"
            guard request != lastReactionKey else {return}
            lastReactionKey=request
            let chosen = localSignal > 0 ? tappedAction : action
            currentAction = chosen
            sleeping = chosen == .sleep
            happy = chosen != .sleep
            lift = 0; tilt = 0; squash = 1; sparkle = false;armSwing=0;expression = .normal
            if audible { if chosen == .sleep { SoundService.shared.play(.click) } else { SoundService.shared.react(voice: friend.voice?.rawValue ?? 0) } }
            withAnimation(.easeOut(duration: 0.2)) { sparkle = chosen != .sleep }
            do {
                expression=chosen == .feed ? .chew : chosen == .jump ? .wonder : chosen == .hug ? .wink : .normal
                if !reduceMotion {
                    for step in 0..<(chosen == .dance || chosen == .tickle || chosen == .feed ? 6 : 4) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                            switch chosen {
                            case .jump: lift = step.isMultiple(of:2) ? -42 : 0;armSwing = step.isMultiple(of:2) ? 28 : 0
                            case .dance: tilt = step.isMultiple(of: 2) ? -(friend.gait == .waddle ? 20 : 10) : (friend.gait == .waddle ? 20 : 10); lift = friend.gait == .glide ? -8 : (step.isMultiple(of: 2) ? -22 : 0)
                            case .tickle: tilt = step.isMultiple(of: 2) ? -6 : 6;armSwing = step.isMultiple(of:2) ? 20 : -8
                            case .hug: squash = step.isMultiple(of:2) ? 0.92 : 1;armSwing = step.isMultiple(of:2) ? 34 : 15
                            case .feed: squash = step.isMultiple(of:2) ? 1.035 : 1;expression = step.isMultiple(of:2) ? .chew : .normal
                            case .sleep: tilt = 7
                            }
                        }
                        try await Task.sleep(nanoseconds: 230_000_000)
                    }
                }
                try await Task.sleep(nanoseconds: 900_000_000)
                withAnimation(.easeOut(duration: 0.3)) { happy = false; sparkle = false; lift = 0; squash = 1;armSwing=0;expression = .normal; if !sleeping { tilt = 0 } }
            } catch { /* A newer reaction or navigation cancels this animation task. */ }
        }
    }
}
