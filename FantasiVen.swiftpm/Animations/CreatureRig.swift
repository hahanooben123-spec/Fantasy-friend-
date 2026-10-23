import SwiftUI

enum CreatureMotion: Equatable {
    case idle, walk, jump, laugh, eat, dance, hug, sleep
    init(_ action: PlayAction) {
        switch action {
        case .tickle: self = .laugh
        case .feed: self = .eat
        case .jump: self = .jump
        case .dance: self = .dance
        case .sleep: self = .sleep
        case .hug: self = .hug
        }
    }
    var duration: Double {
        switch self {
        case .jump: return 1.55
        case .eat: return 2.5
        case .laugh: return 2.1
        case .dance: return 3.2
        case .hug: return 2.4
        case .sleep, .idle, .walk: return .infinity
        }
    }
}

struct CreatureJoint {
    var angle = 0.0
    var offset = CGPoint.zero
    var bend = 0.0
    func blended(to b: Self, by t: Double) -> Self {
        Self(angle: angle+(b.angle-angle)*t,
             offset: CGPoint(x: offset.x+(b.offset.x-offset.x)*t, y: offset.y+(b.offset.y-offset.y)*t),
             bend: bend+(b.bend-bend)*t)
    }
}

/// A render-only pose. The child's saved positions, rotations and paint never change.
struct CreaturePose {
    var x = 0.0
    var y = 0.0
    var roll = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var headTilt = 0.0
    var headY = 0.0
    var jaw = 0.0
    var brow = 0.0
    var eyelid = 0.0
    var cheek = 0.0
    var joints: [Attachment: CreatureJoint] = [:]
    var expression = CreatureExpression.normal
    var happy = false
    var asleep = false
    var particle = 0.0

    func joint(_ part: Attachment) -> CreatureJoint { joints[part] ?? CreatureJoint() }

    func creativeJoint(_ piece: CreativePiece) -> CreatureJoint {
        switch piece.kind {
        case .arm: return joint(piece.mirrored ? .rightArm : .leftArm)
        case .leg: return joint(piece.mirrored ? .rightLeg : .leftLeg)
        case .extra: return joint(.extra(piece.variant))
        case .eye: return CreatureJoint(angle: headTilt, offset: CGPoint(x: 0, y: headY))
        }
    }
}

/// Small authored clips plus secondary spring motion, evaluated at the display time.
/// Feet alternate contact/swing; arms rotate at shoulders and legs at hips.
enum CreatureRig {
    static func key(_ time: Double, _ frames: [(Double, Double)]) -> Double {
        guard let first=frames.first, let last=frames.last else { return 0 }
        if time <= first.0 { return first.1 }
        for i in 1..<frames.count where time <= frames[i].0 {
            let a=frames[i-1], b=frames[i]
            let u=max(0,min(1,(time-a.0)/max(0.001,b.0-a.0)))
            let eased=u*u*(3-2*u)
            return a.1+(b.1-a.1)*eased
        }
        return last.1
    }

