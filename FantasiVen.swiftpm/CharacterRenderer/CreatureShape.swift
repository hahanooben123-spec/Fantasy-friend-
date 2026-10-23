import SwiftUI

struct CreatureShape: Shape {
    var kind: BodyKind
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch kind {
        case .round:
            p.move(to:CGPoint(x:149,y:77))
            p.addCurve(to:CGPoint(x:232,y:124),control1:CGPoint(x:181,y:68),control2:CGPoint(x:222,y:85))
            p.addCurve(to:CGPoint(x:239,y:202),control1:CGPoint(x:249,y:145),control2:CGPoint(x:251,y:178))
            p.addCurve(to:CGPoint(x:198,y:250),control1:CGPoint(x:238,y:229),control2:CGPoint(x:221,y:247))
            p.addQuadCurve(to:CGPoint(x:150,y:257),control:CGPoint(x:174,y:264))
            p.addCurve(to:CGPoint(x:67,y:218),control1:CGPoint(x:109,y:263),control2:CGPoint(x:79,y:247))
            p.addCurve(to:CGPoint(x:69,y:121),control1:CGPoint(x:48,y:193),control2:CGPoint(x:49,y:151))
            p.addCurve(to:CGPoint(x:149,y:77),control1:CGPoint(x:85,y:90),control2:CGPoint(x:119,y:74))
            p.closeSubpath()
        case .oval: p.addEllipse(in: CGRect(x: 77, y: 62, width: 146, height: 197))
        case .cushion: p.addRoundedRect(in: CGRect(x: 64, y: 87, width: 172, height: 163), cornerSize: CGSize(width: 48, height: 48))
        case .pear:
            p.move(to: CGPoint(x: 150, y: 65))
            p.addCurve(to: CGPoint(x: 231, y: 208), control1: CGPoint(x: 218, y: 61), control2: CGPoint(x: 205, y: 144))
            p.addCurve(to: CGPoint(x: 69, y: 208), control1: CGPoint(x: 264, y: 285), control2: CGPoint(x: 36, y: 285))
            p.addCurve(to: CGPoint(x: 150, y: 65), control1: CGPoint(x: 95, y: 144), control2: CGPoint(x: 82, y: 61))
            p.closeSubpath()
        case .drop:
            p.move(to:CGPoint(x:139,y:58))
            p.addCurve(to:CGPoint(x:179,y:101),control1:CGPoint(x:137,y:83),control2:CGPoint(x:158,y:85))
            p.addCurve(to:CGPoint(x:235,y:187),control1:CGPoint(x:215,y:118),control2:CGPoint(x:238,y:146))
            p.addCurve(to:CGPoint(x:199,y:253),control1:CGPoint(x:240,y:225),control2:CGPoint(x:222,y:250))
            p.addCurve(to:CGPoint(x:85,y:250),control1:CGPoint(x:165,y:267),control2:CGPoint(x:110,y:268))
            p.addCurve(to:CGPoint(x:75,y:146),control1:CGPoint(x:54,y:230),control2:CGPoint(x:56,y:181))
            p.addCurve(to:CGPoint(x:139,y:58),control1:CGPoint(x:90,y:116),control2:CGPoint(x:126,y:109))
            p.closeSubpath()
        case .cloud:
            p.move(to:CGPoint(x:83,y:245))
            p.addCurve(to:CGPoint(x:49,y:207),control1:CGPoint(x:48,y:253),control2:CGPoint(x:27,y:229))
            p.addCurve(to:CGPoint(x:58,y:151),control1:CGPoint(x:26,y:188),control2:CGPoint(x:27,y:160))
            p.addCurve(to:CGPoint(x:108,y:101),control1:CGPoint(x:40,y:119),control2:CGPoint(x:72,y:88))
            p.addCurve(to:CGPoint(x:154,y:76),control1:CGPoint(x:107,y:73),control2:CGPoint(x:132,y:58))
            p.addCurve(to:CGPoint(x:202,y:100),control1:CGPoint(x:185,y:57),control2:CGPoint(x:209,y:75))
            p.addCurve(to:CGPoint(x:247,y:151),control1:CGPoint(x:238,y:82),control2:CGPoint(x:266,y:119))
            p.addCurve(to:CGPoint(x:252,y:210),control1:CGPoint(x:278,y:157),control2:CGPoint(x:281,y:195))
            p.addCurve(to:CGPoint(x:214,y:245),control1:CGPoint(x:272,y:238),control2:CGPoint(x:241,y:261))
            p.addCurve(to:CGPoint(x:151,y:255),control1:CGPoint(x:198,y:268),control2:CGPoint(x:170,y:265))
            p.addQuadCurve(to:CGPoint(x:83,y:245),control:CGPoint(x:111,y:270))
            p.closeSubpath()
        case .bean:
            p.move(to: CGPoint(x: 176, y: 67))
            p.addCurve(to: CGPoint(x: 227, y: 231), control1: CGPoint(x: 252, y: 60), control2: CGPoint(x: 260, y: 196))
            p.addCurve(to: CGPoint(x: 64, y: 210), control1: CGPoint(x: 166, y: 288), control2: CGPoint(x: 48, y: 267))
            p.addCurve(to: CGPoint(x: 126, y: 137), control1: CGPoint(x: 74, y: 166), control2: CGPoint(x: 144, y: 187))
            p.addCurve(to: CGPoint(x: 176, y: 67), control1: CGPoint(x: 98, y: 95), control2: CGPoint(x: 130, y: 69)); p.closeSubpath()
        case .chubby:
            p.move(to: CGPoint(x: 150, y: 98))
            p.addCurve(to: CGPoint(x: 236, y: 210), control1: CGPoint(x: 227, y: 88), control2: CGPoint(x: 222, y: 166))
            p.addCurve(to: CGPoint(x: 64, y: 210), control1: CGPoint(x: 275, y: 286), control2: CGPoint(x: 25, y: 286))
            p.addCurve(to: CGPoint(x: 150, y: 98), control1: CGPoint(x: 78, y: 166), control2: CGPoint(x: 73, y: 88)); p.closeSubpath()
        }
        return p.applying(CGAffineTransform(scaleX: rect.width / 300, y: rect.height / 320).translatedBy(x: rect.minX, y: rect.minY))
    }
    // Attachment points follow the silhouette rather than the containing rectangle.
    var shoulder: CGFloat {
        switch kind { case .oval: return 82; case .pear: return 88; case .drop: return 79; case .cloud: return 49; case .bean: return 89; default: return 65 }
    }
}
