import SwiftUI

enum WorkshopLook {
    static let sea = Color(red: 0.06, green: 0.29, blue: 0.37)
    static let blue = Color(red: 0.02, green: 0.55, blue: 0.72)
    static let cream = Color(red: 1, green: 0.96, blue: 0.84)
    static let yellow = Color(red: 1, green: 0.77, blue: 0.12)
}

enum CreatorMark: Equatable { case close, undo, redo, done, shuffle, duplicate, mirror, trash, rotate, resize, help, voice, add }

struct CreatorLineIcon: View {
    let mark: CreatorMark
    var color = WorkshopLook.sea
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 40, y: size.height / 40)
            func line(_ points: [CGPoint]) {
                var p = Path(); if let first = points.first { p.move(to: first) }
                for point in points.dropFirst() { p.addLine(to: point) }
                context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 3.8, lineCap: .round, lineJoin: .round))
            }
            switch mark {
            case .close: line([CGPoint(x: 11,y:11),CGPoint(x:29,y:29)]); line([CGPoint(x:29,y:11),CGPoint(x:11,y:29)])
            case .done: line([CGPoint(x:8,y:21),CGPoint(x:16,y:29),CGPoint(x:32,y:10)])
            case .undo, .redo:
                var p = Path(); p.move(to: CGPoint(x: 30,y:29)); p.addCurve(to: CGPoint(x:10,y:15),control1: CGPoint(x:40,y:10),control2: CGPoint(x:17,y:6))
                if mark == .redo { p = p.applying(CGAffineTransform(a:-1,b:0,c:0,d:1,tx:40,ty:0)) }
                context.stroke(p,with:.color(color),style:StrokeStyle(lineWidth:3.8,lineCap:.round))
                if mark == .undo { line([CGPoint(x:11,y:7),CGPoint(x:8,y:17),CGPoint(x:20,y:19)]) }
                else { line([CGPoint(x:29,y:7),CGPoint(x:32,y:17),CGPoint(x:20,y:19)]) }
            case .duplicate:
                context.stroke(Path(roundedRect:CGRect(x:8,y:7,width:19,height:22),cornerRadius:5),with:.color(color.opacity(0.5)),lineWidth:3)
                context.stroke(Path(roundedRect:CGRect(x:15,y:14,width:19,height:22),cornerRadius:5),with:.color(color),lineWidth:3)
                line([CGPoint(x:20,y:25),CGPoint(x:29,y:25)]); line([CGPoint(x:24.5,y:21),CGPoint(x:24.5,y:29)])
            case .mirror:
                line([CGPoint(x:20,y:6),CGPoint(x:20,y:34)])
                line([CGPoint(x:13,y:11),CGPoint(x:6,y:27),CGPoint(x:13,y:27),CGPoint(x:13,y:11)])
                line([CGPoint(x:27,y:11),CGPoint(x:34,y:27),CGPoint(x:27,y:27),CGPoint(x:27,y:11)])
            case .trash:
                line([CGPoint(x:11,y:13),CGPoint(x:13,y:33),CGPoint(x:27,y:33),CGPoint(x:29,y:13)])
                line([CGPoint(x:8,y:11),CGPoint(x:32,y:11)]); line([CGPoint(x:16,y:7),CGPoint(x:24,y:7)])
                line([CGPoint(x:18,y:17),CGPoint(x:18,y:27)]); line([CGPoint(x:23,y:17),CGPoint(x:23,y:27)])
            case .rotate:
                var p = Path(); p.addArc(center:CGPoint(x:20,y:21),radius:12,startAngle:.degrees(30),endAngle:.degrees(300),clockwise:false)
                context.stroke(p,with:.color(color),style:StrokeStyle(lineWidth:3.8,lineCap:.round))
                line([CGPoint(x:26,y:7),CGPoint(x:31,y:12),CGPoint(x:23,y:14)])
            case .resize:
                line([CGPoint(x:10,y:28),CGPoint(x:30,y:8)]); line([CGPoint(x:19,y:8),CGPoint(x:30,y:8),CGPoint(x:30,y:19)])
                line([CGPoint(x:10,y:17),CGPoint(x:10,y:28),CGPoint(x:21,y:28)])
            case .shuffle:
                line([CGPoint(x:7,y:12),CGPoint(x:14,y:12),CGPoint(x:26,y:29),CGPoint(x:33,y:29)])
                line([CGPoint(x:7,y:29),CGPoint(x:14,y:29),CGPoint(x:26,y:12),CGPoint(x:33,y:12)])
                line([CGPoint(x:29,y:7),CGPoint(x:34,y:12),CGPoint(x:29,y:17)])
            case .help:
                context.draw(Text("?").font(.system(size:30,weight:.heavy,design:.rounded)).foregroundColor(color),at:CGPoint(x:20,y:21))
            case .voice:
                line([CGPoint(x:10,y:17),CGPoint(x:16,y:17),CGPoint(x:24,y:10),CGPoint(x:24,y:31),CGPoint(x:16,y:24),CGPoint(x:10,y:24),CGPoint(x:10,y:17)])
                var p = Path(); p.addArc(center:CGPoint(x:23,y:20),radius:12,startAngle:.degrees(-45),endAngle:.degrees(45),clockwise:false)
                context.stroke(p,with:.color(color),style:StrokeStyle(lineWidth:3,lineCap:.round))
            case .add: line([CGPoint(x:9,y:20),CGPoint(x:31,y:20)]); line([CGPoint(x:20,y:9),CGPoint(x:20,y:31)])
            }
        }.accessibilityHidden(true)
    }
}