    static func sample(_ motion: CreatureMotion, time: Double, clock: Double,
                       energy: Double = 1, reduced: Bool = false) -> CreaturePose {
        var p=CreaturePose()
        guard !reduced else {
            p.asleep=motion == .sleep
            p.happy=motion == .hug || motion == .laugh
            p.expression=motion == .eat ? .chew : motion == .jump ? .wonder : .normal
            return p
        }
        let t=max(0,time), e=min(1,max(-1,energy))
        let breathing=sin(clock*2.2)
        p.scaleY=1+breathing*0.009
        p.scaleX=1-breathing*0.004
        p.headY=sin(clock*1.1)*0.7
        var armL=sin(clock*1.3)*2, armR = -sin(clock*1.3+0.4)*2
        var legL=0.0, legR=0.0
        var liftL=0.0, liftR=0.0
        var bendL=0.0, bendR=0.0
        var secondary=sin(clock*1.7)*2
        switch motion {
        case .idle: break
        case .walk:
            let phase=t*8.5
            let stride=sin(phase)*e
            legL=stride*24; legR = -stride*24
            liftL = -max(0,cos(phase))*11*abs(e)
            liftR = -max(0,-cos(phase))*11*abs(e)
            bendL=max(0,cos(phase))*12*abs(e)
            bendR=max(0,-cos(phase))*12*abs(e)
            armL = -stride*25; armR=stride*25
            p.y = -abs(sin(phase))*3*abs(e)
            p.roll=stride*2.5; p.headTilt = -stride*2
            secondary=sin(phase-0.65)*7*e
        case .jump:
            p.y=key(t,[(0,0),(0.23,8),(0.49,-55),(0.68,-62),(1.02,0),(1.15,5),(1.55,0)])
            p.scaleX=key(t,[(0,1),(0.23,1.13),(0.45,0.94),(0.8,1),(1.06,1.17),(1.3,0.98),(1.55,1)])
            p.scaleY=key(t,[(0,1),(0.23,0.84),(0.45,1.10),(0.8,1),(1.06,0.81),(1.3,1.025),(1.55,1)])
            armL=key(t,[(0,0),(0.23,-18),(0.5,105),(0.8,85),(1.08,-23),(1.55,0)])
            armR = -armL
            legL=key(t,[(0,0),(0.23,10),(0.6,-22),(0.95,0),(1.55,0)])
            legR = -legL
            p.expression=t<0.95 ? .wonder : .normal
            p.brow=t<0.95 ? 7 : 0
            p.particle=max(0,1-abs(t-1.06)*5)
            secondary=sin((t-0.18)*15)*exp(-max(0,t-0.8)*4)*12
        case .laugh:
            let envelope=min(1,t*5)*max(0,min(1,(2.1-t)*4))
            p.roll=sin(t*19)*4*envelope
            p.y = -abs(sin(t*12))*4*envelope
            p.headTilt=sin(t*12-0.4)*5*envelope
            p.jaw=(0.35+abs(sin(t*13))*0.65)*envelope
            p.cheek=sin(t*13)*envelope
            armL=(35+sin(t*17)*13)*envelope; armR = -armL
            p.happy=true; p.particle=envelope*0.55
            secondary=sin(t*13-0.7)*11*envelope
        case .eat:
            // Reach -> open -> bite -> alternating chew -> satisfied smile.
            let reach=key(t,[(0,0),(0.35,1),(0.85,1),(1.25,0),(2.5,0)])
            armL = -reach*115; armR=reach*105
            p.headY=key(t,[(0,0),(0.6,4),(1,0),(2.5,0)])
            p.headTilt=key(t,[(0,0),(0.5,-4),(1.1,1),(2.5,0)])
            p.jaw=key(t,[(0,0),(0.4,0.85),(0.78,1),(0.98,0.1),(2.5,0)])
            let chew=t>0.95 && t<2.05 ? sin((t-0.95)*19) : 0
            p.cheek=chew; p.scaleX += chew*0.01
            p.expression=t>0.95 && t<2.05 ? .chew : .normal
            p.happy=t>2.05; p.brow=t<0.85 ? 3 : 0
        case .dance:
            let envelope=min(1,t*4)*min(1,max(0,(3.2-t)*3))
            let beat=t*9
            p.x=sin(beat*0.5)*9*envelope
            p.y = -abs(sin(beat))*8*envelope
            p.roll=sin(beat)*9*envelope
            p.headTilt = -sin(beat-0.3)*8*envelope
            armL=(55+sin(beat)*40)*envelope
            armR=(-55+cos(beat)*40)*envelope
            legL=sin(beat)*20*envelope; legR = -legL
            liftL = -max(0,cos(beat))*8*envelope
            liftR = -max(0,-cos(beat))*8*envelope
            p.happy=true; secondary=sin(beat-0.8)*15*envelope
        case .hug:
            let embrace=key(t,[(0,0),(0.35,1),(1.5,1),(2.4,0)])
            armL = -embrace*72; armR=embrace*72
            p.scaleX=1-embrace*0.045; p.scaleY=1+embrace*0.025
            p.headTilt=embrace*7; p.headY=embrace*3
            p.happy=true; p.particle=embrace
            secondary=sin(t*7)*5*embrace
        case .sleep:
            let settle=min(1,t/0.8)
            p.roll=settle*7; p.headTilt=settle*5
            p.scaleX=1+breathing*0.015; p.scaleY=1-breathing*0.022
            p.eyelid=1; p.asleep=true
            armL = -8*settle; armR=8*settle
            secondary=sin(clock*1.4)
        }
        if motion == .walk {
            // Cancel the torso bob/hip arc on the planted foot; lift only the swinging foot.
            liftL += 33*(1-cos(legL*Double.pi/180))-p.y
            liftR += 33*(1-cos(legR*Double.pi/180))-p.y
        }
        p.joints[.leftArm]=CreatureJoint(angle:armL,bend:motion == .eat ? 10 : 0)
        p.joints[.rightArm]=CreatureJoint(angle:armR,bend:motion == .hug ? -8 : 0)
        p.joints[.leftLeg]=CreatureJoint(angle:legL,offset:CGPoint(x:0,y:liftL),bend:bendL)
        p.joints[.rightLeg]=CreatureJoint(angle:legR,offset:CGPoint(x:0,y:liftR),bend:bendR)
        for (part, weight) in [(Attachment.ears,1.0),(.antennae,1.4),(.tail,1.8),
                               (.wings,0.8),(.hat,0.35),(.crown,0.3),(.horns,0.4),(.scarf,0.7)] {
            p.joints[part]=CreatureJoint(angle:secondary*weight)
        }
        return p
    }

    static func pivot(_ part: Attachment, friend: FantasyFriend) -> CGPoint {
        let rect=AttachmentLayout.bounds(for:part,friend:friend)
        switch part {
        case .leftArm: return CGPoint(x:CreatureShape(kind:friend.body).shoulder+6,y:179)
        case .rightArm: return CGPoint(x:294-CreatureShape(kind:friend.body).shoulder,y:179)
        case .leftLeg: return CGPoint(x:110,y:237)
        case .rightLeg: return CGPoint(x:180,y:237)
        case .ears,.antennae,.horns,.hat,.crown: return CGPoint(x:150,y:rect.maxY)
        case .tail: return CGPoint(x:211,y:220)
        case .wings: return CGPoint(x:150,y:172)
        default: return CGPoint(x:rect.midX,y:rect.midY)
        }
    }
}
