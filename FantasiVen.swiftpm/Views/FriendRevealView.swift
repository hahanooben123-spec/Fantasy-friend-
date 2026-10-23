import SwiftUI

struct FriendRevealView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    let friend:FantasyFriend
    let updated:Bool
    let onFinish:()->Void
    @State private var curtainsOpen=false
    @State private var entered=false
    @State private var introduced=false
    @State private var creating=false
    @State private var freshFriend=FantasyFriend.studioStarter()
    var body:some View {
        NavigationView {
            GeometryReader {proxy in
                ZStack {
                    WelcomeGardenBackdrop()
                    ScrollView(showsIndicators:false) {
                        VStack(spacing:18) {
                            HStack {
                                Text(store.t("revealStage")).font(.system(size:17,weight:.heavy,design:.rounded))
                                Spacer()
                                RoundButton(icon:"xmark",label:store.t("close"),action:onFinish)
                            }
                            stage.frame(height:min(430,max(220,proxy.size.height*0.46)))
                            VStack(spacing:7) {
                                Text(friend.name).font(.system(size:38,weight:.heavy,design:.rounded))
                                Text(store.t(updated ? "revealUpdated" : "revealWelcome"))
                                    .font(.system(size:19,weight:.bold,design:.rounded)).multilineTextAlignment(.center)
                            }.opacity(introduced ? 1 : 0)
                            VStack(spacing:12) {
                                NavigationLink(destination:FriendRoomView(friendID:friend.id)) {
                                    door("revealRoom","house.fill",color:WorkshopLook.yellow)
                                }
                                NavigationLink(destination:MiniGamesView(onCreate:{creating=true})) {
                                    door("revealPlay","play.fill",color:Color(red:0.22,green:0.72,blue:0.84))
                                }
                            }.buttonStyle(SquishStyle()).opacity(introduced ? 1 : 0).disabled(!introduced)
                            Button(store.t("revealHome"),action:onFinish)
                                .font(.system(size:15,weight:.bold,design:.rounded)).frame(minHeight:48)
                        }.padding(22).frame(maxWidth:650).frame(maxWidth:.infinity)
                    }
                    PlayCelebration(revision:introduced ? 1 : 0)
                }.foregroundColor(WorkshopLook.sea)
            }.navigationBarHidden(true)
        }.navigationViewStyle(.stack)
            .fullScreenCover(isPresented:$creating) {
                BuilderView(original:freshFriend,existing:false).environmentObject(store)
            }
            .task(id:phase) {
                guard phase == .active,!introduced else {return}
                if reduced {
                    curtainsOpen=true;entered=true;introduced=true
                    SoundService.shared.play(.complete)
                    SoundService.shared.speak(store.t("revealHello")+" "+friend.name,language:store.settings.language)
                    return
                }
                do {
                    try await Task.sleep(nanoseconds:200_000_000)
                    withAnimation(.easeInOut(duration:0.65)) {curtainsOpen=true}
                    try await Task.sleep(nanoseconds:300_000_000)
                    withAnimation(.spring(response:0.7,dampingFraction:0.65)) {entered=true}
                    try await Task.sleep(nanoseconds:650_000_000)
                    withAnimation(.easeOut(duration:0.3)) {introduced=true}
                    SoundService.shared.play(.complete)
                    SoundService.shared.speak(store.t("revealHello")+" "+friend.name,language:store.settings.language)
                } catch {return}
            }
            .onDisappear {SoundService.shared.stopSpeech()}
    }
    private func door(_ key:String,_ icon:String,color:Color)->some View {
        HStack(spacing:14) {
            Image(systemName:icon).font(.system(size:24,weight:.bold))
            Text(store.t(key)).font(.system(size:19,weight:.heavy,design:.rounded))
            Spacer()
            Image(systemName:"chevron.right").font(.system(size:16,weight:.heavy))
        }.padding(.horizontal,21).frame(minHeight:62)
            .background(CandySurface(color:color,cornerRadius:24)).foregroundColor(WorkshopLook.sea)
    }
    private var stage:some View {
        GeometryReader {proxy in
            ZStack {
                RoundedRectangle(cornerRadius:40).fill(LinearGradient(colors:[
                    Color(red:0.10,green:0.32,blue:0.47),Color(red:0.24,green:0.56,blue:0.55)],
                    startPoint:.top,endPoint:.bottom))
                Canvas {c,s in
                    let center=CGPoint(x:s.width/2,y:s.height*0.52)
                    c.fill(Path(ellipseIn:CGRect(x:s.width*0.1,y:0,width:s.width*0.8,height:s.height)),
                        with:.radialGradient(Gradient(colors:[Color.yellow.opacity(0.35),.clear]),center:center,startRadius:20,endRadius:s.height*0.65))
                    ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:s.width*0.12,y:s.height*0.79,width:s.width*0.76,height:s.height*0.16)),
                        color:Color(red:0.95,green:0.74,blue:0.36),edge:1.5)
                    for i in 0..<15 {
                        let x=CGFloat((i*43+13)%100)/100*s.width,y=CGFloat((i*31+7)%75)/100*s.height
                        c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:3,height:3)),with:.color(.white.opacity(0.6)))
                    }
                }
                LivingFriend(friend:friend,action:.hug,signal:entered ? 1 : 0)
                    .frame(width:proxy.size.height*0.82,height:proxy.size.height*0.92)
                    .scaleEffect(entered ? 1 : 0.65)
                    .offset(x:entered ? 0 : -proxy.size.width*0.3,y:entered ? 0 : 35)
                    .opacity(entered ? 1 : 0)
                ForEach(0..<2) {side in
                    RevealCurtain(opening:curtainsOpen ? 1 : 0)
                        .frame(width:proxy.size.width*0.54,height:proxy.size.height)
                        .scaleEffect(x:curtainsOpen ? 0.58 : 1,y:1,anchor:side == 0 ? .leading : .trailing)
                        .offset(x:(side == 0 ? -1 : 1)*(curtainsOpen ? proxy.size.width*0.73 : proxy.size.width*0.24))
                }
                Capsule().fill(WorkshopLook.yellow).frame(height:13).frame(maxHeight:.infinity,alignment:.top)
            }.storybookScene(night:true,lamps:true).clipShape(RoundedRectangle(cornerRadius:40))
                .overlay(RoundedRectangle(cornerRadius:40).stroke(StorybookStyle.honey,lineWidth:3))
                .shadow(color:StorybookStyle.plum.opacity(0.24),radius:12,y:8)
        }
    }
}
private struct RevealCurtain:View {
    var opening:Double
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                LinearGradient(colors:[Color(red:0.60,green:0.19,blue:0.42),Color(red:0.83,green:0.26,blue:0.39)],startPoint:.leading,endPoint:.trailing)
                HStack(spacing:0) {
                    ForEach(0..<7) {_ in
                        RoundedRectangle(cornerRadius:12).fill(LinearGradient(colors:[.black.opacity(0.18),.white.opacity(0.13),.clear],
                            startPoint:.leading,endPoint:.trailing))
                    }
                }
                Capsule().fill(WorkshopLook.yellow).frame(height:9).offset(y:proxy.size.height*0.28)
            }.clipShape(CurtainFabric(opening:opening))
                .overlay(CurtainFabric(opening:opening).stroke(StorybookStyle.plum.opacity(0.35),lineWidth:2))
                .shadow(color:StorybookStyle.plum.opacity(0.3),radius:8,x:5,y:3)
        }.allowsHitTesting(false)
    }
}

private struct CurtainFabric:Shape {
    var opening:Double
    var animatableData:Double {
        get {opening}
        set {opening=newValue}
    }
    func path(in rect:CGRect)->Path {
        var path=Path()
        path.move(to:.zero)
        path.addLine(to:CGPoint(x:rect.width,y:0))
        path.addQuadCurve(to:CGPoint(x:rect.width,y:rect.height*0.94),
            control:CGPoint(x:rect.width*(1-opening*0.13),y:rect.height*0.5))
        for i in stride(from:6,through:1,by:-1) {
            let x=rect.width*CGFloat(i)/6
            let next=rect.width*CGFloat(i-1)/6
            path.addQuadCurve(to:CGPoint(x:next,y:rect.height*0.94),
                control:CGPoint(x:(x+next)/2,y:rect.height*(1+opening*0.025)))
        }
        path.closeSubpath()
        return path
    }
}
