import SwiftUI

struct WelcomeGardenBackdrop:View {
    var dusk=false
    var active=true
    @State private var visible=true
    var body:some View {
        PaintedVillageBackdrop(dusk:dusk,active:active && visible)
            .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
            .onAppear {visible=true;SoundService.shared.setWorld(.meadow)}
            .onDisappear {visible=false}
    }
}
struct WelcomeCompanion:View {
    @EnvironmentObject private var store:FriendStore
    let friend:FantasyFriend
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                Ellipse().fill(RadialGradient(colors:[StorybookStyle.cream.opacity(0.55),.clear],
                    center:.center,startRadius:0,endRadius:proxy.size.height*0.5))
                    .frame(width:proxy.size.width*0.9,height:proxy.size.height)
                StorybookPedestal().frame(width:min(proxy.size.width*0.7,proxy.size.height*1.1),height:44)
                    .position(x:proxy.size.width*0.47,y:proxy.size.height*0.91)
                LivingFriend(friend:friend,action:.hug,signal:1)
                    .frame(width:min(proxy.size.width*0.8,proxy.size.height*1.05),height:proxy.size.height)
                    .position(x:proxy.size.width*0.47,y:proxy.size.height*0.52)
                Text(friend.name.isEmpty ? store.t("homeHello") : store.t("homeHelloName")+" "+friend.name+"!")
                    .font(.system(size:15,weight:.heavy,design:.rounded))
                    .lineLimit(2).multilineTextAlignment(.center).frame(maxWidth:proxy.size.width*0.58)
                    .padding(.horizontal,16).padding(.vertical,9)
                    .background(StorybookPanel(cornerRadius:24))
                    .rotationEffect(.degrees(-5))
                    .position(x:proxy.size.width*0.62,y:proxy.size.height*0.16)
                    .allowsHitTesting(false)
            }
        }
    }
}
struct WelcomeActionCard:View {
    let kind:HomeDestination
    let title:String
    let subtitle:String
    let color:Color
    let height:CGFloat
    var body:some View {
        VStack(spacing:0) {
            HomeDestinationArt(kind:kind).frame(height:max(58,height-70)).padding(.horizontal,4)
            HStack(spacing:5) {
                VStack(alignment:.leading,spacing:3) {
                    Text(title).font(.system(size:height>170 ? 23 : 18,weight:.heavy,design:.rounded)).lineLimit(2)
                    if height>170 {Text(subtitle).font(.system(size:12,weight:.semibold,design:.rounded)).lineLimit(2)}
                }
                Spacer(minLength:0)
                Image(systemName:"play.fill").font(.system(size:14,weight:.heavy))
                    .frame(width:30,height:30).background(Circle().fill(.white.opacity(0.65)))
            }.padding(.horizontal,13).padding(.bottom,12).frame(maxWidth:.infinity,alignment:.leading)
        }.frame(maxWidth:.infinity).frame(height:height)
            .background(CandySurface(color:color,cornerRadius:29))
            .overlay(RoundedRectangle(cornerRadius:29).stroke(.white.opacity(0.7),lineWidth:2))
            .foregroundColor(WorkshopLook.sea).contentShape(RoundedRectangle(cornerRadius:29))
    }
}
