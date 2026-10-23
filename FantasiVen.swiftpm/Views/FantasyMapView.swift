import SwiftUI

struct FantasyMapView:View {
    @EnvironmentObject private var store:FriendStore
    let onCreate:()->Void
    let onEdit:(FantasyFriend,Bool)->Void
    var cardHeight:CGFloat=172
    var body:some View {
        LazyVGrid(columns:[GridItem(.flexible(),spacing:16),GridItem(.flexible(),spacing:16)],spacing:18) {
            Button(action:onCreate) {
                HomeMenuCard(kind:.studio,title:store.t("create"),color:GameStyle.palette[3],height:cardHeight)
            }
            NavigationLink(destination:GalleryView(onEdit:onEdit)) {
                HomeMenuCard(kind:.village,title:store.t("homeCollection"),color:GameStyle.palette[1],height:cardHeight)
            }
            NavigationLink(destination:PlaygroundView(onCreate:onCreate)) {
                HomeMenuCard(kind:.playground,title:store.t("homePlay"),color:GameStyle.palette[11],height:cardHeight)
            }
            NavigationLink(destination:MiniGamesView(onCreate:onCreate)) {
                HomeMenuCard(kind:.games,title:store.t("homeGames"),color:GameStyle.palette[6],height:cardHeight)
            }
        }.buttonStyle(SquishStyle())
    }
}
struct HomeMenuCard:View {
    let kind:HomeDestination
    let title:String
    let color:Color
    let height:CGFloat
    var body:some View {
        VStack(spacing:0) {
            HomeDestinationArt(kind:kind).frame(height:height-55).frame(maxWidth:.infinity).padding(.horizontal,8)
            HStack(spacing:6) {
                Text(title).font(.system(size:height<160 ? 17 : 21,weight:.heavy,design:.rounded))
                    .lineLimit(2).minimumScaleFactor(0.7)
                Spacer(minLength:0)
                Image(systemName:"arrow.right").font(.system(size:12,weight:.heavy))
                    .frame(width:25,height:25).background(Circle().fill(.white.opacity(0.55)))
            }.padding(.horizontal,14).frame(height:49)
        }.frame(maxWidth:.infinity).frame(height:height)
            .background(CandySurface(color:GameStyle.mixed(color,with:.white,amount:0.53),cornerRadius:30))
            .overlay(RoundedRectangle(cornerRadius:30).stroke(.white.opacity(0.7),lineWidth:1.5))
            .foregroundColor(GameStyle.ink).contentShape(RoundedRectangle(cornerRadius:30))
    }
}

struct AdventureTreeArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.65, green: 0.35, blue: 0.16)).frame(width: 46, height: 85).offset(y: 25)
            ForEach(0..<3) { i in
                Circle().fill(StudioStyle.colors[i == 1 ? 6 : 2]).frame(width: 90, height: 90)
                    .overlay(Circle().stroke(GameStyle.ink.opacity(0.7), lineWidth: 2))
                    .offset(x: CGFloat(i-1)*43, y: i == 1 ? -20 : 0)
            }
            MiniGameArt(kind: .apples).scaleEffect(0.35).offset(x: -43, y: 1)
            MiniGameArt(kind: .bubbles).scaleEffect(0.35).offset(x: 43, y: 4)
            Text("★").font(.system(size: 40)).foregroundColor(.yellow).offset(y: -25)
        }.accessibilityHidden(true)
    }
}
