import SwiftUI

struct AdventureGameShell<Content: View>: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.scenePhase) private var phase
    let kind: MiniGameKind
    @ViewBuilder var content: (Bool) -> Content
    @State private var paused = false
    var body: some View {
        ZStack {
            WorldBackdrop(world: kind == .orchestra ? .stars : kind == .kitchen ? .castle : .clouds, animated: !paused)
            VStack(spacing: 12) {
                AdventureHeading(title: store.t(kind.titleKey), subtitle: store.t(kind.hintKey))
                HStack {
                    FlowerDifficulty()
                    Spacer()
                    RoundButton(icon: "speaker.wave.2.fill", label: store.t("help")) { SoundService.shared.speak(store.t(kind.hintKey), language: store.settings.language) }
                    RoundButton(icon: paused ? "play.fill" : "pause.fill", label: store.t(paused ? "resumeGame" : "pauseGame")) { paused.toggle() }
                }.padding(.horizontal, 18)
                ScrollView(showsIndicators: false) {
                    content(!paused && phase == .active)
                        .disabled(paused || phase != .active)
                        .padding(18).frame(maxWidth: 950).frame(maxWidth: .infinity)
                }
            }
            if paused {
                Color.indigo.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("☁️").font(.system(size: 80))
                    Text(store.t("roundDone")).font(.system(.title2, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                    CandyButton(title: store.t("resumeGame"), icon: "play.fill") { paused = false }
                }.padding(28).frame(maxWidth: 350).background(RoundedRectangle(cornerRadius: 36).fill(.white))
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
            .onAppear { SoundService.shared.setWorld(kind == .orchestra ? .stars : kind == .kitchen ? .castle : .clouds) }
            .onDisappear { SoundService.shared.stopSpeech() }
            .alert(store.t("error"), isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
    }
}

struct FlowerDifficulty: View {
    @EnvironmentObject private var store: FriendStore
    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...3, id: \.self) { level in
                Button { store.updateSettings { $0.challenge = level } } label: {
                    Text(String(repeating: "✿", count: level))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .frame(minWidth: 40, minHeight: 44)
                        .background(CandySurface(color: store.settings.challengeLevel == level ? StudioStyle.colors[0] : .white, cornerRadius: 16)).contentShape(Rectangle())
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("challenge") + " \(level)")
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
        case .apples, .bubbles, .hide: MiniGameSessionView(kind: kind, friend: friend)
        case .slide, .trampoline: PhysicsAdventureView(kind: kind, friend: friend)
        case .kitchen: KitchenGameView(friend: friend)
        case .orchestra: OrchestraGameView(friend: friend)
        case .path: PathGameView(friend: friend)
        }
    }
}
