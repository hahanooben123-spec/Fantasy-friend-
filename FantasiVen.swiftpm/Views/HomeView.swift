import SwiftUI

struct EditorRequest: Identifiable {
    let id = UUID()
    var friend: FantasyFriend
    var existing: Bool
}

struct HomeView: View {
    @EnvironmentObject private var store: FriendStore
    @State private var editor: EditorRequest?
    private var mascot: FantasyFriend { store.friends.first ?? FantasyFriend() }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 700
                ZStack {
                    WorldBackdrop(world: .forest)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            HStack {
                                BrandTitle(size: wide ? 52 : 36)
                                Spacer(minLength: 6)
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gearshape.fill").font(.system(size: 23, weight: .bold))
                                        .foregroundColor(GameStyle.ink).frame(width: 50, height: 50)
                                        .background(Circle().fill(Color.white.opacity(0.88)))
                                        .shadow(color: GameStyle.purple.opacity(0.12), radius: 0, y: 4)
                                }.accessibilityLabel(store.t("settings"))
                            }
                            Text(store.t("tagline")).font(.system(.subheadline, design: .rounded).weight(.semibold)).multilineTextAlignment(.center)
                            welcomeStage.frame(height: min(geometry.size.height * (wide ? 0.35 : 0.29), wide ? 350 : 245))
                            if wide {
                                HStack(alignment: .top, spacing: 19) {
                                    Button { openEditor(FantasyFriend(), existing: false) } label: {
                                        DestinationCard(kind: .studio, title: store.t("create"), subtitle: store.t("studioDoorHint"))
                                    }
                                    NavigationLink(destination: GalleryView(onEdit: openEditor)) {
                                        DestinationCard(kind: .village, title: store.t("friendVillage"), subtitle: store.t("villageDoorHint"))
                                    }
                                    NavigationLink(destination: PlaygroundView(onCreate: create)) {
                                        DestinationCard(kind: .playground, title: store.t("playRoom"), subtitle: store.t("playDoorHint"))
                                    }
                                }.buttonStyle(SquishStyle())
                            } else {
                                Button(action: create) {
                                    HStack(spacing: 6) {
                                        DestinationArt(kind: .studio).frame(width: 135, height: 108)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(store.t("create")).font(.system(size: 24, weight: .heavy, design: .rounded))
                                            Text(store.t("studioDoorHint")).font(.system(.caption, design: .rounded)).lineLimit(2)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "arrow.right").font(.system(size: 21, weight: .heavy)).padding(.trailing, 14)
                                    }.foregroundColor(GameStyle.ink).padding(7)
                                        .background(CandySurface(color: StudioStyle.colors[0], cornerRadius: 32))
                                        .contentShape(RoundedRectangle(cornerRadius: 32))
                                }.buttonStyle(SquishStyle())
                                HStack(alignment: .top, spacing: 14) {
                                    NavigationLink(destination: GalleryView(onEdit: openEditor)) {
                                        DestinationCard(kind: .village, title: store.t("friendVillage"), subtitle: "", compact: true)
                                    }
                                    NavigationLink(destination: PlaygroundView(onCreate: create)) {
                                        DestinationCard(kind: .playground, title: store.t("playRoom"), subtitle: "", compact: true)
                                    }
                                }.buttonStyle(SquishStyle())
                            }
                            NavigationLink(destination: MiniGamesView(onCreate: create)) { MiniGamesDoor() }
                                .buttonStyle(SquishStyle())
                            Text(store.t("homeFooter")).font(.system(.caption, design: .rounded).weight(.semibold)).padding(.top, 7).opacity(0.7)
                        }.padding(.horizontal, wide ? 28 : 19).padding(.top, 12).padding(.bottom, 24)
                            .frame(maxWidth: 1100).frame(maxWidth: .infinity)
                    }
                }
            }.navigationBarHidden(true)
        }.navigationViewStyle(.stack)
        .accentColor(GameStyle.purple).foregroundColor(GameStyle.ink)
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-creator") {
                openEditor(FantasyFriend(), existing: false)
            }
            #endif
        }
        .fullScreenCover(item: $editor) { request in
            BuilderView(original: request.friend, existing: request.existing).environmentObject(store)
        }
        .alert(store.t("error"), isPresented: Binding(get: { store.error != nil && editor == nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
    }

    private var welcomeStage: some View {
        GeometryReader { geometry in
            ZStack {
                Ellipse().fill(Color.white.opacity(0.35)).frame(width: geometry.size.width * 0.87, height: 35).offset(y: geometry.size.height * 0.38)
                CharacterView(friend: sample(color: 5, body: .cloud, extra: 8))
                    .frame(height: geometry.size.height * 0.62).rotationEffect(.degrees(-10))
                    .offset(x: -min(geometry.size.width * 0.3, 200), y: geometry.size.height * 0.16)
                    .accessibilityHidden(true)
                CharacterView(friend: sample(color: 2, body: .round, extra: 0))
                    .frame(height: geometry.size.height * 0.56).rotationEffect(.degrees(12))
                    .offset(x: min(geometry.size.width * 0.3, 200), y: geometry.size.height * 0.19)
                    .accessibilityHidden(true)
                LivingFriend(friend: mascot).frame(height: geometry.size.height * 0.98)
                Text(store.t("homePrompt")).font(.system(.caption, design: .rounded).weight(.heavy))
                    .padding(.horizontal, 15).padding(.vertical, 10).background(Capsule().fill(.white))
                    .rotationEffect(.degrees(-6)).position(x: geometry.size.width * 0.24, y: geometry.size.height * 0.13)
                    .allowsHitTesting(false)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    private func sample(color: Int, body: BodyKind, extra: Int) -> FantasyFriend {
        var value = FantasyFriend(); value.color = color; value.body = body; value.accessories = [extra]; return value
    }
    private func create() { openEditor(FantasyFriend(), existing: false) }
    private func openEditor(_ friend: FantasyFriend, existing: Bool) { editor = EditorRequest(friend: friend, existing: existing) }
}

struct MenuTile: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 23, weight: .bold)).frame(width: 30)
            Text(title).font(.system(.headline, design: .rounded))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .heavy))
        }.foregroundColor(.white).padding(.horizontal, 21).frame(minHeight: 58)
            .background(RoundedRectangle(cornerRadius: 24).fill(color))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.35), lineWidth: 2))
            .shadow(color: color.opacity(0.25), radius: 0, y: 5)
    }
}
