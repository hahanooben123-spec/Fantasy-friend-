import SwiftUI

enum CreatureExpression:Equatable {case normal,wink,wonder,chew}

struct CharacterView: View {
    let friend: FantasyFriend
    var blink = false
    var happy = false
    var asleep = false
    var piece: Attachment? = nil
    var detail: Part? = nil
    var gaze = CGPoint.zero
    var zoom: CGFloat = 1
    var expression=CreatureExpression.normal
    var pose=CreaturePose()

    var body: some View {
        Canvas { context, size in
            if detail == .eyes || detail == .mouth {
                let rect = detail == .eyes ? CGRect(x: 85, y: 121, width: 129, height: 65) : CGRect(x: 119, y: 184, width: 68, height: 48)
                let scale = min(size.width / rect.width, size.height / rect.height) * 0.82
                context.translateBy(x: size.width / 2, y: size.height / 2)
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: -rect.midX, y: -rect.midY)
                let painter = CreaturePainter(context: context, friend: friend)
                if detail == .eyes { painter.drawEyes(closed: false, happy: false) }
                else { painter.drawMouth(happy: false, asleep: false) }
            } else if let piece = piece {
                let rect = AttachmentLayout.bounds(for: piece, friend: friend)
                let scale = min(size.width / rect.width, size.height / rect.height) * 0.84
                context.translateBy(x: size.width / 2, y: size.height / 2)
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: -rect.midX, y: -rect.midY)
                CreaturePainter(context: context, friend: friend).drawPiece(piece)
            } else {
                context.translateBy(x: size.width * (1 - zoom) / 2, y: size.height * (1 - zoom) / 2)
                context.scaleBy(x: size.width / 300 * zoom, y: size.height / 320 * zoom)
                CreaturePainter(context: context, friend: friend, gaze: gaze,expression:expression,pose:pose).draw(blink: blink, happy: happy, asleep: asleep)
            }
        }
        .aspectRatio(300.0 / 320, contentMode: .fit)
        .accessibilityLabel(friend.name.isEmpty ? "FantasiVen" : friend.name)
    }
}

private struct CreaturePainter {
    var context: GraphicsContext
    let friend: FantasyFriend
    var gaze = CGPoint.zero
    var singleEye = false
    var expression=CreatureExpression.normal
    var pose=CreaturePose()
    var primary: Color { GameStyle.palette[friend.color % 16] }
    var accent: Color { GameStyle.palette[friend.accent % 16] }
    var ink: Color { GameStyle.ink }

