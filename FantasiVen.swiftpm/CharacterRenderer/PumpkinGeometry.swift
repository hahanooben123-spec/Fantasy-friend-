import SwiftUI

enum PumpkinGeometry {
    static func rect(_ form:PumpkinForm)->CGRect {
        switch form {
        case .round:return CGRect(x:31,y:76,width:238,height:207)
        case .tall:return CGRect(x:58,y:49,width:184,height:238)
        case .flat:return CGRect(x:18,y:113,width:264,height:163)
        case .wonky:return CGRect(x:34,y:77,width:237,height:206)
        case .bumpy:return CGRect(x:23,y:85,width:254,height:194)
        case .little:return CGRect(x:57,y:117,width:186,height:157)
        }
    }
    static func body(_ form:PumpkinForm)->Path {
        let r=rect(form),w=r.width,h=r.height
        let lean:CGFloat=form == .wonky ? 0.13 : 0
        var p=Path()
        p.move(to:CGPoint(x:r.midX+w*lean,y:r.minY+h*0.10))
        p.addCurve(to:CGPoint(x:r.minX,y:r.minY+h*0.48),
                   control1:CGPoint(x:r.minX+w*0.10,y:r.minY-h*0.07),control2:CGPoint(x:r.minX-w*0.02,y:r.minY+h*0.19))
        p.addCurve(to:CGPoint(x:r.minX+w*0.28,y:r.maxY-h*0.01),
                   control1:CGPoint(x:r.minX-w*0.02,y:r.minY+h*0.84),control2:CGPoint(x:r.minX+w*0.07,y:r.maxY+h*0.04))
        p.addQuadCurve(to:CGPoint(x:r.midX,y:r.maxY-h*0.035),control:CGPoint(x:r.minX+w*0.43,y:r.maxY+h*0.035))
        p.addQuadCurve(to:CGPoint(x:r.maxX-w*0.23,y:r.maxY-h*0.01),control:CGPoint(x:r.maxX-w*0.40,y:r.maxY+h*0.04))
        p.addCurve(to:CGPoint(x:r.maxX,y:r.minY+h*0.47),
                   control1:CGPoint(x:r.maxX-w*0.03,y:r.maxY+h*0.035),control2:CGPoint(x:r.maxX+w*0.03,y:r.minY+h*0.80))
        p.addCurve(to:CGPoint(x:r.midX+w*lean,y:r.minY+h*0.10),
                   control1:CGPoint(x:r.maxX+w*0.03,y:r.minY+h*0.15),control2:CGPoint(x:r.maxX-w*0.14,y:r.minY-h*0.05))
        p.closeSubpath();return p
    }
    static func stencil(_ kind:PumpkinCutKind,outline:[PumpkinPoint]=[])->Path {
        var p=Path()
        switch kind {
        case .triangle:p.move(to:CGPoint(x:0.5,y:0));p.addLine(to:CGPoint(x:1,y:1));p.addLine(to:CGPoint(x:0,y:1));p.closeSubpath()
        case .circle:p.addEllipse(in:CGRect(x:0,y:0,width:1,height:1))
        case .heart:
            p.move(to:CGPoint(x:0.5,y:1))
            p.addCurve(to:CGPoint(x:0.5,y:0.22),control1:CGPoint(x:-0.38,y:0.43),control2:CGPoint(x:0.12,y:-0.35))
            p.addCurve(to:CGPoint(x:0.5,y:1),control1:CGPoint(x:0.88,y:-0.35),control2:CGPoint(x:1.38,y:0.43));p.closeSubpath()
        case .star:
            for i in 0..<10 {
                let angle=Double(i)*Double.pi/5-Double.pi/2
                let radius:CGFloat=i.isMultiple(of:2) ? 0.5 : 0.23
                let point=CGPoint(x:0.5+CGFloat(cos(angle))*radius,y:0.5+CGFloat(sin(angle))*radius)
                if i == 0 {p.move(to:point)} else {p.addLine(to:point)}
            };p.closeSubpath()
        case .smile:
            p.move(to:CGPoint(x:0,y:0.10))
            p.addQuadCurve(to:CGPoint(x:1,y:0.10),control:CGPoint(x:0.5,y:0.48))
            p.addCurve(to:CGPoint(x:0,y:0.10),control1:CGPoint(x:1,y:1.2),control2:CGPoint(x:0,y:1.2));p.closeSubpath()
        case .tooth:
            p.move(to:CGPoint(x:0,y:0.12))
            for point in [CGPoint(x:0.25,y:0.12),CGPoint(x:0.25,y:0.43),CGPoint(x:0.43,y:0.43),
                          CGPoint(x:0.43,y:0.12),CGPoint(x:1,y:0.12),CGPoint(x:0.82,y:0.9),
                          CGPoint(x:0.62,y:0.9),CGPoint(x:0.62,y:0.64),CGPoint(x:0.43,y:0.64),
                          CGPoint(x:0.43,y:0.9),CGPoint(x:0.15,y:0.9)] {p.addLine(to:point)}
            p.closeSubpath()
        case .freehand:
            for (i,point) in outline.enumerated() {
                let q=CGPoint(x:point.x,y:point.y)
                if i == 0 {p.move(to:q)} else {p.addLine(to:q)}
            };p.closeSubpath()
        }
        return p
    }
    static func cut(_ cut:PumpkinCut,form:PumpkinForm)->Path {
        let r=rect(form)
        let local=stencil(cut.kind,outline:cut.outline)
            .applying(CGAffineTransform(a:r.width*cut.width,b:0,c:0,d:r.height*cut.height,tx:-r.width*cut.width/2,ty:-r.height*cut.height/2))
        let angle=CGFloat(cut.rotation*Double.pi/180)
        let rotation=CGAffineTransform(rotationAngle:angle)
        return local.applying(rotation).applying(CGAffineTransform(translationX:r.minX+r.width*cut.x,y:r.minY+r.height*cut.y))
    }
    static func hit(_ point:CGPoint,lantern:PumpkinLantern)->UUID? {
        lantern.cuts.reversed().first {
            let path=cut($0,form:lantern.form)
            return path.contains(point) || path.boundingRect.insetBy(dx:-7,dy:-7).contains(point)
        }?.id
    }
}
