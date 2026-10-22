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
    @State private var interacted = false
    @State private var lastPicnic = 0
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
        GeometryReader { geometry in
            ZStack {
                WorldBackdrop(world: kind == .bubbles ? .clouds : .meadow, animated: !paused)
                VStack(spacing: 10) {
                    AdventureHeading(title: store.t(kind.titleKey), subtitle: store.t(kind.hintKey))
                    HStack { FlowerDifficulty(); Spacer(); RoundButton(icon: "speaker.wave.2.fill", label: store.t("help")) { SoundService.shared.speak(store.t(kind.hintKey), language: store.settings.language) } }.padding(.horizontal, 20)
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            MiniGameArt(kind: kind).scaleEffect(0.4).frame(width: 42, height: 42)
                            Text(kind == .hide ? "\(count) / 3" : "\(count)")
                                .font(.system(.title2, design: .rounded).weight(.heavy)).monospacedDigit()
                        }.padding(.horizontal, 14).background(Capsule().fill(.white.opacity(0.9)))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(store.t(kind == .hide ? "friendsFound" : kind == .apples ? "applesCaught" : "bubblesPopped"))
                            .accessibilityValue("\(count)")
                        Spacer()
                        RoundButton(icon: "arrow.counterclockwise", label: store.t("restartGame"), action: restart)
                        RoundButton(icon: paused ? "play.fill" : "pause.fill", label: store.t(paused ? "resumeGame" : "pauseGame")) {
                            paused.toggle(); lastTick = nil
                        }
                    }.padding(.horizontal, 20)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 36).fill(.white.opacity(0.27))
                                if kind == .apples { appleField }
                                else if kind == .bubbles { bubbleField }
                                else { hidingField }
                                if !picnic { TouchDemonstration(activity: count + (interacted ? 1 : 0), slide: kind == .apples) }
                                if picnic {
                                    VStack(spacing: 14) {
                                        Text(store.t("picnic")).font(.system(.title2, design: .rounded).weight(.heavy))
                                        HStack {
                                            CharacterView(friend: friend, happy: true).frame(width: 110, height: 120)
                                            Text(apples.fruitBasket.suffix(8).map { ["🍎", "🍌", "🫐"][$0] }.joined()).font(.system(size: 24)).lineLimit(3)
                                        }
                                        CandyButton(title: store.t("keepPlaying"), icon: "play.fill") { lastPicnic = apples.caught; picnic = false; lastTick = nil }
                                        CandyButton(title: store.t("bye"), icon: "hand.wave.fill") { presentation.wrappedValue.dismiss() }
                                    }.padding(20).background(RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.96))).padding(14)
                                }
                                if paused {
                                    RoundedRectangle(cornerRadius: 36).fill(.white.opacity(0.85))
                                    VStack(spacing: 16) {
                                        CharacterView(friend: friend, asleep: true).frame(width: 140, height: 150)
                                        CandyButton(title: store.t("resumeGame"), icon: "play.fill") {
                                            paused = false; lastTick = nil
                                        }.frame(maxWidth: 260)
                                    }.padding()
                                }
                            }
                            .frame(height: max(360, min(geometry.size.height - 235, 630)))
                            .clipShape(RoundedRectangle(cornerRadius: 36))
                            .overlay(RoundedRectangle(cornerRadius: 36).stroke(.white.opacity(0.85), lineWidth: 3))
                            if kind == .apples {
                                HStack {
                                    movementButton(direction: -1)
                                    Text(store.t("appleHelp")).font(.system(.caption, design: .rounded).weight(.bold)).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                    movementButton(direction: 1)
                                }.disabled(paused || picnic)
                            } else if kind == .bubbles {
                                HStack {
                                    RoundButton(icon: "plus", label: store.t("bubbleGrow")) { bubbleScale = bubbleScale >= 1.3 ? 1 : bubbleScale + 0.1 }
                                    CandyButton(title: store.t(giantBubble ? "releaseBubble" : "bubbleMerge"), icon: giantBubble ? "wind" : "circle.grid.2x2.fill") {
                                        if giantBubble { release() } else { giantBubble = true }
                                    }
                                }.disabled(paused || picnic)
                            } else if kind == .hide && seek.complete {
                                CandyButton(title: store.t("hideAgain"), icon: "arrow.triangle.2.circlepath") {
                                    seek = HideAndSeek(); clueSpot = nil; SoundService.shared.play(.click)
                                }.disabled(paused || picnic)
                            } else {
                                if kind == .hide {
                                    RoundButton(icon: "sparkles", label: store.t("clue")) {
                                        clueSpot = seek.hiding.subtracting(seek.opened).first
                                        SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
                                    }.disabled(paused || picnic)
                                }
                                Text(store.t(kind == .hide ? "hideHelp" : "bubbleHelp"))
                                    .font(.system(.subheadline, design: .rounded).weight(.bold)).multilineTextAlignment(.center).padding(8)
                            }
                        }.padding(.horizontal, 18).padding(.bottom, 20).frame(maxWidth: 860).frame(maxWidth: .infinity)
                    }
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
            .onAppear { visible = true; lastTick = nil }
            .onDisappear { visible = false; lastTick = nil; SoundService.shared.stopSpeech() }
            .onChange(of: scenePhase) { _ in lastTick = nil }
            .onReceive(clock) { date in tick(date) }
    }

    private var appleField: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Ellipse().fill(Color.green.opacity(0.16)).frame(width: size.width * 1.5, height: 120).position(x: size.width / 2, y: size.height * 0.99)
                ForEach(Array(apples.flowers.enumerated()), id: \.offset) { index, x in
                    Text(["🌼", "🌸", "🌷"][index % 3]).font(.system(size: 26))
                        .position(x: x * size.width, y: size.height * 0.94)
                }
                ForEach(apples.drops) { apple in
                    Group {
                        if apple.fruit == 0 { AppleToy() }
                        else { Text(apple.fruit == 1 ? "🍌" : "🫐").font(.system(size: 39)) }
                    }.frame(width: 46, height: 48)
                        .rotationEffect(.degrees(reducedMotion ? 0 : sin(apple.y * 9) * 12))
                        .position(x: apple.x * size.width, y: apple.y * size.height)
                        .accessibilityHidden(true)
                }
                CharacterView(friend: friend, happy: elapsed < cheerUntil)
                    .frame(width: 130, height: 142)
                    .position(x: apples.playerX * size.width, y: size.height * 0.83)
                    .allowsHitTesting(false)
                BasketToy().position(x: apples.playerX * size.width, y: size.height * 0.75)
                    .allowsHitTesting(false)
                if elapsed < cheerUntil {
                    Text("✨").font(.system(size: 35))
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
                CharacterView(friend: friend, happy: bubbles.popped > 0)
                    .frame(width: 130, height: 140)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * (elapsed < flyUntil ? 0.25 : 0.82))
                    .allowsHitTesting(false)
                ForEach(0..<6) { slot in
                    let generation = bubbles.generations[slot]
                    let diameter = min(120, max(64, proxy.size.width * 0.22)) * bubbleScale
                    let drift = reducedMotion ? 0.0 : sin(elapsed * 0.7 + Double(slot)) * 7
                    Button { pop(slot, generation: generation) } label: {
                        BubbleToy(color: GameStyle.palette[(slot * 2 + generation) % GameStyle.palette.count])
                            .overlay {
                                if bubbleFlash == slot {
                                    Text("✦").font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                                } else {
                                    CharacterView(friend: friend).padding(11).opacity(0.75)
                                }
                            }
                            .frame(width: diameter, height: diameter)
                    }.buttonStyle(SquishStyle())
                        .position(x: proxy.size.width * (0.19 + Double(slot % 3) * 0.31), y: proxy.size.height * (slot < 3 ? 0.22 : 0.5) + drift)
                        .accessibilityLabel(store.t("popBubble"))
                        .disabled(paused || giantBubble)
                        .opacity(giantBubble ? 0 : 1)
                }
                if giantBubble {
                    Button(action: release) {
                        BubbleToy(color: .cyan).overlay(CharacterView(friend: friend).padding(30))
                            .frame(width: min(260, proxy.size.width * 0.8), height: min(260, proxy.size.width * 0.8))
                    }.buttonStyle(SquishStyle()).position(x: proxy.size.width / 2, y: proxy.size.height * 0.45)
                        .accessibilityLabel(store.t("releaseBubble")).disabled(paused || picnic)
                }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var hidingField: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / 3
            let cellHeight = proxy.size.height * 0.43
            ZStack {
                ForEach(0..<6) { spot in
                    let opened = seek.opened.contains(spot)
                    let found = seek.hiding.contains(spot) && opened
                    Button {
                        interacted = true
                        let foundNow = seek.reveal(spot)
                        SoundService.shared.play(foundNow ? (seek.complete ? .complete : .reaction) : .click)
                    } label: {
                        ZStack {
                            if !opened && clueSpot == spot {
                                CharacterView(friend: friend).frame(width: 75, height: 85).offset(y: -35)
                            }
                            if found {
                                CharacterView(friend: friend, happy: true)
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
                        .position(x: cellWidth * (Double(spot % 3) + 0.5), y: cellHeight * (spot < 3 ? 0.6 : 1.6))
                        .animation(reducedMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: opened)
                        .disabled(paused || opened)
                        .accessibilityLabel(store.t(opened ? (found ? "foundFriend" : "foundFlower") : "searchBush") + " \(spot + 1)")
                }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
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
        if kind == .apples, apples.step(dt, spawnX: Double.random(in: 0.17...0.83), catchRadius: catchRadius, level: store.settings.challengeLevel) {
            cheerUntil = elapsed + 0.7
            SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
            if apples.caught - lastPicnic >= 5 + store.settings.challengeLevel * 2 { picnic = true; lastTick = nil }
        }
        if bubbleFlash != nil && elapsed >= cheerUntil { bubbleFlash = nil }
    }

    private func pop(_ slot: Int, generation: Int) {
        guard !paused, bubbles.pop(slot: slot, generation: generation) else { return }
        interacted = true
        bubbleFlash = slot; cheerUntil = elapsed + 0.25
        SoundService.shared.play(bubbles.popped.isMultiple(of: 10) ? .complete : .reaction)
    }

    private func release() {
        guard !paused else { return }
        giantBubble = false; flyUntil = elapsed + 2
        for slot in 0..<6 { _ = bubbles.pop(slot: slot, generation: bubbles.generations[slot]) }
        SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
    }
    private func restart() {
        apples = AppleRain(); bubbles = BubbleGarden(); seek = HideAndSeek()
        interacted = false
        picnic = false; lastPicnic = 0; giantBubble = false; bubbleScale = 1; clueSpot = nil; flyUntil = 0
        elapsed = 0; cheerUntil = 0; bubbleFlash = nil; lastTick = nil
        SoundService.shared.play(.click)
    }
}
