import SwiftUI

private enum PlayPicker: Int, Identifiable {
    case worlds, friends
    var id: Int { rawValue }
}

struct PlaygroundView: View {
    @EnvironmentObject private var store: FriendStore
    var initialID: UUID? = nil
    var onCreate: () -> Void
    @State private var selectedID: UUID?
    @State private var action: PlayAction = .jump
    @State private var signal = 0
    @State private var paused = false
    @State private var picker: PlayPicker?
    private let toys: [ToyKind] = [.feather, .berry, .jump, .music, .moon, .heart]
    private var friend: FantasyFriend? {
        store.friends.first { $0.id == (selectedID ?? initialID) } ?? store.friends.first
    }

    var body: some View {
        ZStack {
            WorldBackdrop(world:friend?.world ?? .forest,animated:!paused)
            if let friend=friend {
                RagdollPlayground(friend:friend,action:action,signal:signal,active:!paused).id(friend.id)
                VStack {
                    PlayHUD(title:store.t("playRoom"),hint:store.t("ragdollHint"),paused:$paused)
                    Spacer().allowsHitTesting(false)
                    HStack(spacing:8) {
                        Button {picker = .friends} label:{
                            CharacterView(friend:friend).frame(width:48,height:50)
                                .background(Circle().fill(.white))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("chooseFriend"))
                        Button {picker = .worlds} label:{
                            WorldBackdrop(world:friend.world,immersive:false,animated:false)
                                .frame(width:48,height:48).clipShape(Circle()).overlay(Circle().stroke(.white,lineWidth:3))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("chooseWorld"))
                        NavigationLink(destination:SharedToyYardView(initialFriend:friend)) {
                            Image(systemName:"person.3.fill").font(.title2).frame(width:48,height:48).background(Circle().fill(.white))
                        }.accessibilityLabel(store.t("sharedYard"))
                        Spacer()
                    }.padding(.horizontal,16)
                    PlayDock {
                        ForEach(Array(PlayAction.allCases.enumerated()),id:\.element.rawValue) { index,item in
                            Button {action=item;signal+=1} label:{
                                ToyGlyph(kind:toys[index]).frame(width:36,height:36)
                                    .frame(maxWidth:.infinity,minHeight:52)
                                    .background(RoundedRectangle(cornerRadius:16).fill(StudioStyle.colors[index]))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(item.rawValue))
                        }
                    }.disabled(paused)
                }
            } else {
                VStack {
                    AdventureHeading(title:store.t("playRoom"),subtitle:store.t("ragdollHint"))
                    EmptyCollectionView(create:onCreate)
                }
            }
            if paused {PlayPauseOverlay(resume:{paused=false})}
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .sheet(item:$picker) {choice in pickerContent(choice)}
            .onChange(of:picker != nil) {value in paused=value}
    }

    private func pickerContent(_ choice: PlayPicker) -> some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            VStack(spacing: 12) {
                HStack {
                    Text(store.t(choice == .worlds ? "chooseWorld" : "chooseFriend")).font(.system(.title2, design: .rounded).weight(.heavy))
                    Spacer()
                    RoundButton(icon: "xmark", label: store.t("close")) { picker = nil }
                }.padding(20)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 15)], spacing: 18) {
                        if choice == .worlds {
                            ForEach(World.allCases, id: \.rawValue) { world in
                                Button {
                                    guard var value = friend else { return }
                                    value.world = world
                                    if store.save(value) { picker = nil; SoundService.shared.play(.click) }
                                } label: {
                                    VStack(spacing: 9) {
                                        WorldBackdrop(world: world, immersive: false, animated: false).frame(height: 112).clipShape(RoundedRectangle(cornerRadius: 24))
                                        Text(store.t(Words.worldKeys[world.rawValue])).font(.system(.headline, design: .rounded)).padding(.bottom, 10)
                                    }.padding(8).background(RoundedRectangle(cornerRadius: 30).fill(.white.opacity(0.85)))
                                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(friend?.world == world ? GameStyle.purple : .white, lineWidth: 3))
                                }.buttonStyle(SquishStyle()).accessibilityAddTraits(friend?.world == world ? .isSelected : [])
                            }
                        } else {
                            ForEach(store.friends) { value in
                                Button { selectedID = value.id; signal = 0; picker = nil } label: { FriendHomeCard(friend: value) }
                                    .buttonStyle(SquishStyle()).accessibilityAddTraits(friend?.id == value.id ? .isSelected : [])
                            }
                        }
                    }.padding(20)
                }
            }
        }.foregroundColor(GameStyle.ink)
    }
}
