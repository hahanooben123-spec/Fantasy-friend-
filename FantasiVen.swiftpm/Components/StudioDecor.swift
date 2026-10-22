import SwiftUI

enum StudioStyle {
    static let colors: [Color] = [
        Color(red: 1, green: 0.72, blue: 0.04), Color(red: 1, green: 0.32, blue: 0.53),
        Color(red: 0.04, green: 0.75, blue: 0.67), Color(red: 0.65, green: 0.36, blue: 0.96),
        Color(red: 1, green: 0.49, blue: 0.12), Color(red: 0.12, green: 0.68, blue: 1),
        Color(red: 0.62, green: 0.86, blue: 0.12), Color(red: 0.94, green: 0.36, blue: 0.78),
        Color(red: 1, green: 0.78, blue: 0.02)
    ]
    static func color(_ part: Part) -> Color { colors[part.rawValue % colors.count] }
}

struct StudioBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 1, green: 0.87, blue: 0.36), Color(red: 1, green: 0.69, blue: 0.33)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Canvas { context, size in
                    let shapes: [(CGRect, Color)] = [
                        (CGRect(x: -85, y: -110, width: 330, height: 300), StudioStyle.colors[0]),
                        (CGRect(x: size.width - 155, y: 50, width: 240, height: 260), StudioStyle.colors[2]),
                        (CGRect(x: -80, y: size.height - 180, width: 290, height: 300), StudioStyle.colors[3])
                    ]
                    for (rect, color) in shapes { context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.5))) }
                    for index in 0..<26 {
                        let x = CGFloat((index * 73 + 19) % 307) / 307 * size.width
                        let y = CGFloat((index * 97 + 31) % 503) / 503 * size.height
                        var dash = Path()
                        dash.move(to: CGPoint(x: x, y: y))
                        dash.addQuadCurve(to: CGPoint(x: x + 12, y: y - 6), control: CGPoint(x: x + 3, y: y - 12))
                        context.stroke(dash, with: .color(StudioStyle.colors[index % 9].opacity(0.65)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

struct StudioCategoryTile: View {
    let part: Part
    let title: String
    let selected: Bool
    let sample: FantasyFriend
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                icon.frame(width: 49, height: 44)
                Text(title).font(.system(size: 11, weight: .heavy, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundColor(GameStyle.ink)
            .frame(maxWidth: .infinity).frame(height: 76)
            .background(CandySurface(color: selected ? StudioStyle.color(part) : GameStyle.mixed(StudioStyle.color(part), with: .white, amount: 0.44), cornerRadius: 23))
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(selected ? Color.white : .clear, lineWidth: 3))
            .shadow(color: StudioStyle.color(part).opacity(selected ? 0.35 : 0), radius: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 23))
            .rotationEffect(.degrees(selected ? -3 : 0))
        }.buttonStyle(SquishStyle()).accessibilityLabel(title).accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var icon: some View {
        switch part {
        case .body: CharacterView(friend: sample)
        case .eyes: CharacterView(friend: sample, detail: .eyes)
        case .mouth: CharacterView(friend: sample, detail: .mouth)
        case .arms: CharacterView(friend: sample, piece: .leftArm)
        case .legs: CharacterView(friend: sample, piece: .leftLeg)
        case .extras: CharacterView(friend: sample, piece: .crown)
        case .color, .accent:
            LazyVGrid(columns: [GridItem(.fixed(18)), GridItem(.fixed(18))], spacing: 3) {
                ForEach(0..<4) { index in Circle().fill(GameStyle.palette[(index * 3 + (part == .accent ? 2 : 0)) % 16]).frame(width: 18, height: 18).overlay(Circle().stroke(.white, lineWidth: 2)) }
            }
        case .paint:
            ToyGlyph(kind: .brush).rotationEffect(.degrees(-12))
        }
    }
}

struct StudioBurst: View {
    let revision: Int
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var visible = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<7) { index in
                    Text(index.isMultiple(of: 2) ? "✦" : "●")
                        .font(.system(size: CGFloat(13 + index % 3 * 4), weight: .heavy))
                        .foregroundColor(StudioStyle.colors[index % 9])
                        .position(x: geometry.size.width / 2 + CGFloat(cos(Double(index) * .pi * 2 / 7)) * min(geometry.size.width * 0.34, 150),
                                  y: geometry.size.height * 0.4 + CGFloat(sin(Double(index) * .pi * 2 / 7)) * min(geometry.size.height * 0.32, 140))
                }
            }.opacity(visible ? 1 : 0)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
        .task(id: revision) {
            guard revision > 0 else { return }
            visible = true
            do { try await Task.sleep(nanoseconds: 450_000_000) } catch { return }
            withAnimation(reducedMotion ? nil : .easeOut(duration: 0.25)) { visible = false }
        }
    }
}
