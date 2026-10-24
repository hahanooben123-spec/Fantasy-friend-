import SwiftUI

/// One set of silhouettes drives the live friend, previews, hit areas and physics.
enum CreatureLimbArtwork {
    private struct Roots:Sendable {
        let leftArm:CGPoint
        let rightArm:CGPoint
        let leftLeg:CGPoint
        let rightLeg:CGPoint
    }
    private static let roots:[Roots]=BodyKind.allCases.map {kind in
        let body=CreatureShape(kind:kind).path(in:CGRect(x:0,y:0,width:300,height:320))
        let shoulderY:CGFloat=kind == .chubby ? 185 : 177
        let hipY=body.boundingRect.maxY-19
        func edges(_ y:CGFloat)->(CGFloat,CGFloat) {
            let left=(15...150).first {body.contains(CGPoint(x:CGFloat($0),y:y))} ?? 70
            let right=(150...285).reversed().first {body.contains(CGPoint(x:CGFloat($0),y:y))} ?? 230
            return (CGFloat(left),CGFloat(right))
        }
        let shoulders=edges(shoulderY),hips=edges(hipY)
        return Roots(leftArm:CGPoint(x:shoulders.0+8,y:shoulderY),
            rightArm:CGPoint(x:shoulders.1-8,y:shoulderY),
            leftLeg:CGPoint(x:hips.0+(hips.1-hips.0)*0.34,y:hipY),
            rightLeg:CGPoint(x:hips.0+(hips.1-hips.0)*0.66,y:hipY))
    }
    static func anchor(_ part:Attachment,body:BodyKind)->CGPoint {
        let r=roots[body.rawValue]
        switch part {
        case .leftArm:return r.leftArm
        case .rightArm:return r.rightArm
        case .leftLeg:return r.leftLeg
        case .rightLeg:return r.rightLeg
        default:return CGPoint(x:150,y:175)
        }
    }
    private static func palm(_ kind:Int)->Path {
        var p=Path();p.move(to:CGPoint(x:-12,y:8))
        switch kind {
        case 1: // A teddy paw, with three round lobes.
            p.addCurve(to:CGPoint(x:-3,y:-15),control1:CGPoint(x:-23,y:-2),control2:CGPoint(x:-17,y:-21))
            p.addCurve(to:CGPoint(x:11,y:-17),control1:CGPoint(x:-2,y:-29),control2:CGPoint(x:12,y:-28))
            p.addCurve(to:CGPoint(x:22,y:-4),control1:CGPoint(x:23,y:-24),control2:CGPoint(x:32,y:-10))
            p.addCurve(to:CGPoint(x:18,y:14),control1:CGPoint(x:37,y:4),control2:CGPoint(x:29,y:19))
        case 2: // A soft three-finger mitten.
            p.addCurve(to:CGPoint(x:-5,y:-8),control1:CGPoint(x:-22,y:5),control2:CGPoint(x:-20,y:-12))
            p.addCurve(to:CGPoint(x:3,y:-19),control1:CGPoint(x:-14,y:-26),control2:CGPoint(x:1,y:-31))
            p.addCurve(to:CGPoint(x:14,y:-15),control1:CGPoint(x:9,y:-32),control2:CGPoint(x:23,y:-29))
            p.addCurve(to:CGPoint(x:23,y:-2),control1:CGPoint(x:28,y:-23),control2:CGPoint(x:34,y:-8))
            p.addQuadCurve(to:CGPoint(x:18,y:15),control:CGPoint(x:33,y:20))
        case 3: // A rounded flipper.
            p.addCurve(to:CGPoint(x:25,y:-16),control1:CGPoint(x:-7,y:-10),control2:CGPoint(x:10,y:-31))
            p.addCurve(to:CGPoint(x:29,y:10),control1:CGPoint(x:44,y:-11),control2:CGPoint(x:43,y:4))
            p.addQuadCurve(to:CGPoint(x:8,y:18),control:CGPoint(x:21,y:22))
        case 5: // Three cuddly feather tips.
            p.addCurve(to:CGPoint(x:7,y:-22),control1:CGPoint(x:-22,y:-8),control2:CGPoint(x:-4,y:-27))
            p.addQuadCurve(to:CGPoint(x:17,y:-17),control:CGPoint(x:21,y:-30))
            p.addQuadCurve(to:CGPoint(x:26,y:-7),control:CGPoint(x:34,y:-21))
            p.addQuadCurve(to:CGPoint(x:18,y:13),control:CGPoint(x:40,y:12))
        case 6: // A plump leaf, without a sharp tip.
            p.addCurve(to:CGPoint(x:28,y:-14),control1:CGPoint(x:-18,y:-17),control2:CGPoint(x:21,y:-30))
            p.addCurve(to:CGPoint(x:17,y:15),control1:CGPoint(x:42,y:2),control2:CGPoint(x:30,y:22))
        case 7: // A balloon hand.
            p.addCurve(to:CGPoint(x:9,y:-22),control1:CGPoint(x:-26,y:-11),control2:CGPoint(x:-8,y:-29))
            p.addCurve(to:CGPoint(x:24,y:13),control1:CGPoint(x:39,y:-27),control2:CGPoint(x:44,y:17))
        default: // Pebble hand, also used with a knitted cuff.
            p.addCurve(to:CGPoint(x:7,y:-15),control1:CGPoint(x:-25,y:-11),control2:CGPoint(x:-7,y:-25))
            p.addCurve(to:CGPoint(x:23,y:12),control1:CGPoint(x:31,y:-22),control2:CGPoint(x:38,y:16))
        }
        p.addQuadCurve(to:CGPoint(x:-12,y:8),control:CGPoint(x:0,y:23));p.closeSubpath()
        return p
    }
    private static func arm(_ kind:Int,bend:Double=0)->Path {
        var p=Path();p.move(to:CGPoint(x:-7,y:-10))
        p.addCurve(to:CGPoint(x:25,y:9),control1:CGPoint(x:9,y:-12-CGFloat(bend)),control2:CGPoint(x:13,y:4))
        p.addLine(to:CGPoint(x:28,y:25))
        p.addQuadCurve(to:CGPoint(x:-7,y:11),control:CGPoint(x:10,y:32));p.closeSubpath()
        p.addPath(palm(kind).applying(CGAffineTransform(translationX:23,y:18)))
        return p
    }
    private static func foot(_ kind:Int)->Path {
        var p=Path();p.move(to:CGPoint(x:-9,y:-3))
        p.addQuadCurve(to:CGPoint(x:10,y:0),control:CGPoint(x:1,y:-8))
        p.addLine(to:CGPoint(x:11,y:19))
        switch kind {
        case 1: // Squashy paws.
            p.addQuadCurve(to:CGPoint(x:29,y:22),control:CGPoint(x:28,y:9))
            p.addQuadCurve(to:CGPoint(x:32,y:31),control:CGPoint(x:41,y:23))
            p.addQuadCurve(to:CGPoint(x:23,y:38),control:CGPoint(x:40,y:40))
        case 3: // Three small round toes.
            p.addQuadCurve(to:CGPoint(x:24,y:19),control:CGPoint(x:20,y:10))
            p.addQuadCurve(to:CGPoint(x:28,y:29),control:CGPoint(x:36,y:20))
            p.addQuadCurve(to:CGPoint(x:18,y:35),control:CGPoint(x:36,y:39))
            p.addQuadCurve(to:CGPoint(x:6,y:36),control:CGPoint(x:13,y:43))
        case 2: // Broad duck-like flipper.
            p.addCurve(to:CGPoint(x:38,y:30),control1:CGPoint(x:31,y:9),control2:CGPoint(x:47,y:23))
            p.addQuadCurve(to:CGPoint(x:20,y:41),control:CGPoint(x:41,y:44))
        case 5: // Rounded little rain boot.
            p.addLine(to:CGPoint(x:16,y:23))
            p.addCurve(to:CGPoint(x:30,y:35),control1:CGPoint(x:39,y:18),control2:CGPoint(x:42,y:36))
            p.addLine(to:CGPoint(x:-9,y:37))
        case 7: // Cloud slipper.
            p.addQuadCurve(to:CGPoint(x:24,y:19),control:CGPoint(x:17,y:7))
            p.addQuadCurve(to:CGPoint(x:34,y:29),control:CGPoint(x:42,y:12))
            p.addQuadCurve(to:CGPoint(x:21,y:40),control:CGPoint(x:48,y:42))
        default: // Bean feet, rounded slippers and plush socks.
            p.addCurve(to:CGPoint(x:31,y:34),control1:CGPoint(x:29,y:9),control2:CGPoint(x:46,y:29))
            p.addQuadCurve(to:CGPoint(x:7,y:40),control:CGPoint(x:22,y:46))
        }
        p.addQuadCurve(to:CGPoint(x:-13,y:31),control:CGPoint(x:-19,y:46))
        p.addQuadCurve(to:CGPoint(x:-9,y:-3),control:CGPoint(x:-16,y:15));p.closeSubpath()
        return p
    }
    private static func transform(_ part:Attachment,friend:FantasyFriend)->CGAffineTransform {
        let root=anchor(part,body:friend.body)
        let left=part == .leftArm || part == .leftLeg
        var horizontal:CGFloat=1
        if part.category == .arms {
            let shaped=(friend.bodySculpt ?? BodySculpt()).point(root)
            let x=CGFloat(150)+(shaped.x-150)*CGFloat(friend.widthFactor)
            let room=left ? x-5 : 295-x
            horizontal=min(1,max(0.3,room/CGFloat(78)))
        }
        return CGAffineTransform(a:(left ? -1 : 1)*horizontal,b:0,c:0,d:1,tx:root.x,ty:root.y)
    }
    static func bounds(_ part:Attachment,friend:FantasyFriend)->CGRect {
        let path=part.category == .arms ? arm(friend.arms) : foot(friend.legs)
        return path.applying(transform(part,friend:friend)).boundingRect.insetBy(dx:-2,dy:-2)
    }
    static func paint(_ context:GraphicsContext,part:Attachment,friend:FantasyFriend,bend:Double=0) {
        let isArm=part.category == .arms
        let kind=isArm ? friend.arms : friend.legs
        let t=transform(part,friend:friend)
        let primary=GameStyle.palette[friend.color%16],accent=GameStyle.palette[friend.accent%16]
        let base=isArm || kind<4 ? primary : accent
        let path=(isArm ? arm(kind,bend:bend) : foot(kind)).applying(t)
        ToyFinish.paint(context,path:path,color:base,edge:1.5)
        func patch(_ r:CGRect,_ color:Color) {
            ToyFinish.paint(context,path:Path(ellipseIn:r).applying(t),color:color,edge:0.5)
        }
        func seam(_ from:CGPoint,_ to:CGPoint,_ control:CGPoint,_ color:Color,_ width:CGFloat=1.5) {
            var line=Path();line.move(to:from);line.addQuadCurve(to:to,control:control)
            context.stroke(line.applying(t),with:.color(color),style:StrokeStyle(lineWidth:width,lineCap:.round))
        }
        if isArm {
            if kind == 1 || kind == 2 {
                patch(CGRect(x:23,y:18,width:14,height:11),accent)
                for i in 0..<3 {patch(CGRect(x:15+CGFloat(i)*9,y:6-CGFloat(i%2)*4,width:6,height:7),accent)}
            } else if kind == 4 {
                let cuff=Path(roundedRect:CGRect(x:-4,y:-9,width:14,height:24),cornerRadius:6)
                ToyFinish.paint(context,path:cuff.applying(t),color:accent,edge:0.8)
                seam(CGPoint(x:2,y:-5),CGPoint(x:2,y:10),CGPoint(x:4,y:2),.white.opacity(0.55))
            } else if kind == 6 {
                seam(CGPoint(x:15,y:27),CGPoint(x:41,y:7),CGPoint(x:22,y:7),accent,2)
            } else if kind == 5 {
                seam(CGPoint(x:24,y:19),CGPoint(x:36,y:3),CGPoint(x:29,y:11),accent)
                seam(CGPoint(x:26,y:23),CGPoint(x:46,y:14),CGPoint(x:37,y:14),accent)
            } else {patch(CGRect(x:29,y:6,width:9,height:5),.white.opacity(0.36))}
        } else {
            if kind == 1 || kind == 3 {for i in 0..<3 {patch(CGRect(x:12+CGFloat(i)*7,y:24,width:5,height:6),accent)}}
            if kind == 4 || kind == 5 || kind == 6 {
                let cuff=Path(roundedRect:CGRect(x:-11,y:0,width:24,height:9),cornerRadius:4)
                ToyFinish.paint(context,path:cuff.applying(t),color:primary,edge:0.6)
                seam(CGPoint(x:-8,y:34),CGPoint(x:28,y:33),CGPoint(x:9,y:39),primary,2.5)
            }
            if kind == 6 {
                for y in [CGFloat(12),CGFloat(20)] {
                    seam(CGPoint(x:-10,y:y),CGPoint(x:10,y:y),CGPoint(x:0,y:y+3),primary,4)
                }
            }
            if kind == 4 {patch(CGRect(x:4,y:25,width:18,height:8),primary.opacity(0.6))}
            if kind == 2 {seam(CGPoint(x:12,y:28),CGPoint(x:28,y:33),CGPoint(x:18,y:29),accent,2)}
            if kind == 7 {patch(CGRect(x:6,y:22,width:16,height:9),primary.opacity(0.6))}
        }
    }
}
