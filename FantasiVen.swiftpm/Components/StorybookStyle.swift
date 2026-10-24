import SwiftUI

/// The pumpkin workshop's shared materials. Character paint indices stay unchanged.
enum StorybookStyle {
    static let cream = Color(red: 1, green: 0.97, blue: 0.88)
    static let honey = Color(red: 1, green: 0.74, blue: 0.12)
    static let timber = Color(red: 0.46, green: 0.25, blue: 0.22)
    static let teal = Color(red: 0.04, green: 0.49, blue: 0.56)
    static let plum = Color(red: 0.19, green: 0.12, blue: 0.26)
}

/// Cream enamel, an amber bevel and a warm contact shadow, like the pumpkin tools.
struct StorybookPanel: View {
    var cornerRadius: CGFloat = 28
    var body:some View {
        RoundedRectangle(cornerRadius:cornerRadius,style:.continuous)
            .fill(Color.white.opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius:cornerRadius,style:.continuous)
                .strokeBorder(StorybookStyle.teal.opacity(0.16),lineWidth:1.5))
            .shadow(color:StorybookStyle.plum.opacity(0.10),radius:6,y:4)
            .allowsHitTesting(false)
    }
}

/// A shared toy tray: pictures sit on a light surface with a soft turquoise rim.
struct StorybookShelf: View {
    var body:some View {
        RoundedRectangle(cornerRadius:28,style:.continuous)
            .fill(LinearGradient(colors:[.white,Color(red:0.89,green:0.97,blue:0.97)],
                startPoint:.top,endPoint:.bottom))
            .overlay(RoundedRectangle(cornerRadius:28,style:.continuous)
                .strokeBorder(.white.opacity(0.95),lineWidth:3))
            .overlay(RoundedRectangle(cornerRadius:28,style:.continuous)
                .strokeBorder(StorybookStyle.teal.opacity(0.16),lineWidth:1))
            .shadow(color:StorybookStyle.plum.opacity(0.12),radius:6,y:4)
            .allowsHitTesting(false)
    }
}

/// Keep the play surface large; the same tools move beside it on larger screens.
struct PlayWorkspace<Scene:View,Tools:View>:View {
    let wide:Bool
    var toolWidth:CGFloat=300
    let toolHeight:CGFloat
    let scene:Scene
    let tools:Tools
    init(wide:Bool,toolWidth:CGFloat=300,toolHeight:CGFloat,
         @ViewBuilder scene:()->Scene,@ViewBuilder tools:()->Tools) {
        self.wide=wide;self.toolWidth=toolWidth;self.toolHeight=toolHeight
        self.scene=scene();self.tools=tools()
    }
    var body:some View {
        Group {
            if wide {
                HStack(spacing:8) {
                    scene.frame(maxWidth:.infinity,maxHeight:.infinity)
                    tools.frame(width:toolWidth).frame(maxHeight:.infinity)
                }
            } else {
                VStack(spacing:8) {
                    scene.frame(maxWidth:.infinity,maxHeight:.infinity)
                    tools.frame(height:toolHeight)
                }
            }
        }.padding(.horizontal,8).padding(.bottom,8)
    }
}

enum StorybookScenery {
    /// Shared with PumpkinBackdrop so lamp shapes and light stay identical.
    static func garland(_ c: GraphicsContext, size: CGSize, darkness: Double = 0, compact: Bool = false) {
        let y = compact ? CGFloat(5) : size.height * 0.04
        let drop = compact ? min(35, size.width * 0.075) : min(62, size.width * 0.11)
        var wire = Path()
        wire.move(to: CGPoint(x: -10, y: y))
        wire.addQuadCurve(to: CGPoint(x: size.width+10, y: y),
            control: CGPoint(x: size.width/2, y: y+drop*2))
        c.stroke(wire, with: .color(StorybookStyle.plum), lineWidth: 3)
        // Wider screens get more lamps, rather than stretching the artwork.
        let count = min(17, max(7, Int(size.width/80)))
        for i in 0..<count {
            let t = CGFloat(i+1)/CGFloat(count+1)
            let x = t*size.width, cy = y+4*t*(1-t)*drop
            let color = [StorybookStyle.honey, Color(red: 1, green: 0.37, blue: 0.49),
                         Color(red: 0.4, green: 0.87, blue: 0.72)][i%3]
            let center = CGPoint(x: x, y: cy+7)
            c.fill(Path(ellipseIn: CGRect(x: x-27, y: cy-20, width: 54, height: 54)),
                with: .radialGradient(Gradient(colors: [color.opacity(0.3+darkness*0.15), .clear]),
                    center: center, startRadius: 1, endRadius: 27))
            c.fill(Path(roundedRect: CGRect(x: x-3, y: cy-3, width: 6, height: 7), cornerRadius: 2),
                with: .color(StorybookStyle.plum))
            c.fill(Path(ellipseIn: CGRect(x: x-6, y: cy+2, width: 12, height: 16)),
                with: .linearGradient(Gradient(colors: [.white, color]),
                    startPoint: CGPoint(x: x-4, y: cy), endPoint: CGPoint(x: x+6, y: cy+18)))
        }
    }

