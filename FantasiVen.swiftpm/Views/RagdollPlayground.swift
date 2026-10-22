import SwiftUI
import SpriteKit

@MainActor
struct RagdollPlayground: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    let friend: FantasyFriend
    let action: PlayAction
    let signal: Int
    @StateObject private var simulation = RagdollSimulation()
    @State private var attemptedDrag = false

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, min(geometry.size.width - 24, geometry.size.height * 600 / 440))
            let size = CGSize(width: width, height: width * 440 / 600)
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30).fill(Color.white.opacity(0.19))
                    SpriteView(scene: simulation.scene, options: [.allowsTransparency])
                        .allowsHitTesting(false).accessibilityHidden(true)
                    RagdollCharacterView(frame: simulation.frame)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !attemptedDrag {
                            attemptedDrag = true
                            simulation.beginDrag(at: scenePoint(value.startLocation, size: size))
                        }
                        simulation.moveDrag(to: scenePoint(value.location, size: size))
                    }
                    .onEnded { value in
                        let wasDragging = simulation.isDragging
                        simulation.endDrag()
                        attemptedDrag = false
                        if wasDragging && hypot(value.translation.width, value.translation.height) < 6 { simulation.react(.tickle) }
                    })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(friend.name)
                .accessibilityHint(store.t("ragdollHint"))
                .accessibilityAction(named: Text(store.t("jump"))) { simulation.react(.jump) }
                .accessibilityAction(named: Text(store.t("dance"))) { simulation.react(.dance) }
                RoundButton(icon: "arrow.counterclockwise", label: store.t("resetPlay")) {
                    simulation.configure(friend, reducedMotion: reducedMotion)
                    simulation.setActive(scenePhase == .active)
                    attemptedDrag = false
                }.padding(8)
            }
            .frame(width: size.width, height: size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .task(id: scenePhase) {
            simulation.configure(friend, reducedMotion: reducedMotion)
            simulation.setActive(scenePhase == .active)
            guard scenePhase == .active else { attemptedDrag = false; return }
            // SpriteKit owns the physics step. Only sample poses for SwiftUI at 30 Hz.
            while !Task.isCancelled {
                simulation.refresh()
                do { try await Task.sleep(nanoseconds: 33_333_333) }
                catch { return }
            }
        }
        .onChange(of: signal) { _ in simulation.react(action) }
        .onChange(of: friend) { value in
            simulation.configure(value, reducedMotion: reducedMotion)
            simulation.setActive(scenePhase == .active)
        }
        .onChange(of: reducedMotion) { value in
            simulation.configure(friend, reducedMotion: value)
            simulation.setActive(scenePhase == .active)
        }
        .onDisappear { simulation.setActive(false); attemptedDrag = false }
    }

    private func scenePoint(_ point: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(x: point.x / size.width * 600, y: 440 - point.y / size.height * 440)
    }
}
