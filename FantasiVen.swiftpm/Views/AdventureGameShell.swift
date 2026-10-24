import SwiftUI

/// The world occupies the entire viewport. Only the small HUD floats above it.
struct AdventureGameShell<Content: View>: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.scenePhase) private var phase
    let kind: MiniGameKind
    @ViewBuilder var content: (Bool) -> Content
    @State private var paused = false
    var body: some View {
        ZStack {
            WorldBackdrop(world: kind == .orchestra ? .stars : kind == .kitchen ? .castle : .clouds, animated: !paused)
            content(!paused && phase == .active)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .disabled(paused || phase != .active)
            VStack {
                PlayHUD(title:store.t(kind.titleKey),hint:store.t(kind.hintKey),paused:$paused)
                Spacer().allowsHitTesting(false)
            }
            if paused { PlayPauseOverlay(resume:{paused=false}) }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .alert(store.t("error"),isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error=nil}})) {
                Button("OK") {store.error=nil}
            } message:{Text(store.error ?? "")}
    }
}

struct FlowerDifficulty: View {
    @EnvironmentObject private var store: FriendStore
    var body: some View {
        HStack(spacing:8) {
            ForEach(1...3,id:\.self) { level in
                Button {store.updateSettings {$0.challenge=level}} label:{
                    Text(String(repeating:"✿",count:level)).font(.system(size:18,weight:.heavy,design:.rounded))
                        .frame(minWidth:64,minHeight:52)
                        .background(Capsule().fill(store.settings.challengeLevel == level ? StudioStyle.colors[0] : .white))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("challenge")+" \(level)")
                    .accessibilityAddTraits(store.settings.challengeLevel == level ? .isSelected : [])
            }
        }
    }
}

struct GameDestinationView: View {
    let kind: MiniGameKind
    let friend: FantasyFriend
    var body: some View {
        switch kind {
        case .apples,.bubbles,.hide:MiniGameSessionView(kind:kind,friend:friend)
        case .slide,.trampoline:PhysicsAdventureView(kind:kind,friend:friend)
        case .kitchen:KitchenGameView(friend:friend)
        case .orchestra:OrchestraGameView(friend:friend)
        case .path:PathGameView(friend:friend)
        }
    }
}
