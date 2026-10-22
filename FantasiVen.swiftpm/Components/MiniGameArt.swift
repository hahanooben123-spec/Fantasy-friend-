import SwiftUI

/// Original small toy illustrations shared by the hub and playfields.
struct MiniGameArt: View {
    let kind: MiniGameKind
    var body: some View {
        ZStack {
            switch kind {
            case .apples:
                Circle().fill(Color(red: 1, green: 0.89, blue: 0.58)).padding(4)
                AppleToy().padding(19).rotationEffect(.degrees(-12))
            case .bubbles:
                ForEach(0..<3) { index in
                    BubbleToy(color: [Color.pink, .cyan, .purple][index])
                        .frame(width: index == 1 ? 61 : 43, height: index == 1 ? 61 : 43)
                        .offset(x: [CGFloat(-23), 18, -6][index], y: [CGFloat(-16), 0, 26][index])
                }
            case .hide:
                BushToy().padding(.top, 32)
                HStack(spacing: 10) {
                    Ellipse().fill(.white).frame(width: 23, height: 29).overlay(Circle().fill(GameStyle.ink).frame(width: 10, height: 10))
                    Ellipse().fill(.white).frame(width: 23, height: 29).overlay(Circle().fill(GameStyle.ink).frame(width: 10, height: 10))
                }.offset(y: -5)
            }
        }.frame(width: 105, height: 105).accessibilityHidden(true)
    }
}

struct AppleToy: View {
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 100, sy = size.height / 100
            context.scaleBy(x: sx, y: sy)
            var body = Path()
            body.move(to: CGPoint(x: 50, y: 27))
            body.addCurve(to: CGPoint(x: 12, y: 53), control1: CGPoint(x: 21, y: 12), control2: CGPoint(x: 7, y: 32))
            body.addCurve(to: CGPoint(x: 50, y: 91), control1: CGPoint(x: 16, y: 85), control2: CGPoint(x: 32, y: 98))
            body.addCurve(to: CGPoint(x: 88, y: 53), control1: CGPoint(x: 70, y: 100), control2: CGPoint(x: 86, y: 81))
            body.addCurve(to: CGPoint(x: 50, y: 27), control1: CGPoint(x: 97, y: 24), control2: CGPoint(x: 72, y: 12))
            context.fill(body, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.43, blue: 0.47), Color(red: 0.88, green: 0.19, blue: 0.32)]), startPoint: CGPoint(x: 25, y: 25), endPoint: CGPoint(x: 75, y: 90)))
            var stem = Path(); stem.move(to: CGPoint(x: 49, y: 29)); stem.addQuadCurve(to: CGPoint(x: 56, y: 7), control: CGPoint(x: 46, y: 15))
            context.stroke(stem, with: .color(Color(red: 0.45, green: 0.28, blue: 0.22)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: 57, y: 9, width: 25, height: 12)), with: .color(Color(red: 0.36, green: 0.75, blue: 0.08)))
            context.stroke(body, with: .color(GameStyle.ink.opacity(0.85)), lineWidth: 3)
            context.fill(Path(ellipseIn: CGRect(x: 24, y: 34, width: 11, height: 22)), with: .color(.white.opacity(0.55)))
        }
    }
}

struct BubbleToy: View {
    var color: Color
    var body: some View {
        Circle().fill(RadialGradient(colors: [.white.opacity(0.45), color.opacity(0.22), color.opacity(0.7)], center: .init(x: 0.35, y: 0.28), startRadius: 0, endRadius: 65))
            .overlay(Circle().stroke(.white.opacity(0.95), lineWidth: 3))
            .overlay(Circle().trim(from: 0.55, to: 0.78).stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 5, lineCap: .round)).padding(10))
            .shadow(color: color.opacity(0.23), radius: 8, y: 5)
    }
}

struct BushToy: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(red: 0.08, green: 0.48, blue: 0.22)).frame(height: 57).offset(y: 17)
            HStack(spacing: -13) {
                Circle().fill(Color(red: 0.46, green: 0.79, blue: 0.08)).frame(width: 60, height: 60)
                Circle().fill(Color(red: 0.22, green: 0.68, blue: 0.11)).frame(width: 76, height: 76).offset(y: -13)
                Circle().fill(Color(red: 0.36, green: 0.78, blue: 0.12)).frame(width: 60, height: 60)
            }
            ForEach(0..<3) { i in
                Circle().fill(Color(red: 1, green: 0.74, blue: 0.75)).frame(width: 9, height: 9)
                    .offset(x: CGFloat(i - 1) * 36, y: i == 1 ? 13 : -1)
            }
        }.frame(width: 170, height: 110)
    }
}

struct BasketToy: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).stroke(Color(red: 0.69, green: 0.39, blue: 0.23), lineWidth: 7).frame(width: 68, height: 52).offset(y: -19)
            RoundedRectangle(cornerRadius: 17).fill(Color(red: 0.91, green: 0.64, blue: 0.32)).frame(width: 100, height: 52)
            HStack(spacing: 14) {
                ForEach(0..<5) { _ in Capsule().fill(Color(red: 0.71, green: 0.43, blue: 0.25).opacity(0.4)).frame(width: 4, height: 38) }
            }
            Capsule().fill(Color(red: 1, green: 0.79, blue: 0.44)).frame(width: 108, height: 10).offset(y: -23)
        }.frame(width: 112, height: 82)
    }
}
