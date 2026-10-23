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
    @State private var starter=FriendSeed.bimse.make()
    private var mascot:FantasyFriend {store.friends.first ?? starter}
    var body:some View {
        NavigationView {
            GeometryReader {proxy in
                let tablet=proxy.size.width>=700
                let landscape=proxy.size.width>=900 && proxy.size.width>proxy.size.height
                ZStack {
                    WelcomeGardenBackdrop()
                    ScrollView(showsIndicators:false) {
                        VStack(spacing:tablet ? 18 : 12) {
                            header(tablet:tablet)
                            NavigationLink(destination:resumeDestination,isActive:$resumeNavigation) {EmptyView()}.hidden()
                            if landscape {
                                HStack(alignment:.center,spacing:28) {
                                    VStack(spacing:14) {
                                        welcome(height:min(410,max(270,proxy.size.height-280)))
                                        if recent != nil {resumeCard}
                                    }.frame(width:proxy.size.width*0.39)
                                    menu(height:min(230,max(165,proxy.size.height*0.29)))
                                        .frame(maxWidth:.infinity)
                                }
                            } else {
                                welcome(height:tablet ? 235 : 155)
                                if recent != nil {resumeCard}
                                menu(height:tablet ? 183 : 145)
                            }
                        }.padding(.horizontal,tablet ? 28 : 16).padding(.top,16).padding(.bottom,28)
                            .frame(maxWidth:1280).frame(maxWidth:.infinity)
                    }
                }.onAppear {pumpkins.reload()}
            }.navigationBarHidden(true)
        }.navigationViewStyle(.stack).accentColor(GameStyle.purple).foregroundColor(GameStyle.ink)
            .onAppear {pumpkins.reload()}
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
        HStack(alignment:.center,spacing:12) {
            VStack(alignment:.leading,spacing:6) {
                BrandTitle(size:tablet ? 43 : 33)
                Text(store.t("homeInvitation")).font(.system(size:tablet ? 16 : 13,weight:.bold,design:.rounded))
                    .foregroundColor(WorkshopLook.sea)
            }
            Spacer(minLength:0)
            NavigationLink(destination:SettingsView()) {
                Image(systemName:"gearshape.fill").font(.system(size:22,weight:.bold))
                    .foregroundColor(GameStyle.ink).frame(width:52,height:52)
                    .background(CandySurface(color:WorkshopLook.cream,cornerRadius:24))
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("settings"))
        }
    }
    private func welcome(height:CGFloat)->some View {
        WelcomeCompanion(friend:mascot).frame(height:height)
    }
    private func menu(height:CGFloat)->some View {
        VStack(spacing:14) {
            HStack(spacing:14) {
                Button(action:create) {
                    WelcomeActionCard(kind:.studio,title:store.t("create"),subtitle:store.t("homeCreateHint"),
                        color:Color(red:1,green:0.68,blue:0.22),height:height)
                }
                NavigationLink(destination:MiniGamesView(onCreate:create)) {
                    WelcomeActionCard(kind:.games,title:store.t("homePlayGames"),subtitle:store.t("homePlayHint"),
                        color:Color(red:0.20,green:0.70,blue:0.86),height:height)
                }
            }.buttonStyle(SquishStyle())
            HStack(spacing:12) {
                NavigationLink(destination:GalleryView(onEdit:openEditor)) {
                    littleDoor(title:store.t("homeCollection"),kind:.village)
                }
                if let friend=store.friends.first {
                    NavigationLink(destination:FriendRoomView(friendID:friend.id)) {
                        littleDoor(title:store.t("myRoom"),kind:.studio)
                    }
                } else {
                    NavigationLink(destination:PlaygroundView(onCreate:create)) {
                        littleDoor(title:store.t("homePlay"),kind:.playground)
                    }
                }
            }.buttonStyle(SquishStyle())
            HStack(spacing:12) {
                NavigationLink(destination:KitchenGameView(friend:mascot)) {workshop(title:store.t("game_kitchen"),pumpkin:false)}
                NavigationLink(destination:PumpkinGameView()) {workshop(title:store.t("pumpkinTitle"),pumpkin:true)}
            }.buttonStyle(SquishStyle())
        }
    }
    private func littleDoor(title:String,kind:HomeDestination)->some View {
        HStack(spacing:7) {
            HomeDestinationArt(kind:kind).frame(width:54,height:52)
            Text(title).font(.system(size:15,weight:.heavy,design:.rounded)).lineLimit(2)
                .frame(maxWidth:.infinity,alignment:.leading)
        }.padding(.horizontal,10).frame(maxWidth:.infinity,minHeight:65)
            .background(CandySurface(color:WorkshopLook.cream,cornerRadius:23))
    }
    private func workshop(title:String,pumpkin:Bool)->some View {
        HStack(spacing:7) {
            Group {
                if pumpkin {PumpkinIllustration(lantern:PumpkinDoor.sample,animated:false)}
                else {PizzaIllustration(recipe:.sample,baked:1,board:false)}
            }.frame(width:49,height:61).accessibilityHidden(true)
            Text(title).font(.system(size:15,weight:.heavy,design:.rounded))
                .lineLimit(2).minimumScaleFactor(0.72).frame(maxWidth:.infinity,alignment:.leading)
        }.padding(.horizontal,10).frame(maxWidth:.infinity).frame(height:72)
            .background(CandySurface(color:pumpkin ? Color(red:0.47,green:0.29,blue:0.62) : Color(red:1,green:0.76,blue:0.39),cornerRadius:25))
            .foregroundColor(pumpkin ? WorkshopLook.cream : GameStyle.ink)
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
            HStack(spacing:14) {
                Group {
                    switch recent?.kind {
                    case .creator:CharacterView(friend:store.sessions.editor?.friend ?? mascot)
                    case .pizza:PizzaIllustration(recipe:store.sessions.pizza?.recipe ?? .sample,baked:store.sessions.pizza?.baked ?? 1)
                    case .pumpkin:PumpkinIllustration(lantern:pumpkins.draft ?? pumpkins.lanterns.first ?? PumpkinDoor.sample,animated:false)
                    default:CharacterView(friend:recentFriend)
                    }
                }.frame(width:48,height:51).accessibilityHidden(true)
                VStack(alignment:.leading,spacing:5) {
                    Text(store.t("resumePlay")).font(.system(size:17,weight:.heavy,design:.rounded))
                    Text(store.t("resume_"+(recent?.kind.rawValue ?? "creator")))
                        .font(.system(size:14,weight:.bold,design:.rounded))
                }
                Spacer(minLength:0)
                Image(systemName:"play.fill").font(.system(size:25,weight:.bold))
                    .frame(width:42,height:42).background(Circle().fill(.white.opacity(0.7)))
            }.padding(10).foregroundColor(GameStyle.ink)
                .background(CandySurface(color:WorkshopLook.yellow,cornerRadius:28))
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
