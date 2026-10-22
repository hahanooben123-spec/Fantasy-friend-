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
                .background(RoundedRectangle(cornerRadius: 17).fill(tint))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(WorkshopLook.sea.opacity(0.2), lineWidth: 1.5))
                .shadow(color: WorkshopLook.sea.opacity(0.25), radius: 0, y: 3).contentShape(Rectangle())
        }.buttonStyle(SquishStyle()).accessibilityLabel(label)
    }
}

struct CreatorRoomArtwork: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(CGRect(origin:.zero,size:size)),with:.color(WorkshopLook.cream))
            let window = Path(roundedRect:CGRect(x:w*0.1,y:h*0.08,width:w*0.8,height:h*0.77),cornerRadius:min(w*0.4,170))
            context.fill(window,with:.linearGradient(Gradient(colors:[Color(red:0.29,green:0.82,blue:0.87),Color(red:0.78,green:0.96,blue:0.82)]),startPoint:CGPoint(x:0,y:0),endPoint:CGPoint(x:0,y:h)))
            context.stroke(window,with:.color(WorkshopLook.sea.opacity(0.18)),lineWidth:5)
            for i in 0..<5 {
                let x = w * (0.15 + CGFloat(i) * 0.18)
                context.fill(Path(ellipseIn:CGRect(x:x,y:h*0.23+CGFloat(i%2)*17,width:7,height:7)),with:.color(.white.opacity(0.6)))
            }
            var floor = Path(); floor.move(to:CGPoint(x:0,y:h*0.84)); floor.addQuadCurve(to:CGPoint(x:w,y:h*0.84),control:CGPoint(x:w/2,y:h*0.77)); floor.addLine(to:CGPoint(x:w,y:h));floor.addLine(to:CGPoint(x:0,y:h));floor.closeSubpath()
            context.fill(floor,with:.color(Color(red:0.91,green:0.69,blue:0.39)))
            context.stroke(floor,with:.color(Color(red:0.7,green:0.45,blue:0.23).opacity(0.35)),lineWidth:3)
            for side in 0..<2 {
                let x = side == 0 ? w*0.03 : w*0.87
                let y = h*0.72
                let pot = Path(roundedRect:CGRect(x:x,y:y,width:w*0.09,height:h*0.1),cornerRadius:8)
                context.fill(pot,with:.color(side == 0 ? StudioStyle.colors[1] : StudioStyle.colors[5]))
                context.stroke(pot,with:.color(WorkshopLook.sea.opacity(0.7)),lineWidth:2)
                var brush = Path();brush.move(to:CGPoint(x:x+w*0.045,y:y+10));brush.addLine(to:CGPoint(x:x+w*0.065,y:y-h*0.09))
                context.stroke(brush,with:.color(WorkshopLook.yellow),style:StrokeStyle(lineWidth:8,lineCap:.round))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
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
