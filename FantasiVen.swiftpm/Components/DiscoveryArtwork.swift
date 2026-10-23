import SwiftUI

struct FruitCanopy:View {
    let weather:FruitWeather
    var body:some View {
        Canvas {context,size in
            var branch=Path()
            branch.move(to:CGPoint(x:-20,y:110))
            branch.addCurve(to:CGPoint(x:size.width+20,y:115),control1:CGPoint(x:size.width*0.3,y:60),control2:CGPoint(x:size.width*0.7,y:150))
            context.stroke(branch,with:.color(Color(red:0.47,green:0.27,blue:0.13)),style:StrokeStyle(lineWidth:16,lineCap:.round))
            for i in 0..<12 {
                let x=CGFloat(i)/11*size.width
                let y=85+CGFloat(i%3)*17
                let rect=CGRect(x:x-30,y:y-22,width:65,height:38)
                context.fill(Path(ellipseIn:rect),with:.color(GameStyle.palette[weather == .rainbow ? [4,5,11][i%3] : 5].opacity(0.85)))
            }
        }.frame(height:155).allowsHitTesting(false).accessibilityHidden(true)
    }
}
struct BubbleSurpriseArt:View {
    let kind:BubbleSurpriseKind
    let friend:FantasyFriend
    let age:Double
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body:some View {
        Group {
            switch kind {
            case .music:
                Text("♪ ♫").font(.system(size:40,weight:.heavy,design:.rounded)).foregroundColor(GameStyle.palette[friend.color])
            case .littleFriend:
                CharacterView(friend:friend,happy:true).frame(width:85,height:90)
                    .rotationEffect(.degrees(reduced ? 0 : sin(age*6)*14))
            case .paint:
                Canvas {context,size in
                    for i in 0..<9 {
                        let angle=Double(i)*Double.pi*2/9
                        let radius=CGFloat(8+min(1,age)*23)
                        let rect=CGRect(x:size.width/2+CGFloat(cos(angle))*radius-7,
                                        y:size.height/2+CGFloat(sin(angle))*radius-7,width:14,height:17)
                        context.fill(Path(ellipseIn:rect),with:.color(GameStyle.palette[i.isMultiple(of:2) ? friend.color : friend.accent]))
                    }
                }
            case .butterfly:
                Canvas {context,size in
                    let flap=reduced ? 1 : 0.55+abs(sin(age*12))*0.45
                    let w=CGFloat(flap)*size.width*0.45
                    for side in [-1.0,1.0] {
                        let x=size.width/2+CGFloat(side)*w*0.48-w/2
                        context.fill(Path(ellipseIn:CGRect(x:x,y:12,width:w,height:36)),with:.color(GameStyle.palette[friend.accent]))
                        context.fill(Path(ellipseIn:CGRect(x:x+4,y:40,width:w*0.8,height:27)),with:.color(GameStyle.palette[friend.color]))
                    }
                    context.fill(Path(roundedRect:CGRect(x:size.width/2-3,y:25,width:6,height:38),cornerRadius:3),with:.color(GameStyle.ink))
                }
            }
        }.frame(width:95,height:95).accessibilityHidden(true).allowsHitTesting(false)
    }
}
struct BubbleWand:View {
    var body:some View {
        Canvas {context,size in
            var stick=Path();stick.move(to:CGPoint(x:size.width*0.3,y:size.height))
            stick.addLine(to:CGPoint(x:size.width*0.6,y:size.height*0.35))
            context.stroke(stick,with:.color(StudioStyle.colors[0]),style:StrokeStyle(lineWidth:7,lineCap:.round))
            context.stroke(Path(ellipseIn:CGRect(x:size.width*0.35,y:0,width:size.width*0.5,height:size.height*0.4)),with:.color(.white),lineWidth:6)
        }.allowsHitTesting(false)
    }
}
struct DishReactionArt:View {
    let feeling:DishFeeling
    let friend:FantasyFriend
    let progress:Double
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body:some View {
        Group {
            switch feeling {
            case .rainbow:
                Canvas {context,size in
                    for i in 0..<6 {
                        var arc=Path()
                        arc.addArc(center:CGPoint(x:size.width/2,y:size.height*0.72),radius:CGFloat(45+i*9),startAngle:.degrees(195),endAngle:.degrees(345),clockwise:false)
                        context.stroke(arc,with:.color(GameStyle.palette[[1,2,3,5,6,8][i]]),style:StrokeStyle(lineWidth:8,lineCap:.round))
                    }
                }
            case .fizzy:
                HStack {ForEach(0..<4) {i in BubbleToy(color:GameStyle.palette[(friend.accent+i)%16]).frame(width:24,height:24).offset(y:reduced ? 0 : CGFloat(sin(progress*8+Double(i)))*15)}}
            default:
                Text(feeling == .berry ? "♥  ♥  ♥" : feeling == .crunchy ? "✦  ✦  ✦" : feeling == .bouncy ? "⭐️  ⭐️" : "♡  ♡")
                    .font(.system(size:30,weight:.heavy,design:.rounded)).foregroundColor(GameStyle.palette[friend.accent])
            }
        }.frame(width:240,height:150).allowsHitTesting(false).accessibilityHidden(true)
    }
}
