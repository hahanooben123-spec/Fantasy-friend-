import SwiftUI

struct OrchestraGameView: View {
    @EnvironmentObject private var store: FriendStore
    let friend: FantasyFriend
    @State private var pattern = OrchestraPattern()
    @State private var playing = false
    @State private var beat = -1
    @State private var saved = false
    @State private var signals = [0, 0, 0]
    private func performer(_ row: Int) -> FantasyFriend {
        let others = store.friends.filter { $0.id != friend.id }
        return row == 0 ? friend : (others.indices.contains(row - 1) ? others[row - 1] : friend)
    }
    var body: some View {
        AdventureGameShell(kind: .orchestra) { active in
            VStack(spacing: 22) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { row in
                        VStack(spacing: 5) {
                            LivingFriend(friend: performer(row), action: .dance, signal: signals[row])
                                .frame(height: 130)
                            Button {
                                SoundService.shared.instrument(row, beat: max(0, beat)); signals[row] += 1
                            } label: {
                                VStack {
                                    Text(["🥁", "🎹", "🎤"][row]).font(.system(size: 35))
                                    Text(store.t("instrument_\(row)")).font(.system(.caption, design: .rounded).weight(.heavy))
                                }.frame(maxWidth: .infinity, minHeight: 80)
                                    .background(CandySurface(color: StudioStyle.colors[row], cornerRadius: 22)).contentShape(Rectangle())
                            }.buttonStyle(SquishStyle())
                        }
                    }
                }
                Text(store.t("songHint")).font(.system(.subheadline, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center).padding(12).background(Capsule().fill(.white.opacity(0.9)))
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 8) {
                                ForEach(0..<8) { column in
                                    Button {
                                        pattern.toggle(row: row, beat: column); saved = false
                                        if pattern.rows[row][column] { SoundService.shared.instrument(row, beat: column) }
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14).fill(pattern.rows[row][column] ? StudioStyle.colors[row] : .white.opacity(0.85))
                                            if pattern.rows[row][column] { Text("♪").font(.title2).foregroundColor(GameStyle.ink) }
                                        }.frame(width: 46, height: 50)
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(playing && column == beat ? Color.yellow : .white.opacity(0.5), lineWidth: playing && column == beat ? 4 : 1))
                                    }.buttonStyle(SquishStyle())
                                        .accessibilityLabel(store.t("instrument_\(row)") + ", " + store.t("beat") + " \(column + 1)")
                                        .accessibilityAddTraits(pattern.rows[row][column] ? .isSelected : [])
                                }
                            }
                        }
                    }.padding(6)
                }
                CandyButton(title: store.t(playing ? "stopSong" : "playSong"), icon: playing ? "pause.fill" : "play.fill") { playing.toggle() }
                CandyButton(title: store.t("saveCreation"), icon: "heart.fill", color: Color(red: 0.1, green: 0.49, blue: 0.37)) {
                    guard var current = store.friends.first(where: { $0.id == friend.id }) else { return }
                    current.song = pattern; saved = store.save(current)
                }
                if saved { Text(store.t("saved")).padding(10).background(Capsule().fill(.white)) }
            }
            .task(id: "\(active)-\(playing)") {
                SoundService.shared.setPerformance(active && playing)
                guard active && playing else { return }
                while !Task.isCancelled {
                    beat = (beat + 1) % 8
                    for row in 0..<3 where pattern.rows[row][beat] {
                        SoundService.shared.instrument(row, beat: beat); signals[row] += 1
                    }
                    do { try await Task.sleep(nanoseconds: UInt64([0.55, 0.42, 0.32][store.settings.challengeLevel - 1] * 1_000_000_000)) }
                    catch { return }
                }
            }
        }.onAppear { pattern = friend.song ?? OrchestraPattern() }
            .onDisappear { SoundService.shared.setPerformance(false) }
    }
}
