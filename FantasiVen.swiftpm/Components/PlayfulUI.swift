import SwiftUI

enum RoomKind { case studio, village, playground }
enum ToyKind { case brush, berry, feather, jump, music, moon, heart }

struct ToyGlyph: View {
    let kind: ToyKind
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 100, y: size.height / 100)
            func oval(_ rect:CGRect,_ color:Color) {ToyFinish.paint(context,path:Path(ellipseIn:rect),color:color,edge:1)}
            func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat) {
                var path = Path(); if let first = points.first { path.move(to: first) }
                for point in points.dropFirst() { path.addLine(to: point) }
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            switch kind {
            case .brush:
                line([CGPoint(x: 41, y: 58), CGPoint(x: 77, y: 20)], Color(red: 1, green: 0.68, blue: 0.27), 18)
                line([CGPoint(x: 39, y: 60), CGPoint(x: 50, y: 49)], GameStyle.purple, 21)
                var tip = Path(); tip.move(to: CGPoint(x: 36, y: 55)); tip.addCurve(to: CGPoint(x: 16, y: 87), control1: CGPoint(x: 8, y: 61), control2: CGPoint(x: 38, y: 78)); tip.addCurve(to: CGPoint(x: 49, y: 67), control1: CGPoint(x: 45, y: 93), control2: CGPoint(x: 63, y: 77)); tip.closeSubpath()
                ToyFinish.paint(context,path:tip,color:StudioStyle.colors[1],edge:1.8)
                line([CGPoint(x: 61, y: 33), CGPoint(x: 74, y: 20)], .white.opacity(0.6), 4)
            case .berry:
                var berry = Path(); berry.move(to: CGPoint(x: 50, y: 86)); berry.addCurve(to: CGPoint(x: 16, y: 41), control1: CGPoint(x: 27, y: 76), control2: CGPoint(x: 13, y: 56)); berry.addCurve(to: CGPoint(x: 84, y: 41), control1: CGPoint(x: 11, y: 12), control2: CGPoint(x: 88, y: 12)); berry.addCurve(to: CGPoint(x: 50, y: 86), control1: CGPoint(x: 87, y: 56), control2: CGPoint(x: 73, y: 76))
                context.fill(berry, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.54, blue: 0.61), Color(red: 0.89, green: 0.26, blue: 0.44)]), startPoint: CGPoint(x: 25, y: 25), endPoint: CGPoint(x: 70, y: 84)))
                for x in [30, 48, 66] { oval(CGRect(x: x, y: 39, width: 4, height: 7), Color.yellow.opacity(0.85)) }
                for x in [39, 57] { oval(CGRect(x: x, y: 57, width: 4, height: 7), Color.yellow.opacity(0.85)) }
                for x in [25, 44, 60] { oval(CGRect(x: x, y: 17, width: 21, height: 15), StudioStyle.colors[6]) }
            case .feather:
                var feather = Path(); feather.move(to: CGPoint(x: 24, y: 77)); feather.addCurve(to: CGPoint(x: 77, y: 14), control1: CGPoint(x: 6, y: 29), control2: CGPoint(x: 49, y: 9)); feather.addCurve(to: CGPoint(x: 24, y: 77), control1: CGPoint(x: 94, y: 57), control2: CGPoint(x: 66, y: 79))
                context.fill(feather, with: .color(StudioStyle.colors[3]))
                line([CGPoint(x: 17, y: 87), CGPoint(x: 65, y: 28)], .white, 5)
                line([CGPoint(x: 39, y: 60), CGPoint(x: 63, y: 60)], .white.opacity(0.6), 3)
            case .jump:
                oval(CGRect(x: 12, y: 62, width: 76, height: 23), .white)
                oval(CGRect(x: 24, y: 49, width: 35, height: 32), .white)
                oval(CGRect(x: 50, y: 55, width: 26, height: 26), .white)
                line([CGPoint(x: 50, y: 52), CGPoint(x: 50, y: 16)], GameStyle.purple, 8)
                line([CGPoint(x: 34, y: 31), CGPoint(x: 50, y: 15), CGPoint(x: 66, y: 31)], GameStyle.purple, 8)
            case .music:
                line([CGPoint(x: 38, y: 69), CGPoint(x: 38, y: 28), CGPoint(x: 76, y: 17), CGPoint(x: 76, y: 60)], GameStyle.purple, 8)
                oval(CGRect(x: 17, y: 62, width: 26, height: 20), StudioStyle.colors[1])
                oval(CGRect(x: 55, y: 53, width: 26, height: 20), StudioStyle.colors[1])
                line([CGPoint(x: 39, y: 38), CGPoint(x: 74, y: 28)], GameStyle.purple, 6)
            case .moon:
                var crescent = Path(); crescent.addEllipse(in: CGRect(x: 15, y: 15, width: 70, height: 70)); crescent.addEllipse(in: CGRect(x: 39, y: 3, width: 65, height: 65))
                var moonContext = context
                moonContext.clip(to: Path(ellipseIn: CGRect(x: 15, y: 15, width: 70, height: 70)))
                moonContext.fill(crescent, with: .color(Color(red: 1, green: 0.80, blue: 0.29)), style: FillStyle(eoFill: true))
                line([CGPoint(x: 28, y: 52), CGPoint(x: 34, y: 55), CGPoint(x: 41, y: 52)], GameStyle.ink, 3)
            case .heart:
                var heart = Path(); heart.move(to: CGPoint(x: 50, y: 84)); heart.addCurve(to: CGPoint(x: 14, y: 35), control1: CGPoint(x: 25, y: 67), control2: CGPoint(x: 7, y: 51)); heart.addCurve(to: CGPoint(x: 50, y: 29), control1: CGPoint(x: 15, y: 7), control2: CGPoint(x: 41, y: 7)); heart.addCurve(to: CGPoint(x: 86, y: 35), control1: CGPoint(x: 59, y: 7), control2: CGPoint(x: 85, y: 7)); heart.addCurve(to: CGPoint(x: 50, y: 84), control1: CGPoint(x: 93, y: 51), control2: CGPoint(x: 75, y: 67))
                ToyFinish.paint(context,path:heart,color:StudioStyle.colors[1],edge:1.8)
                line([CGPoint(x: 24, y: 34), CGPoint(x: 29, y: 27)], .white.opacity(0.65), 5)
            }
        }.aspectRatio(1, contentMode: .fit).accessibilityHidden(true)
    }
}

