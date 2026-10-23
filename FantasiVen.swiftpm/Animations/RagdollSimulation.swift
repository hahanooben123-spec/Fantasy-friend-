import SwiftUI
import SpriteKit

struct RagdollFrame {
    var friend = FantasyFriend()
    var position = CGPoint(x: 300, y: 235)
    var angle: Double = 0
    var happy = false
    var asleep = false
    var blink = false
    var reaction: PlayAction?
    var canvasSize = CGSize(width:600,height:440)
}

@MainActor
final class RagdollSimulation: ObservableObject {
    nonisolated static let stageSize = CGSize(width: 600, height: 440)
    nonisolated static let characterScale: CGFloat = 0.98
    @Published private(set) var frame = RagdollFrame()
    let scene = SKScene(size: stageSize)
    private let body = SKNode()
    private var limbs: [Attachment: SKNode] = [:]
    private var original = FantasyFriend()
    private var pointer: SKNode?
    private var dragJoint: SKPhysicsJointSpring?
    private var heldBody: SKPhysicsBody?
    private var gripOffset = CGVector.zero
    private var reactionUntil: TimeInterval = 0
    private var asleep = false
    private var reaction: PlayAction?
    private var reducedMotion = false

    var isDragging: Bool { heldBody != nil }

    init() {
        scene.scaleMode = .fill
        scene.backgroundColor = .clear
        scene.isPaused = true
    }

    func resize(to size: CGSize) {
        guard size.width>0,size.height>0 else { return }
        let width = min(600,max(360,size.width))
        scene.size = CGSize(width:width,height:max(440,width*size.height/size.width))
    }

