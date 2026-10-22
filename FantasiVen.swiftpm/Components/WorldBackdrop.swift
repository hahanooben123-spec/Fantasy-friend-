import SwiftUI

struct WorldBackdrop: View {
    var world: World = .forest
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                Canvas { context, size in
                    func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
                    }
                    for index in 0..<18 {
                        let x = CGFloat((index * 67 + 23) % 293) / 300 * size.width
                        let y = CGFloat((index * 97 + 31) % 499) / 520 * size.height
                        oval(x, y, index % 3 == 0 ? 5 : 3, index % 3 == 0 ? 5 : 3, .white.opacity(0.65))
                    }
                    if world == .rainbow {
                        for index in 0..<5 {
                            let inset = CGFloat(index) * 16
                            context.stroke(Path(ellipseIn: CGRect(x: -80 + inset, y: size.height * 0.13 + inset, width: size.width + 160 - inset * 2, height: size.width + 70 - inset * 2)), with: .color(GameStyle.palette[index + 1].opacity(0.3)), lineWidth: 15)
                        }
                    }
                    if world == .forest {
                        for index in 0..<6 {
                            let x = CGFloat(index) * size.width / 5 - 35
                            let y = size.height * 0.72 + CGFloat(index % 2) * 40
                            context.fill(Path(roundedRect: CGRect(x: x + 28, y: y, width: 13, height: 145), cornerRadius: 6), with: .color(Color(red: 0.55, green: 0.69, blue: 0.61).opacity(0.4)))
                            oval(x - 8, y - 56, 90, 120, Color(red: 0.57, green: 0.78, blue: 0.67).opacity(0.4))
                        }
                    }
                    if world == .clouds || world == .rainbow {
                        for index in 0..<4 {
                            let x = CGFloat(index % 2) * size.width * 0.7 - 30
                            let y = CGFloat(index) * size.height * 0.21 + 80
                            oval(x, y, 130, 34, .white.opacity(0.48)); oval(x + 26, y - 22, 64, 58, .white.opacity(0.48))
                        }
                    }
                    if world == .castle {
                        for index in 0..<3 {
                            let x = size.width * 0.55 + CGFloat(index) * 44
                            let y = size.height * 0.74 - CGFloat(index % 2) * 40
                            context.fill(Path(roundedRect: CGRect(x: x, y: y, width: 40, height: 150), cornerRadius: 8), with: .color(GameStyle.palette[8].opacity(0.35)))
                            var roof = Path(); roof.move(to: CGPoint(x: x - 8, y: y + 3)); roof.addLine(to: CGPoint(x: x + 20, y: y - 36)); roof.addLine(to: CGPoint(x: x + 48, y: y + 3)); roof.closeSubpath()
                            context.fill(roof, with: .color(GameStyle.purple.opacity(0.25)))
                        }
                    }
                    if world != .stars {
                        oval(-size.width * 0.3, size.height * 0.89, size.width * 1.6, size.height * 0.35, .white.opacity(0.27))
                    }
                    if world == .meadow {
                        for index in 0..<15 {
                            let x = CGFloat(index) * size.width / 14
                            let y = size.height * 0.9 + CGFloat(index % 3) * 14
                            for petal in 0..<5 {
                                let a = Double(petal) * .pi * 2 / 5
                                oval(x + CGFloat(cos(a)) * 6, y + CGFloat(sin(a)) * 6, 9, 9, GameStyle.palette[index % 16].opacity(0.65))
                            }
                            oval(x + 2, y + 2, 5, 5, .yellow)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
    private var colors: [Color] {
        switch world {
        case .forest: return [Color(red: 0.90, green: 0.91, blue: 0.99), Color(red: 0.84, green: 0.94, blue: 0.87)]
        case .rainbow: return [Color(red: 0.98, green: 0.88, blue: 0.91), Color(red: 0.91, green: 0.92, blue: 1)]
        case .stars: return [Color(red: 0.44, green: 0.42, blue: 0.65), Color(red: 0.79, green: 0.76, blue: 0.91)]
        case .clouds: return [Color(red: 0.77, green: 0.89, blue: 0.99), Color(red: 0.96, green: 0.93, blue: 1)]
        case .meadow: return [Color(red: 0.93, green: 0.96, blue: 0.85), Color(red: 0.77, green: 0.89, blue: 0.75)]
        case .castle: return [Color(red: 0.97, green: 0.87, blue: 0.85), Color(red: 0.88, green: 0.83, blue: 0.97)]
        }
    }
}
