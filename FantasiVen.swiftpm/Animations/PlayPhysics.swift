import SpriteKit
import SwiftUI

struct PhysicsFriendFrame: Identifiable {
    let id: UUID
    var friend: FantasyFriend
    var x: CGFloat
    var y: CGFloat
    var angle: Double
}
struct PhysicsToyFrame: Identifiable {
    let id: UUID
    var kind: Int
    var x: CGFloat
    var y: CGFloat
    var angle: Double
}

@MainActor
final class PlayPhysics: ObservableObject {
    enum Mode { case yard, slide(SlideTrack), trampoline }
    private struct Actor {
        let original: FantasyFriend
        let node: SKNode
        let limbs: [Attachment: SKNode]
    }
    private struct Toy {
        let id = UUID()
        let kind: Int
        let node: SKNode
    }
    nonisolated static let size = CGSize(width: 800, height: 500)
    nonisolated static let scale: CGFloat = 0.4
    let scene = SKScene(size: size)
    @Published private(set) var friends: [PhysicsFriendFrame] = []
    @Published private(set) var toys: [PhysicsToyFrame] = []
    @Published private(set) var arrived = false
    private var actors: [Actor] = []
    private var objects: [Toy] = []
    private var handle: SKNode?
    private var spring: SKPhysicsJointSpring?
    private var held: SKNode?
    private var heldActor: Int?
    private var reduced = false
    private var mode = Mode.yard
    private let trampoline = SKNode()
    private var bounceCooldown = 0.0
    var isDragging: Bool {held != nil}
    var toyCount: Int { objects.count }
    var friendCount: Int { actors.count }

    init() { scene.backgroundColor = .clear; scene.scaleMode = .fill; scene.isPaused = true }

