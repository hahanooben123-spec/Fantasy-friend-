import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var store: FriendStore
    var onEdit: (FantasyFriend, Bool) -> Void
    var body: some View {
        ZStack {
            WorldBackdrop(world: .meadow)
            VStack(spacing: 14) {
                AdventureHeading(title: store.t("friendVillage"), subtitle: store.t("villageSubtitle"))
                if store.friends.isEmpty { EmptyCollectionView { onEdit(FantasyFriend(), false) } }
                else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 148, maximum: 235), spacing: 16)], spacing: 22) {
                            Button { onEdit(FantasyFriend(), false) } label: {
                                VStack(spacing: 12) {
                                    DestinationArt(kind: .studio).frame(height: 151)
                                    Label(store.t("newFriend"), systemImage: "plus.circle.fill")
                                        .font(.system(.headline, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                                }.foregroundColor(GameStyle.ink).padding(12).frame(maxWidth: .infinity).frame(height: 246)
                                    .background(RoundedRectangle(cornerRadius: 38).fill(StudioStyle.colors[0].opacity(0.65)))
                                    .overlay(RoundedRectangle(cornerRadius: 38).stroke(.white, style: StrokeStyle(lineWidth: 3, dash: [9, 6])))
                            }.buttonStyle(SquishStyle())
                            ForEach(store.friends) { friend in
                                NavigationLink(destination: FriendDetailView(friendID: friend.id, onEdit: onEdit)) {
                                    FriendHomeCard(friend: friend)
                                }.buttonStyle(SquishStyle()).accessibilityLabel(friend.name)
                            }
                        }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 1150).frame(maxWidth: .infinity)
                    }
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
    }
}

struct EmptyCollectionView: View {
    @EnvironmentObject private var store: FriendStore
    var create: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    DestinationArt(kind: .village).opacity(0.65).frame(height: 210)
                    LivingFriend(friend: FantasyFriend()).frame(height: 238).offset(y: 20)
                }.frame(height: 260)
                Text(store.t("empty")).font(.system(size: 29, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                Text(store.t("emptyHint")).font(.system(.body, design: .rounded)).multilineTextAlignment(.center)
                CandyButton(title: store.t("create"), icon: "paintbrush.pointed.fill", color: GameStyle.purple, action: create)
            }.padding(26).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
    }
}

struct FriendDetailView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    let friendID: UUID
    var onEdit: (FantasyFriend, Bool) -> Void
    @State private var gate = false
    @State private var confirm = false
    @State private var gatePassed = false
    private var friend: FantasyFriend? { store.friends.first { $0.id == friendID } }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WorldBackdrop(world: friend?.world ?? .forest)
                if let friend = friend {
                    VStack(spacing: 8) {
                        AdventureHeading(title: friend.name, subtitle: store.t("friendDetailHint"))
                        ScrollView {
                            VStack(spacing: 19) {
                                LivingFriend(friend: friend).frame(height: min(geometry.size.height * 0.48, 420))
                                NavigationLink(destination: PlaygroundView(initialID: friend.id, onCreate: { onEdit(FantasyFriend(), false) })) {
                                    MenuTile(title: store.t("playTogether"), icon: "sparkles", color: Color(red: 0.22, green: 0.62, blue: 0.5))
                                }.buttonStyle(SquishStyle())
                                CandyButton(title: store.t("editLook"), icon: "paintbrush.pointed.fill") { onEdit(friend, true) }
                                Button { gate = true } label: {
                                    Label(store.t("delete"), systemImage: "lock.fill").font(.system(.footnote, design: .rounded)).frame(minHeight: 48)
                                }.foregroundColor(GameStyle.ink.opacity(0.65))
                            }.padding(.horizontal, 24).padding(.bottom, 24).frame(maxWidth: 560).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
        .sheet(isPresented: $gate, onDismiss: { confirm = gatePassed; gatePassed = false }) {
            ParentGate { gatePassed = true; gate = false }.environmentObject(store)
        }
        .alert(store.t("confirmDelete"), isPresented: $confirm) {
            Button(store.t("cancel"), role: .cancel) {}
            Button(store.t("delete"), role: .destructive) {
                if let friend = friend, store.delete(friend) { presentation.wrappedValue.dismiss() }
            }
        }
    }
}

struct ParentGate: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    @State private var answer = ""
    var proceed: () -> Void
    var body: some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "lock.fill").font(.system(size: 44)).padding(.top, 35)
                    Text(store.t("gate")).font(.system(.title2, design: .rounded).weight(.bold))
                    Text(store.t("gateHint")).multilineTextAlignment(.center)
                    TextField("…", text: $answer).keyboardType(.numberPad).multilineTextAlignment(.center)
                        .font(.largeTitle).padding().background(RoundedRectangle(cornerRadius: 20).fill(.white))
                    CandyButton(title: store.t("continue"), icon: "lock.open.fill", action: proceed).disabled(answer != "37").opacity(answer == "37" ? 1 : 0.45)
                    Button(store.t("cancel")) { presentation.wrappedValue.dismiss() }.frame(minHeight: 48)
                }.padding(30)
            }
        }.foregroundColor(GameStyle.ink)
    }
}
