import SwiftUI

struct EditorRequest:Identifiable {
    let id=UUID()
    var friend:FantasyFriend
    var existing:Bool
    var resuming=false
}
struct HomeView:View {
    @EnvironmentObject private var store:FriendStore
    @State private var editor:EditorRequest?
    @State private var resumeNavigation=false
    @StateObject private var pumpkins=PumpkinStore()
    @State private var journey:VillagePlace?
    @State private var destination=VillagePlace.games
    @State private var visitNavigation=false
    @State private var choosingFriend=false
    @State private var createAfterChoosing=false
    @State private var dusk=false
    @State private var homeVisible=true
    @State private var travelFriend:FantasyFriend?
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    private var mascot:FantasyFriend {store.companion}
    var body:some View {
        NavigationView {
            GeometryReader {proxy in
                let tablet=proxy.size.width>=700
                let wide=proxy.size.width>=650 && proxy.size.width>proxy.size.height
                ZStack {
                    WelcomeGardenBackdrop(dusk:dusk,active:homeVisible && journey == nil)
                    VStack(spacing:0) {
                        header(tablet:tablet).padding(.horizontal,tablet ? 28 : 16).padding(.vertical,4)
                        VillageSquare(friend:mascot,lanterns:pumpkins.lanterns,pizza:store.sessions.pizza,
                            wide:wide,dusk:dusk,active:homeVisible && journey == nil && phase == .active,
                            visit:beginVisit,chooseFriend:{choosingFriend=true})
                            .frame(maxWidth:1400,maxHeight:.infinity).frame(maxWidth:.infinity)
                        if recent != nil {
                            resumeCard.padding(.horizontal,tablet ? 28 : 16).padding(.vertical,8).frame(maxWidth:850)
                        }
                    }.disabled(journey != nil).accessibilityHidden(journey != nil)
                    NavigationLink(destination:visitDestination,isActive:$visitNavigation) {EmptyView()}.hidden()
                    NavigationLink(destination:resumeDestination,isActive:$resumeNavigation) {EmptyView()}.hidden()
                    if let place=journey {
                        VillageJourney(place:place,friend:travelFriend ?? mascot) {finishVisit(place)}
                            .zIndex(10)
                    }
                }
            }.navigationBarHidden(true)
                .onAppear {homeVisible=true;pumpkins.reload();SoundService.shared.setWorld(.meadow)}
                .onDisappear {homeVisible=false;journey=nil}
        }.navigationViewStyle(.stack).accentColor(GameStyle.purple).foregroundColor(GameStyle.ink)
            .sheet(isPresented:$choosingFriend,onDismiss:{
                if createAfterChoosing {createAfterChoosing=false;create()}
            }) {
                VillageCompanionPicker(create:{createAfterChoosing=true},close:{choosingFriend=false})
            }
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--preview-creator") {
                    openEditor(FantasyFriend.studioStarter(),existing:false)
                }
                #endif
            }
            .fullScreenCover(item:$editor) {request in
                BuilderView(original:request.friend,existing:request.existing,resuming:request.resuming).environmentObject(store)
            }
            .alert(store.t("error"),isPresented:Binding(get:{store.error != nil && editor == nil},set:{if !$0 {store.error=nil}})) {
                Button("OK") {store.error=nil}
            } message:{Text(store.error ?? "")}
    }
    private func header(tablet:Bool)->some View {
        HStack(spacing:12) {
            BrandTitle(size:tablet ? 42 : 29)
                .minimumScaleFactor(0.75)
            Spacer(minLength:0)
            Button {
                withAnimation(reduced ? nil : .easeInOut(duration:0.5)) {dusk.toggle()}
                SoundService.shared.play(.click)
            } label: {
                Image(systemName:dusk ? "moon.stars.fill" : "sun.max.fill")
                    .font(.system(size:21,weight:.bold)).frame(width:52,height:52)
                    .background(CandySurface(color:StorybookStyle.honey,cornerRadius:26))
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("villageLights"))
            NavigationLink(destination:SettingsView()) {
                Image(systemName:"gearshape.fill").font(.system(size:21,weight:.bold))
                    .frame(width:52,height:52).background(CandySurface(color:StorybookStyle.honey,cornerRadius:26))
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("settings"))
        }.padding(.horizontal,4).padding(.vertical,7)
    }
    private func beginVisit(_ place:VillagePlace) {
        guard journey == nil,!visitNavigation else {return}
        travelFriend=mascot
        journey=place
    }
    private func finishVisit(_ place:VillagePlace) {
        journey=nil
        if place == .studio {create()}
        else {destination=place;visitNavigation=true}
    }
    @ViewBuilder private var visitDestination:some View {
        switch destination {
        case .studio: EmptyView()
        case .pizza: KitchenGameView(friend:travelFriend ?? mascot)
        case .games: MiniGamesView(onCreate:create)
        case .homes: GalleryView(onEdit:openEditor)
        case .pumpkins: PumpkinGameView()
        }
    }

    private var recent:ActivityBookmark? {
        if let value=store.sessions.recent {
            if value.kind == .creator && store.sessions.editor == nil {return nil}
            if value.kind == .room && !store.friends.contains(where:{$0.id == value.friendID}) {return nil}
            return value
        }
        return nil
    }
    private var recentFriend:FantasyFriend {
        store.friends.first {$0.id == recent?.friendID}
            ?? (recent?.kind == .pizza ? store.sessions.pizza?.companion : nil) ?? mascot
    }
    private var resumeCard:some View {
        Button(action:resume) {
            HStack(spacing:12) {
                CharacterView(friend:recentFriend).frame(width:48,height:50).allowsHitTesting(false)
                VillageCaption(title:store.t("resumePlay"),size:18)
                Image(systemName:"play.circle.fill").font(.system(size:32,weight:.heavy))
                    .foregroundColor(StorybookStyle.teal)
            }.padding(.horizontal,18).frame(minHeight:58)
                .background(CandySurface(color:StorybookStyle.cream,cornerRadius:29))
                .contentShape(Capsule())
        }.buttonStyle(SquishStyle())
    }
    private func resume() {
        if recent?.kind == .creator,let draft=store.sessions.editor {
            editor=EditorRequest(friend:draft.friend,existing:draft.existing,resuming:true)
        } else {resumeNavigation=true}
    }
    @ViewBuilder private var resumeDestination:some View {
        switch recent?.kind {
        case .pizza:KitchenGameView(friend:recentFriend)
        case .pumpkin:PumpkinGameView()
        case .room:FriendRoomView(friendID:recentFriend.id)
        case .apples:MiniGameSessionView(kind:.apples,friend:recentFriend)
        case .bubbles:MiniGameSessionView(kind:.bubbles,friend:recentFriend)
        case .orchestra:OrchestraGameView(friend:recentFriend)
        case .playground:PlaygroundView(initialID:recentFriend.id,onCreate:create)
        default:GalleryView(onEdit:openEditor)
        }
    }

    private func create() {openEditor(FantasyFriend.studioStarter(),existing:false)}
    private func openEditor(_ friend:FantasyFriend,existing:Bool) {
        editor=EditorRequest(friend:friend,existing:existing)
    }
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
            .background(CandySurface(color:color,cornerRadius:24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.35), lineWidth: 2))
            .shadow(color: color.opacity(0.25), radius: 0, y: 5)
    }
}
