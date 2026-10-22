import SwiftUI

struct PathGameView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend: FantasyFriend
    @State private var puzzle = PathPuzzle(level: 1)
    @State private var walking = false
    @State private var progress = 0.0
    @State private var round = 0
    private func pathY(height: CGFloat) -> CGFloat {
        let p = min(0.99999, max(0, progress)) * 4
        let i = Int(p), t = p - Double(i)
        let a = puzzle.target[max(0, i - 1)], b = puzzle.target[i]
        let smooth = t * t * (3 - 2 * t)
        return (height - 230) / 2 + (0.25 + (Double(a) + Double(b - a) * smooth) * 0.25) * 230 - 28
    }
    var body: some View {
        AdventureGameShell(kind: .path) { active in
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    ZStack {
                        RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.75))
                        HStack(spacing: 0) {
                            ForEach(0..<4) { tile in
                                Button { puzzle.turn(tile); SoundService.shared.play(.click) } label: {
                                    PathTile(entry: tile == 0 ? puzzle.target[0] : puzzle.target[tile-1], exit: puzzle.tiles[tile])
                                        .frame(height: 230).contentShape(Rectangle())
                                }.buttonStyle(.plain).disabled(walking)
                                    .accessibilityLabel(store.t("pathHelp") + " \(tile + 1)")
                            }
                        }.padding(.horizontal, 18)
                        DestinationArt(kind: .village).frame(width: 85, height: 70).position(x: proxy.size.width * 0.88, y: 55)
                        CharacterView(friend: friend, happy: progress >= 1)
                            .frame(width: 65, height: 70)
                            .position(x: 18 + progress * (proxy.size.width - 36), y: pathY(height: proxy.size.height))
                    }.clipShape(RoundedRectangle(cornerRadius: 32))
                }.frame(height: 320)
                Text(store.t(progress >= 1 ? "wellDone" : "pathHelp")).font(.system(.title3, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                CandyButton(title: store.t("go"), icon: "figure.walk") { walking = true; progress = 0 }.disabled(!puzzle.complete || walking)
                CandyButton(title: store.t("nextPuzzle"), icon: "arrow.triangle.2.circlepath", color: Color(red: 0.1, green: 0.49, blue: 0.37)) {
                    round += 1; puzzle = PathPuzzle(level: store.settings.challengeLevel + round % 3)
                    progress = 0; walking = false
                }
            }.task(id: "\(active)-\(walking)") {
                guard active && walking else { return }
                while progress < 1 && !Task.isCancelled {
                    progress = min(1, progress + (reduced ? 0.05 : 0.015))
                    do { try await Task.sleep(nanoseconds: reduced ? 150_000_000 : 33_333_333) } catch { return }
                }
                SoundService.shared.play(.complete)
            }
        }.onAppear { puzzle = PathPuzzle(level: store.settings.challengeLevel) }
    }
}
struct PathTile: View {
    let entry: Int
    let exit: Int
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: (0.25 + Double(entry) * 0.25) * size.height))
            path.addCurve(to: CGPoint(x: size.width, y: (0.25 + Double(exit) * 0.25) * size.height),
                          control1: CGPoint(x: size.width * 0.45, y: (0.25 + Double(entry) * 0.25) * size.height),
                          control2: CGPoint(x: size.width * 0.55, y: (0.25 + Double(exit) * 0.25) * size.height))
            context.stroke(path, with: .color(GameStyle.ink), style: StrokeStyle(lineWidth: 24, lineCap: .round))
            context.stroke(path, with: .color(StudioStyle.colors[0]), style: StrokeStyle(lineWidth: 19, lineCap: .round))
            context.stroke(Path(CGRect(x: 1, y: 5, width: size.width - 2, height: size.height - 10)), with: .color(.white), lineWidth: 2)
        }
    }
}
