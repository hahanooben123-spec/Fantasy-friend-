import SwiftUI

struct WelcomeGardenBackdrop:View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    @State private var drifting=false
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                Canvas {c,s in
                    c.fill(Path(CGRect(origin:.zero,size:s)),with:.linearGradient(Gradient(colors:[
                        Color(red:0.40,green:0.82,blue:0.93),Color(red:0.89,green:0.96,blue:0.81)]),
                        startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)))
                    let sun=CGPoint(x:s.width*0.83,y:s.height*0.14)
                    c.fill(Path(ellipseIn:CGRect(x:sun.x-120,y:sun.y-120,width:240,height:240)),
                        with:.radialGradient(Gradient(colors:[Color.yellow.opacity(0.45),.clear]),center:sun,startRadius:15,endRadius:120))
                    ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:sun.x-31,y:sun.y-31,width:62,height:62)),color:Color(red:1,green:0.86,blue:0.31),edge:0.5)
                    for i in 0..<3 {
                        let y=s.height*(0.69+CGFloat(i)*0.12)
                        var hill=Path();hill.move(to:CGPoint(x:-40,y:y))
                        hill.addCurve(to:CGPoint(x:s.width+40,y:y+40),control1:CGPoint(x:s.width*0.3,y:y-110),control2:CGPoint(x:s.width*0.65,y:y+90))
                        hill.addLine(to:CGPoint(x:s.width+40,y:s.height+20));hill.addLine(to:CGPoint(x:-40,y:s.height+20));hill.closeSubpath()
                        c.fill(hill,with:.color([Color(red:0.47,green:0.78,blue:0.39),Color(red:0.33,green:0.68,blue:0.37),Color(red:0.19,green:0.55,blue:0.37)][i]))
                    }
                    var trail=Path();trail.move(to:CGPoint(x:s.width*0.36,y:s.height))
                    trail.addCurve(to:CGPoint(x:s.width*0.62,y:s.height*0.73),control1:CGPoint(x:s.width*0.85,y:s.height*0.89),control2:CGPoint(x:s.width*0.3,y:s.height*0.80))
                    c.stroke(trail,with:.color(Color(red:1,green:0.86,blue:0.58).opacity(0.65)),style:StrokeStyle(lineWidth:40,lineCap:.round))
                }
                ForEach(0..<3) {i in
                    CloudArtwork().frame(width:100+CGFloat(i)*25,height:70)
                        .position(x:proxy.size.width*(0.15+CGFloat(i)*0.31)+(drifting ? 12 : -12),y:proxy.size.height*(0.17+CGFloat(i%2)*0.15))
                        .opacity(0.75)
                }
                ForEach(0..<7) {i in
                    FlowerArtwork(index:i).frame(width:26,height:34)
                        .position(x:proxy.size.width*CGFloat((i*23+7)%100)/100,y:proxy.size.height*(0.94+CGFloat(i%2)*0.035))
                }
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
            .onAppear {SoundService.shared.setWorld(.meadow)}
            .task(id:"\(phase)-\(reduced)") {
                drifting=false
                guard phase == .active,!reduced else {return}
                withAnimation(.easeInOut(duration:7).repeatForever(autoreverses:true)) {drifting=true}
            }
    }
}
struct WelcomeCompanion:View {
    @EnvironmentObject private var store:FriendStore
    let friend:FantasyFriend
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                Ellipse().fill(.white.opacity(0.28)).frame(width:proxy.size.width*0.9,height:proxy.size.height*0.80)
                LivingFriend(friend:friend,action:.hug,signal:1)
                    .frame(width:min(proxy.size.width*0.8,proxy.size.height*1.05),height:proxy.size.height)
                    .position(x:proxy.size.width*0.47,y:proxy.size.height*0.52)
                Text(friend.name.isEmpty ? store.t("homeHello") : store.t("homeHelloName")+" "+friend.name+"!")
                    .font(.system(size:15,weight:.heavy,design:.rounded))
                    .lineLimit(2).multilineTextAlignment(.center).frame(maxWidth:proxy.size.width*0.58)
                    .padding(.horizontal,16).padding(.vertical,9)
                    .background(Capsule().fill(WorkshopLook.cream))
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
