import SwiftUI

struct PumpkinBackdrop:View {
    var darkness=0.0
    var garden=false
    var body:some View {
        GeometryReader {proxy in
            ZStack {
                LinearGradient(colors:[
                    GameStyle.mixed(Color(red:0.53,green:0.71,blue:0.77),with:Color(red:0.10,green:0.09,blue:0.24),amount:darkness),
                    GameStyle.mixed(Color(red:1,green:0.77,blue:0.48),with:Color(red:0.24,green:0.16,blue:0.34),amount:darkness)],
                    startPoint:.top,endPoint:.bottom)
                Canvas {context,size in
                    for i in 0..<26 {
                        let x=CGFloat((i*71+19)%283)/283*size.width
                        let y=CGFloat((i*37+11)%193)/250*size.height
                        let dot=Path(ellipseIn:CGRect(x:x,y:y,width:i%3 == 0 ? 4 : 2,height:i%3 == 0 ? 4 : 2))
                        context.fill(dot,with:.color(PumpkinLook.cream.opacity(darkness*0.75)))
                    }
                    context.fill(Path(ellipseIn:CGRect(x:size.width*0.78,y:size.height*0.12,width:60,height:60)),with:.color(PumpkinLook.cream.opacity(darkness)))
                    let floorY=size.height*(garden ? 0.38 : 0.76)
                    let floor=CGRect(x:0,y:floorY,width:size.width,height:size.height-floorY)
                    context.fill(Path(floor),with:.color(GameStyle.mixed(Color(red:0.67,green:0.36,blue:0.18),with:Color(red:0.14,green:0.08,blue:0.16),amount:darkness*0.8)))
                    for i in 0..<10 {
                        let y=floorY+CGFloat(i)*65
                        var plank=Path();plank.move(to:CGPoint(x:0,y:y));plank.addLine(to:CGPoint(x:size.width,y:y))
                        context.stroke(plank,with:.color(PumpkinLook.ink.opacity(0.20)),lineWidth:2)
                    }
                    for i in 0..<9 {
                        let x=CGFloat(i)/8*size.width
                        var rail=Path();rail.move(to:CGPoint(x:x,y:floorY-28));rail.addLine(to:CGPoint(x:x,y:floorY+4))
                        if garden {context.stroke(rail,with:.color(Color(red:0.42,green:0.27,blue:0.29)),style:StrokeStyle(lineWidth:13,lineCap:.round))}
                    }
                }
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
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
                .background(RoundedRectangle(cornerRadius:30).fill(Color(red:0.28,green:0.14,blue:0.36)))
                .overlay(RoundedRectangle(cornerRadius:30).stroke(Color.orange.opacity(0.7),lineWidth:2))
        }.buttonStyle(SquishStyle())
    }
    static var sample:PumpkinLantern {
        var p=PumpkinLantern();p.addFace();p.darkness=1;p.light = .candle;return p
    }
}