    func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
        let shape = Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
        if w >= 20 && h >= 20 {
            ToyFinish.paint(context,path:shape,color:color,edge:1.6)
        } else {context.fill(shape,with:.color(color))}
    }
    func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat = 5) {
        guard let first = points.first else { return }
        var path = Path(); path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        if width >= 6 {
            context.stroke(path, with: .color(GameStyle.mixed(color,with:ink,amount:0.58)), style: StrokeStyle(lineWidth: width + 2, lineCap: .round, lineJoin: .round))
        }
        context.stroke(path, with: .linearGradient(Gradient(colors:[GameStyle.mixed(color,with:.white,amount:0.24),color,GameStyle.mixed(color,with:ink,amount:0.22)]),
            startPoint:CGPoint(x:70,y:90),endPoint:CGPoint(x:210,y:270)),style:StrokeStyle(lineWidth:width,lineCap:.round,lineJoin:.round))
    }
    func curve(_ start: CGPoint, _ end: CGPoint, _ control: CGPoint, _ color: Color, _ width: CGFloat = 5) {
        var path = Path(); path.move(to: start); path.addQuadCurve(to: end, control: control)
        if width >= 7 {
            context.stroke(path, with: .color(GameStyle.mixed(color,with:ink,amount:0.58)), style: StrokeStyle(lineWidth: width + 2, lineCap: .round))
        }
        context.stroke(path, with: .linearGradient(Gradient(colors:[GameStyle.mixed(color,with:.white,amount:0.25),color,GameStyle.mixed(color,with:ink,amount:0.24)]),
            startPoint:start,endPoint:end),style:StrokeStyle(lineWidth:width,lineCap:.round))
    }
    func polygon(_ points: [CGPoint], _ color: Color) {
        guard let first = points.first else { return }
        var path = Path(); path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }; path.closeSubpath()
        ToyFinish.paint(context,path:path,color:color,edge:1.8)
    }
    func star(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ color: Color) {
        polygon((0..<10).map { i in
            let a = Double(i) * .pi / 5 - .pi / 2
            let r = i.isMultiple(of: 2) ? radius : radius * 0.47
            return CGPoint(x: x + CGFloat(cos(a)) * r, y: y + CGFloat(sin(a)) * r)
        }, color)
    }

    func placed(for attachment: Attachment) -> CreaturePainter {
        let rect = AttachmentLayout.bounds(for: attachment, friend: friend)
        let pose = friend.placement(for: attachment)
        var transformed = context
        transformed.translateBy(x: rect.midX + CGFloat(pose.x) * 300, y: rect.midY + CGFloat(pose.y) * 320)
        transformed.rotate(by: .degrees(pose.rotation))
        transformed.scaleBy(x: CGFloat(pose.scale) * ((friend.mirroredParts?.contains(attachment.rawValue) ?? false) ? -1 : 1), y: CGFloat(pose.scale))
        transformed.translateBy(x: -rect.midX, y: -rect.midY)
        let joint = self.pose.joint(attachment)
        let pivot = CreatureRig.pivot(attachment,friend:friend)
        transformed.translateBy(x:pivot.x+joint.offset.x,y:pivot.y+joint.offset.y)
        let headParts:[Attachment]=[.ears,.antennae,.horns,.hat,.crown,.glasses,.bow]
        transformed.rotate(by:.degrees(joint.angle+(headParts.contains(attachment) ? self.pose.headTilt*0.65 : 0)))
        transformed.translateBy(x:-pivot.x,y:-pivot.y)
        return CreaturePainter(context:transformed,friend:friend,gaze:gaze,expression:expression,pose:self.pose)
    }

    func draw(blink: Bool, happy: Bool, asleep: Bool) {
        var root=context
        root.translateBy(x:150+pose.x,y:275+pose.y)
        root.rotate(by:.degrees(pose.roll))
        root.scaleBy(x:pose.scaleX,y:pose.scaleY)
        root.translateBy(x:-150,y:-275)
        CreaturePainter(context:root,friend:friend,gaze:gaze,expression:expression,pose:pose)
            .drawArtwork(blink:blink,happy:happy || pose.happy,asleep:asleep || pose.asleep)
    }

    private func drawArtwork(blink: Bool, happy: Bool, asleep: Bool) {
        for attachment in [Attachment.tail, .wings, .spikes] {
            if let index = attachment.extraIndex, friend.accessories.contains(index), friend.placement(for: attachment) == PartPlacement() { placed(for: attachment).drawPiece(attachment) }
        }
        let limbs: [Attachment] = [.leftArm, .rightArm, .leftLeg, .rightLeg]
        for attachment in limbs where friend.placement(for: attachment) == PartPlacement() { placed(for: attachment).drawPiece(attachment) }
        drawBody(blink: blink, happy: happy, asleep: asleep)
        // Moved limbs remain visible even when children place them on the tummy.
        for attachment in limbs where friend.placement(for: attachment) != PartPlacement() { placed(for: attachment).drawPiece(attachment) }
        for attachment in [Attachment.tail, .wings, .spikes] {
            if let index = attachment.extraIndex, friend.accessories.contains(index), friend.placement(for: attachment) != PartPlacement() {
                placed(for: attachment).drawPiece(attachment)
            }
        }
        for index in [0, 1, 2, 5, 8, 6, 7, 12, 13, 14] where friend.accessories.contains(index) {
            let attachment = Attachment.extra(index)
            placed(for: attachment).drawPiece(attachment)
        }
        for piece in friend.pieces ?? [] { drawCreative(piece) }
    }

    func drawCreative(_ piece: CreativePiece, preview: Bool = false) {
        var sample = friend
        sample.placements = nil; sample.pieces = nil; sample.hiddenParts = nil; sample.mirroredParts = nil; sample.facePlacements = nil
        sample.partColors = piece.kind == .eye ? ["eyes": piece.color] : nil
        sample.color = piece.color; sample.accent = piece.accent
        var rect: CGRect
        switch piece.kind {
        case .eye: sample.eyes = piece.variant; rect = CGRect(x: 116, y: 123, width: 68, height: 70)
        case .arm: sample.arms = piece.variant; rect = AttachmentLayout.bounds(for: .leftArm, friend: sample)
        case .leg: sample.legs = piece.variant; rect = AttachmentLayout.bounds(for: .leftLeg, friend: sample)
        case .extra: rect = AttachmentLayout.bounds(for: .extra(piece.variant), friend: sample)
        }
        var canvas = context
        canvas.translateBy(x: preview ? 150 : piece.x * 300, y: preview ? 160 : piece.y * 320)
        canvas.rotate(by: .degrees(piece.rotation))
        let joint = preview ? CreatureJoint() : pose.creativeJoint(piece)
        // Creative pieces follow their own saved anchor, including duplicates.
        let pivot = piece.kind == .arm ? CGPoint(x:rect.maxX-8,y:179) :
            piece.kind == .leg ? CGPoint(x:rect.midX,y:237) : CGPoint(x:rect.midX,y:rect.maxY)
        let scale = preview ? min(210 / rect.width, 250 / rect.height) : CGFloat(piece.scale)
        canvas.scaleBy(x: (piece.mirrored ? -1 : 1) * scale, y: scale)
        canvas.translateBy(x: -rect.midX, y: -rect.midY)
        canvas.translateBy(x:pivot.x+joint.offset.x,y:pivot.y+joint.offset.y)
        canvas.rotate(by:.degrees(joint.angle))
        canvas.translateBy(x:-pivot.x,y:-pivot.y)
        let painter = CreaturePainter(context: canvas, friend: sample, singleEye: true,expression:expression,pose:pose)
        switch piece.kind {
        case .eye: painter.drawEyes(closed: false, happy: false)
        case .arm: painter.drawArm(side: 0)
        case .leg: painter.drawLeg(side: 0)
        case .extra: painter.drawExtra(piece.variant)
        }
    }

    func drawBody(blink: Bool, happy: Bool, asleep: Bool) {
        var bodyContext = context
        bodyContext.translateBy(x: 150, y: 175)
        bodyContext.scaleBy(x: CGFloat(friend.widthFactor), y: CGFloat(friend.heightFactor))
        bodyContext.translateBy(x: -150, y: -175)
        CreaturePainter(context: bodyContext, friend: friend, gaze: gaze,expression:expression,pose:pose).drawBaseBody(blink: blink, happy: happy, asleep: asleep)
    }

    func drawBaseBody(blink: Bool, happy: Bool, asleep: Bool) {
        let silhouette = CreatureSilhouette.path(for:friend)
        ToyFinish.paint(context,path:silhouette,color:primary,edge:2.6)
        var clipped = context; clipped.clip(to: silhouette)
        let tummy=Path(ellipseIn:CGRect(x:103,y:183,width:98,height:85))
        clipped.fill(tummy,with:.radialGradient(Gradient(colors:[
            GameStyle.mixed(primary,with:Color(red:1,green:0.91,blue:0.68),amount:0.35).opacity(0.55),.clear]),
            center:CGPoint(x:149,y:213),startRadius:0,endRadius:52))
        var rim=Path();rim.move(to:CGPoint(x:218,y:118))
        rim.addQuadCurve(to:CGPoint(x:224,y:229),control:CGPoint(x:254,y:167))
        clipped.stroke(rim,with:.color(accent.opacity(0.16)),style:StrokeStyle(lineWidth:9,lineCap:.round))
        if friend.accessories.contains(9) {
            let attachment = Attachment.extra(9)
            let paintingContext = friend.placement(for: attachment) == PartPlacement() ? clipped : context
            CreaturePainter(context: paintingContext, friend: friend).placed(for: attachment).drawPiece(attachment)
        }
        if friend.accessories.contains(10) {
            let attachment = Attachment.extra(10)
            let paintingContext = friend.placement(for: attachment) == PartPlacement() ? clipped : context
            CreaturePainter(context: paintingContext, friend: friend).placed(for: attachment).drawPiece(attachment)
        }
        drawDoodles(in: clipped)
        // Highlights stay clipped to every body shape, including narrow beans and drops.
        var sheen=Path();sheen.move(to:CGPoint(x:94,y:116))
        sheen.addQuadCurve(to:CGPoint(x:119,y:94),control:CGPoint(x:98,y:94))
        clipped.stroke(sheen,with:.color(.white.opacity(0.34)),style:StrokeStyle(lineWidth:7,lineCap:.round))
        clipped.fill(Path(ellipseIn:CGRect(x:124,y:91,width:8,height:5)),with:.color(.white.opacity(0.65)))
        ellipse(87, 180, 27, 15, Color(red: 1, green: 0.23, blue: 0.42).opacity(0.48)); ellipse(190, 180, 27, 15, Color(red: 1, green: 0.23, blue: 0.42).opacity(0.48))
        if !friend.isHidden("eyes") { drawEyes(closed: blink || asleep, happy: happy) }
        if !friend.isHidden("mouth") { drawMouth(happy: happy, asleep: asleep) }
    }

    func drawDoodles(in canvas: GraphicsContext) {
        for stroke in friend.doodles ?? [] {
            guard stroke.isValid, let first = stroke.points.first else { continue }
            let color = GameStyle.palette[stroke.color]
            let start = CGPoint(x: first.x * 300, y: first.y * 320)
            if stroke.points.count == 1 {
                let radius = CGFloat(stroke.width) / 2
                canvas.fill(Path(ellipseIn: CGRect(x: start.x - radius, y: start.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
            } else {
                var line = Path()
                line.move(to: start)
                for point in stroke.points.dropFirst() { line.addLine(to: CGPoint(x: point.x * 300, y: point.y * 320)) }
                canvas.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: CGFloat(stroke.width), lineCap: .round, lineJoin: .round))
            }
        }
    }

    func drawPiece(_ attachment: Attachment) {
        guard !friend.isHidden(attachment.rawValue) else { return }
        if let color = friend.partColors?[attachment.rawValue] {
            var colored = friend; colored.partColors = nil; colored.color = color; colored.accent = color
            CreaturePainter(context: context, friend: colored).drawPiece(attachment)
            return
        }
        switch attachment {
        case .leftArm: drawArm(side: 0)
        case .rightArm: drawArm(side: 1)
        case .leftLeg: drawLeg(side: 0)
        case .rightLeg: drawLeg(side: 1)
        default:
            if let index = attachment.extraIndex { drawExtra(index) }
        }
    }

    func drawArm(side:Int) {
        let sign:CGFloat=side == 0 ? -1 : 1
        let shoulder=CreatureShape(kind:friend.body).shoulder
        let start=CGPoint(x:side == 0 ? shoulder+6 : 294-shoulder,y:179)
        let reach=CGFloat(20+friend.arms*3)
        let hand=CGPoint(x:start.x+sign*reach,y:208-CGFloat(friend.arms%4)*16)
        let joint=pose.joint(side == 0 ? .leftArm : .rightArm)
        let bend=CGPoint(x:hand.x+joint.bend*sign,y:start.y-CGFloat(friend.arms%3)*15-joint.bend)
        let thickness=CGFloat(15+friend.arms%3*3)
        var arm=Path();arm.move(to:CGPoint(x:start.x,y:start.y-thickness/2))
        arm.addQuadCurve(to:CGPoint(x:hand.x,y:hand.y-8),control:CGPoint(x:bend.x,y:bend.y-thickness/2))
        arm.addQuadCurve(to:CGPoint(x:hand.x,y:hand.y+8),control:CGPoint(x:hand.x+sign*9,y:hand.y))
        arm.addQuadCurve(to:CGPoint(x:start.x,y:start.y+thickness/2),control:CGPoint(x:bend.x,y:bend.y+thickness/2))
        arm.closeSubpath()
        ToyFinish.paint(context,path:arm,color:primary,edge:1.7)
        var palm=context
        palm.translateBy(x:hand.x,y:hand.y);palm.scaleBy(x:sign,y:1)
        var mitten=Path()
        mitten.move(to:CGPoint(x:-8,y:6))
        if friend.arms == 6 {
            mitten.addCurve(to:CGPoint(x:13,y:-13),control1:CGPoint(x:-8,y:-17),control2:CGPoint(x:3,y:-23))
            mitten.addQuadCurve(to:CGPoint(x:15,y:9),control:CGPoint(x:28,y:-1))
        } else if friend.arms >= 4 {
            mitten.addCurve(to:CGPoint(x:-2,y:-11),control1:CGPoint(x:-17,y:-2),control2:CGPoint(x:-9,y:-22))
            mitten.addCurve(to:CGPoint(x:7,y:-13),control1:CGPoint(x:-2,y:-23),control2:CGPoint(x:8,y:-25))
            mitten.addCurve(to:CGPoint(x:14,y:-6),control1:CGPoint(x:15,y:-22),control2:CGPoint(x:20,y:-15))
            mitten.addCurve(to:CGPoint(x:15,y:9),control1:CGPoint(x:26,y:-10),control2:CGPoint(x:28,y:8))
        } else {
            mitten.addCurve(to:CGPoint(x:8,y:-11),control1:CGPoint(x:-17,y:-8),control2:CGPoint(x:-3,y:-17))
            mitten.addCurve(to:CGPoint(x:15,y:9),control1:CGPoint(x:23,y:-11),control2:CGPoint(x:25,y:9))
        }
        mitten.addQuadCurve(to:CGPoint(x:-8,y:6),control:CGPoint(x:3,y:18));mitten.closeSubpath()
        ToyFinish.paint(palm,path:mitten,color:primary,edge:1.7)
        if friend.arms == 2 || friend.arms == 7 {
            for i in 0..<3 {
                let dot=Path(ellipseIn:CGRect(x:CGFloat(i)*6-4,y:-7-CGFloat(i%2)*3,width:5,height:6))
                ToyFinish.paint(palm,path:dot,color:accent,edge:0.6)
            }
            ToyFinish.paint(palm,path:Path(ellipseIn:CGRect(x:-1,y:0,width:13,height:10)),color:accent,edge:0.7)
        } else if friend.arms == 3 {
            var seam=Path();seam.move(to:CGPoint(x:-7,y:7));seam.addQuadCurve(to:CGPoint(x:14,y:7),control:CGPoint(x:3,y:12))
            palm.stroke(seam,with:.color(accent.opacity(0.65)),style:StrokeStyle(lineWidth:2,lineCap:.round,dash:[2,3]))
        }
        if friend.arms == 1 || friend.arms == 5 {
            palm.fill(Path(ellipseIn:CGRect(x:-1,y:-2,width:11,height:9)),with:.color(accent.opacity(0.55)))
        }
    }

    func drawLeg(side:Int) {
        let sign:CGFloat=side == 0 ? -1 : 1
        let footX:CGFloat=side == 0 ? 110 : 180
        let footY=CGFloat(265+friend.legs%4*4)
        curve(CGPoint(x:footX,y:237),CGPoint(x:footX+sign*CGFloat(friend.legs*2),y:footY),
              CGPoint(x:footX+sign*(10+pose.joint(side == 0 ? .leftLeg : .rightLeg).bend),y:257),
              primary,CGFloat(16-friend.legs%3*2))
        let x=footX-19+sign*CGFloat(friend.legs*2)
        let width=CGFloat(32+friend.legs%3*5)
        var foot=Path();foot.move(to:CGPoint(x:x,y:footY+7))
        foot.addCurve(to:CGPoint(x:x+width*0.5,y:footY-7),control1:CGPoint(x:x-3,y:footY-5),control2:CGPoint(x:x+width*0.25,y:footY-13))
        foot.addCurve(to:CGPoint(x:x+width,y:footY+5),control1:CGPoint(x:x+width*0.78,y:footY-12),control2:CGPoint(x:x+width+5,y:footY-4))
        foot.addQuadCurve(to:CGPoint(x:x,y:footY+7),control:CGPoint(x:x+width*0.55,y:footY+18));foot.closeSubpath()
        ToyFinish.paint(context,path:foot,color:friend.legs>=4 ? accent : primary,edge:1.7)
        if friend.legs == 2 || friend.legs == 7 {
            let pad=Path(ellipseIn:CGRect(x:x+width*0.27,y:footY-3,width:width*0.48,height:8))
            ToyFinish.paint(context,path:pad,color:friend.legs == 7 ? primary : accent,edge:0.7)
        }
        if friend.legs>=4 {
            for i in 0..<2 {
                let y=footY-4+CGFloat(i)*4
                line([CGPoint(x:x+width*0.34,y:y),CGPoint(x:x+width*0.61,y:y+1)],StorybookStyle.cream.opacity(0.8),1.8)
            }
        }
        if friend.legs == 0 || friend.legs == 3 || friend.legs == 6 {
            for i in 0..<2 {
                let toe=x+width*(0.3+CGFloat(i)*0.27)
                curve(CGPoint(x:toe,y:footY-3),CGPoint(x:toe+1,y:footY+2),CGPoint(x:toe-2,y:footY),ink.opacity(0.3),1.3)
            }
        } else if friend.legs>=4 {
            curve(CGPoint(x:x+4,y:footY+8),CGPoint(x:x+width-3,y:footY+7),
                  CGPoint(x:x+width*0.5,y:footY+13),GameStyle.mixed(accent,with:ink,amount:0.3),2.5)
        }
    }

    func drawExtra(_ index: Int) {
        switch index {
        case 0:
            for (i,x) in [CGFloat(98),CGFloat(184)].enumerated() {
                let lean:CGFloat=i == 0 ? -1 : 1
                var horn=Path();horn.move(to:CGPoint(x:x-3,y:93))
                horn.addCurve(to:CGPoint(x:x+lean*4,y:43),control1:CGPoint(x:x-6,y:68),control2:CGPoint(x:x+lean*17,y:40))
                horn.addCurve(to:CGPoint(x:x+25,y:89),control1:CGPoint(x:x+13,y:51),control2:CGPoint(x:x+15,y:71))
                horn.addQuadCurve(to:CGPoint(x:x-3,y:93),control:CGPoint(x:x+12,y:101));horn.closeSubpath()
                ToyFinish.paint(context,path:horn,color:accent,edge:1.8)
                curve(CGPoint(x:x+1,y:76),CGPoint(x:x+17,y:78),CGPoint(x:x+9,y:83),primary.opacity(0.3),2.5)
            }

        case 1:
            for (i,x) in [CGFloat(101),CGFloat(171)].enumerated() {
                let lean:CGFloat=i == 0 ? -12 : 10
                var earCanvas=context
                earCanvas.translateBy(x:x+15,y:97)
                earCanvas.rotate(by:.degrees(pose.joint(.ears).angle*(i == 0 ? 0.45 : -0.35)))
                earCanvas.translateBy(x:-x-15,y:-97)
                var ear=Path();ear.move(to:CGPoint(x:x+2,y:99))
                ear.addCurve(to:CGPoint(x:x+12+lean,y:13),control1:CGPoint(x:x-11,y:66),control2:CGPoint(x:x-9+lean,y:10))
                ear.addCurve(to:CGPoint(x:x+29,y:96),control1:CGPoint(x:x+39+lean,y:8),control2:CGPoint(x:x+38,y:70))
                ear.addQuadCurve(to:CGPoint(x:x+2,y:99),control:CGPoint(x:x+16,y:109));ear.closeSubpath()
                ToyFinish.paint(earCanvas,path:ear,color:primary,edge:2)
                var inner=Path();inner.move(to:CGPoint(x:x+11,y:85))
                inner.addQuadCurve(to:CGPoint(x:x+14+lean*0.7,y:29),control:CGPoint(x:x+lean,y:44))
                inner.addQuadCurve(to:CGPoint(x:x+20,y:85),control:CGPoint(x:x+28+lean,y:39));inner.closeSubpath()
                ToyFinish.paint(earCanvas,path:inner,color:accent,edge:0.8)
            }

        case 2:
            for x in [115,185] as [CGFloat] {
                curve(CGPoint(x:x,y:87),CGPoint(x:x-8,y:38),CGPoint(x:x+18,y:44),primary,7)
                let bulb=Path(ellipseIn:CGRect(x:x-20,y:23,width:25,height:25))
                context.fill(Path(ellipseIn:CGRect(x:x-26,y:17,width:37,height:37)),with:.radialGradient(
                    Gradient(colors:[accent.opacity(0.3),.clear]),center:CGPoint(x:x-7,y:35),startRadius:0,endRadius:19))
                ToyFinish.paint(context,path:bulb,color:accent,edge:1.2)
                ellipse(x-15,27,7,5,.white.opacity(0.75))
            }

        case 3:
            for side in 0..<2 {
                var c=context;c.translateBy(x:side == 0 ? 24 : 276,y:130);c.scaleBy(x:side == 0 ? 1 : -1,y:1)
                var wing=Path();wing.move(to:CGPoint(x:58,y:49))
                wing.addCurve(to:CGPoint(x:2,y:1),control1:CGPoint(x:34,y:-9),control2:CGPoint(x:-11,y:-15))
                wing.addCurve(to:CGPoint(x:15,y:65),control1:CGPoint(x:-9,y:24),control2:CGPoint(x:-7,y:55))
                wing.addCurve(to:CGPoint(x:58,y:49),control1:CGPoint(x:4,y:102),control2:CGPoint(x:52,y:92));wing.closeSubpath()
                ToyFinish.paint(c,path:wing,color:accent,edge:1.8)
                for i in 0..<3 {
                    var vein=Path();vein.move(to:CGPoint(x:54,y:50))
                    vein.addQuadCurve(to:CGPoint(x:8+CGFloat(i)*8,y:13+CGFloat(i)*25),control:CGPoint(x:25,y:35+CGFloat(i)*15))
                    c.stroke(vein,with:.color(.white.opacity(0.36)),style:StrokeStyle(lineWidth:2,lineCap:.round))
                }
            }

        case 4:
            curve(CGPoint(x: 211, y: 220), CGPoint(x: 270, y: 184), CGPoint(x: 289, y: 254), accent, 17)
            ellipse(257, 173, 24, 29, accent)

        case 5:
            var hat=Path();hat.move(to:CGPoint(x:106,y:83))
            hat.addCurve(to:CGPoint(x:120,y:40),control1:CGPoint(x:111,y:68),control2:CGPoint(x:108,y:43))
            hat.addQuadCurve(to:CGPoint(x:177,y:40),control:CGPoint(x:150,y:49))
            hat.addCurve(to:CGPoint(x:191,y:83),control1:CGPoint(x:190,y:39),control2:CGPoint(x:181,y:66))
            hat.closeSubpath()
            ToyFinish.paint(context,path:hat,color:accent,edge:2)
            var ribbon=Path();ribbon.move(to:CGPoint(x:112,y:71))
            ribbon.addQuadCurve(to:CGPoint(x:185,y:71),control:CGPoint(x:149,y:80))
            context.stroke(ribbon,with:.color(primary),style:StrokeStyle(lineWidth:9,lineCap:.round))
            let brim=Path(ellipseIn:CGRect(x:92,y:79,width:114,height:18))
            ToyFinish.paint(context,path:brim,color:accent,edge:2)

        case 6:
            polygon([CGPoint(x: 150, y: 98), CGPoint(x: 108, y: 80), CGPoint(x: 106, y: 115)], accent)
            polygon([CGPoint(x: 150, y: 98), CGPoint(x: 191, y: 80), CGPoint(x: 194, y: 115)], accent)
            ellipse(141, 88, 19, 21, .white.opacity(0.65))

        case 7:
            for x in [101,166] as [CGFloat] {
                let lens=Path(roundedRect:CGRect(x:x,y:142,width:40,height:35),cornerRadius:13)
                context.fill(lens,with:.linearGradient(Gradient(colors:[Color.cyan.opacity(0.15),.white.opacity(0.04)]),
                    startPoint:CGPoint(x:x,y:142),endPoint:CGPoint(x:x+40,y:177)))
                context.stroke(lens,with:.color(GameStyle.mixed(accent,with:ink,amount:0.45)),lineWidth:5)
                context.stroke(lens.applying(CGAffineTransform(translationX:0,y:-1)),with:.color(accent),lineWidth:2.5)
                line([CGPoint(x:x+8,y:149),CGPoint(x:x+15,y:146)],.white.opacity(0.7),2.5)
            }
            curve(CGPoint(x:141,y:155),CGPoint(x:166,y:155),CGPoint(x:153,y:147),accent,4)

        case 8:
            polygon([CGPoint(x: 110, y: 86), CGPoint(x: 102, y: 48), CGPoint(x: 130, y: 63), CGPoint(x: 151, y: 33), CGPoint(x: 172, y: 63), CGPoint(x: 198, y: 48), CGPoint(x: 190, y: 86)], Color(red: 1, green: 0.80, blue: 0.25))
            ellipse(145, 64, 12, 14, accent)

        case 9:
            for p in [CGPoint(x: 81, y: 159), CGPoint(x: 211, y: 208), CGPoint(x: 97, y: 223), CGPoint(x: 194, y: 104)] {
                context.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 21, height: 17)), with: .color(accent.opacity(0.85)))
            }

        case 10:
            for y in stride(from: 111, through: 251, by: 33) {
                context.fill(Path(roundedRect: CGRect(x: 50, y: CGFloat(y), width: 200, height: 9), cornerRadius: 5), with: .color(accent.opacity(0.75)))
            }

        case 11:
            for i in 0..<5 {
                let x = CGFloat(84 + i * 27)
                polygon([CGPoint(x: x, y: 108), CGPoint(x: x + 10, y: 67 - CGFloat(i % 2) * 10), CGPoint(x: x + 26, y: 109)], accent)
            }

        case 12:
            for i in 0..<5 {
                let a = Double(i) * .pi * 2 / 5
                ellipse(205 + CGFloat(cos(a)) * 12, 99 + CGFloat(sin(a)) * 12, 18, 18, accent)
            }
            ellipse(211, 105, 13, 13, .yellow)

        case 13:
            curve(CGPoint(x: 95, y: 216), CGPoint(x: 207, y: 216), CGPoint(x: 150, y: 242), accent, 15)
            line([CGPoint(x: 183, y: 226), CGPoint(x: 196, y: 258)], accent, 16)

        case 14:
            for x in [96, 106, 193, 203] as [CGFloat] { ellipse(x, 182 + (x.truncatingRemainder(dividingBy: 3)) * 3, 4, 4, ink.opacity(0.45)) }

        default: break
        }
    }

    private func facialContext(_ key: String, center: CGPoint) -> GraphicsContext {
        let pose = friend.facePlacements?[key] ?? PartPlacement()
        var canvas = context
        canvas.translateBy(x: center.x + pose.x * 300, y: center.y + pose.y * 320 + self.pose.headY)
        canvas.rotate(by: .degrees(pose.rotation+self.pose.headTilt))
        if key == "eyes" {canvas.scaleBy(x:1,y:max(0.08,1-self.pose.eyelid*0.92))}
        if key == "mouth" {canvas.scaleBy(x:1+self.pose.cheek*0.09,y:1-self.pose.cheek*0.12)}
        canvas.scaleBy(x: pose.scale * ((friend.mirroredParts?.contains(key) ?? false) ? -1 : 1), y: pose.scale)
        canvas.translateBy(x: -center.x, y: -center.y)
        return canvas
    }
    private func eyeOrb(x:CGFloat,y:CGFloat,radius:CGFloat) {
        let rect=CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2.16)
        let shape=Path(ellipseIn:rect)
        context.fill(shape.applying(CGAffineTransform(translationX:0,y:2)),
            with:.color(GameStyle.mixed(primary,with:ink,amount:0.5)))
        context.fill(shape,with:.radialGradient(Gradient(stops:[
            .init(color:.white,location:0),.init(color:Color(red:0.99,green:0.99,blue:1),location:0.63),
            .init(color:Color(red:0.76,green:0.82,blue:0.92),location:1)]),
            center:CGPoint(x:x-radius*0.3,y:y-radius*0.35),startRadius:0,endRadius:radius*1.6))
        context.stroke(shape,with:.color(GameStyle.mixed(primary,with:ink,amount:0.56)),lineWidth:1.7)
    }
    func drawEyes(closed: Bool, happy: Bool) {
        CreaturePainter(context: facialContext("eyes", center: CGPoint(x: 150, y: 157)), friend: friend, gaze: gaze, singleEye: singleEye,expression:expression,pose:pose).drawEyesArtwork(closed: closed, happy: happy)
    }
    func drawEyesArtwork(closed: Bool, happy: Bool) {
        let ink = friend.partColors?["eyes"].map { GameStyle.palette[$0] } ?? self.ink
        let kind = friend.eyes
        let centers: [CGFloat] = singleEye || kind == 5 ? [150] : (kind == 6 ? [110, 150, 190] : [120, 181])
        let radius: CGFloat = kind == 1 ? 13 : (kind == 5 ? 35 : (kind == 6 && !singleEye ? 17 : 28))
        for x in centers {
            let y: CGFloat = 157
            if closed || kind == 3 || happy || (expression == .wink && x == centers[0]) {
                curve(CGPoint(x: x - radius * 0.65, y: y), CGPoint(x: x + radius * 0.65, y: y), CGPoint(x: x, y: y + (closed ? 9 : -13)), ink, 5)
                continue
            }
            eyeOrb(x:x,y:y,radius:radius)
            if radius>=24 {
                curve(CGPoint(x:x-radius*0.55,y:y-radius-7-pose.brow),CGPoint(x:x+radius*0.4,y:y-radius-10-pose.brow),
                    CGPoint(x:x-radius*0.1,y:y-radius-15-pose.brow),GameStyle.mixed(primary,with:ink,amount:0.4),3)
            }
            if kind == 4 { star(x, y, radius * 0.64, ink) }
            else if kind == 10 {
                ellipse(x - 10, y - 7, 11, 12, ink); ellipse(x, y - 7, 11, 12, ink)
                polygon([CGPoint(x: x - 10, y: y), CGPoint(x: x + 11, y: y), CGPoint(x: x, y: y + 12)], ink)
            } else if kind == 9 {
                ellipse(x - 12, y - 8, 24, 22, accent); ellipse(x - 5, y - 8, 10, 22, ink)
            } else {
                let irisX=x+gaze.x*5+(kind == 7 ? 5 : 0)
                let irisY=y+gaze.y*4
                ellipse(irisX-radius*0.61,irisY-radius*0.52,radius*1.22,radius*1.42,
                    GameStyle.mixed(accent,with:ink,amount:0.18))
                let pupilWidth: CGFloat = kind == 8 ? 7 : radius * 0.9
                ellipse(x - pupilWidth / 2 + (kind == 7 ? 5 : 0) + gaze.x * 5, y - radius * 0.35 + gaze.y * 4, pupilWidth, radius * 1.15, ink)
            }
            ellipse(x-5+gaze.x*5,y-8+gaze.y*4,7,8,.white)
            ellipse(x+5+gaze.x*5,y+5+gaze.y*4,3,3,.white.opacity(0.8))
            if kind == 2 {
                var lid = context
                lid.clip(to: Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2.16)))
                lid.fill(Path(CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius)), with: .color(primary))
                line([CGPoint(x: x - radius + 2, y: y), CGPoint(x: x + radius - 2, y: y)], ink, 3)
            }
            if kind == 11 {
                for i in -1...1 { line([CGPoint(x: x + CGFloat(i) * 10, y: y - radius + 1), CGPoint(x: x + CGFloat(i) * 13, y: y - radius - 9)], ink, 3) }
            }
        }
    }

    func drawMouth(happy: Bool, asleep: Bool) {
        CreaturePainter(context: facialContext("mouth", center: CGPoint(x: 151, y: 207)), friend: friend,expression:expression,pose:pose).drawMouthArtwork(happy: happy, asleep: asleep)
    }
    func drawMouthArtwork(happy: Bool, asleep: Bool) {
        let ink = friend.partColors?["mouth"].map { GameStyle.palette[$0] } ?? self.ink
        if pose.jaw>0.03 && !asleep {
            let width=28+pose.jaw*22,height=6+pose.jaw*31
            let mouth=Path(ellipseIn:CGRect(x:151-width/2,y:204-height/2,width:width,height:height))
            context.fill(mouth,with:.color(ink))
            var inner=context;inner.clip(to:mouth)
            inner.fill(Path(ellipseIn:CGRect(x:136,y:208,width:34,height:17)),
                with:.color(Color(red:1,green:0.38,blue:0.49)))
            inner.fill(Path(roundedRect:CGRect(x:136,y:187,width:30,height:12),cornerRadius:4),with:.color(.white))
            return
        }
        if expression == .wonder && !asleep {
            ellipse(136,191,30,31,ink);ellipse(144,196,10,5,.white.opacity(0.5));return
        }
        if expression == .chew && !asleep {
            ellipse(137,203,28,8,ink);return
        }
        let kind = happy ? 1 : friend.mouth
        if asleep || kind == 3 { ellipse(142, 192, 17, 23, ink); ellipse(146, 196, 7, 5, .white.opacity(0.45)); return }
        if kind == 0 || kind == 2 || kind == 6 || kind == 9 {
            let width: CGFloat = kind == 2 ? 10 : 28
            curve(CGPoint(x: 151 - width, y: 196), CGPoint(x: 151 + width, y: kind == 6 ? 189 : 196), CGPoint(x: 151, y: kind == 9 ? 204 : 221), ink, 5)
            if kind == 9 { ellipse(173, 191, 6, 6, ink) }
        } else {
            var mouth = Path(); mouth.move(to: CGPoint(x: 118, y: 195))
            mouth.addQuadCurve(to: CGPoint(x: 184, y: 195), control: CGPoint(x: 151, y: 201))
            mouth.addCurve(to: CGPoint(x: 118, y: 195), control1: CGPoint(x: 186, y: 246), control2: CGPoint(x: 115, y: 246))
            context.fill(mouth, with: .color(ink))
            var clipped = context; clipped.clip(to: mouth)
            clipped.fill(Path(ellipseIn:CGRect(x:133,y:kind == 4 ? 207 : 219,width:40,height:24)),with:.linearGradient(
                Gradient(colors:[Color(red:1,green:0.63,blue:0.68),Color(red:0.94,green:0.25,blue:0.45)]),
                startPoint:CGPoint(x:0,y:213),endPoint:CGPoint(x:0,y:243)))
            if kind == 1 {
                clipped.fill(Path(roundedRect: CGRect(x: 128, y: 193, width: 47, height: 12), cornerRadius: 5), with: .color(.white))
            }
            if kind == 5 || kind == 7 {
                for x in [136, 150, 164] as [CGFloat] { clipped.fill(Path(roundedRect: CGRect(x: x, y: 191, width: 10, height: kind == 7 ? 14 : 8), cornerRadius: 3), with: .color(.white)) }
            }
            if kind == 8 { line([CGPoint(x: 133, y: 195), CGPoint(x: 169, y: 195)], .white, 5) }
        }
    }
}