    func configure(friends: [FantasyFriend], mode: Mode, reducedMotion: Bool) {
        endDrag(); scene.physicsWorld.removeAllJoints(); scene.removeAllChildren()
        actors.removeAll(); objects.removeAll(); arrived = false
        self.mode = mode; reduced = reducedMotion
        scene.physicsWorld.gravity = reduced ? .zero : CGVector(dx: 0, dy: -5)
        let edge = SKNode()
        edge.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x:5,y:65,width:790,height:390))
        edge.physicsBody?.categoryBitMask = 2; edge.physicsBody?.collisionBitMask = 7
        scene.addChild(edge)
        switch mode {
        case .yard: break
        case .slide(let track):
            let path = CGMutablePath()
            for i in 0..<5 {
                let point = CGPoint(x: 70 + CGFloat(i) * 160, y: 400 - track.heights[i] * 300)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            let rail = SKNode(); rail.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            rail.physicsBody?.categoryBitMask = 2; rail.physicsBody?.friction = 0.15
            scene.addChild(rail)
        case .trampoline:
            trampoline.position = CGPoint(x: 400, y: 85)
            trampoline.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 150, height: 16))
            trampoline.physicsBody?.isDynamic = false; trampoline.physicsBody?.categoryBitMask = 2
            trampoline.physicsBody?.restitution = 1
            scene.addChild(trampoline)
        }
        for (i, friend) in friends.prefix(4).enumerated() {
            let point: CGPoint
            switch mode {
            case .yard: point = CGPoint(x: 180 + i * 150, y: 280)
            case .slide(let track): point = CGPoint(x: 80, y: min(435, 490 - track.heights[0] * 300))
            case .trampoline: point = CGPoint(x: 400, y: 360)
            }
            addFriend(friend, at: point)
        }
        refresh()
    }

    func addFriend(_ friend: FantasyFriend, at point: CGPoint = CGPoint(x: 300, y: 330)) {
        guard actors.count < 4 else { return }
        var value = friend
        if actors.contains(where: { $0.original.id == friend.id }) { value.id = UUID() }
        let body = SKNode(); body.position = point
        body.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 57, height: 64))
        prepare(body.physicsBody, category: 1, mass: 0.7)
        scene.addChild(body)
        var limbs: [Attachment: SKNode] = [:]
        for attachment in [Attachment.leftArm, .rightArm, .leftLeg, .rightLeg] {
            let center = AttachmentLayout.center(for: attachment, friend: value)
            let node = SKNode()
            node.position = CGPoint(x: point.x + (center.x - 150) * Self.scale, y: point.y - (center.y - 160) * Self.scale)
            node.zRotation = -CGFloat(value.placement(for: attachment).rotation) * .pi / 180
            node.physicsBody = SKPhysicsBody(circleOfRadius: 8)
            prepare(node.physicsBody, category: 4, mass: 0.05)
            node.physicsBody?.collisionBitMask = 2
            scene.addChild(node); limbs[attachment] = node
            if let a = body.physicsBody, let b = node.physicsBody {
                let joint = SKPhysicsJointPin.joint(withBodyA: a, bodyB: b, anchor: node.position)
                joint.shouldEnableLimits = true; joint.lowerAngleLimit = -1; joint.upperAngleLimit = 1
                scene.physicsWorld.add(joint)
            }
        }
        actors.append(Actor(original: value, node: body, limbs: limbs))
    }

    func addToy(_ kind:Int,at point:CGPoint? = nil) {
        guard objects.count < 12, (0..<3).contains(kind) else { return }
        let node = SKNode()
        let spawn=point ?? CGPoint(x:CGFloat.random(in:110...690),y:370)
        node.position=CGPoint(x:min(740,max(60,spawn.x)),y:min(420,max(100,spawn.y)))
        node.physicsBody = kind == 1 ? SKPhysicsBody(rectangleOf: CGSize(width: 54, height: 54)) : SKPhysicsBody(circleOfRadius: 28)
        prepare(node.physicsBody, category: 2, mass: kind == 2 ? 0.1 : 0.5)
        node.physicsBody?.restitution = kind == 0 ? 0.85 : 0.3
        node.physicsBody?.affectedByGravity = kind != 2
        node.physicsBody?.collisionBitMask = 7
        scene.addChild(node); objects.append(Toy(kind: kind, node: node))
        refresh()
    }
    private func prepare(_ body: SKPhysicsBody?, category: UInt32, mass: CGFloat) {
        body?.categoryBitMask = category; body?.collisionBitMask = 3
        body?.mass = mass; body?.linearDamping = 0.5; body?.angularDamping = 1.2
        body?.restitution = 0.25; body?.friction = 0.25; body?.isDynamic = !reduced
        body?.usesPreciseCollisionDetection = true
    }

    func beginDrag(_ point: CGPoint) {
        guard held == nil else { return }
        heldActor = actors.firstIndex { hypot($0.node.position.x - point.x, $0.node.position.y - point.y) < 70 }
        let node = heldActor.map { actors[$0].node } ?? objects.reversed().first { hypot($0.node.position.x - point.x, $0.node.position.y - point.y) < 60 }?.node
        guard let node = node, let body = node.physicsBody else { return }
        held = node
        guard !reduced else { return }
        let pointer = SKNode(); pointer.position = point
        pointer.physicsBody = SKPhysicsBody(circleOfRadius: 1); pointer.physicsBody?.isDynamic = false
        pointer.physicsBody?.categoryBitMask = 0; pointer.physicsBody?.collisionBitMask = 0
        scene.addChild(pointer); handle = pointer
        if let pointerBody = pointer.physicsBody {
            let joint = SKPhysicsJointSpring.joint(withBodyA: body, bodyB: pointerBody, anchorA: node.position, anchorB: point)
            joint.frequency = 6; joint.damping = 1
            scene.physicsWorld.add(joint); spring = joint
        }
    }
    func moveDrag(_ point: CGPoint) {
        let bounded = CGPoint(x: min(740, max(60, point.x)), y: min(420,max(100,point.y)))
        if reduced, let node = held {
            let delta = CGPoint(x: bounded.x - node.position.x, y: bounded.y - node.position.y)
            node.position = bounded
            if let index = heldActor {
                for limb in actors[index].limbs.values { limb.position.x += delta.x; limb.position.y += delta.y }
            }
            refresh()
        } else { handle?.position = bounded }
    }
    func endDrag() {
        if let spring = spring { scene.physicsWorld.remove(spring) }
        spring = nil; handle?.removeFromParent(); handle = nil; held = nil; heldActor = nil
    }
    func moveTrampoline(_ x: CGFloat) { trampoline.position.x = min(690, max(110, x)) }
    var trampolineX: CGFloat { trampoline.position.x }
    func accessibleRide(progress: Double, track: SlideTrack?) {
        guard let actor = actors.first else { return }
        let x = 80 + progress * 650
        let y = track.map { 470 - $0.height(at: progress) * 300 } ?? (110 + sin(progress * .pi) * 220)
        let delta = CGPoint(x: x - actor.node.position.x, y: y - actor.node.position.y)
        actor.node.position = CGPoint(x: x, y: y)
        for node in actor.limbs.values { node.position.x += delta.x; node.position.y += delta.y }
        if case .slide = mode {arrived=progress>=1}
        refresh()
    }
    func jump() {
        for actor in actors { actor.node.physicsBody?.velocity = CGVector(dx: 80, dy: 340) }
        SoundService.shared.play(.reaction)
    }
    func setActive(_ active: Bool) { scene.isPaused = !active; if !active { endDrag() } }

    func refresh() {
        for actor in actors {
            let body = actor.node
            if !reduced && held !== body {
                switch mode {
                case .slide: body.physicsBody?.applyForce(CGVector(dx: 40, dy: 0))
                case .trampoline:
                    let now = Date.timeIntervalSinceReferenceDate
                    if abs(body.position.x - trampoline.position.x) < 88 && body.position.y < 150 &&
                        body.physicsBody!.velocity.dy < 0 && now > bounceCooldown {
                        body.physicsBody?.velocity = CGVector(dx: (body.position.x - trampoline.position.x) * 3, dy: 360)
                        bounceCooldown = now + 0.5; SoundService.shared.play(.reaction)
                    }
                case .yard: break
                }
            }
            if case .slide = mode,body.position.x>680 && body.position.y<160 {arrived=true}
        }
        for node in actors.map(\.node) + actors.flatMap({ Array($0.limbs.values) }) + objects.map(\.node) {
            guard let physics = node.physicsBody else { continue }
            let speed = hypot(physics.velocity.dx, physics.velocity.dy)
            if speed > 550 { physics.velocity = CGVector(dx: physics.velocity.dx / speed * 550, dy: physics.velocity.dy / speed * 550) }
            physics.angularVelocity = min(5, max(-5, physics.angularVelocity))
        }
        friends = actors.map { actor in
            var value = actor.original
            if objects.contains(where: { $0.kind == 2 && hypot($0.node.position.x - actor.node.position.x, $0.node.position.y - actor.node.position.y) < 95 }) {
                value.accessories.insert(11)
            }
            for (attachment, limb) in actor.limbs {
                let delta = actor.node.convert(limb.position, from: scene)
                let rect = AttachmentLayout.bounds(for: attachment, friend: value)
                var pose = value.placement(for: attachment)
                pose.x = Double((150 + delta.x / Self.scale - rect.midX) / 300)
                pose.y = Double((160 - delta.y / Self.scale - rect.midY) / 320)
                pose.rotation = -Double(limb.zRotation - actor.node.zRotation) * 180 / .pi
                value.setPlacement(pose, for: attachment)
            }
            return PhysicsFriendFrame(id: value.id, friend: value, x: actor.node.position.x, y: actor.node.position.y, angle: -Double(actor.node.zRotation) * 180 / .pi)
        }
        toys = objects.map { PhysicsToyFrame(id: $0.id, kind: $0.kind, x: $0.node.position.x, y: $0.node.position.y, angle: -Double($0.node.zRotation) * 180 / .pi) }
    }
}
