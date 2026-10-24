import SwiftUI

private enum PlayPicker: Int, Identifiable {
    case worlds, friends, toys
    var id: Int { rawValue }
}

struct PlaygroundView: View {
    @EnvironmentObject private var store: FriendStore
    var initialID: UUID? = nil
    var onCreate: () -> Void
    @State private var guest=FriendSeed.bimse.make()
    @State private var selectedID: UUID?
    @State private var action: PlayAction = .jump
    @State private var signal = 0
    @State private var paused = false
    @State private var picker: PlayPicker?
    @State private var beforePicker=false
    private let toys: [ToyKind] = [.feather, .berry, .jump, .music, .moon, .heart]
    private var friend: FantasyFriend? {
        store.friends.first { $0.id == (selectedID ?? initialID) } ?? (store.friends.isEmpty ? guest : store.companion)
    }

    var body: some View {
        ZStack {
            WorldBackdrop(world:friend?.world ?? .forest,animated:!paused)
            if let friend=friend {
                RagdollPlayground(friend:friend,action:action,signal:signal,active:!paused).id(friend.id)
                VStack {
                    PlayHUD(title:store.t("playRoom"),hint:store.t("ragdollHint"),paused:$paused)
                    Spacer().allowsHitTesting(false)
                    PlayDock(spacing:0) {
                        ForEach(Array(PlayAction.allCases.enumerated()).filter { [.jump,.tickle,.hug].contains($0.element) },id:\.element.rawValue) { index,item in
                            Button {action=item;signal+=1} label:{
                                ToyGlyph(kind:toys[index]).frame(width:36,height:36)
                                    .frame(maxWidth:.infinity,minHeight:52)
                                    .background(CandySurface(color:StudioStyle.colors[index],cornerRadius:16))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(item.rawValue))
                        }
                        RoundButton(icon:"tray.fill",label:store.t("toybox")) {picker = .toys}
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
            .onAppear {store.visit(.playground,friendID:friend?.id)}
            .sheet(item:$picker) {choice in NavigationView {pickerContent(choice).navigationBarHidden(true)}.navigationViewStyle(.stack)}
            .onChange(of:picker != nil) {value in
                if value {beforePicker=paused;paused=true} else {paused=beforePicker}
            }
    }

    private func pickerContent(_ choice: PlayPicker) -> some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            VStack(spacing: 12) {
                HStack {
                    Text(store.t(choice == .worlds ? "chooseWorld" : choice == .toys ? "toybox" : "chooseFriend")).font(.system(.title2, design: .rounded).weight(.heavy))
                    Spacer()
                    RoundButton(icon: "xmark", label: store.t("close")) { picker = nil }
                }.padding(20)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 15)], spacing: 18) {
                        if choice == .toys {
                            LazyVGrid(columns:[GridItem(.adaptive(minimum:120))],spacing:16) {
                                ForEach(Array(PlayAction.allCases.enumerated()),id:\.element.rawValue) {index,item in
                                    Button {action=item;signal+=1;picker=nil} label:{
                                        VStack(spacing:8) {
                                            ToyGlyph(kind:toys[index]).frame(width:58,height:58)
                                            Text(store.t(item.rawValue)).font(.system(size:16,weight:.heavy,design:.rounded))
                                        }.frame(maxWidth:.infinity,minHeight:110).background(GameChoiceSurface(selected:false))
                                    }.buttonStyle(SquishStyle())
                                }
                            }.padding(18)
                            CandyButton(title:store.t("chooseWorld"),icon:"sparkles") {picker = .worlds}.padding(.horizontal,18)
                            CandyButton(title:store.t("chooseFriend"),icon:"heart.fill") {
                                if store.friends.isEmpty {picker=nil;onCreate()} else {picker = .friends}
                            }.padding(.horizontal,18)
                            ForEach(MiniGameKind.playgroundToys) {toy in
                                NavigationLink(destination:PhysicsAdventureView(kind:toy,friend:friend ?? guest)) {
                                    HStack {
                                        MiniGameArt(kind:toy).frame(width:75,height:65)
                                        Text(store.t(toy == .slide ? "buildTrackToy" : "game_trampoline")).font(.system(size:18,weight:.heavy,design:.rounded))
                                        Spacer()
                                    }.padding(12).background(StorybookShelf())
                                }.buttonStyle(SquishStyle()).padding(.horizontal,18)
                            }
                            NavigationLink(destination:SharedToyYardView(initialFriend:friend ?? guest)) {
                                Label(store.t("sharedYard"),systemImage:"person.3.fill").font(.system(size:18,weight:.heavy,design:.rounded)).padding(18).background(StorybookShelf())
                            }.buttonStyle(SquishStyle()).padding(18)
                        } else if choice == .worlds {
                            ForEach(World.allCases, id: \.rawValue) { world in
                                Button {
                                    guard var value = friend else { return }
                                    value.world = world
                                    if store.friends.contains(where:{$0.id == value.id}) {
                                        if store.save(value) {picker=nil;SoundService.shared.play(.click)}
                                    } else {guest=value;picker=nil;SoundService.shared.play(.click)}
                                } label: {
                                    VStack(spacing: 9) {
                                        WorldBackdrop(world: world, immersive: false, animated: false).frame(height: 112).clipShape(RoundedRectangle(cornerRadius: 24))
                                        Text(store.t(Words.worldKeys[world.rawValue])).font(.system(.headline, design: .rounded)).padding(.bottom, 10)
                                    }.padding(8).background(StorybookPanel(cornerRadius:30))
                                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(friend?.world == world ? GameStyle.purple : .white, lineWidth: 3))
                                }.buttonStyle(SquishStyle()).accessibilityAddTraits(friend?.world == world ? .isSelected : [])
                            }
                        } else {
                            ForEach(store.friends) { value in
                                Button { selectedID = value.id; store.selectCompanion(value.id); signal = 0; picker = nil } label: { FriendHomeCard(friend: value) }
                                    .buttonStyle(SquishStyle()).accessibilityAddTraits(friend?.id == value.id ? .isSelected : [])
                            }
                        }
                    }.padding(20)
                }
            }
        }.foregroundColor(GameStyle.ink)
    }
}
