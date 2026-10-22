import SwiftUI

struct CreatureShape: Shape {
    var kind: BodyKind
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch kind {
        case .round:
            p.move(to: CGPoint(x: 150, y: 78))
            p.addCurve(to: CGPoint(x: 241, y: 172), control1: CGPoint(x: 210, y: 73), control2: CGPoint(x: 249, y: 115))
            p.addCurve(to: CGPoint(x: 151, y: 258), control1: CGPoint(x: 253, y: 230), control2: CGPoint(x: 207, y: 264))
            p.addCurve(to: CGPoint(x: 59, y: 172), control1: CGPoint(x: 90, y: 266), control2: CGPoint(x: 52, y: 226))
            p.addCurve(to: CGPoint(x: 150, y: 78), control1: CGPoint(x: 48, y: 118), control2: CGPoint(x: 90, y: 78)); p.closeSubpath()
        case .oval: p.addEllipse(in: CGRect(x: 77, y: 62, width: 146, height: 197))
        case .cushion: p.addRoundedRect(in: CGRect(x: 64, y: 87, width: 172, height: 163), cornerSize: CGSize(width: 48, height: 48))
        case .pear:
            p.move(to: CGPoint(x: 150, y: 65))
            p.addCurve(to: CGPoint(x: 231, y: 208), control1: CGPoint(x: 218, y: 61), control2: CGPoint(x: 205, y: 144))
            p.addCurve(to: CGPoint(x: 69, y: 208), control1: CGPoint(x: 264, y: 285), control2: CGPoint(x: 36, y: 285))
            p.addCurve(to: CGPoint(x: 150, y: 65), control1: CGPoint(x: 95, y: 144), control2: CGPoint(x: 82, y: 61))
            p.closeSubpath()
        case .drop:
            p.move(to: CGPoint(x: 145, y: 58))
            p.addCurve(to: CGPoint(x: 235, y: 197), control1: CGPoint(x: 152, y: 106), control2: CGPoint(x: 241, y: 121))
            p.addCurve(to: CGPoint(x: 65, y: 197), control1: CGPoint(x: 233, y: 279), control2: CGPoint(x: 67, y: 279))
            p.addCurve(to: CGPoint(x: 145, y: 58), control1: CGPoint(x: 57, y: 132), control2: CGPoint(x: 127, y: 100))
            p.closeSubpath()
        case .cloud:
            p.move(to: CGPoint(x: 80, y: 243))
            p.addCurve(to: CGPoint(x: 61, y: 160), control1: CGPoint(x: 25, y: 236), control2: CGPoint(x: 32, y: 174))
            p.addCurve(to: CGPoint(x: 113, y: 99), control1: CGPoint(x: 44, y: 112), control2: CGPoint(x: 85, y: 87))
            p.addCurve(to: CGPoint(x: 190, y: 94), control1: CGPoint(x: 120, y: 51), control2: CGPoint(x: 185, y: 53))
            p.addCurve(to: CGPoint(x: 246, y: 153), control1: CGPoint(x: 235, y: 78), control2: CGPoint(x: 269, y: 117))
            p.addCurve(to: CGPoint(x: 217, y: 245), control1: CGPoint(x: 288, y: 186), control2: CGPoint(x: 267, y: 247))
            p.addQuadCurve(to: CGPoint(x: 80, y: 243), control: CGPoint(x: 150, y: 275)); p.closeSubpath()
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
