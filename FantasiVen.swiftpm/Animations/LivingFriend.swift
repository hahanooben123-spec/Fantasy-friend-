import SwiftUI

enum PlayAction: String, CaseIterable { case tickle, feed, jump, dance, sleep, hug }

struct LivingFriend: View {
    let friend: FantasyFriend
    var action: PlayAction = .jump
    var signal = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blink = false
    @State private var breathe = false
    @State private var happy = false
    @State private var sleeping = false
    @State private var lift: CGFloat = 0
    @State private var tilt: Double = 0
    @State private var squash: CGFloat = 1
    @State private var sparkle = false
    @State private var localSignal = 0
    @State private var tappedAction = PlayAction.jump
    @State private var currentAction = PlayAction.jump
    @Environment(\.locale) private var locale

    var body: some View {
        Button {
            tappedAction = [PlayAction.tickle, .jump, .hug].randomElement() ?? .jump
            localSignal += 1
        } label: {
            ZStack {
                Ellipse().fill(GameStyle.ink.opacity(0.09)).frame(width: 150, height: 17).offset(y: 128)
                CharacterView(friend: friend, blink: blink, happy: happy, asleep: sleeping)
                    .scaleEffect(x: squash, y: (breathe ? 1.018 : 1) / squash, anchor: .bottom)
                    .rotationEffect(.degrees(tilt), anchor: .bottom)
                    .offset(y: lift)
                if sparkle {
                    ForEach(0..<7) { index in
                        Image(systemName: currentAction == .hug ? "heart.fill" : "sparkle")
                            .font(.system(size: CGFloat(14 + index % 3 * 5), weight: .bold))
                            .foregroundColor(GameStyle.palette[(index + 2) % 16])
                            .offset(x: CGFloat(cos(Double(index) * .pi * 2 / 7)) * 115,
                                    y: CGFloat(sin(Double(index) * .pi * 2 / 7)) * 110 - 20)
                    }
                }
                if sleeping { Text("z Z").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(GameStyle.purple).offset(x: 90, y: -90) }
                if happy && currentAction == .feed { Text("🍓").font(.system(size: 42)).offset(y: 30) }
            }.aspectRatio(300.0 / 320, contentMode: .fit).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(friend.name.isEmpty ? "FantasiVen" : friend.name)
        .accessibilityHint(Words.text("tap", locale.identifier.hasPrefix("en") ? .en : .da))
        .onChange(of: signal) { _ in localSignal = 0 }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 3_600_000_000)
                    blink = true
                    try await Task.sleep(nanoseconds: 160_000_000)
                    blink = false
                } catch { blink = false; return }
            }
        }
        .task(id: reduceMotion) {
            breathe = false
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { breathe = true }
        }
        .task(id: "\(signal)-\(localSignal)") {
            guard signal + localSignal > 0 else { return }
            let chosen = localSignal > 0 ? tappedAction : action
            currentAction = chosen
            sleeping = chosen == .sleep
            happy = chosen != .sleep
            lift = 0; tilt = 0; squash = 1; sparkle = false
            SoundService.shared.play(chosen == .sleep ? .click : .reaction)
            withAnimation(.easeOut(duration: 0.2)) { sparkle = chosen != .sleep }
            do {
                if !reduceMotion {
                    for step in 0..<(chosen == .dance || chosen == .tickle ? 6 : 2) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                            switch chosen {
                            case .jump: lift = step == 0 ? -55 : 0
                            case .dance: tilt = step.isMultiple(of: 2) ? -13 : 13; lift = step.isMultiple(of: 2) ? -12 : 0
                            case .tickle: tilt = step.isMultiple(of: 2) ? -6 : 6
                            case .hug: squash = step == 0 ? 0.89 : 1
                            case .feed: squash = step == 0 ? 1.06 : 1
                            case .sleep: tilt = 7
                            }
                        }
                        try await Task.sleep(nanoseconds: 230_000_000)
                    }
                }
                try await Task.sleep(nanoseconds: 900_000_000)
                withAnimation(.easeOut(duration: 0.3)) { happy = false; sparkle = false; lift = 0; squash = 1; if !sleeping { tilt = 0 } }
            } catch { /* A newer reaction or navigation cancels this animation task. */ }
        }
    }
}
