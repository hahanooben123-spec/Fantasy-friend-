import Foundation

enum AttachmentLayout {
    static let canvas = CGSize(width: 300, height: 320)

    static func attachments(in friend: FantasyFriend) -> [Attachment] {
        [.leftArm, .rightArm, .leftLeg, .rightLeg] + friend.accessories.sorted().map(Attachment.extra)
    }

    static func bounds(for attachment: Attachment, friend: FantasyFriend) -> CGRect {
        switch attachment {
        case .leftArm, .rightArm:
            let left = attachment == .leftArm
            let shoulder: CGFloat
            switch friend.body {
            case .oval: shoulder = 82
            case .pear: shoulder = 88
            case .drop: shoulder = 79
            case .cloud: shoulder = 49
            case .bean: shoulder = 89
            default: shoulder = 65
            }
            let start = left ? shoulder + 6 : 294 - shoulder
            let hand = start + (left ? -1 : 1) * CGFloat(20 + friend.arms * 3)
            let handY = CGFloat(208 - friend.arms % 4 * 16)
            return CGRect(x: min(start, hand) - 15, y: min(165, handY - 20),
                          width: abs(hand - start) + 30, height: max(195, handY + 15) - min(165, handY - 20))
        case .leftLeg, .rightLeg:
            let left = attachment == .leftLeg
            let x: CGFloat = left ? 110 : 180
            let foot = x + (left ? -1 : 1) * CGFloat(friend.legs * 2)
            return CGRect(x: min(x - 12, foot - 20), y: 228,
                          width: max(x + 12, foot + 26) - min(x - 12, foot - 20),
                          height: CGFloat(58 + friend.legs % 4 * 4))
        case .horns: return CGRect(x: 90, y: 40, width: 122, height: 56)
        case .ears: return CGRect(x: 99, y: 9, width: 103, height: 96)
        case .antennae: return CGRect(x: 93, y: 21, width: 103, height: 70)
        case .wings: return CGRect(x: 19, y: 130, width: 262, height: 84)
        case .tail: return CGRect(x: 201, y: 163, width: 90, height: 94)
        case .hat: return CGRect(x: 86, y: 38, width: 126, height: 59)
        case .bow: return CGRect(x: 103, y: 77, width: 94, height: 41)
        case .glasses: return CGRect(x: 98, y: 139, width: 111, height: 41)
        case .crown: return CGRect(x: 100, y: 31, width: 100, height: 58)
        case .spots: return CGRect(x: 79, y: 102, width: 155, height: 140)
        case .stripes: return CGRect(x: 50, y: 109, width: 200, height: 145)
        case .spikes: return CGRect(x: 82, y: 55, width: 138, height: 57)
        case .flower: return CGRect(x: 187, y: 78, width: 52, height: 53)
        case .scarf: return CGRect(x: 86, y: 207, width: 130, height: 60)
        case .freckles: return CGRect(x: 93, y: 180, width: 118, height: 17)
        }
    }

    static func center(for attachment: Attachment, friend: FantasyFriend) -> CGPoint {
        let rect = bounds(for: attachment, friend: friend)
        let pose = friend.placement(for: attachment)
        return CGPoint(x: rect.midX + CGFloat(pose.x) * canvas.width,
                       y: rect.midY + CGFloat(pose.y) * canvas.height)
    }

    static func visualBounds(for attachment: Attachment, friend: FantasyFriend) -> CGRect {
        let rect = bounds(for: attachment, friend: friend)
        let pose = friend.placement(for: attachment)
        let angle = pose.rotation * .pi / 180
        let w = (Double(rect.width) * abs(cos(angle)) + Double(rect.height) * abs(sin(angle))) * pose.scale
        let h = (Double(rect.width) * abs(sin(angle)) + Double(rect.height) * abs(cos(angle))) * pose.scale
        let center = center(for: attachment, friend: friend)
        return CGRect(x: center.x - CGFloat(w / 2), y: center.y - CGFloat(h / 2), width: CGFloat(w), height: CGFloat(h))
    }

    static func constrained(_ placement: PartPlacement, for attachment: Attachment, friend: FantasyFriend) -> PartPlacement {
        var pose = placement.isValid ? placement : PartPlacement()
        let rect = bounds(for: attachment, friend: friend)
        let angle = pose.rotation * .pi / 180
        let width = (Double(rect.width) * abs(cos(angle)) + Double(rect.height) * abs(sin(angle))) * pose.scale
        let height = (Double(rect.width) * abs(sin(angle)) + Double(rect.height) * abs(cos(angle))) * pose.scale
        // Fit even very wide wings after rotation or enlargement.
        let fit = min(1, min(288 / width, 308 / height))
        pose.scale *= fit
        let halfWidth = width * fit / 2
        let halfHeight = height * fit / 2
        let cx = min(294 - halfWidth, max(6 + halfWidth, Double(rect.midX) + pose.x * 300))
        let cy = min(314 - halfHeight, max(6 + halfHeight, Double(rect.midY) + pose.y * 320))
        pose.x = (cx - Double(rect.midX)) / 300
        pose.y = (cy - Double(rect.midY)) / 320
        return pose
    }

    static func moved(_ attachment: Attachment, in friend: FantasyFriend, by translation: CGSize, stageSize: CGSize) -> PartPlacement {
        guard stageSize.width > 0, stageSize.height > 0 else { return friend.placement(for: attachment) }
        var pose = friend.placement(for: attachment)
        pose.x += Double(translation.width / stageSize.width)
        pose.y += Double(translation.height / stageSize.height)
        // Translation is bounded by the stage, including for a very long gesture.
        pose.x = min(1, max(-1, pose.x)); pose.y = min(1, max(-1, pose.y))
        return constrained(pose, for: attachment, friend: friend)
    }

    static func placed(_ attachment: Attachment, in friend: FantasyFriend, at point: CGPoint, stageSize: CGSize) -> PartPlacement {
        let bounds = bounds(for: attachment, friend: friend)
        var pose = friend.placement(for: attachment)
        pose.x = Double(point.x / max(1, stageSize.width) - bounds.midX / 300)
        pose.y = Double(point.y / max(1, stageSize.height) - bounds.midY / 320)
        pose.x = min(1, max(-1, pose.x)); pose.y = min(1, max(-1, pose.y))
        return constrained(pose, for: attachment, friend: friend)
    }
}
