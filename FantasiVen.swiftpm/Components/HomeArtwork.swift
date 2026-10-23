import SwiftUI

enum HomeDestination:Int {case studio,village,playground,games}

struct HomeDestinationArt:View {
    let kind:HomeDestination
    var body:some View {
        ZStack {
            if kind == .games {
                GeometryReader {proxy in
                    let scale=min(proxy.size.width/240,proxy.size.height/170)
                    ZStack {
                        PizzaIllustration(recipe:.sample,baked:1,board:false).frame(width:145,height:150).rotationEffect(.degrees(-13)).offset(x:-26,y:7)
                        BubbleToy(color:.cyan).frame(width:58,height:58).offset(x:62,y:-30)
                        ToyGlyph(kind:.music).frame(width:59,height:59).rotationEffect(.degrees(12)).offset(x:60,y:33)
                    }.frame(width:240,height:170).scaleEffect(scale)
                        .position(x:proxy.size.width/2,y:proxy.size.height/2)
                }
            } else {
                Canvas {c,s in
                    c.scaleBy(x:s.width/240,y:s.height/170)
                    let ground=Path(ellipseIn:CGRect(x:17,y:139,width:207,height:18))
                    c.fill(ground,with:.color(GameStyle.ink.opacity(0.13)))
                    switch kind {
                    case .studio:
                        HomeCottage.draw(c,x:51,y:29,width:137,height:119,color:Color(red:1,green:0.72,blue:0.32),roof:Color(red:0.77,green:0.25,blue:0.45))
                    case .village:
                        HomeCottage.draw(c,x:20,y:63,width:67,height:88,color:GameStyle.palette[11],roof:GameStyle.palette[8])
                        HomeCottage.draw(c,x:146,y:59,width:69,height:91,color:GameStyle.palette[2],roof:GameStyle.palette[7])
                        HomeCottage.draw(c,x:81,y:34,width:78,height:117,color:Color(red:1,green:0.83,blue:0.49),roof:GameStyle.palette[1])
                    case .playground:
                        for x in [CGFloat(60),CGFloat(106)] {
                            var post=Path();post.move(to:CGPoint(x:x,y:65));post.addLine(to:CGPoint(x:x,y:146))
                            c.stroke(post,with:.color(Color(red:0.52,green:0.28,blue:0.23)),style:StrokeStyle(lineWidth:9,lineCap:.round))
                        }
                        ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:46,y:47,width:73,height:24),cornerRadius:9),color:GameStyle.palette[3],edge:1.5)
                        var slide=Path();slide.move(to:CGPoint(x:110,y:66))
                        slide.addCurve(to:CGPoint(x:205,y:140),control1:CGPoint(x:147,y:69),control2:CGPoint(x:135,y:143))
                        c.stroke(slide,with:.color(GameStyle.mixed(GameStyle.palette[6],with:GameStyle.ink,amount:0.4)),style:StrokeStyle(lineWidth:24,lineCap:.round))
                        c.stroke(slide,with:.linearGradient(Gradient(colors:[Color.cyan,GameStyle.palette[6]]),startPoint:CGPoint(x:110,y:66),endPoint:CGPoint(x:205,y:140)),style:StrokeStyle(lineWidth:17,lineCap:.round))
                        for i in 0..<3 {
                            var rung=Path();rung.move(to:CGPoint(x:59,y:84+CGFloat(i)*18));rung.addLine(to:CGPoint(x:105,y:84+CGFloat(i)*18))
                            c.stroke(rung,with:.color(Color(red:1,green:0.81,blue:0.45)),style:StrokeStyle(lineWidth:6,lineCap:.round))
                        }
                        ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:25,y:113,width:34,height:34)),color:GameStyle.palette[1],edge:1.3)
                    case .games:break
                    }
                }
                if kind == .studio {
                    GeometryReader {proxy in
                        ToyGlyph(kind:.brush).frame(width:proxy.size.width*0.23,height:proxy.size.height*0.36)
                            .rotationEffect(.degrees(15)).position(x:proxy.size.width*0.76,y:proxy.size.height*0.70)
                    }
                }
            }
        }.aspectRatio(240.0/170,contentMode:.fit).accessibilityHidden(true).allowsHitTesting(false)
    }
}
private enum HomeCottage {
    static func draw(_ c:GraphicsContext,x:CGFloat,y:CGFloat,width w:CGFloat,height h:CGFloat,color:Color,roof:Color) {
        let wall=Path(roundedRect:CGRect(x:x,y:y+h*0.28,width:w,height:h*0.72),cornerRadius:w*0.12)
        ToyFinish.paint(c,path:wall,color:color,edge:2)
        for i in 0..<5 {
            let yy=y+h*0.38+CGFloat(i)*h*0.12
            var seam=Path();seam.move(to:CGPoint(x:x+4,y:yy));seam.addLine(to:CGPoint(x:x+w-4,y:yy))
            c.stroke(seam,with:.color(GameStyle.ink.opacity(0.07)),lineWidth:1)
        }
        var cap=Path();cap.move(to:CGPoint(x:x-10,y:y+h*0.36))
        cap.addQuadCurve(to:CGPoint(x:x+w*0.53,y:y-10),control:CGPoint(x:x+w*0.3,y:y+h*0.16))
        cap.addQuadCurve(to:CGPoint(x:x+w+10,y:y+h*0.36),control:CGPoint(x:x+w*0.76,y:y+h*0.18))
        cap.closeSubpath()
        ToyFinish.paint(c,path:cap,color:roof,edge:2)
        var tiles=c;tiles.clip(to:cap)
        for row in 0..<4 {
            for col in 0..<6 {
                let xx=x+CGFloat(col)*w/5-CGFloat(row%2)*w/10,yy=y+CGFloat(row)*h*0.1
                var tile=Path();tile.move(to:CGPoint(x:xx,y:yy))
                tile.addQuadCurve(to:CGPoint(x:xx+w/5,y:yy),control:CGPoint(x:xx+w/10,y:yy+h*0.09))
                tiles.stroke(tile,with:.color(.white.opacity(0.17)),lineWidth:1.5)
            }
        }
        let door=Path(roundedRect:CGRect(x:x+w*0.37,y:y+h*0.59,width:w*0.27,height:h*0.42),cornerRadius:w*0.12)
        ToyFinish.paint(c,path:door,color:GameStyle.mixed(roof,with:GameStyle.ink,amount:0.25),edge:1.5)
        c.fill(Path(ellipseIn:CGRect(x:x+w*0.57,y:y+h*0.82,width:3,height:3)),with:.color(.yellow))
        for side in 0..<2 {
            let xx=x+w*(side == 0 ? 0.11 : 0.73)
            let window=Path(roundedRect:CGRect(x:xx,y:y+h*0.46,width:w*0.17,height:h*0.22),cornerRadius:w*0.07)
            c.fill(window,with:.linearGradient(Gradient(colors:[Color(red:1,green:0.98,blue:0.66),Color(red:1,green:0.64,blue:0.22)]),
                startPoint:CGPoint(x:xx,y:y+h*0.46),endPoint:CGPoint(x:xx,y:y+h*0.68)))
            c.stroke(window,with:.color(roof),lineWidth:2.5)
            var bar=Path();bar.move(to:CGPoint(x:xx+w*0.085,y:y+h*0.46));bar.addLine(to:CGPoint(x:xx+w*0.085,y:y+h*0.68))
            c.stroke(bar,with:.color(color),lineWidth:1.5)
        }
    }
}
struct HomeWelcomeScene:View {
    @EnvironmentObject private var store:FriendStore
    let friend:FantasyFriend
    var body:some View {
        GeometryReader {proxy in
            let w=proxy.size.width,h=proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius:38).fill(LinearGradient(colors:[
                    Color(red:0.10,green:0.46,blue:0.57),Color(red:0.39,green:0.71,blue:0.65),Color(red:0.78,green:0.87,blue:0.49)],
                    startPoint:.topLeading,endPoint:.bottomTrailing))
                Canvas {c,size in
                    let light=CGPoint(x:size.width*0.73,y:size.height*0.23)
                    c.fill(Path(CGRect(origin:.zero,size:size)),with:.radialGradient(Gradient(colors:[
                        Color(red:1,green:0.94,blue:0.65).opacity(0.35),.clear]),center:light,startRadius:0,endRadius:size.width*0.65))
                    for i in 0..<12 {
                        let x=CGFloat((i*43+11)%149)/149*size.width,y=CGFloat((i*31+9)%97)/137*size.height
                        c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:3,height:3)),with:.color(.white.opacity(0.45)))
                    }
                    let island=CGRect(x:size.width*0.06,y:size.height*0.76,width:size.width*0.88,height:size.height*0.2)
                    ToyFinish.paint(c,path:Path(ellipseIn:island),color:Color(red:0.54,green:0.76,blue:0.3),edge:1)
                    c.fill(Path(ellipseIn:island.insetBy(dx:12,dy:6)),with:.linearGradient(Gradient(colors:[
                        Color(red:0.85,green:0.93,blue:0.52),Color(red:0.37,green:0.65,blue:0.29)]),
                        startPoint:island.origin,endPoint:CGPoint(x:island.midX,y:island.maxY)))
                    for side in 0..<2 {
                        let x=side == 0 ? size.width*0.06 : size.width*0.88
                        for leaf in 0..<3 {
                            let y=size.height*0.78+CGFloat(leaf)*9
                            var p=Path();p.move(to:CGPoint(x:x,y:y+15))
                            p.addQuadCurve(to:CGPoint(x:x+CGFloat(side == 0 ? 19 : -19),y:y-14),control:CGPoint(x:x-10,y:y-8))
                            p.addQuadCurve(to:CGPoint(x:x,y:y+15),control:CGPoint(x:x+12,y:y));p.closeSubpath()
                            ToyFinish.paint(c,path:p,color:GameStyle.palette[leaf%2 == 0 ? 5 : 4],edge:0.5)
                        }
                    }
                }
                CharacterView(friend:FriendSeed.pjuske.make()).frame(width:w*0.31,height:h*0.48)
                    .rotationEffect(.degrees(-12)).position(x:w*0.18,y:h*0.61).accessibilityHidden(true)
                CharacterView(friend:FriendSeed.lumi.make()).frame(width:w*0.28,height:h*0.46)
                    .rotationEffect(.degrees(12)).position(x:w*0.83,y:h*0.63).accessibilityHidden(true)
                LivingFriend(friend:friend).frame(width:min(w*0.69,h*0.83),height:h*0.83)
                    .position(x:w*0.51,y:h*0.49)
                Text(store.t("homePrompt")).font(.system(size:12,weight:.heavy,design:.rounded))
                    .padding(.horizontal,15).padding(.vertical,9).background(Capsule().fill(Color(red:1,green:0.96,blue:0.82)))
                    .rotationEffect(.degrees(-5)).position(x:w*0.30,y:h*0.14).allowsHitTesting(false)
            }.clipShape(RoundedRectangle(cornerRadius:38))
                .overlay(RoundedRectangle(cornerRadius:38).stroke(LinearGradient(colors:[.white.opacity(0.65),.white.opacity(0.08)],startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2).allowsHitTesting(false))
                .shadow(color:GameStyle.ink.opacity(0.2),radius:14,x:0,y:9)
        }
    }
}
