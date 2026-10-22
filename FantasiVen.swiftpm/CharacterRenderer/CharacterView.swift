import SwiftUI

struct CharacterView: View {
    let friend: FantasyFriend
    var blink = false
    var happy = false
    var asleep = false
    var piece: Attachment? = nil
    var detail: Part? = nil

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
                context.scaleBy(x: size.width / 300, y: size.height / 320)
                CreaturePainter(context: context, friend: friend).draw(blink: blink, happy: happy, asleep: asleep)
            }
        }
        .aspectRatio(300.0 / 320, contentMode: .fit)
        .accessibilityLabel(friend.name.isEmpty ? "FantasiVen" : friend.name)
    }
}

private struct CreaturePainter {
    var context: GraphicsContext
    let friend: FantasyFriend
    var primary: Color { GameStyle.palette[friend.color % 16] }
    var accent: Color { GameStyle.palette[friend.accent % 16] }
    var ink: Color { GameStyle.ink }

    func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }
    func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat = 5) {
        guard let first = points.first else { return }
        var path = Path(); path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    func curve(_ start: CGPoint, _ end: CGPoint, _ control: CGPoint, _ color: Color, _ width: CGFloat = 5) {
        var path = Path(); path.move(to: start); path.addQuadCurve(to: end, control: control)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
    func polygon(_ points: [CGPoint], _ color: Color) {
        guard let first = points.first else { return }
        var path = Path(); path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }; path.closeSubpath()
        context.fill(path, with: .color(color))
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
        transformed.scaleBy(x: CGFloat(pose.scale), y: CGFloat(pose.scale))
        transformed.translateBy(x: -rect.midX, y: -rect.midY)
        return CreaturePainter(context: transformed, friend: friend)
    }

    func draw(blink: Bool, happy: Bool, asleep: Bool) {
        for attachment in [Attachment.tail, .wings, .spikes] {
            if let index = attachment.extraIndex, friend.accessories.contains(index), friend.placement(for: attachment) == PartPlacement() { drawPiece(attachment) }
        }
        let limbs: [Attachment] = [.leftArm, .rightArm, .leftLeg, .rightLeg]
        for attachment in limbs where friend.placement(for: attachment) == PartPlacement() { drawPiece(attachment) }
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
    }

    func drawBody(blink: Bool, happy: Bool, asleep: Bool) {
        let silhouette = CreatureShape(kind: friend.body).path(in: CGRect(x: 0, y: 0, width: 300, height: 320))
        context.fill(silhouette, with: .linearGradient(Gradient(colors: [primary.opacity(0.78), primary, primary]), startPoint: CGPoint(x: 85, y: 76), endPoint: CGPoint(x: 207, y: 260)))
        context.stroke(silhouette, with: .color(primary.opacity(0.45)), lineWidth: 2)
        var clipped = context; clipped.clip(to: silhouette)
        clipped.fill(Path(ellipseIn: CGRect(x: 105, y: 196, width: 96, height: 72)), with: .color(accent.opacity(0.33)))
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
        ellipse(95, 106, 15, 28, .white.opacity(0.18))
        ellipse(87, 180, 27, 15, Color.pink.opacity(0.32)); ellipse(190, 180, 27, 15, Color.pink.opacity(0.32))
        drawEyes(closed: blink || asleep, happy: happy)
        drawMouth(happy: happy, asleep: asleep)
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
        switch attachment {
        case .leftArm: drawArm(side: 0)
        case .rightArm: drawArm(side: 1)
        case .leftLeg: drawLeg(side: 0)
        case .rightLeg: drawLeg(side: 1)
        default:
            if let index = attachment.extraIndex { drawExtra(index) }
        }
    }

    func drawArm(side: Int) {
        let sign: CGFloat = side == 0 ? -1 : 1
        let shoulder = CreatureShape(kind: friend.body).shoulder
        let start = CGPoint(x: side == 0 ? shoulder + 6 : 294 - shoulder, y: 179)
        let reach = CGFloat(20 + friend.arms * 3)
        let hand = CGPoint(x: start.x + sign * reach, y: 208 - CGFloat(friend.arms % 4) * 16)
        curve(start, hand, CGPoint(x: hand.x, y: start.y - CGFloat(friend.arms % 3) * 15), primary, CGFloat(15 + friend.arms % 3 * 3))
        ellipse(hand.x - 11, hand.y - 10, 22, 22, primary)
        if friend.arms >= 4 {
            for finger in 0..<3 {
                let x = hand.x + CGFloat(finger - 1) * 7
                line([CGPoint(x: x, y: hand.y), CGPoint(x: x + sign * 3, y: hand.y - 14)], primary, 6)
            }
        }
    }

    func drawLeg(side: Int) {
        let sign: CGFloat = side == 0 ? -1 : 1
        let footX: CGFloat = side == 0 ? 110 : 180
        let footY = CGFloat(265 + friend.legs % 4 * 4)
        curve(CGPoint(x: footX, y: 237), CGPoint(x: footX + sign * CGFloat(friend.legs * 2), y: footY), CGPoint(x: footX + sign * 10, y: 257), primary, CGFloat(16 - friend.legs % 3 * 2))
        ellipse(footX - 19 + sign * CGFloat(friend.legs * 2), footY - 5, CGFloat(32 + friend.legs % 3 * 5), 17, friend.legs >= 4 ? accent : primary)
    }

    func drawExtra(_ index: Int) {
        switch index {
        case 0:
            for x in [98, 184] as [CGFloat] {
                polygon([CGPoint(x: x, y: 93), CGPoint(x: x - 7, y: 42), CGPoint(x: x + 26, y: 88)], accent)
                line([CGPoint(x: x + 1, y: 65), CGPoint(x: x + 11, y: 73)], .white.opacity(0.6), 3)
            }

        case 1:
            for x in [101, 171] as [CGFloat] {
                ellipse(x, 11, 29, 91, primary); ellipse(x + 7, 23, 14, 62, accent)
            }

        case 2:
            for x in [115, 185] as [CGFloat] {
                curve(CGPoint(x: x, y: 87), CGPoint(x: x - 8, y: 38), CGPoint(x: x + 18, y: 44), primary, 7)
                ellipse(x - 20, 23, 25, 25, accent)
            }

        case 3:
            for x in [21, 206] as [CGFloat] {
                ellipse(x, 132, 73, 49, accent.opacity(0.9)); ellipse(x + 9, 168, 55, 44, accent.opacity(0.75))
                curve(CGPoint(x: x + 17, y: 153), CGPoint(x: x + 57, y: 166), CGPoint(x: x + 38, y: 149), .white.opacity(0.5), 3)
            }

        case 4:
            curve(CGPoint(x: 211, y: 220), CGPoint(x: 270, y: 184), CGPoint(x: 289, y: 254), accent, 17)
            ellipse(257, 173, 24, 29, accent)

        case 5:
            polygon([CGPoint(x: 105, y: 87), CGPoint(x: 118, y: 40), CGPoint(x: 177, y: 40), CGPoint(x: 191, y: 87)], accent)
            line([CGPoint(x: 94, y: 88), CGPoint(x: 204, y: 88)], accent, 13)
            line([CGPoint(x: 113, y: 73), CGPoint(x: 184, y: 73)], primary, 9)

        case 6:
            polygon([CGPoint(x: 150, y: 98), CGPoint(x: 108, y: 80), CGPoint(x: 106, y: 115)], accent)
            polygon([CGPoint(x: 150, y: 98), CGPoint(x: 191, y: 80), CGPoint(x: 194, y: 115)], accent)
            ellipse(141, 88, 19, 21, .white.opacity(0.65))

        case 7:
            for x in [101, 166] as [CGFloat] {
                context.stroke(Path(roundedRect: CGRect(x: x, y: 142, width: 40, height: 35), cornerRadius: 12), with: .color(ink), lineWidth: 4)
            }
            curve(CGPoint(x: 141, y: 155), CGPoint(x: 166, y: 155), CGPoint(x: 153, y: 147), ink, 4)

        case 8:
            polygon([CGPoint(x: 110, y: 86), CGPoint(x: 102, y: 48), CGPoint(x: 130, y: 63), CGPoint(x: 151, y: 33), CGPoint(x: 172, y: 63), CGPoint(x: 198, y: 48), CGPoint(x: 190, y: 86)], Color(red: 1, green: 0.80, blue: 0.25))
            ellipse(145, 64, 12, 14, accent)

        case 9:
            for p in [CGPoint(x: 81, y: 159), CGPoint(x: 211, y: 208), CGPoint(x: 97, y: 223), CGPoint(x: 194, y: 104)] {
                context.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 21, height: 17)), with: .color(accent.opacity(0.65)))
            }

        case 10:
            for y in stride(from: 111, through: 251, by: 33) {
                context.fill(Path(roundedRect: CGRect(x: 50, y: CGFloat(y), width: 200, height: 9), cornerRadius: 5), with: .color(accent.opacity(0.4)))
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

    func drawEyes(closed: Bool, happy: Bool) {
        let kind = friend.eyes
        let centers: [CGFloat] = kind == 5 ? [150] : (kind == 6 ? [110, 150, 190] : [120, 181])
        let radius: CGFloat = kind == 1 ? 10 : (kind == 5 ? 31 : (kind == 6 ? 15 : 22))
        for x in centers {
            let y: CGFloat = 157
            if closed || kind == 3 || happy {
                curve(CGPoint(x: x - radius * 0.65, y: y), CGPoint(x: x + radius * 0.65, y: y), CGPoint(x: x, y: y + (closed ? 9 : -13)), ink, 5)
                continue
            }
            ellipse(x - radius, y - radius, radius * 2, radius * 2.16, .white)
            if kind == 4 { star(x, y, radius * 0.64, ink) }
            else if kind == 10 {
                ellipse(x - 10, y - 7, 11, 12, ink); ellipse(x, y - 7, 11, 12, ink)
                polygon([CGPoint(x: x - 10, y: y), CGPoint(x: x + 11, y: y), CGPoint(x: x, y: y + 12)], ink)
            } else if kind == 9 {
                ellipse(x - 12, y - 8, 24, 22, accent); ellipse(x - 5, y - 8, 10, 22, ink)
            } else {
                let pupilWidth: CGFloat = kind == 8 ? 7 : radius * 0.9
                ellipse(x - pupilWidth / 2 + (kind == 7 ? 5 : 0), y - radius * 0.35, pupilWidth, radius * 1.15, ink)
            }
            ellipse(x - 5, y - 8, 6, 7, .white)
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
        let kind = happy ? 1 : friend.mouth
        if asleep || kind == 3 { ellipse(142, 192, 17, 23, ink); ellipse(146, 196, 7, 5, .white.opacity(0.45)); return }
        if kind == 0 || kind == 2 || kind == 6 || kind == 9 {
            let width: CGFloat = kind == 2 ? 10 : 21
            curve(CGPoint(x: 151 - width, y: 196), CGPoint(x: 151 + width, y: kind == 6 ? 189 : 196), CGPoint(x: 151, y: kind == 9 ? 204 : 221), ink, 5)
            if kind == 9 { ellipse(173, 191, 6, 6, ink) }
        } else {
            var mouth = Path(); mouth.move(to: CGPoint(x: 125, y: 191))
            mouth.addQuadCurve(to: CGPoint(x: 177, y: 191), control: CGPoint(x: 151, y: 201))
            mouth.addCurve(to: CGPoint(x: 125, y: 191), control1: CGPoint(x: 178, y: 233), control2: CGPoint(x: 123, y: 233))
            context.fill(mouth, with: .color(ink))
            var clipped = context; clipped.clip(to: mouth)
            clipped.fill(Path(ellipseIn: CGRect(x: 138, y: kind == 4 ? 202 : 212, width: 31, height: 22)), with: .color(Color(red: 1, green: 0.5, blue: 0.62)))
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
            context.scaleBy(x: size.width / RagdollSimulation.stageSize.width, y: size.height / RagdollSimulation.stageSize.height)
            let position = CGPoint(x: frame.position.x, y: 440 - frame.position.y)
            var character = context
            character.translateBy(x: position.x, y: position.y)
            character.rotate(by: .radians(-frame.angle))
            character.scaleBy(x: RagdollSimulation.characterScale, y: RagdollSimulation.characterScale)
            character.translateBy(x: -150, y: -170)
            CreaturePainter(context: character, friend: frame.friend).draw(blink: frame.blink, happy: frame.happy, asleep: frame.asleep)
            if frame.happy {
                for index in 0..<6 {
                    let angle = Double(index) * .pi / 3
                    let point = CGPoint(x: position.x + CGFloat(cos(angle)) * 113, y: position.y + CGFloat(sin(angle)) * 100)
                    context.draw(Text(frame.reaction == .hug ? "♥" : "✦").font(.system(size: 20)).foregroundColor(GameStyle.palette[(index + 2) % 16]), at: point)
                }
            }
            if frame.reaction == .feed {
                context.draw(Text("🍓").font(.system(size: 32)), at: CGPoint(x: position.x, y: position.y + 20))
            }
            if frame.asleep {
                context.draw(Text("z Z").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(GameStyle.purple), at: CGPoint(x: position.x + 85, y: position.y - 90))
            }
        }
    }
}