struct CreatorToolButton: View {
    let mark: CreatorMark
    let label: String
    var tint = Color.white
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            CreatorLineIcon(mark: mark).frame(width: 32, height: 32).frame(width: 48, height: 48)
                .background(CandySurface(color:tint,cornerRadius:17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(WorkshopLook.sea.opacity(0.2), lineWidth: 1.5))
                .shadow(color: WorkshopLook.sea.opacity(0.25), radius: 0, y: 3).contentShape(Rectangle())
        }.buttonStyle(SquishStyle()).accessibilityLabel(label)
    }
}

struct CreatorRoomArtwork: View {
    var body:some View {
        GeometryReader {proxy in
            let w=proxy.size.width,h=proxy.size.height
            ZStack {
                LinearGradient(colors:[Color(red:1,green:0.90,blue:0.68),Color(red:0.97,green:0.69,blue:0.44)],
                    startPoint:.topLeading,endPoint:.bottomTrailing)
                WorldBackdrop(world:.forest,immersive:false,animated:false)
                    .frame(width:w*0.84,height:h*0.78)
                    .clipShape(RoundedRectangle(cornerRadius:min(w*0.35,160)))
                    .overlay(RoundedRectangle(cornerRadius:min(w*0.35,160)).strokeBorder(Color(red:0.48,green:0.25,blue:0.28),lineWidth:9))
                    .overlay(RoundedRectangle(cornerRadius:min(w*0.35,160)).strokeBorder(Color(red:1,green:0.89,blue:0.63),lineWidth:3).padding(9))
                    .shadow(color:WorkshopLook.sea.opacity(0.22),radius:12,x:0,y:6)
                    .position(x:w/2,y:h*0.43)
                Canvas {c,size in furnishings(c,size:size)}
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private func furnishings(_ c:GraphicsContext,size:CGSize) {
        let w=size.width,h=size.height
        let floorY=h*0.84
        let top=Path(roundedRect:CGRect(x:-12,y:floorY,width:w+24,height:h*0.19),cornerRadius:18)
        c.fill(top,with:.linearGradient(Gradient(colors:[
            Color(red:0.91,green:0.65,blue:0.37),Color(red:0.63,green:0.34,blue:0.23)]),
            startPoint:CGPoint(x:0,y:floorY),endPoint:CGPoint(x:0,y:h)))
        c.stroke(top,with:.color(Color(red:1,green:0.85,blue:0.55)),lineWidth:5)
        for i in 0..<8 {
            let x=CGFloat(i)*w/7
            var seam=Path();seam.move(to:CGPoint(x:w/2+(x-w/2)*0.8,y:floorY+3));seam.addLine(to:CGPoint(x:x,y:h))
            c.stroke(seam,with:.color(Color(red:0.35,green:0.19,blue:0.22).opacity(0.2)),lineWidth:2)
        }
        for side in 0..<2 {
            let x=side == 0 ? w*0.03 : w*0.88,y=h*0.76
            let width=max(18,w*0.09),height=max(28,h*0.12)
            for pencil in 0..<3 {
                let px=x+width*(0.2+CGFloat(pencil)*0.25)
                var brush=Path();brush.move(to:CGPoint(x:px,y:y+12))
                brush.addLine(to:CGPoint(x:px+CGFloat(pencil-1)*6,y:y-height*0.62-CGFloat(pencil%2)*10))
                c.stroke(brush,with:.color(GameStyle.palette[(pencil+side*4+2)%16]),style:StrokeStyle(lineWidth:6,lineCap:.round))
            }
            let pot=Path(roundedRect:CGRect(x:x,y:y,width:width,height:height),cornerRadius:width*0.22)
            ToyFinish.paint(c,path:pot,color:side == 0 ? GameStyle.palette[1] : GameStyle.palette[6],edge:2)
            let label=Path(ellipseIn:CGRect(x:x+width*0.25,y:y+height*0.28,width:width*0.5,height:height*0.4))
            c.fill(label,with:.color(.white.opacity(0.65)))
        }
        var cord=Path();cord.move(to:CGPoint(x:0,y:h*0.02));cord.addQuadCurve(to:CGPoint(x:w,y:h*0.02),control:CGPoint(x:w/2,y:h*0.13))
        c.stroke(cord,with:.color(WorkshopLook.sea.opacity(0.45)),lineWidth:2)
        for i in 0..<7 {
            let t=CGFloat(i+1)/8,x=w*t,y=h*0.02+4*t*(1-t)*h*0.055
            var flag=Path();flag.move(to:CGPoint(x:x-9,y:y));flag.addLine(to:CGPoint(x:x+9,y:y))
            flag.addQuadCurve(to:CGPoint(x:x,y:y+22),control:CGPoint(x:x+8,y:y+15));flag.closeSubpath()
            ToyFinish.paint(c,path:flag,color:GameStyle.palette[(i*2+1)%16],edge:1)
        }
    }
}

struct CreatorCategoryIcon: View {
    let part: Part
    var body: some View {
        Group {
            switch part {
            case .body:
                CharacterView(friend: sample)
            case .eyes:
                CharacterView(friend: sample, detail: .eyes)
            case .mouth:
                CharacterView(friend: sample, detail: .mouth)
            case .arms:
                CreativePieceView(piece: CreativePiece(kind:.arm,variant:5,color:2))
            case .legs:
                CreativePieceView(piece: CreativePiece(kind:.leg,variant:5,color:6))
            case .extras:
                CreativePieceView(piece:CreativePiece(kind:.extra,variant:8,color:3,accent:3))
            case .paint: ToyGlyph(kind:.brush)
            case .color, .accent:
                ZStack {
                    ForEach(0..<3) { i in
                        Circle().fill(GameStyle.palette[[1,3,6][i]]).frame(width:26,height:26).overlay(Circle().stroke(.white,lineWidth:2))
                            .offset(x:CGFloat(i-1)*12,y:i == 1 ? -8 : 6)
                    }
                }
            }
        }.accessibilityHidden(true)
    }
    private var sample: FantasyFriend {
        var f = FantasyFriend(); f.body = .round;f.color=4;f.accessories=[];f.mouth=1
        return f
    }
}


struct StarterFriendsSheet:View {
    @EnvironmentObject private var store:FriendStore
    let onChoose:(FriendSeed)->Void
    let onClose:()->Void
    var body:some View {
        GeometryReader {proxy in
            let wide=proxy.size.width>=620
            ZStack {
                WorldBackdrop(world:.clouds,animated:false)
                ScrollView {
                    VStack(spacing:18) {
                        HStack {
                            Text(store.t("starterTitle")).font(.system(size:28,weight:.heavy,design:.rounded))
                            Spacer(minLength:0)
                            RoundButton(icon:"xmark",label:store.t("close"),action:onClose)
                        }
                        Text(store.t("starterFreedom")).font(.system(.subheadline,design:.rounded)).multilineTextAlignment(.center)
                        if wide {
                            HStack(alignment:.top,spacing:18) {
                                ForEach(FriendSeed.allCases,id:\.rawValue) {seed in card(seed,wide:true)}
                            }
                        } else {
                            VStack(spacing:18) {
                                ForEach(FriendSeed.allCases,id:\.rawValue) {seed in card(seed,wide:false)}
                            }
                        }
                    }.padding(22).frame(maxWidth:1000).frame(maxWidth:.infinity)
                }
            }.foregroundColor(GameStyle.ink)
        }
    }
    private func card(_ seed:FriendSeed,wide:Bool)->some View {
        Button {onChoose(seed)} label:{
            Group {
                if wide {
                    VStack(spacing:8) {
                        LivingFriend(friend:seed.make()).frame(height:230).allowsHitTesting(false).accessibilityHidden(true)
                        caption(seed)
                    }.padding(18).frame(maxWidth:.infinity,minHeight:340)
                } else {
                    HStack(spacing:12) {
                        LivingFriend(friend:seed.make()).frame(width:125,height:140).allowsHitTesting(false).accessibilityHidden(true)
                        caption(seed).frame(maxWidth:.infinity,alignment:.leading)
                        Image(systemName:"arrow.right.circle.fill").font(.system(size:26)).foregroundColor(GameStyle.purple)
                    }.padding(14)
                }
            }.background(CandySurface(color:GameStyle.mixed(GameStyle.palette[seed.make().color],with:.white,amount:0.75),cornerRadius:30))
        }.buttonStyle(SquishStyle()).accessibilityLabel(seed.title+". "+store.t(seed.hintKey))
    }
    private func caption(_ seed:FriendSeed)->some View {
        VStack(alignment:.leading,spacing:7) {
            Text(seed.title).font(.system(size:25,weight:.heavy,design:.rounded))
            Text(store.t(seed.hintKey)).font(.system(size:14,weight:.semibold,design:.rounded)).fixedSize(horizontal:false,vertical:true)
        }
    }
}
