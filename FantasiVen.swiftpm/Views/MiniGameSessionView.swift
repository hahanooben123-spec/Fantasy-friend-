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
    @State private var picnicSignal=0
    @State private var picnicFruit:Int?
    @State private var picnicShared:Set<Int>=[]
    @State private var bubbleOffsets:[Int:CGSize]=[:]
    @State private var bubbleOrigins:[Int:CGPoint]=[:]
    @State private var giantColor=Color.cyan
    @State private var giantSize=1.0
    @State private var mergedSlots:Set<Int>=[]
    @State private var bubbleSizes:[Int:Double]=[:]
    @State private var pinchBases:[Int:Double]=[:]
    @State private var heldBubble:Int?
    @State private var heldUntil=0.0
    @State private var paletteOffset=0
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
                    HStack(spacing:8) {
                        Group {
                            if kind == .apples {FruitArtwork()}
                            else if kind == .bubbles {BubbleToy(color:.cyan)}
                            else {FlowerArtwork()}
                        }.frame(width:30,height:32)
                        Text(kind == .hide ? "\(count) / 3" : "\(count)")
                            .font(.system(size:22,weight:.heavy,design:.rounded)).monospacedDigit()
                    }
                        .padding(12).background(Capsule().fill(.white.opacity(0.9)))
                        .accessibilityLabel(store.t(kind == .hide ? "friendsFound" : kind == .apples ? "applesCaught" : "bubblesPopped"))
                        .accessibilityValue("\(count)")
                    Spacer()
                    if kind == .apples {
                        Button {apples.chooseNextWeather();SoundService.shared.play(.reaction)} label:{
                            HStack(spacing:6) {
                                Image(systemName:["leaf.fill","wind","cloud.sun.fill"][apples.weather.rawValue])
                                Text(store.t(apples.weather.key))
                            }.font(.system(size:12,weight:.heavy,design:.rounded))
                                .padding(12).frame(minHeight:48).background(Capsule().fill(.white.opacity(0.92)))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("changeFruitWeather")).disabled(paused || picnic)
                    }
                }.padding(.horizontal,18)
                Spacer().allowsHitTesting(false)
                if !interacted {Text(store.t(kind == .apples ? "appleHelp" : kind == .hide ? "hideHelp" : "bubbleSwipe")).font(.system(.subheadline,design:.rounded).weight(.bold)).padding(10).background(Capsule().fill(.white.opacity(0.9)))}
                if kind == .apples && apples.fruitBasket.count>=6 && !picnic {
                    Text(store.t("picnicReady")).font(.system(size:14,weight:.heavy,design:.rounded))
                        .padding(10).background(Capsule().fill(WorkshopLook.yellow))
                }
                PlayDock {
                    RoundButton(icon:"arrow.counterclockwise",label:store.t("restartGame"),action:restart)
                    if kind == .apples {
                        movementButton(direction:-1)
                        Spacer(minLength:0)
                        PlayToken(symbol:"🧺",label:store.t("picnic")) {picnicShared=[];picnic=true}
                        Spacer(minLength:0)
                        movementButton(direction:1)
                    } else if kind == .bubbles {
                        PlayToken(symbol:"🫧",label:store.t("bubbleGrow")) {bubbleScale = bubbleScale >= 1.3 ? 1 : bubbleScale+0.1}
                        Button {paletteOffset=(paletteOffset+3)%16;SoundService.shared.play(.click)} label:{
                            Circle().fill(AngularGradient(colors:[.pink,.yellow,.cyan,.purple,.pink],center:.center))
                                .frame(width:38,height:38).padding(8).background(Circle().fill(.white))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("bubblePalette"))
                        Spacer(minLength:0)
                        PlayToken(symbol:"🌈",label:store.t(giantBubble ? "releaseBubble" : "bubbleMerge"),selected:giantBubble) {
                            if giantBubble {release()} else {makeGiantBubble()}
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
            .onAppear {visible=true;lastTick=nil;if kind == .apples || kind == .bubbles {store.visit(kind == .apples ? .apples : .bubbles,friendID:friend.id)}}
            .onDisappear {visible=false;lastTick=nil;SoundService.shared.stopSpeech()}
            .onChange(of:scenePhase) {_ in lastTick=nil;bubbleOffsets=[:];bubbleOrigins=[:];pinchBases=[:];heldBubble=nil]}
            .onChange(of:paused) {_ in lastTick=nil;bubbleOffsets=[:];bubbleOrigins=[:];pinchBases=[:];heldBubble=nil]}
            .onReceive(clock) {date in tick(date)}
    }

    private var picnicOverlay:some View {
        ZStack {
            Color.indigo.opacity(0.38).ignoresSafeArea()
            ScrollView(showsIndicators:false) {
            VStack(spacing:14) {
                LivingFriend(friend:friend,action:.feed,signal:picnicSignal,feedingFood:nil)
                    .frame(height:180).allowsHitTesting(false)
                Text(store.t("picnic")).font(.system(.title2,design:.rounded).weight(.heavy))
                Text(store.t("picnicShareHint")).font(.system(.subheadline,design:.rounded).weight(.bold)).multilineTextAlignment(.center)
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:10),count:4),spacing:12) {
                    ForEach(Array(apples.fruitBasket.enumerated()),id:\.offset) {index,kind in
                        Button {shareFruit(index,kind:kind)} label:{
                            FruitArtwork(kind:kind).frame(height:56)
                                .padding(5).background(Circle().fill(.white.opacity(0.8)))
                                .opacity(picnicShared.contains(index) ? 0.15 : 1)
                        }.buttonStyle(SquishStyle()).disabled(picnicShared.contains(index))
                            .accessibilityLabel(store.t("shareFruit"))
                    }
                }.padding(18).background(PicnicBlanket())
                if apples.fruitBasket.isEmpty {Text(store.t("picnicEmpty")).font(.system(.body,design:.rounded))}
                CandyButton(title:store.t("keepPlaying"),icon:"play.fill") {picnic=false;lastTick=nil}
            }.padding(22).frame(maxWidth:440)
                .background(CandySurface(color:WorkshopLook.cream,cornerRadius:36)).padding(18)
            }.frame(maxWidth:480)
            if let fruit=picnicFruit,picnicSignal>0 {
                FruitDelivery(kind:fruit,revision:picnicSignal).frame(maxWidth:440,maxHeight:550)
            }
        }
    }
    private func shareFruit(_ index:Int,kind:Int) {
        guard !picnicShared.contains(index) else {return}
        picnicShared.insert(index);picnicFruit=kind;picnicSignal+=1
        SoundService.shared.play(.munch)
    }

    private var orchardGaze:CGPoint {
        guard let fruit=apples.drops.max(by:{$0.y<$1.y}) else {return .zero}
        return CGPoint(x:min(1,max(-1,(fruit.x-apples.playerX)*4)),y:-0.7)
    }
    private var appleField: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                VStack {ShakingFruitCanopy(weather:apples.weather,onShake:{guard !paused && !picnic else {return};interacted=true;apples.shake();SoundService.shared.play(.bounce)}).padding(.top,65);Spacer().allowsHitTesting(false)}
                Ellipse().fill(Color.green.opacity(0.16)).frame(width: size.width * 1.5, height: 120).position(x: size.width / 2, y: size.height * 0.99)
                ForEach(Array(apples.flowers.enumerated()), id: \.offset) { index, x in
                    FlowerArtwork(index:index).frame(width:32,height:38)
                        .position(x: x * size.width, y: size.height * 0.94)
                }
                ForEach(apples.drops) { apple in
                    FruitArtwork(kind:apple.fruit,golden:apple.golden).frame(width:46,height:48)
                        .rotationEffect(.degrees(reducedMotion ? 0 : sin(apple.y * 9) * 12))
                        .position(x: apple.x * size.width, y: apple.y * size.height)
                        .accessibilityHidden(true)
                }
                CharacterView(friend:friend,happy:elapsed<cheerUntil,gaze:orchardGaze)
                    .scaleEffect(x:elapsed<cheerUntil ? 1.035 : 1,y:elapsed<cheerUntil ? 0.97 : 1,anchor:.bottom)
                    .animation(reducedMotion ? nil : .spring(response:0.3,dampingFraction:0.5),value:elapsed<cheerUntil)
                    .frame(width: min(210,size.width*0.34), height:min(225,size.width*0.37))
                    .position(x: apples.playerX * size.width, y: size.height * 0.83)
                    .allowsHitTesting(false)
                BasketToy().position(x: apples.playerX * size.width, y: size.height * 0.75)
                    .allowsHitTesting(false)
                HStack(spacing:-3) {
                    ForEach(Array(apples.fruitBasket.suffix(3).enumerated()),id:\.offset) {_,fruit in
                        FruitArtwork(kind:fruit).frame(width:23,height:23)
                    }
                }.position(x:apples.playerX*size.width,y:size.height*0.74).allowsHitTesting(false)
                OrchardCatchBurst(revision:apples.caught,fruit:apples.lastFruit)
                    .frame(width:140,height:140).position(x:apples.playerX*size.width,y:size.height*0.72)
                if elapsed < cheerUntil {
                    FruitArtwork(kind:apples.lastFruit).frame(width:47,height:47)
                        .position(x: apples.playerX * size.width, y: size.height * 0.57)
                        .allowsHitTesting(false)
                }
            }.frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { value in
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
                CharacterView(friend:blowingFriend,blink:elapsed.truncatingRemainder(dividingBy:4)<0.13,happy:elapsed<cheerUntil && !blowing,gaze:CGPoint(x:sin(elapsed*0.5)*0.35,y:elapsed<flyUntil ? 0.5 : -0.6),expression:elapsed<flyUntil ? .wonder : .normal)
                    .frame(width:180,height:192)
                    .position(x:proxy.size.width/2,y:proxy.size.height*(elapsed<flyUntil ? 0.25 : 0.81))
                    .animation(reducedMotion ? nil : .easeInOut(duration:0.6),value:elapsed<flyUntil)
                    .allowsHitTesting(false)
                BubbleWand().frame(width:55,height:70)
                    .position(x:proxy.size.width/2+48,y:proxy.size.height*0.83).allowsHitTesting(false)
                ForEach(0..<6) { slot in
                    let generation = bubbles.generations[slot]
                    let diameter = min(170, max(70, proxy.size.width * 0.22)) * bubbleScale * (bubbleSizes[slot] ?? 1)
                    let base=bubbleOrigins[slot] ?? bubbleCenter(slot,generation:generation,size:proxy.size)
                    let offset=bubbleOffsets[slot] ?? .zero
                    let center=CGPoint(x:base.x+offset.width,y:base.y+offset.height)
                    Button { pop(slot, generation: generation) } label: {
                        BubbleToy(color:bubbleColor(slot,generation:generation))
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
                        .onLongPressGesture(minimumDuration:0.35) {growBubble(slot)}
                        .simultaneousGesture(bubbleDrag(slot,generation:generation,size:proxy.size))
                        .simultaneousGesture(MagnificationGesture().onChanged {scale in
                            guard !paused,!mergedSlots.contains(slot) else {return}
                            if pinchBases[slot] == nil {pinchBases[slot]=bubbleSizes[slot] ?? 1}
                            heldBubble=slot;heldUntil=elapsed+0.45;interacted=true
                            bubbleSizes[slot]=min(1.9,max(0.7,(pinchBases[slot] ?? 1)*Double(scale)))
                        }.onEnded {_ in pinchBases[slot]=nil})
                        .animation(reducedMotion ? nil : .spring(response:0.35,dampingFraction:0.6),value:elapsed-(popTimes[slot] ?? -10)<0.22)
                        .accessibilityLabel(store.t("popBubble"))
                        .disabled(paused || mergedSlots.contains(slot))
                        .opacity(mergedSlots.contains(slot) ? 0 : 1)
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
                        BubbleToy(color:giantColor).overlay(CharacterView(friend: friend).padding(30))
                            .frame(width: min(260, proxy.size.width * 0.8), height: min(260, proxy.size.width * 0.8))
                    }.buttonStyle(SquishStyle()).scaleEffect(giantSize)
                        .animation(reducedMotion ? nil : .spring(response:0.35,dampingFraction:0.6),value:giantSize)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.45)
                        .accessibilityLabel(store.t("releaseBubble")).disabled(paused || picnic)
                }
            }.frame(width:proxy.size.width,height:proxy.size.height)
                .coordinateSpace(name:"bubbleGarden")
                .overlay(GestureLesson(activity:interacted ? 1 : 0,from:UnitPoint(x:0.2,y:0.57),to:UnitPoint(x:0.5,y:0.4)))
        }
    }


    private func bubbleColor(_ slot:Int,generation:Int)->Color {
        GameStyle.palette[(slot*2+generation+paletteOffset)%GameStyle.palette.count]
    }
    private func growBubble(_ slot:Int) {
        guard !paused,!mergedSlots.contains(slot) else {return}
        heldBubble=slot;heldUntil=elapsed+0.45;interacted=true
        withAnimation(reducedMotion ? nil : .spring(response:0.4,dampingFraction:0.65)) {
            bubbleSizes[slot]=min(1.9,(bubbleSizes[slot] ?? 1)+0.25)
        }
        SoundService.shared.play(.bubble)
    }
    private func makeGiantBubble() {
        var color=bubbleColor(0,generation:bubbles.generations[0])
        for slot in 1..<6 {color=GameStyle.mixed(color,with:bubbleColor(slot,generation:bubbles.generations[slot]),amount:1/Double(slot+1))}
        giantColor=color;giantSize=1.25;mergedSlots=Set(0..<6)
        for slot in 0..<6 {_=bubbles.pop(slot:slot,generation:bubbles.generations[slot])}
        withAnimation(reducedMotion ? nil : .spring(response:0.4,dampingFraction:0.65)) {giantBubble=true}
        interacted=true;SoundService.shared.play(.bubble)
    }
    private func bubbleDrag(_ slot:Int,generation:Int,size:CGSize)->some Gesture {
        DragGesture(minimumDistance:10,coordinateSpace:.named("bubbleGarden")).onChanged {value in
            guard !paused,!mergedSlots.contains(slot),bubbles.generations[slot] == generation else {return}
            interacted=true
            if bubbleOrigins[slot] == nil {bubbleOrigins[slot]=bubbleCenter(slot,generation:generation,size:size)}
            bubbleOffsets[slot]=value.translation
        }.onEnded {value in
            defer {bubbleOffsets[slot]=nil;bubbleOrigins[slot]=nil}
            guard !paused,!mergedSlots.contains(slot),bubbles.generations[slot] == generation else {return}
            let origin=bubbleOrigins[slot] ?? bubbleCenter(slot,generation:generation,size:size)
            let end=CGPoint(x:origin.x+value.translation.width,y:origin.y+value.translation.height)
            let sourceColor=bubbleColor(slot,generation:generation)
            if giantBubble {
                let radius=min(260,size.width*0.8)*giantSize*0.55
                if hypot(end.x-size.width*0.5,end.y-size.height*0.45)<radius {
                    giantColor=GameStyle.mixed(giantColor,with:sourceColor,amount:1/Double(mergedSlots.count+1))
                    mergedSlots.insert(slot)
                    giantSize=min(1.45,1+Double(mergedSlots.count)*0.07)
                    _=bubbles.pop(slot:slot,generation:generation)
                    SoundService.shared.play(.bubble)
                }
                return
            }
            let diameter=min(170,max(70,size.width*0.22))*bubbleScale
            if let other=(0..<6).filter({$0 != slot && !mergedSlots.contains($0)}).min(by:{
                let a=bubbleCenter($0,generation:bubbles.generations[$0],size:size)
                let b=bubbleCenter($1,generation:bubbles.generations[$1],size:size)
                return hypot(a.x-end.x,a.y-end.y)<hypot(b.x-end.x,b.y-end.y)
            }) {
                let target=bubbleCenter(other,generation:bubbles.generations[other],size:size)
                let radius=diameter*((bubbleSizes[slot] ?? 1)+(bubbleSizes[other] ?? 1))*0.32
                if hypot(target.x-end.x,target.y-end.y)<radius {
                    giantColor=GameStyle.mixed(sourceColor,with:bubbleColor(other,generation:bubbles.generations[other]),amount:0.5)
                    mergedSlots=[slot,other];giantSize=1
                    _=bubbles.pop(slot:slot,generation:generation)
                    _=bubbles.pop(slot:other,generation:bubbles.generations[other])
                    withAnimation(reducedMotion ? nil : .spring(response:0.45,dampingFraction:0.65)) {giantBubble=true}
                    SoundService.shared.play(.bubble)
                }
            }
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
                                FlowerArtwork().frame(width:48,height:54).offset(y: -20)
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
            SoundService.shared.play(.catchFruit)
            if apples.caught.isMultiple(of:5) || apples.goldenCaught>lastGolden {celebration += 1}
            lastGolden=apples.goldenCaught
        }
        if bubbleFlash != nil && elapsed >= cheerUntil { bubbleFlash = nil }
    }

    private func pop(_ slot: Int, generation: Int) {
        guard !paused,!picnic,!mergedSlots.contains(slot),
              !(heldBubble == slot && elapsed<heldUntil),
              elapsed-(popTimes[slot] ?? -10)>0.28,bubbles.pop(slot:slot,generation:generation) else {return}
        let point=bubbleCenter(slot,generation:generation,size:CGSize(width:1,height:1))
        let kind=BubbleSurpriseKind(rawValue:(slot+generation)%4) ?? .music
        surprises.append(BubbleSurprise(kind:kind,x:point.x,y:point.y,born:elapsed))
        if surprises.count>8 {surprises.removeFirst()}
        popTimes[slot]=elapsed;bubbleSizes[slot]=nil
        if kind == .music {SoundService.shared.instrument(1,beat:slot,voice:friend.voice?.rawValue ?? 0)}
        if bubbles.popped.isMultiple(of:6) {celebration += 1}
        interacted = true
        bubbleFlash = slot; cheerUntil = elapsed + 0.25
        SoundService.shared.play(bubbles.popped.isMultiple(of: 10) ? .complete : .bubble)
    }

    private func release() {
        guard !paused else { return }
        giantBubble = false; flyUntil = elapsed + 2; celebration += 1
        for slot in 0..<6 where !mergedSlots.contains(slot) {_=bubbles.pop(slot:slot,generation:bubbles.generations[slot])}
        for slot in 0..<6 {popTimes[slot]=elapsed}
        for i in 0..<4 {
            surprises.append(BubbleSurprise(kind:i.isMultiple(of:2) ? .butterfly : .paint,x:0.29+Double(i)*0.14,y:0.44,born:elapsed))
        }
        if surprises.count>12 {surprises.removeFirst(surprises.count-12)}
        mergedSlots=[];bubbleSizes=[:];giantSize=1
        SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
    }
    private func restart() {
        apples = AppleRain(); bubbles = BubbleGarden(); seek = HideAndSeek()
        picnicShared=[];picnicSignal=0;picnicFruit=nil;bubbleOffsets=[:];bubbleOrigins=[:]
        mergedSlots=[];bubbleSizes=[:];pinchBases=[:];heldBubble=nil;giantSize=1
        interacted = false; popTimes=[:]; surprises=[]; lastGolden=0
        picnic = false; giantBubble = false; bubbleScale = 1; clueSpot = nil; flyUntil = 0
        elapsed = 0; cheerUntil = 0; bubbleFlash = nil; lastTick = nil
        SoundService.shared.play(.click)
    }
}
