import SwiftUI

struct PumpkinBackdrop:View {
    var darkness=0.0
    var garden=false
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                VillageArtwork.image("PumpkinBackdropCartoon").resizable().interpolation(.high).scaledToFill()
                    .frame(width:proxy.size.width,height:proxy.size.height).clipped()
                Color(red:0.12,green:0.08,blue:0.28).opacity(darkness*0.30)
                LinearGradient(colors:[Color(red:1,green:0.82,blue:0.47).opacity((1-darkness)*0.16),.clear],
                    startPoint:.top,endPoint:.bottom).blendMode(.screen)
                TimelineView(.animation(minimumInterval:1.0/12,paused:darkness<0.1 || reduced || phase != .active)) {frame in
                    Canvas {context,size in
                        fireflies(context,size:size,time:reduced ? 0 : frame.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
    private func fireflies(_ c:GraphicsContext,size:CGSize,time:Double) {
        guard darkness>0.1 else {return}
        for i in 0..<8 {
            let seed=Double(i)
            let x=(0.08+Double((i*31)%87)/100)*size.width+sin(time*0.4+seed)*9
            let y=size.height*(garden ? 0.27 : 0.62)+cos(time*0.33+seed*2)*26
            let alpha=(0.45+sin(time*1.1+seed)*0.25)*darkness
            let center=CGPoint(x:x,y:y)
            c.fill(Path(ellipseIn:CGRect(x:x-9,y:y-9,width:18,height:18)),with:.radialGradient(
                Gradient(colors:[PumpkinLook.cream.opacity(alpha),.clear]),center:center,startRadius:0,endRadius:9))
            c.fill(Path(ellipseIn:CGRect(x:x-1.5,y:y-1.5,width:3,height:3)),with:.color(PumpkinLook.cream.opacity(alpha)))
        }
    }
}

struct PumpkinDoor:View {
    @EnvironmentObject private var store:FriendStore
    var body:some View {
        NavigationLink(destination:PumpkinGameView()) {
            HStack(spacing:12) {
                PumpkinIllustration(lantern:Self.sample,animated:false).frame(width:78,height:84)
                VStack(alignment:.leading,spacing:4) {
                    Text(store.t("pumpkinTitle")).font(.system(size:22,weight:.heavy,design:.rounded))
                    Text(store.t("pumpkinDoorHint")).font(.system(size:12,weight:.semibold,design:.rounded))
                }
                Spacer(minLength:0)
                Image(systemName:"chevron.right").font(.headline)
            }.foregroundColor(PumpkinLook.cream).padding(.horizontal,14).padding(.vertical,5)
                .background(RoundedRectangle(cornerRadius:30).fill(LinearGradient(colors:[
                    Color(red:0.40,green:0.17,blue:0.55),Color(red:0.16,green:0.10,blue:0.29)],
                    startPoint:.topLeading,endPoint:.bottomTrailing)))
                .overlay(RoundedRectangle(cornerRadius:30).stroke(LinearGradient(colors:[
                    Color(red:1,green:0.75,blue:0.34),Color.orange.opacity(0.35)],
                    startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2))
                .shadow(color:Color(red:0.32,green:0.12,blue:0.43).opacity(0.3),radius:10,x:0,y:6)
        }.buttonStyle(SquishStyle())
    }
    static var sample:PumpkinLantern {
        var p=PumpkinLantern();p.addFace();p.darkness=1;p.light = .candle;return p
    }
}
