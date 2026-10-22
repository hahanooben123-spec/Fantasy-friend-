import SwiftUI

struct TrackArtwork: View {
    let track: SlideTrack
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for i in 0..<5 {
                let point = CGPoint(x: (0.0875 + Double(i) * 0.2) * size.width, y: (0.2 + track.heights[i] * 0.6) * size.height)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(GameStyle.ink), style: StrokeStyle(lineWidth: 23, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color(StudioStyle.colors[5]), style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }.allowsHitTesting(false)
    }
}

struct PhysicsAdventureView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let kind: MiniGameKind
    let friend: FantasyFriend
    @StateObject private var physics = PlayPhysics()
    @State private var track = SlideTrack()
    @State private var selectedPoint = 0
    @State private var running = false
    @State private var history: [SlideTrack] = []
    @State private var dragStart: SlideTrack?
    @State private var accessibleProgress = 0.0
    @State private var saved = false

    var body: some View {
        AdventureGameShell(kind: kind) { active in
            VStack(spacing: 18) {
                GeometryReader { proxy in
                    ZStack {
                        RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.5))
                        if kind == .slide { TrackArtwork(track: track) }
                        RoomFurniture(kind: 0).frame(width: 80, height: 90).position(x: proxy.size.width * 0.93, y: proxy.size.height * 0.88)
                        if running {
                            PhysicsPlayfield(physics: physics, trampoline: kind == .trampoline)
                        } else if kind == .slide {
                            ForEach(0..<5) { point in
                                Circle().fill(point == selectedPoint ? StudioStyle.colors[1] : StudioStyle.colors[0])
                                    .frame(width: 44, height: 44).overlay(Circle().stroke(.white, lineWidth: 3))
                                    .position(x: (0.0875 + Double(point) * 0.2) * proxy.size.width, y: (0.2 + track.heights[point] * 0.6) * proxy.size.height)
                                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("track")).onChanged { value in
                                        if dragStart == nil { dragStart = track }
                                        selectedPoint = point
                                        track.set(point, y: (value.location.y / proxy.size.height - 0.2) / 0.6)
                                    }.onEnded { _ in
                                        if let previous = dragStart { history.append(previous) }; dragStart = nil
                                    })
                                    .accessibilityLabel(store.t("bodyHeight") + " \(point + 1)")
                            }
                            CharacterView(friend: friend).frame(width: 90, height: 96).position(x: proxy.size.width * 0.1, y: proxy.size.height * 0.12)
                        }
                        if physics.arrived && running {
                            VStack {
                                Text(store.t("wellDone")).font(.system(.title2, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                                Text("✨").font(.system(size: 55))
                            }.padding(18).background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.95)))
                        }
                    }.coordinateSpace(name: "track").clipShape(RoundedRectangle(cornerRadius: 32))
                }.frame(height: 365)
                if kind == .slide && !running {
                    Slider(value: Binding(get: { track.heights[selectedPoint] }, set: { value in track.set(selectedPoint, y: value) }), in: 0.12...0.86)
                        .accessibilityLabel(store.t("bodyHeight"))
                    HStack {
                        RoundButton(icon: "arrow.uturn.backward", label: store.t("undo")) { if let last = history.popLast() { track = last } }.disabled(history.isEmpty)
                        CandyButton(title: store.t("saveCreation"), icon: "heart.fill") { save() }
                    }
                }
                HStack {
                    CandyButton(title: store.t(running ? "buildMore" : "go"), icon: running ? "hammer.fill" : "play.fill") {
                        if running { running = false; physics.setActive(false) }
                        else { start(active: active) }
                    }
                    if kind == .trampoline {
                        RoundButton(icon: "arrow.up", label: store.t("jump")) { physics.jump() }.disabled(!running)
                    }
                }
                if kind == .trampoline && running {
                    Slider(value: Binding(get: { Double(physics.trampolineX) }, set: { value in physics.moveTrampoline(CGFloat(value)); physics.refresh() }), in: 110...690)
                        .accessibilityLabel(store.t("game_trampoline"))
                }
                if saved { Text(store.t("saved")).font(.headline) }
            }
            .task(id: "\(active)-\(running)-\(reduced)") {
                physics.setActive(active && running && !physics.arrived)
                guard active && running else { return }
                while !Task.isCancelled && !physics.arrived {
                    if reduced {
                        accessibleProgress = min(1, accessibleProgress + 0.008)
                        physics.accessibleRide(progress: accessibleProgress, track: kind == .slide ? track : nil)
                    } else { physics.refresh() }
                    do { try await Task.sleep(nanoseconds: 33_333_333) } catch { return }
                }
                physics.setActive(false)
                if physics.arrived { SoundService.shared.play(.complete) }
            }
        }.onAppear { track = friend.track ?? SlideTrack() }
            .onDisappear { physics.setActive(false) }
    }
    private func start(active: Bool) {
        physics.configure(friends: [friend], mode: kind == .slide ? .slide(track) : .trampoline, reducedMotion: reduced)
        physics.scene.speed = [0.75, 0.9, 1.0][store.settings.challengeLevel - 1]
        accessibleProgress = 0; running = true; physics.setActive(active)
    }
    private func save() {
        guard var current = store.friends.first(where: { $0.id == friend.id }) else { return }
        current.track = track
        saved = store.save(current)
    }
}
