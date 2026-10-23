import SwiftUI

struct MiniGamesView:View {
    @EnvironmentObject private var store:FriendStore
    let onCreate:()->Void
    @State private var guest=FriendSeed.bimse.make()
    @State private var selectedID:UUID?
    @State private var choosingFriend=false
    private var friend:FantasyFriend {
        store.friends.first {$0.id == selectedID} ?? store.friends.first ?? guest
    }
    var body:some View {
        ZStack {
            WelcomeGardenBackdrop()
            VStack(spacing:8) {
                AdventureHeading(title:store.t("homePlayGames"),subtitle:store.t("gamesInvitation"))
                ScrollView(showsIndicators:false) {
                    VStack(spacing:16) {
                        HStack(spacing:12) {
                            CharacterView(friend:friend).frame(width:60,height:64).accessibilityHidden(true)
                            Text(store.friends.isEmpty ? store.t("guestPlay") : friend.name)
                                .font(.system(size:18,weight:.heavy,design:.rounded)).lineLimit(1)
                            Spacer(minLength:0)
                            Button {
                                if store.friends.isEmpty {onCreate()} else {choosingFriend=true}
                            } label:{
                                Image(systemName:store.friends.isEmpty ? "paintbrush.fill" : "arrow.triangle.2.circlepath")
                                    .font(.system(size:22,weight:.bold)).frame(width:52,height:52)
                                    .background(CandySurface(color:WorkshopLook.yellow,cornerRadius:19))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(store.friends.isEmpty ? "create" : "chooseFriend"))
                        }.padding(.horizontal,13).padding(.vertical,5).background(CandySurface(color:WorkshopLook.cream,cornerRadius:26))
                        LazyVGrid(columns:[GridItem(.flexible(),spacing:14),GridItem(.flexible(),spacing:14)],spacing:15) {
                            ForEach(MiniGameKind.menuGames) {kind in
                                NavigationLink(destination:GameDestinationView(kind:kind,friend:friend).id(friend.id)) {
                                    GameInvitationCard(kind:kind,friend:friend)
                                }.buttonStyle(SquishStyle())
                            }
                        }
                        NavigationLink(destination:PlaygroundView(initialID:friend.id,onCreate:onCreate)) {
                            HStack(spacing:12) {
                                HomeDestinationArt(kind:.playground).frame(width:88,height:68)
                                VStack(alignment:.leading,spacing:4) {
                                    Text(store.t("freePlayDoor")).font(.system(size:20,weight:.heavy,design:.rounded))
                                    Text(store.t("freePlayHint")).font(.system(size:13,weight:.semibold,design:.rounded))
                                }
                                Spacer(minLength:0)
                                Image(systemName:"play.fill").font(.system(size:23,weight:.heavy))
                            }.padding(12).background(CandySurface(color:WorkshopLook.yellow,cornerRadius:27))
                        }.buttonStyle(SquishStyle())
                    }.padding(.horizontal,18).padding(.bottom,22).frame(maxWidth:900).frame(maxWidth:.infinity)
                }
            }
        }.foregroundColor(WorkshopLook.sea).navigationBarHidden(true)
            .sheet(isPresented:$choosingFriend) {
                ZStack {
                    WelcomeGardenBackdrop()
                    VStack {
                        HStack {
                            Text(store.t("chooseFriend")).font(.system(.title2,design:.rounded).weight(.heavy))
                            Spacer()
                            RoundButton(icon:"xmark",label:store.t("close")) {choosingFriend=false}
                        }.padding(20)
                        ScrollView {
                            LazyVGrid(columns:[GridItem(.adaptive(minimum:145))],spacing:18) {
                                ForEach(store.friends) {candidate in
                                    Button {selectedID=candidate.id;choosingFriend=false;SoundService.shared.play(.click)} label:{
                                        FriendHomeCard(friend:candidate)
                                    }.buttonStyle(SquishStyle())
                                }
                            }.padding(20)
                        }
                    }
                }
            }
    }
}
private struct GameInvitationCard:View {
    @EnvironmentObject private var store:FriendStore
    let kind:MiniGameKind
    let friend:FantasyFriend
    var body:some View {
        VStack(spacing:8) {
            GeometryReader {proxy in
                ZStack {
                    Circle().fill(.white.opacity(0.34)).frame(width:115,height:115)
                    CharacterView(friend:friend,happy:false,gaze:CGPoint(x:0.5,y:0.2))
                        .frame(width:90,height:98).rotationEffect(.degrees(-8))
                        .position(x:proxy.size.width*0.34,y:proxy.size.height*0.55)
                    MiniGameArt(kind:kind).scaleEffect(0.85)
                        .position(x:proxy.size.width*0.69,y:proxy.size.height*0.58)
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
            }.frame(height:112).accessibilityHidden(true)
            HStack {
                Text(store.t(kind.titleKey)).font(.system(size:20,weight:.heavy,design:.rounded)).lineLimit(2)
                Spacer(minLength:0)
                Image(systemName:"play.fill").font(.system(size:14,weight:.heavy))
            }.padding(.horizontal,13).padding(.bottom,13)
        }.frame(maxWidth:.infinity,minHeight:172)
            .background(CandySurface(color:kind.tint,cornerRadius:29))
            .overlay(RoundedRectangle(cornerRadius:29).stroke(.white.opacity(0.65),lineWidth:2))
            .contentShape(RoundedRectangle(cornerRadius:29))
    }
}

extension MiniGameKind {
    var tint: Color {
        switch self {
        case .slide, .trampoline, .apples: return Color(red: 1, green: 0.70, blue: 0.15)
        case .orchestra, .path, .bubbles: return Color(red: 0.22, green: 0.77, blue: 1)
        case .kitchen, .hide: return Color(red: 0.64, green: 0.87, blue: 0.22)
        }
    }
}

struct MiniGamesDoor: View {
    @EnvironmentObject private var store: FriendStore
    var body: some View {
        HStack(spacing: 10) {
            MiniGameArt(kind: .apples).scaleEffect(0.76).frame(width: 80, height: 85)
            VStack(alignment: .leading, spacing: 5) {
                Text(store.t("miniGames")).font(.system(size: 24, weight: .heavy, design: .rounded))
                Text(store.t("miniGamesDoor")).font(.system(.subheadline, design: .rounded))
            }
            Spacer(minLength: 0)
            Image(systemName: "play.fill").font(.title2).padding(.trailing, 19)
        }.foregroundColor(GameStyle.ink).padding(9).frame(maxWidth: .infinity)
            .background(CandySurface(color: Color(red: 0.49, green: 0.76, blue: 1), cornerRadius: 30))
            .contentShape(RoundedRectangle(cornerRadius: 30))
    }
}
