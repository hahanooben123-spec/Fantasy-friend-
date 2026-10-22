import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var store: FriendStore
    var onEdit: (FantasyFriend, Bool) -> Void
    var body: some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            if store.friends.isEmpty {
                EmptyCollectionView { onEdit(FantasyFriend(), false) }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 16)], spacing: 18) {
                        ForEach(store.friends) { friend in
                            NavigationLink(destination: FriendDetailView(friendID: friend.id, onEdit: onEdit)) {
                                VStack(spacing: 0) {
                                    CharacterView(friend: friend).frame(height: 155)
                                    Text(friend.name).font(.system(.headline, design: .rounded)).lineLimit(2).frame(minHeight: 44).padding(.horizontal, 8)
                                }.padding(8).frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 29).fill(.white.opacity(0.72)))
                            }.buttonStyle(SquishStyle())
                        }
                    }.padding(20)
                }
            }
        }.foregroundColor(GameStyle.ink).navigationTitle(store.t("friends"))
            .navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { onEdit(FantasyFriend(), false) } label: { Image(systemName: "plus.circle.fill").font(.title2).frame(width: 44, height: 44) }.accessibilityLabel(store.t("create"))
                }
            }
    }
}

struct EmptyCollectionView: View {
    @EnvironmentObject private var store: FriendStore
    var create: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                CharacterView(friend: FantasyFriend()).frame(height: 220)
                Text(store.t("empty")).font(.system(.title2, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                Text(store.t("emptyHint")).font(.system(.body, design: .rounded)).multilineTextAlignment(.center)
                CandyButton(title: store.t("create"), icon: "plus", action: create)
            }.padding(28).frame(maxWidth: 500).frame(maxWidth: .infinity)
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
        ZStack {
            WorldBackdrop(world: friend?.world ?? .forest)
            if let friend = friend {
                ScrollView {
                    VStack(spacing: 20) {
                        LivingFriend(friend: friend).frame(height: 320)
                        Text(friend.name).font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        NavigationLink(destination: PlaygroundView(initialID: friend.id, onCreate: { onEdit(FantasyFriend(), false) })) {
                            MenuTile(title: store.t("play"), icon: "sparkles", color: Color(red: 0.26, green: 0.65, blue: 0.57))
                        }
                        CandyButton(title: store.t("edit"), icon: "paintbrush.fill") { onEdit(friend, true) }
                        Button { gate = true } label: {
                            Label(store.t("delete"), systemImage: "lock.fill").font(.system(.footnote, design: .rounded)).frame(minHeight: 48)
                        }.foregroundColor(GameStyle.ink.opacity(0.7))
                    }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
                }
            }
        }.foregroundColor(GameStyle.ink)
            .navigationTitle(friend?.name ?? "FantasiVen").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $gate, onDismiss: { confirm = gatePassed; gatePassed = false }) {
                ParentGate {
                    gatePassed = true
                    gate = false
                }.environmentObject(store)
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
