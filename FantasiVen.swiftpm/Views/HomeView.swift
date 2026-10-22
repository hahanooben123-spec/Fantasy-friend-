import SwiftUI

struct EditorRequest: Identifiable {
    let id = UUID()
    var friend: FantasyFriend
    var existing: Bool
}

struct HomeView: View {
    @EnvironmentObject private var store: FriendStore
    @State private var editor: EditorRequest?
    private let mascot = FantasyFriend()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    WorldBackdrop()
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            HStack {
                                Text(store.t("eyebrow"))
                                    .font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(2)
                                    .opacity(0.55)
                                Spacer()
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gearshape.fill").font(.system(size: 23)).frame(width: 48, height: 48).background(Circle().fill(.white.opacity(0.7)))
                                }.accessibilityLabel(store.t("settings"))
                            }
                            VStack(spacing: 6) {
                                Text("FantasiVen").font(.system(size: 43, weight: .heavy, design: .rounded)).tracking(-2)
                                    .foregroundColor(GameStyle.purple)
                                Text(store.t("tagline")).font(.system(.subheadline, design: .rounded)).multilineTextAlignment(.center)
                            }
                            LivingFriend(friend: mascot).frame(height: min(geometry.size.height * 0.34, 285))
                            Text(store.t("tap")).font(.system(.caption, design: .rounded)).foregroundColor(GameStyle.purple).padding(.top, -12)
                            VStack(spacing: 14) {
                                CandyButton(title: store.t("create"), icon: "paintbrush.pointed.fill") { openEditor(FantasyFriend(), existing: false) }
                                NavigationLink(destination: GalleryView(onEdit: openEditor)) {
                                    MenuTile(title: store.t("friends"), icon: "square.grid.2x2.fill", color: Color(red: 0.85, green: 0.48, blue: 0.61))
                                }
                                NavigationLink(destination: PlaygroundView(onCreate: { openEditor(FantasyFriend(), existing: false) })) {
                                    MenuTile(title: store.t("play"), icon: "sparkles", color: Color(red: 0.26, green: 0.65, blue: 0.57))
                                }
                            }.buttonStyle(SquishStyle())
                            Text("✦  FANTASIVEN  ✦").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(3).opacity(0.4).padding(.top, 8)
                        }.padding(.horizontal, 28).padding(.top, 10).padding(.bottom, 24).frame(maxWidth: 500).frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationBarHidden(true)
        }.navigationViewStyle(.stack)
        .accentColor(GameStyle.purple).foregroundColor(GameStyle.ink)
        .fullScreenCover(item: $editor) { request in
            BuilderView(original: request.friend, existing: request.existing).environmentObject(store)
        }
        .alert(store.t("error"), isPresented: Binding(get: { store.error != nil && editor == nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
    }
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
