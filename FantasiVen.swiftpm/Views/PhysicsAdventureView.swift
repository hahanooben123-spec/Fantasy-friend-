import SwiftUI

struct TrackArtwork:View {
    let track:SlideTrack
    var body:some View {
        Canvas {context,size in
            var path=Path()
            for i in 0..<5 {
                let point=CGPoint(x:(0.0875+Double(i)*0.2)*size.width,y:(0.2+track.heights[i]*0.6)*size.height)
                if i == 0 {path.move(to:point)} else {path.addLine(to:point)}
            }
            context.stroke(path,with:.color(GameStyle.ink),style:StrokeStyle(lineWidth:24,lineCap:.round,lineJoin:.round))
            context.stroke(path,with:.color(StudioStyle.colors[5]),style:StrokeStyle(lineWidth:18,lineCap:.round,lineJoin:.round))
            context.stroke(path,with:.color(.white.opacity(0.6)),style:StrokeStyle(lineWidth:4,lineCap:.round,lineJoin:.round))
        }.allowsHitTesting(false)
    }
}
struct PhysicsAdventureView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let kind:MiniGameKind
    let friend:FantasyFriend
    var previewRide=false
    @StateObject private var physics=PlayPhysics()
    @State private var track=SlideTrack()
    @State private var running=false
    @State private var history:[SlideTrack]=[]
    @State private var dragStart:SlideTrack?
    @State private var accessibleProgress=0.0
    @State private var saved=false
    @State private var trail=StarTrail()
    @State private var celebration=0

    var body:some View {
        AdventureGameShell(kind:kind) {active in
            GeometryReader {proxy in
                ZStack {
                    if kind == .slide {TrackArtwork(track:track)}
                    if running {
                        PhysicsPlayfield(physics:physics,trampoline:kind == .trampoline)
                    } else if kind == .slide {
                        ForEach(0..<5) {point in
                            Circle().fill(StudioStyle.colors[point%3]).frame(width:48,height:48)
                                .overlay(Circle().stroke(.white,lineWidth:4))
                                .overlay(Image(systemName:"arrow.up.and.down").font(.headline))
                                .position(x:(0.0875+Double(point)*0.2)*proxy.size.width,y:(0.2+track.heights[point]*0.6)*proxy.size.height)
                                .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("track")).onChanged {value in
                                    if dragStart == nil {dragStart=track}
                                    track.set(point,y:(value.location.y/proxy.size.height-0.2)/0.6)
                                }.onEnded {_ in
                                    if let before=dragStart {history.append(before)}
                                    dragStart=nil;trail.follow(track)
                                })
                                .accessibilityLabel(store.t("bodyHeight")+" \(point+1)")
                                .accessibilityAdjustableAction {direction in
                                    history.append(track)
                                    track.set(point,y:track.heights[point]+(direction == .increment ? 0.05 : -0.05))
                                    trail.follow(track)
                                }
                        }
                        LivingFriend(friend:friend,audible:false,active:active).frame(width:130,height:140).position(x:proxy.size.width*0.1,y:proxy.size.height*0.22)
                    } else {
                        LivingFriend(friend:friend,audible:false,active:active).frame(width:160,height:175).position(x:proxy.size.width*0.5,y:proxy.size.height*0.4)
                        Capsule().fill(StudioStyle.colors[1]).frame(width:proxy.size.width*0.3,height:22)
                            .position(x:proxy.size.width*0.5,y:proxy.size.height*0.83)
                    }
                    ForEach(trail.stars) {star in
                        StarArtwork().frame(width:34,height:34).position(x:star.x*proxy.size.width,y:star.y*proxy.size.height)
                            .allowsHitTesting(false)
                    }
                    PlayCelebration(revision:celebration)
                    VStack {
                        HStack {
                            HStack {StarArtwork().frame(width:30,height:30);Text("\(trail.collected)").font(.system(size:24,weight:.heavy,design:.rounded))}
                                .padding(12).background(StorybookPanel(cornerRadius:24))
                            Spacer()
                            if saved {Text(store.t("saved")).padding(10).background(Capsule().fill(.white))}
                        }.padding(.horizontal,18).padding(.top,78)
                        Spacer()
                        if physics.arrived && running {
                            Text(store.t("wellDone")).font(.system(.title,design:.rounded).weight(.heavy))
                                .padding(16).background(Capsule().fill(.white))
                        }
                        PlayDock {
                            if kind == .slide && !running {
                                RoundButton(icon:"arrow.uturn.backward",label:store.t("undo")) {
                                    if let last=history.popLast() {track=last;trail.follow(track)}
                                }.disabled(history.isEmpty)
                                RoundButton(icon:"heart.fill",label:store.t("saveCreation"),action:save)
                            }
                            if running {
                                RoundButton(icon:"arrow.counterclockwise",label:store.t("restartGame")) {start(active:active)}
                            }
                            Spacer(minLength:0)
                            PlayToken(symbol:running ? "🛠️" : "▶️",label:store.t(running ? "buildMore" : "go")) {
                                if running {running=false;physics.setActive(false)}
                                else {start(active:active)}
                            }
                            if kind == .trampoline && running {
                                Spacer()
                                PlayToken(symbol:"🚀",label:store.t("jump")) {physics.jump()}
                            }
                        }
                    }
                }.coordinateSpace(name:"track")
            }
            .task(id:"\(active)-\(running)-\(reduced)") {
                physics.setActive(active && running && !physics.arrived)
                guard active && running else {return}
                while !Task.isCancelled && !physics.arrived {
                    if reduced {
                        accessibleProgress = kind == .trampoline && accessibleProgress>=1 ? 0 : min(1,accessibleProgress+0.008)
                        physics.accessibleRide(progress:accessibleProgress,track:kind == .slide ? track : nil)
                    } else {physics.refresh()}
                    if let actor=physics.friends.first {
                        if trail.collect(x:Double(actor.x/800),y:Double(1-actor.y/500)) {
                            SoundService.shared.play(.reaction)
                            if trail.stars.isEmpty {
                                celebration+=1
                                if kind == .trampoline {trail.reseed()}
                            }
                        }
                    }
                    do {try await Task.sleep(nanoseconds:33_333_333)} catch {return}
                }
                physics.setActive(false)
                if physics.arrived {celebration+=1;SoundService.shared.play(.complete)}
            }
        }.onAppear {
            track=friend.track ?? SlideTrack()
            if kind == .slide {trail.follow(track)}
            if previewRide {start(active:true)}
        }
        .onChange(of:track) {_ in saved=false}
        .onDisappear {physics.setActive(false)}
    }
    private func start(active:Bool) {
        physics.configure(friends:[friend],mode:kind == .slide ? .slide(track) : .trampoline,reducedMotion:reduced)
        physics.scene.speed=[0.75,0.9,1.0][store.settings.challengeLevel-1]
        accessibleProgress=0;running=true
        if kind == .slide {trail.follow(track)} else {trail.reseed()}
        physics.setActive(active)
    }
    private func save() {
        guard var current=store.friends.first(where:{$0.id == friend.id}) else {return}
        current.track=track;saved=store.save(current)
    }
}
