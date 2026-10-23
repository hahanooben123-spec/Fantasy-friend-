import SwiftUI

struct EditorRequest:Identifiable {
    let id=UUID()
    var friend:FantasyFriend
    var existing:Bool
}
struct HomeView:View {
    @EnvironmentObject private var store:FriendStore
    @State private var editor:EditorRequest?
    @State private var starter=FriendSeed.bimse.make()
    private var mascot:FantasyFriend {store.friends.first ?? starter}
    var body:some View {
        NavigationView {
            GeometryReader {proxy in
                let tablet=proxy.size.width>=700
                let landscape=proxy.size.width>=900 && proxy.size.width>proxy.size.height
                ZStack {
                    WorldBackdrop(world:.castle)
                    ScrollView(showsIndicators:false) {
                        VStack(spacing:tablet ? 24 : 18) {
                            header(tablet:tablet)
                            if landscape {
                                HStack(alignment:.top,spacing:28) {
                                    welcome(height:max(310,min(470,proxy.size.height-215)))
                                        .frame(width:min(440,proxy.size.width*0.38))
                                    menu(height:max(145,min(185,(proxy.size.height-250)/2)))
                                        .frame(maxWidth:.infinity)
                                }
                            } else {
                                welcome(height:tablet ? min(300,proxy.size.height*0.28) : 205)
                                menu(height:tablet ? 174 : 151)
                            }
                            Text(store.t("homeFooter")).font(.system(size:11,weight:.semibold,design:.rounded))
                                .multilineTextAlignment(.center).foregroundColor(GameStyle.ink.opacity(0.8))
                                .padding(.top,3)
                        }.padding(.horizontal,tablet ? 28 : 16).padding(.top,16).padding(.bottom,28)
                            .frame(maxWidth:1280).frame(maxWidth:.infinity)
                    }
                }
            }.navigationBarHidden(true)
        }.navigationViewStyle(.stack).accentColor(GameStyle.purple).foregroundColor(GameStyle.ink)
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--preview-creator") {
                    openEditor(FantasyFriend.studioStarter(),existing:false)
                }
                #endif
            }
            .fullScreenCover(item:$editor) {request in
                BuilderView(original:request.friend,existing:request.existing).environmentObject(store)
            }
            .alert(store.t("error"),isPresented:Binding(get:{store.error != nil && editor == nil},set:{if !$0 {store.error=nil}})) {
                Button("OK") {store.error=nil}
            } message:{Text(store.error ?? "")}
    }
    private func header(tablet:Bool)->some View {
        HStack(alignment:.center,spacing:12) {
            VStack(alignment:.leading,spacing:6) {
                BrandTitle(size:tablet ? 43 : 33)
                Text(store.t("homeWelcome")).font(.system(size:tablet ? 16 : 13,weight:.bold,design:.rounded))
                    .foregroundColor(.white).shadow(color:GameStyle.ink.opacity(0.25),radius:2,y:1)
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
        VStack(spacing:13) {
            HomeWelcomeScene(friend:mascot).frame(height:height)
            if let friend=store.friends.first {
                NavigationLink(destination:FriendRoomView(friendID:friend.id)) {
                    HStack(spacing:10) {
                        Image(systemName:"house.fill").font(.system(size:20,weight:.bold)).foregroundColor(GameStyle.purple)
                        VStack(alignment:.leading,spacing:1) {
                            Text(store.t("homeVisitRoom")).font(.system(size:14,weight:.heavy,design:.rounded))
                            Text(friend.name).font(.system(size:12,weight:.semibold,design:.rounded)).lineLimit(1)
                        }
                        Spacer(minLength:0)
                        Image(systemName:"chevron.right").font(.system(size:13,weight:.heavy))
                    }.padding(.horizontal,17).frame(height:57)
                        .background(CandySurface(color:WorkshopLook.cream,cornerRadius:23))
                }.buttonStyle(SquishStyle())
            }
        }
    }
    private func menu(height:CGFloat)->some View {
        VStack(alignment:.leading,spacing:17) {
            FantasyMapView(onCreate:create,onEdit:openEditor,cardHeight:height)
            Text(store.t("homeWorkshops")).font(.system(size:16,weight:.heavy,design:.rounded))
                .padding(.leading,5).padding(.top,5)
            HStack(spacing:16) {
                NavigationLink(destination:KitchenGameView(friend:mascot)) {
                    workshop(title:store.t("game_kitchen"),pumpkin:false)
                }
                NavigationLink(destination:PumpkinGameView()) {
                    workshop(title:store.t("pumpkinTitle"),pumpkin:true)
                }
            }.buttonStyle(SquishStyle())
        }
    }
    private func workshop(title:String,pumpkin:Bool)->some View {
        HStack(spacing:7) {
            Group {
                if pumpkin {PumpkinIllustration(lantern:PumpkinDoor.sample,animated:false)}
                else {PizzaIllustration(recipe:.sample,baked:1,board:false)}
            }.frame(width:49,height:61).accessibilityHidden(true)
            Text(title).font(.system(size:15,weight:.heavy,design:.rounded))
                .lineLimit(2).minimumScaleFactor(0.72).frame(maxWidth:.infinity,alignment:.leading)
        }.padding(.horizontal,10).frame(maxWidth:.infinity).frame(height:86)
            .background(CandySurface(color:pumpkin ? Color(red:0.47,green:0.29,blue:0.62) : Color(red:1,green:0.76,blue:0.39),cornerRadius:25))
            .foregroundColor(pumpkin ? WorkshopLook.cream : GameStyle.ink)
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
