import SwiftUI
import Combine

struct MiniGameSessionView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    let kind: MiniGameKind
    let friend: FantasyFriend
    @Environment(\.presentationMode) private var presentation
    @State private var picnic = false
    @State private var celebration = 0
    @State private var lastGolden = 0
    @State private var surprises:[BubbleSurprise] = []
    @State private var popTimes: [Int:Double] = [:]
    @State private var interacted = false
    @State private var bubbleScale = 1.0
    @State private var giantBubble = false
    @State private var flyUntil = 0.0
    @State private var clueSpot: Int?
    @State private var apples = AppleRain()
    @State private var bubbles = BubbleGarden()
    @State private var seek = HideAndSeek()
    @State private var paused = false
    @State private var visible = false
    @State private var lastTick: Date?
    @State private var elapsed = 0.0
    @State private var cheerUntil = 0.0
    @State private var bubbleFlash: Int?
    @State private var catchRadius = 0.15
    private let clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private var count: Int {
        switch kind {
        case .apples: return apples.caught
        case .bubbles: return bubbles.popped
        case .hide: return seek.found
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            WorldBackdrop(world:kind == .bubbles ? .clouds : .meadow,animated:!paused)
            Group {
                if kind == .apples {appleField}
                else if kind == .bubbles {bubbleField}
                else {hidingField}
            }.disabled(paused || picnic || scenePhase != .active)
            PlayCelebration(revision:celebration)
            VStack {
                PlayHUD(title:store.t(kind.titleKey),hint:store.t(kind.hintKey),paused:$paused)
                HStack {
                    Text(kind == .hide ? "🌿 \(count) / 3" : kind == .apples ? "🍎 \(count)  ·  ✨ \(apples.streak)" : "🫧 \(count)")
                        .font(.system(size:22,weight:.heavy,design:.rounded)).monospacedDigit()
                        .padding(12).background(Capsule().fill(.white.opacity(0.9)))
                        .accessibilityLabel(store.t(kind == .hide ? "friendsFound" : kind == .apples ? "applesCaught" : "bubblesPopped"))
                        .accessibilityValue("\(count)")
                    Spacer()
                    if kind == .apples {
                        Text(store.t(apples.weather.key)).font(.system(size:12,weight:.heavy,design:.rounded))
                            .padding(10).background(Capsule().fill(.white.opacity(0.92)))
                    }
                }.padding(.horizontal,18)
                Spacer().allowsHitTesting(false)
                if !interacted {Text(store.t(kind == .apples ? "appleHelp" : kind == .hide ? "hideHelp" : "bubbleSwipe")).font(.system(.subheadline,design:.rounded).weight(.bold)).padding(10).background(Capsule().fill(.white.opacity(0.9)))}
                PlayDock {
                    RoundButton(icon:"arrow.counterclockwise",label:store.t("restartGame"),action:restart)
                    if kind == .apples {
                        movementButton(direction:-1)
                        Spacer(minLength:0)
                        PlayToken(symbol:"🧺",label:store.t("picnic")) {picnic=true}
                        Spacer(minLength:0)
                        movementButton(direction:1)
                    } else if kind == .bubbles {
                        PlayToken(symbol:"🫧",label:store.t("bubbleGrow")) {bubbleScale = bubbleScale >= 1.3 ? 1 : bubbleScale+0.1}
                        Spacer(minLength:0)
                        PlayToken(symbol:"🌈",label:store.t(giantBubble ? "releaseBubble" : "bubbleMerge"),selected:giantBubble) {
                            if giantBubble {release()} else {giantBubble=true}
                        }
                    } else {
                        Spacer()
                        if seek.complete {
                            PlayToken(symbol:"🙈",label:store.t("hideAgain")) {seek=HideAndSeek();clueSpot=nil}
                        } else {
                            PlayToken(symbol:"✨",label:store.t("clue")) {
                                clueSpot=seek.hiding.subtracting(seek.opened).first
                                SoundService.shared.react(voice:friend.voice?.rawValue ?? 0)
                            }
                        }
                    }
                }.disabled(paused)
            }
            if picnic {picnicOverlay}
            if paused {PlayPauseOverlay(resume:{paused=false;lastTick=nil})}
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .onAppear {visible=true;lastTick=nil}
            .onDisappear {visible=false;lastTick=nil;SoundService.shared.stopSpeech()}
            .onChange(of:scenePhase) {_ in lastTick=nil}
            .onChange(of:paused) {_ in lastTick=nil}
            .onReceive(clock) {date in tick(date)}
    }
    private var picnicOverlay:some View {
        ZStack {
            Color.indigo.opacity(0.3).ignoresSafeArea()
            VStack(spacing:18) {
                CharacterView(friend:friend,happy:true).frame(width:190,height:200)
                Text(store.t("picnic")).font(.system(.title2,design:.rounded).weight(.heavy))
                Text(apples.fruitBasket.suffix(12).map {["🍎","🍌","🫐"][$0]}.joined()).font(.system(size:30))
                CandyButton(title:store.t("keepPlaying"),icon:"play.fill") {picnic=false;lastTick=nil}
            }.padding(24).frame(maxWidth:400).background(RoundedRectangle(cornerRadius:36).fill(.white)).padding(20)
        }
    }

    private var appleField: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                VStack {FruitCanopy(weather:apples.weather);Spacer()}.allowsHitTesting(false)
                Ellipse().fill(Color.green.opacity(0.16)).frame(width: size.width * 1.5, height: 120).position(x: size.width / 2, y: size.height * 0.99)
                ForEach(Array(apples.flowers.enumerated()), id: \.offset) { index, x in
                    Text(["🌼", "🌸", "🌷"][index % 3]).font(.system(size: 26))
                        .position(x: x * size.width, y: size.height * 0.94)
                }
                ForEach(apples.drops) { apple in
                    Group {
                        if apple.golden {Text("🌟").font(.system(size:48))}
                        else if apple.fruit == 0 { AppleToy() }
                        else { Text(apple.fruit == 1 ? "🍌" : "🫐").font(.system(size: 39)) }
                    }.frame(width: 46, height: 48)
                        .rotationEffect(.degrees(reducedMotion ? 0 : sin(apple.y * 9) * 12))
                        .position(x: apple.x * size.width, y: apple.y * size.height)
                        .accessibilityHidden(true)
                }
                CharacterView(friend: friend, happy: elapsed < cheerUntil)
                    .frame(width: min(210,size.width*0.34), height:min(225,size.width*0.37))
                    .position(x: apples.playerX * size.width, y: size.height * 0.83)
                    .allowsHitTesting(false)
                BasketToy().position(x: apples.playerX * size.width, y: size.height * 0.75)
                    .allowsHitTesting(false)
                if elapsed < cheerUntil {
                    Text(["🍎","🍌","🫐"][apples.lastFruit]+" ✨").font(.system(size:35))
                        .position(x: apples.playerX * size.width, y: size.height * 0.57)
                        .allowsHitTesting(false)
                }
            }.frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    guard !paused && !picnic else { return }
                    interacted = true
                    apples.move(to: value.location.x / max(1, size.width))
                })
                .onAppear { catchRadius = max(0.09, min(0.22, 62 / max(1, size.width))) }
                .onChange(of: size.width) { width in catchRadius = max(0.09, min(0.22, 62 / max(1, width))) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(store.t("appleHelp"))
                .accessibilityAdjustableAction { direction in
                    guard !paused && !picnic else { return }
                    interacted = true
                    apples.move(to: apples.playerX + (direction == .increment ? 0.12 : -0.12))
                }
        }
    }

    private var bubbleField: some View {
        GeometryReader { proxy in
            ZStack {
                CharacterView(friend:blowingFriend,happy:elapsed<cheerUntil && !blowing)
                    .frame(width:180,height:192)
                    .position(x:proxy.size.width/2,y:proxy.size.height*(elapsed<flyUntil ? 0.25 : 0.81))
                    .animation(reducedMotion ? nil : .easeInOut(duration:0.6),value:flyUntil)
                    .allowsHitTesting(false)
                BubbleWand().frame(width:55,height:70)
                    .position(x:proxy.size.width/2+48,y:proxy.size.height*0.83).allowsHitTesting(false)
                ForEach(0..<6) { slot in
                    let generation = bubbles.generations[slot]
                    let diameter = min(170, max(70, proxy.size.width * 0.22)) * bubbleScale
                    let center=bubbleCenter(slot,generation:generation,size:proxy.size)
                    Button { pop(slot, generation: generation) } label: {
                        BubbleToy(color: GameStyle.palette[(slot * 2 + generation) % GameStyle.palette.count])
                            .overlay {
                                if bubbleFlash == slot {
                                    Text("✦").font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                                } else {
                                    BubbleSurpriseArt(kind:BubbleSurpriseKind(rawValue:(slot+generation)%4) ?? .music,friend:friend,age:elapsed)
                                        .scaleEffect(0.58).frame(width:60,height:60)
                                }
                            }
                            .frame(width: diameter, height: diameter)
                    }.buttonStyle(SquishStyle())
                        .scaleEffect(elapsed-(popTimes[slot] ?? -10)<0.22 ? 0.1 : 1,anchor:.center)
                        .position(center)
                        .animation(reducedMotion ? nil : .spring(response:0.35,dampingFraction:0.6),value:elapsed-(popTimes[slot] ?? -10)<0.22)
                        .accessibilityLabel(store.t("popBubble"))
                        .disabled(paused || giantBubble)
                        .opacity(giantBubble ? 0 : 1)
                }
                ForEach(surprises) {surprise in
                    let age=max(0,elapsed-surprise.born)
                    BubbleSurpriseArt(kind:surprise.kind,friend:friend,age:age)
                        .opacity(max(0,1-age/surprise.lifetime))
                        .position(x:proxy.size.width*(surprise.x+(reducedMotion ? 0 : sin(age*4)*0.04)),
                                  y:proxy.size.height*(surprise.y-(reducedMotion ? 0 : age*0.11)))
                }
                if giantBubble {
                    Button(action: release) {
                        BubbleToy(color: .cyan).overlay(CharacterView(friend: friend).padding(30))
                            .frame(width: min(260, proxy.size.width * 0.8), height: min(260, proxy.size.width * 0.8))
                    }.buttonStyle(SquishStyle()).position(x: proxy.size.width / 2, y: proxy.size.height * 0.45)
                        .accessibilityLabel(store.t("releaseBubble")).disabled(paused || picnic)
                }
            }.frame(width:proxy.size.width,height:proxy.size.height)
                .simultaneousGesture(DragGesture(minimumDistance:5).onChanged {value in
                    guard !paused && !giantBubble else {return}
                    let radius=min(170,max(70,proxy.size.width*0.22))*bubbleScale/2
                    for slot in 0..<6 {
                        let generation=bubbles.generations[slot]
                        let point=bubbleCenter(slot,generation:generation,size:proxy.size)
                        if hypot(point.x-value.location.x,point.y-value.location.y)<radius {pop(slot,generation:generation)}
                    }
                })
        }
    }
    private var blowing:Bool {sin(elapsed*2.6)>0.65}
    private var blowingFriend:FantasyFriend {
        var copy=friend
        if blowing {copy.mouth=3}
        return copy
    }
    private func bubbleCenter(_ slot:Int,generation:Int,size:CGSize)->CGPoint {
        if reducedMotion {return CGPoint(x:size.width*(0.18+Double(slot%3)*0.32),y:size.height*(slot<3 ? 0.32 : 0.59))}
        let age=max(0,elapsed-(popTimes[slot] ?? -Double(slot)*1.3))
        let flight=age.truncatingRemainder(dividingBy:10)
        let spread=min(1,flight/1.6)
        let target=0.18+Double(slot%3)*0.32
        let x=0.5+(target-0.5)*spread+sin(flight*1.4+Double(slot))*0.035*spread
        return CGPoint(x:size.width*x,y:size.height*(0.84-flight*0.064))
    }

    private var hidingField: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / 3
            let cellHeight = proxy.size.height * 0.32
            ZStack {
                ForEach(0..<6) { spot in
                    let opened = seek.opened.contains(spot)
                    let found = seek.hiding.contains(spot) && opened
                    Button {
                        interacted = true
                        let foundNow = seek.reveal(spot)
                        if foundNow {celebration += 1}
                        SoundService.shared.play(foundNow ? (seek.complete ? .complete : .reaction) : .click)
                    } label: {
                        ZStack {
                            if !opened && clueSpot == spot {
                                CharacterView(friend: friend).frame(width: 75, height: 85).offset(y: -35)
                            }
                            if found {
                                CharacterView(friend:hidingFriend(spot),happy:true)
                                    .frame(width: min(115, cellWidth), height: min(125, cellHeight))
                                    .offset(y: -24)
                            } else if opened {
                                Text("🌼").font(.system(size: 48)).offset(y: -20)
                            }
                            BushToy().scaleEffect(min(0.9, cellWidth / 180))
                                .offset(y: opened ? 40 : 5)
                                .opacity(opened ? 0.65 : 1)
                        }.frame(width: cellWidth, height: cellHeight).contentShape(Rectangle())
                    }.buttonStyle(SquishStyle())
                        .position(x: cellWidth * (Double(spot % 3) + 0.5), y: proxy.size.height*0.23+cellHeight*(spot < 3 ? 0.4 : 1.4))
                        .animation(reducedMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: opened)
                        .disabled(paused || opened)
                        .accessibilityLabel(store.t(opened ? (found ? "foundFriend" : "foundFlower") : "searchBush") + " \(spot + 1)")
                }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func hidingFriend(_ spot:Int)->FantasyFriend {
        if store.friends.count>1 {return store.friends[spot%store.friends.count]}
        var copy=friend
        if spot>0 {copy.color=(friend.color+spot*3)%16;copy.accessories.insert(spot%15)}
        return copy
    }
    private func movementButton(direction: Double) -> some View {
        RoundButton(icon: direction < 0 ? "arrow.left" : "arrow.right", label: store.t(direction < 0 ? "moveLeft" : "moveRight")) {
            apples.move(to: apples.playerX + direction * 0.12)
        }
    }

    private func tick(_ date: Date) {
        guard visible, !paused, !picnic, scenePhase == .active, kind != .hide else { lastTick = nil; return }
        guard let previous = lastTick else { lastTick = date; return }
        lastTick = date
        let dt = max(0, min(0.08, date.timeIntervalSince(previous)))
        elapsed += dt
        surprises.removeAll {elapsed-$0.born >= $0.lifetime}
        if kind == .apples, apples.step(dt, spawnX: Double.random(in: 0.17...0.83), catchRadius: catchRadius, level:store.settings.challengeLevel,adventurous:true) {
            cheerUntil = elapsed + 0.7
            SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
            if apples.caught.isMultiple(of:5) || apples.goldenCaught>lastGolden {celebration += 1}
            lastGolden=apples.goldenCaught
        }
        if bubbleFlash != nil && elapsed >= cheerUntil { bubbleFlash = nil }
    }

    private func pop(_ slot: Int, generation: Int) {
        guard !paused,!picnic,elapsed-(popTimes[slot] ?? -10)>0.28,bubbles.pop(slot:slot,generation:generation) else {return}
        let point=bubbleCenter(slot,generation:generation,size:CGSize(width:1,height:1))
        let kind=BubbleSurpriseKind(rawValue:(slot+generation)%4) ?? .music
        surprises.append(BubbleSurprise(kind:kind,x:point.x,y:point.y,born:elapsed))
        if surprises.count>8 {surprises.removeFirst()}
        popTimes[slot]=elapsed
        if kind == .music {SoundService.shared.instrument(1,beat:slot,voice:friend.voice?.rawValue ?? 0)}
        if bubbles.popped.isMultiple(of:6) {celebration += 1}
        interacted = true
        bubbleFlash = slot; cheerUntil = elapsed + 0.25
        SoundService.shared.play(bubbles.popped.isMultiple(of: 10) ? .complete : .reaction)
    }

    private func release() {
        guard !paused else { return }
        giantBubble = false; flyUntil = elapsed + 2; celebration += 1
        for slot in 0..<6 { _ = bubbles.pop(slot: slot, generation: bubbles.generations[slot]) }
        SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
    }
    private func restart() {
        apples = AppleRain(); bubbles = BubbleGarden(); seek = HideAndSeek()
        interacted = false; popTimes=[:]; surprises=[]; lastGolden=0
        picnic = false; giantBubble = false; bubbleScale = 1; clueSpot = nil; flyUntil = 0
        elapsed = 0; cheerUntil = 0; bubbleFlash = nil; lastTick = nil
        SoundService.shared.play(.click)
    }
}