    func configure(_ friend: FantasyFriend, reducedMotion: Bool) {
        endDrag()
        scene.physicsWorld.removeAllJoints()
        scene.removeAllChildren()
        limbs.removeAll()
        original = friend
        self.reducedMotion = reducedMotion
        asleep = false; reaction = nil; reactionUntil = 0
        scene.physicsWorld.gravity = reducedMotion ? .zero : CGVector(dx: 0, dy: -5)
        let floor = SKNode()
        floor.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x:8,y:90,width:scene.size.width-16,height:scene.size.height-165))
        floor.physicsBody?.categoryBitMask = 4
        floor.physicsBody?.collisionBitMask = 3
        floor.physicsBody?.friction = 0.7
        floor.physicsBody?.restitution = 0.18
        scene.addChild(floor)

        body.position = CGPoint(x:scene.size.width/2,y:scene.size.height/2+15)
        body.zRotation = 0
        body.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 142 * Self.characterScale, height: 160 * Self.characterScale))
        prepare(body.physicsBody, mass: 1.8, category: 1)
        scene.addChild(body)

        for attachment in [Attachment.leftArm, .rightArm, .leftLeg, .rightLeg] {
            let bounds = AttachmentLayout.bounds(for: attachment, friend: friend)
            let pose = friend.placement(for: attachment)
            let center = AttachmentLayout.center(for: attachment, friend: friend)
            let node = SKNode()
            node.position = world(center)
            node.zRotation = -CGFloat(pose.rotation) * .pi / 180
            node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(
                width: bounds.width * CGFloat(pose.scale) * Self.characterScale,
                height: bounds.height * CGFloat(pose.scale) * Self.characterScale))
            prepare(node.physicsBody, mass: 0.16, category: 2)
            scene.addChild(node)
            limbs[attachment] = node

            // The pin follows the saved placement, including rotated/scaled limbs.
            let localPin: CGPoint
            switch attachment {
            case .leftArm: localPin = CGPoint(x: bounds.maxX - 15, y: 179)
            case .rightArm: localPin = CGPoint(x: bounds.minX + 15, y: 179)
            default: localPin = CGPoint(x: bounds.midX, y: 237)
            }
            let angle = CGFloat(pose.rotation) * .pi / 180
            let dx = (localPin.x - bounds.midX) * CGFloat(pose.scale)
            let dy = (localPin.y - bounds.midY) * CGFloat(pose.scale)
            let pin = CGPoint(x: center.x + dx * cos(angle) - dy * sin(angle),
                              y: center.y + dx * sin(angle) + dy * cos(angle))
            if let a = body.physicsBody, let b = node.physicsBody {
                let joint = SKPhysicsJointPin.joint(withBodyA: a, bodyB: b, anchor: world(pin))
                joint.frictionTorque = 0.15
                joint.shouldEnableLimits = true
                joint.lowerAngleLimit = -2.2
                joint.upperAngleLimit = 2.2
                scene.physicsWorld.add(joint)
            }
        }
        refresh()
    }

    private func prepare(_ physics: SKPhysicsBody?, mass: CGFloat, category: UInt32) {
        physics?.mass = mass
        physics?.categoryBitMask = category
        physics?.collisionBitMask = 4
        physics?.contactTestBitMask = 0
        physics?.linearDamping = 1.1
        physics?.angularDamping = 1.8
        physics?.friction = 0.7
        physics?.restitution = 0.18
        physics?.isDynamic = !reducedMotion
        physics?.usesPreciseCollisionDetection = true
    }

    private func world(_ point: CGPoint) -> CGPoint {
        CGPoint(x: body.position.x + (point.x - 150) * Self.characterScale,
                y: body.position.y - (point.y - 170) * Self.characterScale)
    }

    private func bounded(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(scene.size.width-20,max(20,point.x)),y:min(scene.size.height-80,max(100,point.y)))
    }

    func beginDrag(at point: CGPoint) {
        guard heldBody == nil else { return }
        let ordered: [Attachment] = [.leftArm, .rightArm, .leftLeg, .rightLeg]
        var candidates: [(SKNode, CGSize)] = ordered.compactMap { attachment in
            guard let node = limbs[attachment] else { return nil }
            let rect = AttachmentLayout.bounds(for: attachment, friend: original)
            let scale = CGFloat(original.placement(for: attachment).scale) * Self.characterScale
            return (node, CGSize(width: rect.width * scale, height: rect.height * scale))
        }
        candidates.append((body, CGSize(width: 142 * Self.characterScale, height: 160 * Self.characterScale)))
        guard let chosen = candidates.first(where: { node, size in
            let local = node.convert(point, from: scene)
            let width = max(76, size.width + 20), height = max(76, size.height + 20)
            return CGRect(x: -width / 2, y: -height / 2, width: width, height: height).contains(local)
        }), let physics = chosen.0.physicsBody else { return }
        asleep = false
        heldBody = physics
        gripOffset = CGVector(dx: point.x - body.position.x, dy: point.y - body.position.y)
        if !reducedMotion {
            let handle = SKNode()
            handle.position = bounded(point)
            handle.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            handle.physicsBody?.isDynamic = false
            handle.physicsBody?.categoryBitMask = 0
            handle.physicsBody?.collisionBitMask = 0
            scene.addChild(handle)
            if let handleBody = handle.physicsBody {
                let joint = SKPhysicsJointSpring.joint(withBodyA: physics, bodyB: handleBody, anchorA: point, anchorB: handle.position)
                joint.frequency = 7
                joint.damping = 1
                scene.physicsWorld.add(joint)
                dragJoint = joint
            }
            pointer = handle
        }
        reaction = .hug
        reactionUntil = Date.timeIntervalSinceReferenceDate + 0.7
        SoundService.shared.play(.reaction)
    }

    func moveDrag(to point: CGPoint) {
        guard heldBody != nil else { return }
        let point = bounded(point)
        if reducedMotion {
            let proposed = CGPoint(x: point.x - gripOffset.dx, y: point.y - gripOffset.dy)
            let target = CGPoint(x: min(scene.size.width-100,max(100,proposed.x)),y:min(scene.size.height-120,max(180,proposed.y)))
            let dx = target.x - body.position.x, dy = target.y - body.position.y
            body.position = target
            for node in limbs.values { node.position.x += dx; node.position.y += dy }
            refresh()
        } else { pointer?.position = point }
    }

    func endDrag() {
        if let dragJoint = dragJoint { scene.physicsWorld.remove(dragJoint) }
        dragJoint = nil
        pointer?.removeFromParent()
        pointer = nil; heldBody = nil
    }

    func setActive(_ active: Bool) {
        if !active { endDrag() }
        scene.isPaused = !active
    }

    func react(_ action: PlayAction) {
        asleep = action == .sleep
        reaction = action
        reactionUntil = Date.timeIntervalSinceReferenceDate + 1.4
        SoundService.shared.play(action == .sleep ? .click : .reaction)
        guard !reducedMotion else { refresh(); return }
        switch action {
        case .jump: body.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
        case .dance:
            body.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 110))
            body.physicsBody?.angularVelocity = 1.8
            for (attachment, node) in limbs { node.physicsBody?.angularVelocity = attachment == .leftArm || attachment == .leftLeg ? -4 : 4 }
        case .tickle:
            body.physicsBody?.applyImpulse(CGVector(dx: 45, dy: 70))
            body.physicsBody?.angularVelocity = -1.3
        case .hug: body.physicsBody?.angularVelocity = 0
        case .feed: body.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
        case .sleep:
            body.physicsBody?.velocity = .zero
            body.physicsBody?.angularVelocity = 0
        }
    }

    func refresh() {
        let now = Date.timeIntervalSinceReferenceDate
        // Cap speed after abrupt finger movements to keep play gentle and stable.
        for node in [body] + Array(limbs.values) {
            guard let physics = node.physicsBody else { continue }
            let speed = hypot(physics.velocity.dx, physics.velocity.dy)
            if speed > 700 { physics.velocity = CGVector(dx: physics.velocity.dx / speed * 700, dy: physics.velocity.dy / speed * 700) }
            physics.angularVelocity = min(7, max(-7, physics.angularVelocity))
        }
        var posed = original
        for (attachment, node) in limbs {
            let delta = CGPoint(x: node.position.x - body.position.x, y: node.position.y - body.position.y)
            let angle = -body.zRotation
            let x = delta.x * cos(angle) - delta.y * sin(angle)
            let y = delta.x * sin(angle) + delta.y * cos(angle)
            let bounds = AttachmentLayout.bounds(for: attachment, friend: original)
            var pose = original.placement(for: attachment)
            pose.x = Double((150 + x / Self.characterScale - bounds.midX) / 300)
            pose.y = Double((170 - y / Self.characterScale - bounds.midY) / 320)
            pose.rotation = -Double(node.zRotation - body.zRotation) * 180 / .pi
            posed.setPlacement(pose, for: attachment)
        }
        frame = RagdollFrame(friend: posed, position: body.position, angle: Double(body.zRotation),
            happy: !asleep && now < reactionUntil, asleep: asleep,
            blink: now.truncatingRemainder(dividingBy: 4) < 0.14,
            reaction: now < reactionUntil ? reaction : nil, canvasSize: scene.size)
    }
}