struct DestinationArt: View {
    let kind: RoomKind
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 240, y: size.height / 170)
            func oval(_ rect: CGRect, _ color: Color) { context.fill(Path(ellipseIn: rect), with: .color(color)) }
            func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: Color) { context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color)) }
            func polygon(_ points: [CGPoint], _ color: Color) {
                var p = Path(); if let first = points.first { p.move(to: first) }; for point in points.dropFirst() { p.addLine(to: point) }; p.closeSubpath(); context.fill(p, with: .color(color))
            }
            oval(CGRect(x: 12, y: 142, width: 220, height: 19), GameStyle.ink.opacity(0.08))
            switch kind {
            case .studio:
                rounded(CGRect(x: 41, y: 70, width: 151, height: 76), 23, Color(red: 1, green: 0.78, blue: 0.24))
                polygon([CGPoint(x: 26, y: 75), CGPoint(x: 119, y: 13), CGPoint(x: 208, y: 75)], StudioStyle.colors[1])
                rounded(CGRect(x: 101, y: 97, width: 38, height: 50), 15, GameStyle.purple)
                for x in [60, 154] { rounded(CGRect(x: x, y: 92, width: 24, height: 24), 8, .white.opacity(0.9)) }
                oval(CGRect(x: 105, y: 38, width: 28, height: 28), Color(red: 1, green: 0.84, blue: 0.35))
                for index in 0..<4 { oval(CGRect(x: 112 + index % 2 * 9, y: 43 + index / 2 * 9, width: 6, height: 6), StudioStyle.colors[index]) }
            case .village:
                for index in 0..<3 {
                    let x = CGFloat(15 + index * 68), y = CGFloat(index == 1 ? 34 : 60)
                    rounded(CGRect(x: x, y: y, width: 65, height: 92), 30, StudioStyle.colors[(index * 2 + 2) % 9])
                    rounded(CGRect(x: x + 19, y: y + 47, width: 27, height: 45), 13, .white.opacity(0.8))
                    oval(CGRect(x: x + 25, y: y + 19, width: 16, height: 16), .white)
                }
            case .playground:
                for index in 0..<5 {
                    var rainbow = Path(); rainbow.addArc(center: CGPoint(x: 119, y: 133), radius: CGFloat(84 - index * 11), startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    context.stroke(rainbow, with: .color(StudioStyle.colors[index]), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                }
                oval(CGRect(x: 21, y: 120, width: 60, height: 29), .white)
                oval(CGRect(x: 164, y: 120, width: 60, height: 29), .white)
                oval(CGRect(x: 103, y: 105, width: 38, height: 38), StudioStyle.colors[1])
                oval(CGRect(x: 113, y: 112, width: 12, height: 9), .white.opacity(0.6))
            }
        }.aspectRatio(240.0 / 170, contentMode: .fit).accessibilityHidden(true)
    }
}

