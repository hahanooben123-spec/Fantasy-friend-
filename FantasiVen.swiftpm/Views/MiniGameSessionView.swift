import SwiftUI
import Combine

struct MiniGameSessionView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    let kind: MiniGameKind
    let friend: FantasyFriend
    @Environment(\.presentationMode) private var presentation
    @State private var orchardWalkUntil=0.0
    @State private var orchardDirection=1.0
    @State private var picnic = false
    @State private var picnicSignal=0
    @State private var picnicFruit:Int?
    @State private var picnicShared:Set<Int>=[]
    @State private var bubbleViewport=CGSize(width:390,height:800)
    @State private var bubbleToybox=false
    @State private var bubbleExploring=false
    @State private var bubbleOffsets:[Int:CGSize]=[:]
    @State private var bubbleOrigins:[Int:CGPoint]=[:]
    @State private var giantColor=Color.cyan
    @State private var giantSize=1.0
    @State private var mergedSlots:Set<Int>=[]
    @State private var bubbleSizes:[Int:Double]=[:]
    @State private var heldBubble:Int?
    @State private var heldUntil=0.0
    @State private var paletteOffset=0
    @State private var celebration = 0
    @State private var lastGolden = 0
    @State private var surprises:[BubbleSurprise] = []
    @State private var popTimes: [Int:Double] = [:]
    @State private var interacted = false
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
    @State private var orchardWind=false
    @State private var orchardSize=CGSize(width:390,height:800)
    @State private var orchardLandings:[OrchardLanding]=[]
    @State private var orchardCatchTime = -10.0
    @State private var picnicPoured=false
    @State private var picnicPouring=false
    @State private var lastShareTime = -10.0
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
            WorldBackdrop(world:kind == .bubbles ? .clouds : .meadow,animated:!paused && !bubbleToybox)
            Group {
                if kind == .apples {appleField}
                else if kind == .bubbles {bubbleField}
                else {hidingField}
            }.disabled(paused || picnic || bubbleToybox || scenePhase != .active)
            if kind == .hide {PlayCelebration(revision:celebration)}
            if kind == .apples {orchardHUD} else {
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
                        .padding(12).background(StorybookPanel(cornerRadius:24))
                        .accessibilityLabel(store.t(kind == .hide ? "friendsFound" : kind == .apples ? "applesCaught" : "bubblesPopped"))
                        .accessibilityValue("\(count)")
                    Spacer()

                }.padding(.horizontal,18)
                Spacer().allowsHitTesting(false)
                if !interacted {Text(store.t(kind == .apples ? "appleHelp" : kind == .hide ? "hideHelp" : "bubbleSimpleHint")).font(.system(.subheadline,design:.rounded).weight(.bold)).padding(10).background(StorybookPanel(cornerRadius:24))}
                PlayDock {
                    if kind == .bubbles {
                        Button {paletteOffset=(paletteOffset+3)%16;SoundService.shared.play(.click)} label:{
                            Circle().fill(AngularGradient(colors:[.pink,.yellow,.cyan,.purple,.pink],center:.center))
                                .frame(width:44,height:44).padding(8).background(Circle().fill(.white))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("bubblePalette"))
                        Spacer(minLength:0)
                        RoundButton(icon:"tray.fill",label:store.t("toybox")) {bubbleToybox=true;lastTick=nil}
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
            }
            if picnic {picnicOverlay}
            if paused {
                if kind == .apples {orchardPause}
                else {PlayPauseOverlay(resume:{paused=false;lastTick=nil})}
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .onAppear {visible=true;lastTick=nil;if kind == .apples {apples.setOrchardWind(orchardWind)};if kind == .apples || kind == .bubbles {store.visit(kind == .apples ? .apples : .bubbles,friendID:friend.id)}}
            .onDisappear {visible=false;lastTick=nil;if kind == .apples {store.recordAppleStreak(apples.bestStreak)}}
            .onChange(of:scenePhase) {phase in
                if kind == .apples && phase != .active {store.recordAppleStreak(apples.bestStreak)}
                lastTick=nil
                bubbleOffsets=[:]
                bubbleOrigins=[:]
                heldBubble=nil
            }
            .onChange(of:paused) {_ in
                lastTick=nil
                bubbleOffsets=[:]
                bubbleOrigins=[:]
                heldBubble=nil
            }
            .onChange(of:bubbleToybox) {_ in lastTick=nil}
            .sheet(isPresented:$bubbleToybox) {bubbleExtras}
            .onReceive(clock) {date in tick(date)}
    }

    private var orchardHUD:some View {
        VStack {
            HStack(spacing:12) {
                RoundButton(icon:"chevron.left",label:store.t("back")) {presentation.wrappedValue.dismiss()}
                VillageCaption(title:store.t(kind.titleKey),size:24)
                Spacer(minLength:0)
                if orchardSize.height<520 {
                    orchardScore(store.t("orchardStreak"),value:apples.streak,record:false).frame(width:112)
                    orchardScore(store.t("orchardRecord"),value:store.sessions.appleBestStreak ?? 0,record:true).frame(width:112)
                }
                RoundButton(icon:paused ? "play.fill" : "pause.fill",label:store.t(paused ? "resumeGame" : "pauseGame")) {paused.toggle()}
            }.padding(12)
            if orchardSize.height>=520 {
                HStack(spacing:12) {
                    orchardScore(store.t("orchardStreak"),value:apples.streak,record:false)
                    orchardScore(store.t("orchardRecord"),value:store.sessions.appleBestStreak ?? 0,record:true)
                }.padding(.horizontal,18).frame(maxWidth:500)
            }
            Spacer().allowsHitTesting(false)
            Button {picnicPoured=false;picnicPouring=false;picnicFruit=nil;picnicSignal=0;picnic=true;lastTick=nil} label:{
                HStack(spacing:12) {
                    OrchardBasket(fruits:Array(apples.fruitBasket.suffix(4))).frame(width:72,height:50)
                    Text(store.t("picnic")).font(.system(size:20,weight:.heavy,design:.rounded))
                    if !apples.fruitBasket.isEmpty {
                        Text("\(apples.fruitBasket.count)").font(.system(size:19,weight:.black,design:.rounded))
                            .frame(width:34,height:34).background(Circle().fill(.white))
                    }
                }.padding(.horizontal,20).frame(minHeight:72)
                    .background(CandySurface(color:WorkshopLook.yellow,cornerRadius:30))
            }.buttonStyle(SquishStyle()).disabled(paused).padding(.bottom,12)
                .accessibilityLabel(store.t("picnic")).accessibilityValue("\(apples.fruitBasket.count)")
        }
    }
    private func orchardScore(_ title:String,value:Int,record:Bool)->some View {
        HStack(spacing:8) {
            if record {Image(systemName:"trophy.fill").font(.system(size:24,weight:.bold)).foregroundColor(Color.orange)}
            else {FruitArtwork().frame(width:26,height:28)}
            VStack(alignment:.leading,spacing:1) {
                Text(title).font(.system(size:12,weight:.heavy,design:.rounded))
                Text("\(value)").font(.system(size:23,weight:.black,design:.rounded)).monospacedDigit()
            }
            Spacer(minLength:0)
        }.padding(.horizontal,12).frame(maxWidth:.infinity,minHeight:57)
            .background(StorybookPanel(cornerRadius:22))
            .accessibilityElement(children:.ignore).accessibilityLabel(title).accessibilityValue("\(value)")
    }
    private var orchardPause:some View {
        ZStack {
            GameStyle.ink.opacity(0.35).ignoresSafeArea()
            VStack(spacing:18) {
                LivingFriend(friend:friend,active:false).frame(width:130,height:140)
                CandyButton(title:store.t("resumeGame"),icon:"play.fill",color:StorybookStyle.teal) {paused=false;lastTick=nil}
                Button {
                    orchardWind.toggle();apples.setOrchardWind(orchardWind);SoundService.shared.play(.click)
                } label:{
                    Label(store.t(orchardWind ? "orchardCalm" : "orchardWind"),systemImage:orchardWind ? "leaf.fill" : "wind")
                        .font(.system(size:16,weight:.heavy,design:.rounded)).frame(minHeight:48)
                }.buttonStyle(SquishStyle())
                Button(store.t("restartGame")) {restart();orchardWind=false;apples.calmOrchard();paused=false}
                    .font(.system(size:16,weight:.bold,design:.rounded)).frame(minHeight:48)
            }.padding(24).frame(maxWidth:340).background(StorybookPanel())
        }
    }
    private var picnicOverlay:some View {
        ZStack {
            WorldBackdrop(world:.meadow,animated:scenePhase == .active)
            ScrollView(showsIndicators:false) {
                VStack(spacing:16) {
                    HStack {
                        RoundButton(icon:"chevron.left",label:store.t("keepPlaying")) {picnic=false;lastTick=nil}
                        VillageCaption(title:store.t("picnic"),size:27);Spacer()
                    }
                    LivingFriend(friend:friend,action:.feed,signal:picnicSignal,feedingFood:nil,
                        active:scenePhase == .active,greetOnArrival:true)
                        .frame(height:220).allowsHitTesting(false)
                    if !picnicPoured && !apples.fruitBasket.isEmpty {
                        Button {
                            withAnimation(reducedMotion ? nil : .easeInOut(duration:0.65)) {picnicPouring=true}
                            SoundService.shared.play(.bounce)
                        } label:{
                            VStack(spacing:10) {
                                ZStack {
                                    OrchardBasket(fruits:picnicPouring ? [] : Array(apples.fruitBasket.suffix(5)))
                                        .frame(width:210,height:145)
                                        .rotationEffect(.degrees(reducedMotion ? -12 : picnicPouring ? -75 : -12))
                                        .offset(x:picnicPouring && !reducedMotion ? -45 : 0,y:picnicPouring && !reducedMotion ? -25 : 0)
                                    ForEach(Array(apples.fruitBasket.suffix(6).enumerated()),id:\.offset) {index,kind in
                                        FruitArtwork(kind:kind).frame(width:48,height:48)
                                            .offset(x:picnicPouring ? CGFloat(index%3-1)*55 : -20,
                                                y:picnicPouring ? CGFloat(index/3)*45+48 : 0)
                                            .opacity(picnicPouring ? 1 : 0)
                                    }
                                }.frame(height:190)
                                Label(store.t("orchardPourBasket"),systemImage:"arrow.down.circle.fill")
                                    .font(.system(size:21,weight:.heavy,design:.rounded))
                            }.padding(25).frame(maxWidth:.infinity).background(PicnicBlanket())
                        }.buttonStyle(SquishStyle()).disabled(picnicPouring)
                            .contentShape(Rectangle())
                            .task(id:picnicPouring && scenePhase == .active) {
                                guard picnicPouring else {return}
                                do {try await Task.sleep(nanoseconds:750_000_000);try Task.checkCancellation()} catch {return}
                                withAnimation(reducedMotion ? nil : .easeInOut(duration:0.2)) {picnicPoured=true;picnicPouring=false}
                            }
                    } else if !apples.fruitBasket.isEmpty {
                        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:12),count:4),spacing:16) {
                            ForEach(Array(apples.fruitBasket.enumerated()),id:\.offset) {index,kind in
                                Button {shareFruit(index,kind:kind)} label:{
                                    FruitArtwork(kind:kind).frame(height:76).padding(7)
                                        .background(Circle().fill(.white.opacity(0.8)))
                                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("shareFruit"))
                            }
                        }.padding(20).background(PicnicBlanket())
                            .transition(.scale(scale:reducedMotion ? 1 : 0.8).combined(with:.opacity))
                    } else {
                        FlowerArtwork().frame(width:100,height:110)
                        Text(store.t(apples.caught == 0 ? "picnicEmpty" : "orchardPicnicDone")).font(.system(size:21,weight:.heavy,design:.rounded)).multilineTextAlignment(.center)
                    }
                    CandyButton(title:store.t("keepPlaying"),icon:"play.fill",color:StorybookStyle.teal) {picnic=false;lastTick=nil}
                }.padding(22).frame(maxWidth:560).frame(maxWidth:.infinity)
            }
            if let fruit=picnicFruit,picnicSignal>0 {
                FruitDelivery(kind:fruit,revision:picnicSignal).frame(maxWidth:500,maxHeight:570).allowsHitTesting(false)
            }
        }
    }
    private func shareFruit(_ index:Int,kind:Int) {
        let now=ProcessInfo.processInfo.systemUptime
        guard now-lastShareTime>0.3,let fruit=apples.shareFruit(at:index) else {return}
        lastShareTime=now;picnicFruit=fruit;picnicSignal+=1
        SoundService.shared.play(.munch)
    }

    private var orchardGaze:CGPoint {
        guard let fruit=apples.drops.max(by:{$0.y<$1.y}) else {return .zero}
        return CGPoint(x:min(1,max(-1,(fruit.x-apples.playerX)*4)),y:-0.7)
    }
    private var appleField:some View {
        GeometryReader {proxy in
            let size=proxy.size
            let basket=OrchardMetrics.basketWidth(size)
            let fruit=OrchardMetrics.fruitSize(size)
            let age=max(0,elapsed-orchardCatchTime)
            let bounce=reducedMotion || age>0.5 ? 0 : sin(age*Double.pi/0.5)
            let pending=orchardLandings.filter {elapsed-$0.born<0.42}.count
            ZStack {
                FruitCanopy(weather:apples.weather).frame(height:min(230,size.height*0.28))
                    .position(x:size.width/2,y:size.height*0.22).allowsHitTesting(false)
                Ellipse().fill(Color.green.opacity(0.16)).frame(width:size.width*1.5,height:100)
                    .position(x:size.width/2,y:size.height*0.95).allowsHitTesting(false)
                ForEach(apples.garden) {flower in
                    OrchardBloom(index:flower.variant,time:elapsed,active:!paused && !picnic && scenePhase == .active)
                        .frame(width:65,height:85).position(x:flower.x*size.width,y:size.height*0.88)
                        .allowsHitTesting(false)
                }
                ForEach(apples.drops) {drop in
                    FruitArtwork(kind:drop.fruit,golden:drop.golden).frame(width:fruit,height:fruit)
                        .rotationEffect(.degrees(reducedMotion ? 0 : sin(elapsed*2+drop.x*8)*9))
                        .shadow(color:GameStyle.ink.opacity(0.15),radius:4,y:5)
                        .position(x:drop.x*size.width,y:drop.y*size.height).allowsHitTesting(false)
                }
                CharacterView(friend:friend,blink:elapsed.truncatingRemainder(dividingBy:4.2)>4.05,happy:age<1.3,gaze:orchardGaze,
                    pose:CreatureRig.sample(age<1.3 ? .proud : elapsed<orchardWalkUntil ? .walk : .idle,
                        time:age<1.3 ? age : elapsed,clock:elapsed,energy:orchardDirection,reduced:reducedMotion))
                    .frame(width:OrchardMetrics.friendWidth(size),height:OrchardMetrics.friendWidth(size)*320/300)
                    .position(x:apples.playerX*size.width,y:size.height*0.72).allowsHitTesting(false)
                OrchardBasket(fruits:Array(apples.fruitBasket.dropLast(pending).suffix(5)))
                    .frame(width:basket,height:basket*110/160)
                    .scaleEffect(x:1+bounce*0.06,y:1-bounce*0.10,anchor:.bottom)
                    .position(x:apples.playerX*size.width,y:OrchardMetrics.basketY(size)).allowsHitTesting(false)
                ForEach(orchardLandings) {landing in
                    OrchardLandingArt(landing:landing,time:elapsed,size:size,playerX:apples.playerX,reduced:reducedMotion)
                }
                OrchardCatchBurst(revision:apples.caught,fruit:apples.lastFruit)
                    .frame(width:150,height:150).position(x:apples.playerX*size.width,y:OrchardMetrics.openingY(size))
                if !interacted {
                    if reducedMotion {
                        Image(systemName:"arrow.left.and.right").font(.system(size:35,weight:.heavy))
                            .foregroundColor(.white).shadow(color:GameStyle.purple,radius:2)
                            .position(x:size.width*0.5,y:size.height*0.64).allowsHitTesting(false)
                    } else {
                        GestureLesson(activity:0,from:UnitPoint(x:0.43,y:0.78),to:UnitPoint(x:0.65,y:0.78))
                    }
                }
            }.frame(width:size.width,height:size.height).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0).onChanged {value in
                    guard !paused,!picnic else {return}
                    interacted=true
                    let previous=apples.playerX
                    apples.move(to:value.location.x/max(1,size.width))
                    if abs(apples.playerX-previous)>0.001 {orchardDirection=apples.playerX>previous ? 1 : -1;orchardWalkUntil=elapsed+0.2}
                })
                .onAppear {orchardSize=size}
                .onChange(of:size) {orchardSize=$0}
                .accessibilityElement(children:.ignore).accessibilityLabel(store.t("appleHelp"))
                .accessibilityAdjustableAction {direction in
                    guard !paused,!picnic else {return};interacted=true
                    orchardDirection=direction == .increment ? 1 : -1;orchardWalkUntil=elapsed+0.2
                    apples.move(to:apples.playerX+orchardDirection*0.08)
                }
        }
    }

    private var bubbleField: some View {
        GeometryReader { proxy in
            ZStack {
                CharacterView(friend:blowingFriend,blink:elapsed.truncatingRemainder(dividingBy:4)<0.13,happy:elapsed<cheerUntil && !blowing,gaze:CGPoint(x:sin(elapsed*0.5)*0.35,y:elapsed<flyUntil ? 0.5 : -0.6),expression:elapsed<flyUntil ? .wonder : .normal)
                    .frame(width:min(180,proxy.size.height*0.24),height:min(192,proxy.size.height*0.26))
                    .position(x:proxy.size.width/2,y:proxy.size.height*(elapsed<flyUntil ? 0.25 : 0.81))
                    .animation(reducedMotion ? nil : .easeInOut(duration:0.6),value:elapsed<flyUntil)
                    .allowsHitTesting(false)
                BubbleWand().frame(width:55,height:70)
                    .position(x:proxy.size.width/2+48,y:proxy.size.height*0.83).allowsHitTesting(false)
                ForEach(0..<6) { slot in
                    let generation = bubbles.generations[slot]
                    let diameter=bubbleDiameter(slot,in:proxy.size)
                    let center=bubbleLocation(slot,generation:generation,size:proxy.size)
                    Group {
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
                    }.contentShape(Circle())
                        .scaleEffect(elapsed-(popTimes[slot] ?? -10)<0.22 ? 0.1 : 1,anchor:.center)
                        .highPriorityGesture(LongPressGesture(minimumDuration:0.4).exclusively(before:TapGesture()).onEnded {gesture in
                            switch gesture {
                            case .first:growBubble(slot)
                            case .second:pop(slot,generation:generation)
                            }
                        })
                        .simultaneousGesture(bubbleDrag(slot,generation:generation,size:proxy.size),including:bubbleExploring ? .all : .none)
                        .position(center)
                        .animation(reducedMotion ? nil : .spring(response:0.35,dampingFraction:0.6),value:elapsed-(popTimes[slot] ?? -10)<0.22)
                        .accessibilityLabel(store.t("popBubble"))
                        .accessibilityAddTraits(.isButton).accessibilityAction {pop(slot,generation:generation)}
                        .accessibilityAction(named:Text(store.t("bubbleGrow"))) {growBubble(slot)}
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
                            .frame(width: giantDiameter(proxy.size), height: giantDiameter(proxy.size))
                    }.buttonStyle(SquishStyle()).scaleEffect(giantSize)
                        .animation(reducedMotion ? nil : .spring(response:0.35,dampingFraction:0.6),value:giantSize)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.45)
                        .accessibilityLabel(store.t("releaseBubble")).disabled(paused || picnic)
                }
            }.frame(width:proxy.size.width,height:proxy.size.height)
                .onAppear {bubbleViewport=proxy.size}
                .onChange(of:proxy.size) {bubbleViewport=$0}
                .coordinateSpace(name:"bubbleGarden")
                .overlay(GestureLesson(activity:interacted ? 1 : 0,from:UnitPoint(x:0.5,y:0.4),to:UnitPoint(x:0.5,y:0.4)))
        }
    }


    private func bubbleDiameter(_ slot:Int,in size:CGSize)->CGFloat {
        min(135,min(size.width*0.23,size.height*0.16))*CGFloat(bubbleSizes[slot] ?? 1)
    }
    private func giantDiameter(_ size:CGSize)->CGFloat {min(230,min(size.width*0.66,size.height*0.36))}
    private func bubbleLocation(_ slot:Int,generation:Int,size:CGSize)->CGPoint {
        let base=bubbleOrigins[slot] ?? bubbleCenter(slot,generation:generation,size:size)
        let offset=bubbleOffsets[slot] ?? .zero
        let radius=bubbleDiameter(slot,in:size)/2
        return CGPoint(x:min(max(radius+8,base.x+offset.width),max(radius+8,size.width-radius-8)),
            y:min(max(size.height*0.20+radius,base.y+offset.height),max(size.height*0.20+radius,size.height*0.76-radius)))
    }

    private var bubbleExtras:some View {
        VStack(spacing:20) {
            HStack {VillageCaption(title:store.t("toybox"),size:26);Spacer();RoundButton(icon:"xmark",label:store.t("close")) {bubbleToybox=false}}
            CandyButton(title:store.t(giantBubble ? "releaseBubble" : "bubbleMerge"),icon:"sparkles",color:StorybookStyle.mint) {
                if giantBubble {release()} else {makeGiantBubble()};bubbleToybox=false
            }
            Toggle(store.t("bubbleDragPlay"),isOn:$bubbleExploring).font(.system(size:18,weight:.bold,design:.rounded)).padding(12)
            CandyButton(title:store.t("restartGame"),icon:"arrow.clockwise") {restart();bubbleToybox=false}
        }.padding(24).background(StorybookWorkshopWall())
    }

    private func bubbleColor(_ slot:Int,generation:Int)->Color {
        GameStyle.palette[(slot*2+generation+paletteOffset)%GameStyle.palette.count]
    }
    private func growBubble(_ slot:Int) {
        guard !paused,!mergedSlots.contains(slot) else {return}
        heldBubble=slot;heldUntil=elapsed+0.45;interacted=true
        withAnimation(reducedMotion ? nil : .spring(response:0.4,dampingFraction:0.65)) {
            bubbleSizes[slot]=min(1.45,(bubbleSizes[slot] ?? 1)+0.2)
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
            if bubbleOrigins[slot] == nil {bubbleOrigins[slot]=bubbleLocation(slot,generation:generation,size:size)}
            bubbleOffsets[slot]=value.translation
        }.onEnded {value in
            defer {bubbleOffsets[slot]=nil;bubbleOrigins[slot]=nil}
            guard !paused,!mergedSlots.contains(slot),bubbles.generations[slot] == generation else {return}
            let end=bubbleLocation(slot,generation:generation,size:size)
            let sourceColor=bubbleColor(slot,generation:generation)
            if giantBubble {
                let radius=giantDiameter(size)*giantSize*0.55
                if hypot(end.x-size.width*0.5,end.y-size.height*0.45)<radius {
                    giantColor=GameStyle.mixed(giantColor,with:sourceColor,amount:1/Double(mergedSlots.count+1))
                    mergedSlots.insert(slot)
                    giantSize=min(1.45,1+Double(mergedSlots.count)*0.07)
                    _=bubbles.pop(slot:slot,generation:generation)
                    SoundService.shared.play(.bubble)
                }
                return
            }
            if let other=(0..<6).filter({$0 != slot && !mergedSlots.contains($0)}).min(by:{
                let a=bubbleLocation($0,generation:bubbles.generations[$0],size:size)
                let b=bubbleLocation($1,generation:bubbles.generations[$1],size:size)
                return hypot(a.x-end.x,a.y-end.y)<hypot(b.x-end.x,b.y-end.y)
            }) {
                let target=bubbleLocation(other,generation:bubbles.generations[other],size:size)
                let radius=(bubbleDiameter(slot,in:size)+bubbleDiameter(other,in:size))*0.35
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
    private func tick(_ date: Date) {
        guard visible, !paused, !picnic, !bubbleToybox, scenePhase == .active, kind != .hide else { lastTick = nil; return }
        guard let previous = lastTick else { lastTick = date; return }
        lastTick = date
        let dt = max(0, min(0.08, date.timeIntervalSince(previous)))
        if kind == .apples && !interacted {return}
        elapsed += dt
        surprises.removeAll {elapsed-$0.born >= $0.lifetime}
        if kind == .apples {
            let width=max(1,orchardSize.width),height=max(1,orchardSize.height)
            let radius=(OrchardMetrics.basketWidth(orchardSize)*0.43+OrchardMetrics.fruitSize(orchardSize)*0.20)/width
            let caught=apples.step(dt,spawnX:Double.random(in:0.17...0.83),catchRadius:Double(radius),
                adventurous:orchardWind,catchY:Double(OrchardMetrics.openingY(orchardSize)/height),
                catchHalfHeight:Double((OrchardMetrics.fruitSize(orchardSize)*0.4+8)/height),relaxed:true)
            orchardLandings.removeAll {elapsed-$0.born>0.7}
            if caught {
                store.recordAppleStreak(apples.bestStreak)
                orchardCatchTime=elapsed;cheerUntil=elapsed+0.7
                for drop in apples.lastCatches {orchardLandings.append(OrchardLanding(drop:drop,born:elapsed))}
                SoundService.shared.play(.catchFruit)
            }
        }
        if bubbleFlash != nil && elapsed >= cheerUntil { bubbleFlash = nil }
    }

    private func pop(_ slot: Int, generation: Int) {
        guard !paused,!picnic,!mergedSlots.contains(slot),
              !(heldBubble == slot && elapsed<heldUntil),
              elapsed-(popTimes[slot] ?? -10)>0.28,bubbles.pop(slot:slot,generation:generation) else {return}
        let location=bubbleLocation(slot,generation:generation,size:bubbleViewport)
        let point=CGPoint(x:location.x/max(1,bubbleViewport.width),y:location.y/max(1,bubbleViewport.height))
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
        mergedSlots=[];bubbleSizes=[:];heldBubble=nil;giantSize=1
        interacted = false; popTimes=[:]; surprises=[]; lastGolden=0
        picnic = false; giantBubble = false; clueSpot = nil; flyUntil = 0
        orchardLandings=[];orchardCatchTime = -10;picnicPoured=false;picnicPouring=false
        elapsed = 0; cheerUntil = 0; bubbleFlash = nil; lastTick = nil
        SoundService.shared.play(.click)
    }
}