    static func lighting(_ c: GraphicsContext, size: CGSize, night: Bool) {
        let bounds = Path(CGRect(origin: .zero, size: size))
        c.fill(bounds, with: .radialGradient(Gradient(colors: [
            StorybookStyle.honey.opacity(night ? 0.15 : 0.13), .clear]),
            center: CGPoint(x: size.width*0.73, y: size.height*0.2),
            startRadius: 0, endRadius: max(size.width, size.height)*0.75))
        // Only the outer edges shade: saturated scenery and the play area remain clear.
        c.fill(bounds, with: .linearGradient(Gradient(stops: [
            .init(color: StorybookStyle.plum.opacity(0.06), location: 0),
            .init(color: .clear, location: 0.13), .init(color: .clear, location: 0.87),
            .init(color: StorybookStyle.plum.opacity(0.06), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)))
        c.fill(bounds, with: .linearGradient(Gradient(stops: [
            .init(color: .clear, location: 0.7),
            .init(color: StorybookStyle.plum.opacity(0.07), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    }

    static func leaves(_ c: GraphicsContext, size: CGSize) {
        for side in 0..<2 {
            var edge = c
            edge.translateBy(x: side == 0 ? 0 : size.width, y: size.height)
            edge.scaleBy(x: side == 0 ? 1 : -1, y: 1)
            var stem = Path()
            stem.move(to: CGPoint(x: -6, y: 8))
            stem.addQuadCurve(to: CGPoint(x: 12, y: -115), control: CGPoint(x: 46, y: -45))
            edge.stroke(stem, with: .color(StorybookStyle.teal), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            for i in 0..<4 {
                let y = -CGFloat(i)*27
                var leaf = Path()
                leaf.move(to: CGPoint(x: 15, y: y))
                leaf.addQuadCurve(to: CGPoint(x: 51, y: y-27), control: CGPoint(x: 12, y: y-35))
                leaf.addQuadCurve(to: CGPoint(x: 15, y: y), control: CGPoint(x: 55, y: y+4))
                ToyFinish.paint(edge, path: leaf, color: Color(red: 0.33, green: 0.64, blue: 0.29), edge: 1)
            }
        }
    }
}

/// Applied to scenery only, underneath game objects, gestures and controls.
struct StorybookAtmosphere: View {
    var night = false
    var lamps = false
    var foliage = false
    var body: some View {
        Canvas { c, size in
            StorybookScenery.lighting(c, size: size, night: night)
            if lamps { StorybookScenery.garland(c, size: size, darkness: night ? 1 : 0, compact: true) }
            if foliage { StorybookScenery.leaves(c, size: size) }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

extension View {
    func storybookScene(night: Bool = false, lamps: Bool = false, foliage: Bool = false) -> some View {
        overlay(StorybookAtmosphere(night: night, lamps: lamps, foliage: foliage))
    }
}

/// A little wooden display stage used in the welcome scene and friend collection.
struct StorybookPedestal: View {
    var body: some View {
        Canvas { c, s in
            let base = CGRect(x: s.width*0.07, y: s.height*0.30, width: s.width*0.86, height: s.height*0.55)
            c.fill(Path(ellipseIn: base.offsetBy(dx: 0, dy: s.height*0.12)),
                with: .color(StorybookStyle.plum.opacity(0.2)))
            var side = Path(roundedRect: base, cornerRadius: s.height*0.24)
            side.addEllipse(in: base)
            c.fill(side, with: .linearGradient(Gradient(colors: [
                Color(red: 1, green: 0.65, blue: 0.39), Color(red: 0.91, green: 0.43, blue: 0.40)]),
                startPoint: CGPoint(x: 0, y: base.minY), endPoint: CGPoint(x: 0, y: base.maxY)))
            let top = CGRect(x: base.minX, y: s.height*0.12, width: base.width, height: s.height*0.54)
            ToyFinish.paint(c, path: Path(ellipseIn: top), color: Color(red: 1, green: 0.85, blue: 0.48), edge: 1.5)
            c.stroke(Path(ellipseIn: top.insetBy(dx: 7, dy: 4)),
                with: .color(StorybookStyle.cream.opacity(0.6)), lineWidth: 1.5)
            c.fill(Path(ellipseIn: CGRect(x: s.width*0.28, y: s.height*0.23, width: s.width*0.44, height: s.height*0.22)),
                with: .radialGradient(Gradient(colors: [StorybookStyle.plum.opacity(0.2), .clear]),
                    center: CGPoint(x: s.width/2, y: s.height*0.34), startRadius: 0, endRadius: s.width*0.24))
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Original miniature cottages echo the cozy village in the pumpkin garden.
struct StorybookVillage: View {
    var body: some View {
        Canvas { c, s in
            for side in 0..<2 {
                var house = c
                let scale = min(1.3, s.width/650)
                house.translateBy(x: side == 0 ? -10 : s.width-105*scale, y: s.height*0.60)
                house.scaleBy(x: scale, y: scale)
                let wall = Path(roundedRect: CGRect(x: 0, y: 26, width: 114, height: 127), cornerRadius: 16)
                ToyFinish.paint(house, path: wall,
                    color: side == 0 ? Color(red: 1, green: 0.72, blue: 0.39) : Color(red: 0.81, green: 0.59, blue: 0.76))
                for row in 0..<6 {
                    var seam = Path()
                    seam.move(to: CGPoint(x: 3, y: 43+CGFloat(row)*18))
                    seam.addLine(to: CGPoint(x: 111, y: 43+CGFloat(row)*18))
                    house.stroke(seam, with: .color(StorybookStyle.timber.opacity(0.14)), lineWidth: 2)
                }
                var roof = Path()
                roof.move(to: CGPoint(x: -14, y: 44))
                roof.addQuadCurve(to: CGPoint(x: 53, y: -17), control: CGPoint(x: 35, y: 21))
                roof.addQuadCurve(to: CGPoint(x: 129, y: 44), control: CGPoint(x: 71, y: 23))
                roof.addQuadCurve(to: CGPoint(x: -14, y: 44), control: CGPoint(x: 54, y: 32))
                ToyFinish.paint(house, path: roof, color: Color(red: 0.37, green: 0.22, blue: 0.47))
                let window = CGRect(x: 32, y: 57, width: 47, height: 49)
                house.fill(Path(ellipseIn: window.insetBy(dx: -20, dy: -20)),
                    with: .radialGradient(Gradient(colors: [StorybookStyle.honey.opacity(0.35), .clear]),
                        center: CGPoint(x: 55, y: 80), startRadius: 0, endRadius: 50))
                ToyFinish.paint(house, path: Path(roundedRect: window, cornerRadius: 19),
                    color: StorybookStyle.honey, edge: 3)
                var cross = Path()
                cross.move(to: CGPoint(x: 55, y: 60)); cross.addLine(to: CGPoint(x: 55, y: 105))
                cross.move(to: CGPoint(x: 33, y: 81)); cross.addLine(to: CGPoint(x: 78, y: 81))
                house.stroke(cross, with: .color(StorybookStyle.timber), lineWidth: 3)
                ToyFinish.paint(house, path: Path(roundedRect: CGRect(x: 41, y: 116, width: 31, height: 37), cornerRadius: 14),
                    color: StorybookStyle.teal, edge: 2)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct StorybookWorkshopWall: View {
    var body: some View {
        LinearGradient(colors: [StorybookStyle.teal, Color(red: 0.05, green: 0.24, blue: 0.31)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .top) {
                Rectangle().fill(StorybookStyle.honey.opacity(0.4)).frame(height: 2)
            }.allowsHitTesting(false)
    }
}
