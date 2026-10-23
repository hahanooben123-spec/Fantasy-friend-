import SwiftUI

struct SharedToyYardView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    let initialFriend:FantasyFriend
    @StateObject private var physics=PlayPhysics()
    @State private var paused=false
    @State private var choosing=false
    @State private var selectedToy=0
    private var active:Bool {phase == .active && !paused && !choosing}
    var body:some View {
        ZStack {
            WorldBackdrop(world:initialFriend.world,animated:active)
            PhysicsPlayfield(physics:physics,onEmptyTap:{point in
                guard active else {return}
                physics.addToy(selectedToy,at:point);SoundService.shared.play(.click)
            }).disabled(!active)
            VStack {
                PlayHUD(title:store.t("sharedYard"),hint:store.t("yardHint"),paused:$paused)
                Spacer().allowsHitTesting(false)
                PlayDock {
                    ForEach(0..<3) {kind in
                        PlayToken(symbol:["⚽️","🧊","🎈"][kind],label:store.t(["toy_ball","toy_block","toy_balloon"][kind]),selected:kind == selectedToy) {
                            selectedToy=kind;physics.addToy(kind);SoundService.shared.play(.click)
                        }.disabled(physics.toyCount>=12)
                    }
                    Spacer(minLength:0)
                    RoundButton(icon:"person.badge.plus",label:store.t("addFriend")) {choosing=true}.disabled(physics.friendCount>=4)
                    RoundButton(icon:"arrow.up",label:store.t("jump")) {physics.jump()}
                    RoundButton(icon:"arrow.counterclockwise",label:store.t("restartGame"),action:reset)
                }.disabled(!active)
            }
            if paused {PlayPauseOverlay(resume:{paused=false})}
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .onAppear {reset()}
            .task(id:active) {
                physics.setActive(active)
                guard active else {return}
                while !Task.isCancelled {
                    physics.refresh()
                    do {try await Task.sleep(nanoseconds:33_333_333)} catch {return}
                }
            }
            .onChange(of:reduced) {_ in reset()}
            .onDisappear {physics.setActive(false)}
            .sheet(isPresented:$choosing) {
                ZStack {
                    WorldBackdrop(world:.clouds)
                    VStack {
                        HStack {
                            Text(store.t("chooseFriend")).font(.title2)
                            Spacer()
                            RoundButton(icon:"xmark",label:store.t("close")) {choosing=false}
                        }.padding()
                        ScrollView {
                            LazyVGrid(columns:[GridItem(.adaptive(minimum:145))]) {
                                ForEach(store.friends) {friend in
                                    Button {physics.addFriend(friend);physics.refresh();choosing=false} label:{FriendHomeCard(friend:friend)}.buttonStyle(SquishStyle())
                                }
                            }.padding()
                        }
                    }
                }
            }
    }
    private func reset() {
        physics.configure(friends:[initialFriend],mode:.yard,reducedMotion:reduced)
        for toy in 0..<3 {physics.addToy(toy)}
        physics.setActive(active)
    }
}
