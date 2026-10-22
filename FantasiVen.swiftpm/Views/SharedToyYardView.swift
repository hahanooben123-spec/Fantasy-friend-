import SwiftUI

struct SharedToyYardView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    let initialFriend: FantasyFriend
    @StateObject private var physics = PlayPhysics()
    @State private var paused = false
    @State private var choosing = false
    private var active: Bool { phase == .active && !paused }

    var body: some View {
        ZStack {
            WorldBackdrop(world: initialFriend.world, animated: !paused)
            VStack(spacing: 12) {
                AdventureHeading(title: store.t("sharedYard"), subtitle: store.t("yardHint"))
                ScrollView {
                    VStack(spacing: 18) {
                        PhysicsPlayfield(physics: physics).frame(height: 370)
                            .background(RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.25)))
                            .clipShape(RoundedRectangle(cornerRadius: 32)).disabled(!active)
                        HStack {
                            ForEach(0..<3) { kind in
                                Button { physics.addToy(kind); SoundService.shared.play(.click) } label: {
                                    VStack(spacing: 5) {
                                        Text(["⚽️", "🧊", "🎈"][kind]).font(.system(size: 37))
                                        Text(store.t(["toy_ball", "toy_block", "toy_balloon"][kind])).font(.system(.caption, design: .rounded).weight(.heavy))
                                    }.frame(maxWidth: .infinity, minHeight: 94).background(CandySurface(color: StudioStyle.colors[kind], cornerRadius: 24)).contentShape(Rectangle())
                                }.buttonStyle(SquishStyle()).disabled(physics.toyCount >= 12 || !active)
                            }
                        }
                        CandyButton(title: store.t("addFriend"), icon: "person.2.fill") { choosing = true }.disabled(physics.friendCount >= 4 || !active)
                        HStack {
                            RoundButton(icon: "arrow.up", label: store.t("jump")) { physics.jump() }.disabled(!active)
                            RoundButton(icon: paused ? "play.fill" : "pause.fill", label: store.t(paused ? "resumeGame" : "pauseGame")) { paused.toggle() }
                            RoundButton(icon: "arrow.counterclockwise", label: store.t("restartGame")) { reset() }
                        }
                    }.padding(20).frame(maxWidth: 1000).frame(maxWidth: .infinity)
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
            .onAppear { reset() }
            .task(id: active) {
                physics.setActive(active)
                guard active else { return }
                while !Task.isCancelled {
                    physics.refresh()
                    do { try await Task.sleep(nanoseconds: 33_333_333) } catch { return }
                }
            }
            .onChange(of: reduced) { _ in reset() }
            .onDisappear { physics.setActive(false) }
            .sheet(isPresented: $choosing) {
                ZStack {
                    WorldBackdrop(world: .clouds)
                    VStack {
                        HStack {
                            Text(store.t("chooseFriend")).font(.title2)
                            Spacer()
                            RoundButton(icon: "xmark", label: store.t("close")) { choosing = false }
                        }.padding()
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))]) {
                                ForEach(store.friends) { friend in
                                    Button { physics.addFriend(friend); physics.refresh(); choosing = false } label: { FriendHomeCard(friend: friend) }.buttonStyle(SquishStyle())
                                }
                            }.padding()
                        }
                    }
                }
            }
    }
    private func reset() {
        physics.configure(friends: [initialFriend], mode: .yard, reducedMotion: reduced)
        physics.addToy(0); physics.addToy(1); physics.addToy(2)
        physics.setActive(active)
    }
}
