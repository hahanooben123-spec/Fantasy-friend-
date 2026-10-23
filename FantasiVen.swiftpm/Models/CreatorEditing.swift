import SwiftUI

enum CreatorSelection: Equatable {
    case body, eyes, mouth, attachment(Attachment), piece(UUID)
}
struct CreatorPick: Equatable {
    let part: Part
    let index: Int
}
enum CreatorGeometry {
    static func pieceSource(_ piece: CreativePiece, friend: FantasyFriend) -> CGRect {
        var value = friend
        switch piece.kind {
        case .eye: return CGRect(x: 116, y: 122, width: 68, height: 72)
        case .arm: value.arms = piece.variant; return AttachmentLayout.bounds(for: .leftArm, friend: value)
        case .leg: value.legs = piece.variant; return AttachmentLayout.bounds(for: .leftLeg, friend: value)
        case .extra: return AttachmentLayout.bounds(for: .extra(piece.variant), friend: value)
        }
    }
    static func bounds(_ selection: CreatorSelection, friend: FantasyFriend) -> CGRect {
        switch selection {
        case .body:
            let rect = CreatureShape(kind: friend.body).path(in: CGRect(x: 0, y: 0, width: 300, height: 320)).boundingRect
            return stretch(rect, friend: friend)
        case .eyes, .mouth:
            let key = selection == .eyes ? "eyes" : "mouth"
            let source = selection == .eyes ? CGRect(x: 85, y: 121, width: 129, height: 70) : CGRect(x: 112, y: 188, width: 80, height: 48)
            let pose = friend.facePlacements?[key] ?? PartPlacement()
            return stretch(transformed(source, center: CGPoint(x: source.midX + pose.x * 300, y: source.midY + pose.y * 320), scale: pose.scale, angle: pose.rotation), friend: friend)
        case .attachment(let attachment): return AttachmentLayout.visualBounds(for: attachment, friend: friend)
        case .piece(let id):
            guard let piece = friend.pieces?.first(where: { $0.id == id }) else { return .zero }
            return transformed(pieceSource(piece, friend: friend), center: CGPoint(x: piece.x * 300, y: piece.y * 320), scale: piece.scale, angle: piece.rotation)
        }
    }
    private static func stretch(_ rect: CGRect, friend: FantasyFriend) -> CGRect {
        CGRect(x: 150 + (rect.minX - 150) * friend.widthFactor,
               y: 175 + (rect.minY - 175) * friend.heightFactor,
               width: rect.width * friend.widthFactor, height: rect.height * friend.heightFactor)
    }
    private static func transformed(_ rect: CGRect, center: CGPoint, scale: Double, angle: Double) -> CGRect {
        let a = angle * .pi / 180
        let cosine = CGFloat(abs(cos(a)))
        let sine = CGFloat(abs(sin(a)))
        let factor = CGFloat(scale)
        let width = (cosine * rect.width + sine * rect.height) * factor
        let height = (sine * rect.width + cosine * rect.height) * factor
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }
    static func hit(_ point: CGPoint, friend: FantasyFriend, margin: CGFloat, minimumTouchSize:CGFloat=0) -> CreatorSelection? {
        let pieces = (friend.pieces ?? []).reversed().map { CreatorSelection.piece($0.id) }
        let face: [CreatorSelection] = [.eyes, .mouth].filter { !friend.isHidden($0 == .eyes ? "eyes" : "mouth") }
        let attachments = AttachmentLayout.attachments(in: friend).reversed().filter { !friend.isHidden($0.rawValue) }.map { CreatorSelection.attachment($0) }
        return (pieces + face + attachments + [.body]).first {
            let rect=bounds($0,friend:friend)
            let dx=max(margin,(minimumTouchSize-rect.width)/2)
            let dy=max(margin,(minimumTouchSize-rect.height)/2)
            return rect.insetBy(dx:-dx,dy:-dy).contains(point)
        }
    }
    static func pose(_ selection: CreatorSelection, friend: FantasyFriend) -> PartPlacement {
        switch selection {
        case .attachment(let a): return friend.placement(for: a)
        case .eyes, .mouth: return friend.facePlacements?[selection == .eyes ? "eyes" : "mouth"] ?? PartPlacement()
        case .piece(let id):
            guard let p = friend.pieces?.first(where: { $0.id == id }) else { return PartPlacement() }
            return PartPlacement(rotation:p.rotation,scale:p.scale)
        case .body: return PartPlacement()
        }
    }
    static func transformed(_ selection: CreatorSelection, original: FantasyFriend, rotation: Double, scale: Double) -> FantasyFriend {
        var copy = original
        let angle = (rotation + 540).truncatingRemainder(dividingBy:360) - 180
        let size = min(1.5,max(0.5,scale))
        switch selection {
        case .piece(let id):
            if let i = copy.pieces?.firstIndex(where: { $0.id == id }) { copy.pieces?[i].rotation = angle; copy.pieces?[i].scale = size }
        case .attachment(let a):
            var p = original.placement(for:a);p.rotation=angle;p.scale=size
            copy.setPlacement(AttachmentLayout.constrained(p,for:a,friend:copy),for:a)
        case .eyes, .mouth:
            let key = selection == .eyes ? "eyes" : "mouth"
            var p = original.facePlacements?[key] ?? PartPlacement();p.rotation=angle;p.scale=size
            var values = copy.facePlacements ?? [:];values[key]=p;copy.facePlacements=values
        case .body: break
        }
        return copy
    }
    static func moved(_ selection: CreatorSelection, original: FantasyFriend, delta: CGSize) -> FantasyFriend {
        var copy = original
        switch selection {
        case .body: break
        case .piece(let id):
            if let index = copy.pieces?.firstIndex(where: { $0.id == id }) {
                var piece = copy.pieces![index]
                piece.move(x: piece.x + delta.width / 300, y: piece.y + delta.height / 320, snap: false)
                copy.pieces?[index] = piece
            }
        case .attachment(let attachment):
            let pose = AttachmentLayout.moved(attachment, in: original, by: delta, stageSize: CGSize(width: 300, height: 320))
            copy.setPlacement(pose, for: attachment)
        case .eyes, .mouth:
            let key = selection == .eyes ? "eyes" : "mouth"
            var pose = original.facePlacements?[key] ?? PartPlacement()
            pose.x = min(0.3, max(-0.3, pose.x + delta.width / (300 * original.widthFactor)))
            pose.y = min(0.3, max(-0.3, pose.y + delta.height / (320 * original.heightFactor)))
            var values = copy.facePlacements ?? [:]; values[key] = pose; copy.facePlacements = values
        }
        return copy
    }
}
