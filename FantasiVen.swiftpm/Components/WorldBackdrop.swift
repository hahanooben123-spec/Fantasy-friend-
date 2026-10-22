import SwiftUI

struct WorldBackdrop: View {
    var world: World = .forest
    var immersive = true
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var drift = false

    var body: some View {
        Group {
            if immersive { artwork.ignoresSafeArea() }
            else { artwork }
        }
        .accessibilityHidden(true)
        .onAppear { if immersive { SoundService.shared.setWorld(world) } }
        .onChange(of: world) { value in if immersive { SoundService.shared.setWorld(value) } }
        .task(id: "\(scenePhase)-\(reducedMotion)-\(animated)") {
            drift = false
            guard animated && !reducedMotion && scenePhase == .active else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private var artwork: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                Canvas { context, size in
                    func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
                    }
                    func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: Color) {
                        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
                    }
                    if world == .stars {
                        var moon = Path(); moon.addEllipse(in: CGRect(x: size.width * 0.12, y: size.height * 0.09, width: 74, height: 74)); moon.addEllipse(in: CGRect(x: size.width * 0.12 + 29, y: size.height * 0.09 - 10, width: 67, height: 67))
                        var moonContext = context
                        moonContext.clip(to: Path(ellipseIn: CGRect(x: size.width * 0.12, y: size.height * 0.09, width: 74, height: 74)))
                        moonContext.fill(moon, with: .color(Color(red: 1, green: 0.91, blue: 0.59)), style: FillStyle(eoFill: true))
                    }
                    for index in 0..<25 {
                        let x = CGFloat((index * 67 + 23) % 293) / 300 * size.width
                        let y = CGFloat((index * 97 + 31) % 499) / 650 * size.height
                        oval(x, y, index % 3 == 0 ? 5 : 3, index % 3 == 0 ? 5 : 3, .white.opacity(0.7))
                    }
                    if world == .rainbow || world == .clouds {
                        for index in 0..<5 {
                            var arc = Path(); arc.addArc(center: CGPoint(x: size.width * 0.72, y: size.height * 0.46), radius: max(4, size.width * 0.5 - CGFloat(index) * 12), startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
                            context.stroke(arc, with: .color(StudioStyle.colors[index].opacity(world == .clouds ? 0.48 : 0.85)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        }
                    }
                    if world != .stars {
                        oval(-size.width * 0.3, size.height * 0.78, size.width * 1.15, size.height * 0.5, Color(red: 0.25, green: 0.69, blue: 0.36).opacity(0.85))
                        oval(size.width * 0.25, size.height * 0.84, size.width * 1.1, size.height * 0.4, Color(red: 0.53, green: 0.82, blue: 0.18).opacity(0.9))
                    }
                    if world == .forest {
                        for index in 0..<5 {
                            let x = CGFloat(index) * size.width / 4 - 39
                            let y = size.height * 0.73 + CGFloat(index % 2) * 25
                            rounded(CGRect(x: x + 35, y: y, width: 12, height: 130), 6, Color(red: 0.55, green: 0.33, blue: 0.19))
                            let canopy = index.isMultiple(of: 2) ? Color(red: 0.12, green: 0.65, blue: 0.38) : Color(red: 0.58, green: 0.40, blue: 0.87)
                            oval(x, y - 62, 87, 114, canopy)
                            oval(x + 17, y - 45, 21, 43, .white.opacity(0.18))
                        }
                        for x in [size.width * 0.08, size.width * 0.88] {
                            rounded(CGRect(x: x, y: size.height * 0.92, width: 13, height: 25), 5, Color(red: 1, green: 0.94, blue: 0.79))
                            oval(x - 13, size.height * 0.92 - 15, 40, 23, StudioStyle.colors[1].opacity(0.8))
                            oval(x - 5, size.height * 0.92 - 10, 5, 4, .white)
                            oval(x + 10, size.height * 0.92 - 9, 6, 5, .white)
                        }
                    }
                    if world == .castle {
                        for index in 0..<3 {
                            let x = size.width * 0.55 + CGFloat(index) * 44
                            let y = size.height * 0.74 - CGFloat(index % 2) * 42
                            rounded(CGRect(x: x, y: y, width: 40, height: 150), 9, GameStyle.palette[8])
                            var roof = Path(); roof.move(to: CGPoint(x: x - 8, y: y + 3)); roof.addLine(to: CGPoint(x: x + 20, y: y - 36)); roof.addLine(to: CGPoint(x: x + 48, y: y + 3)); roof.closeSubpath()
                            context.fill(roof, with: .color(GameStyle.purple))
                            rounded(CGRect(x: x + 13, y: y + 17, width: 13, height: 24), 6, .white.opacity(0.8))
                        }
                    }
                    if world == .meadow || world == .forest {
                        for index in 0..<12 {
                            let x = CGFloat(index) * size.width / 11
                            let y = size.height * 0.94 + CGFloat(index % 3) * 13
                            for petal in 0..<5 {
                                let angle = Double(petal) * .pi * 2 / 5
                                oval(x + CGFloat(cos(angle)) * 7, y + CGFloat(sin(angle)) * 7, 10, 10, StudioStyle.colors[index % 9].opacity(0.8))
                            }
                            oval(x + 2, y + 2, 6, 6, Color(red: 1, green: 0.9, blue: 0.43))
                        }
                    }
                }
                cloudRibbon.frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: drift ? 8 : -8, y: drift ? -3 : 3)
            }
        }
    }

    private var cloudRibbon: some View {
        Canvas { context, size in
            guard world != .stars else { return }
            for index in 0..<3 {
                let x = CGFloat(index) * size.width * 0.43 - 25
                let y = size.height * (index == 1 ? 0.07 : 0.16)
                for rect in [CGRect(x: x, y: y, width: 99, height: 25), CGRect(x: x + 18, y: y - 19, width: 48, height: 40), CGRect(x: x + 51, y: y - 8, width: 33, height: 29)] {
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.83)))
                }
            }
        }
    }

    private var colors: [Color] {
        switch world {
        case .forest: return [Color(red: 0.27, green: 0.76, blue: 1), Color(red: 0.85, green: 0.97, blue: 0.57)]
        case .rainbow: return [Color(red: 1, green: 0.53, blue: 0.74), Color(red: 0.78, green: 0.70, blue: 1)]
        case .stars: return [Color(red: 0.13, green: 0.12, blue: 0.4), Color(red: 0.49, green: 0.27, blue: 0.73)]
        case .clouds: return [Color(red: 0.18, green: 0.69, blue: 1), Color(red: 0.77, green: 0.90, blue: 1)]
        case .meadow: return [Color(red: 0.59, green: 0.87, blue: 1), Color(red: 0.66, green: 0.88, blue: 0.28)]
        case .castle: return [Color(red: 1, green: 0.72, blue: 0.37), Color(red: 0.91, green: 0.60, blue: 0.89)]
        }
    }
}