struct DestinationCard: View {
    let kind: RoomKind
    let title: String
    let subtitle: String
    var compact = false
    private var tint: Color {
        switch kind { case .studio: return StudioStyle.colors[0]; case .village: return StudioStyle.colors[1]; case .playground: return StudioStyle.colors[2] }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DestinationArt(kind: kind).frame(height: compact ? 91 : 134).frame(maxWidth: .infinity)
            HStack(alignment: .center, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: compact ? 17 : 22, weight: .heavy, design: .rounded)).lineLimit(2).minimumScaleFactor(0.75)
                    if !compact { Text(subtitle).font(.system(.caption, design: .rounded)).lineLimit(2) }
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right").font(.system(size: 17, weight: .heavy)).frame(width: 35, height: 35).background(Circle().fill(.white.opacity(0.65)))
            }.padding(.horizontal, 17).padding(.bottom, 17)
        }
        .foregroundColor(GameStyle.ink).frame(maxWidth: .infinity, alignment: .leading)
        .background(CandySurface(color: tint, cornerRadius: 32))
        .contentShape(RoundedRectangle(cornerRadius: 32))
    }
}

struct AdventureHeading: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    let title: String
    let subtitle: String
    @State private var leaving = false
    var body: some View {
        HStack(spacing: 12) {
            RoundButton(icon: "chevron.left", label: store.t("back")) { leaving = true }.disabled(leaving)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 27, weight: .heavy, design: .rounded)).lineLimit(2).minimumScaleFactor(0.75)
                Text(subtitle).font(.system(.caption, design: .rounded)).lineLimit(2)
            }
            Spacer(minLength: 0)
        }.foregroundColor(GameStyle.ink).padding(.horizontal, 12).padding(.vertical, 9)
            .background(CandySurface(color:Color(red:1,green:0.96,blue:0.83),cornerRadius:28))
            .padding(.horizontal, 12).padding(.top, 8)
            .overlay(alignment: .trailing) {
                if leaving {
                    HStack(spacing: 2) {
                        Text(store.t("bye")).font(.system(.caption, design: .rounded).weight(.bold))
                        CharacterView(friend: store.friends.first ?? FantasyFriend(), happy: true).frame(width: 60, height: 65).rotationEffect(.degrees(-12))
                    }.padding(8).background(Capsule().fill(.white)).padding(.trailing, 10).allowsHitTesting(false)
                }
            }
            .task(id: leaving) {
                guard leaving else { return }
                do { try await Task.sleep(nanoseconds: 320_000_000) } catch { return }
                presentation.wrappedValue.dismiss()
            }
    }
}

struct FriendHomeCard: View {
    let friend: FantasyFriend
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 68).fill(GameStyle.mixed(GameStyle.palette[friend.color], with: .white, amount: 0.64))
                Ellipse().fill(GameStyle.palette[friend.accent].opacity(0.4)).frame(height: 23).offset(y: 70)
                CharacterView(friend: friend).padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 12)
            }.frame(height: 181)
            Text(friend.name).font(.system(.headline, design: .rounded).weight(.heavy))
                .lineLimit(2).multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 45)
                .background(Capsule().fill(Color.white.opacity(0.94))).padding(.horizontal, 10).padding(.top, -10)
        }.padding(8).padding(.bottom, 6)
        .background(CandySurface(color:Color(red:1,green:0.97,blue:0.88),cornerRadius:38))
        .overlay(RoundedRectangle(cornerRadius: 38).stroke(.white.opacity(0.9), lineWidth: 3))
    }
}

struct BrandTitle: View {
    var size: CGFloat = 44
    var body: some View {
        HStack(spacing: -1) {
            ForEach(Array("FantasiVen".enumerated()), id: \.offset) { index, letter in
                Text(String(letter)).font(.system(size: size, weight: .heavy, design: .rounded))
                    .foregroundColor([GameStyle.purple, Color(red: 0.86, green: 0.10, blue: 0.35), Color(red: 0.02, green: 0.43, blue: 0.32)][index % 3])
                    .shadow(color: .white, radius: 0, x: -2, y: -2)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)
                    .shadow(color: GameStyle.ink.opacity(0.6), radius: 0, y: 3)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -5 : 4)).offset(y: index.isMultiple(of: 3) ? -3 : 1)
            }
        }.shadow(color: .white.opacity(0.9), radius: 0, y: 3).accessibilityElement(children: .ignore).accessibilityLabel("FantasiVen")
    }
}