struct RagdollCharacterView: View {
    let frame: RagdollFrame

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / frame.canvasSize.width, y: size.height / frame.canvasSize.height)
            let position = CGPoint(x: frame.position.x, y: frame.canvasSize.height - frame.position.y)
            var character = context
            character.translateBy(x: position.x, y: position.y)
            character.rotate(by: .radians(-frame.angle))
            character.scaleBy(x: RagdollSimulation.characterScale, y: RagdollSimulation.characterScale)
            character.translateBy(x: -150, y: -170)
            CreaturePainter(context: character, friend: frame.friend,expression:frame.pose.expression,pose:frame.pose).draw(blink: frame.blink, happy: frame.happy, asleep: frame.asleep)
            if frame.happy {
                for index in 0..<6 {
                    let angle = Double(index) * .pi / 3
                    let point = CGPoint(x: position.x + CGFloat(cos(angle)) * 113, y: position.y + CGFloat(sin(angle)) * 100)
                    context.draw(Text(frame.reaction == .hug ? "♥" : "✦").font(.system(size: 20)).foregroundColor(GameStyle.palette[(index + 2) % 16]), at: point)
                }
            }
            if frame.reaction == .feed {
                var food=context
                let reach=CreatureRig.key(frame.reactionTime,[(0,0),(0.5,1),(0.9,1),(1.05,0)])
                food.opacity=reach
                food.translateBy(x:position.x-18,y:position.y+52-reach*35)
                food.scaleBy(x:0.36,y:0.36)
                // Same original berry artwork as the feeding tool.
                let berry=Path(ellipseIn:CGRect(x:8,y:0,width:74,height:63))
                ToyFinish.paint(food,path:berry,color:Color(red:0.97,green:0.24,blue:0.35),edge:2)
                for i in 0..<5 {
                    food.fill(Path(ellipseIn:CGRect(x:20+CGFloat(i%3)*17,y:15+CGFloat(i/3)*20,width:4,height:6)),
                        with:.color(.yellow))
                }
            }
            if frame.asleep {
                context.draw(Text("z Z").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(GameStyle.purple), at: CGPoint(x: position.x + 85, y: position.y - 90))
            }
        }
    }
}

struct CreativePieceView: View {
    let piece: CreativePiece
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 300, y: size.height / 320)
            CreaturePainter(context: context, friend: FantasyFriend()).drawCreative(piece, preview: true)
        }.aspectRatio(300.0 / 320, contentMode: .fit)
    }
}
