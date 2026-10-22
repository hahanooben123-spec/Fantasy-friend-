import SwiftUI
import SpriteKit

struct PhysicsPlayfield: View {
    @ObservedObject var physics: PlayPhysics
    var trampoline = false
    @State private var dragging = false
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                SpriteView(scene: physics.scene, options: [.allowsTransparency]).allowsHitTesting(false).accessibilityHidden(true)
                ForEach(physics.toys) { toy in
                    toyView(toy.kind).frame(width: 56 * size.width / 800, height: 60 * size.height / 500)
                        .rotationEffect(.degrees(toy.angle))
                        .position(x: toy.x / 800 * size.width, y: (500 - toy.y) / 500 * size.height)
                        .allowsHitTesting(false)
                }
                ForEach(physics.friends) { actor in
                    CharacterView(friend: actor.friend, happy: dragging)
                        .frame(width: 120 * size.width / 800, height: 128 * size.height / 500)
                        .rotationEffect(.degrees(actor.angle))
                        .position(x: actor.x / 800 * size.width, y: (500 - actor.y) / 500 * size.height)
                        .allowsHitTesting(false)
                }
                if trampoline {
                    Capsule().fill(StudioStyle.colors[1]).overlay(Capsule().stroke(.white, lineWidth: 3))
                        .frame(width: size.width * 0.19, height: 18)
                        .position(x: physics.trampolineX / 800 * size.width, y: size.height * 0.83)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("physics")).onChanged { value in
                            physics.moveTrampoline(value.location.x / size.width * 800); physics.refresh()
                        })
                }
            }.coordinateSpace(name: "physics").frame(width: size.width, height: size.height).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    if !dragging { physics.beginDrag(point(value.startLocation, size: size)); dragging = true }
                    physics.moveDrag(point(value.location, size: size))
                }.onEnded { _ in physics.endDrag(); dragging = false })
        }
    }
    private func point(_ p: CGPoint, size: CGSize) -> CGPoint { CGPoint(x: p.x / size.width * 800, y: 500 - p.y / size.height * 500) }
    @ViewBuilder private func toyView(_ kind: Int) -> some View {
        if kind == 0 {
            Circle().fill(StudioStyle.colors[0]).overlay(Circle().stroke(GameStyle.ink, lineWidth: 2))
                .overlay(Circle().trim(from: 0, to: 0.5).stroke(StudioStyle.colors[1], lineWidth: 7).padding(9))
        } else if kind == 1 {
            RoundedRectangle(cornerRadius: 8).fill(StudioStyle.colors[5]).overlay(RoundedRectangle(cornerRadius: 8).stroke(GameStyle.ink, lineWidth: 2)).overlay(Text("★").foregroundColor(.white))
        } else {
            Ellipse().fill(StudioStyle.colors[1]).overlay(Ellipse().stroke(GameStyle.ink, lineWidth: 2)).overlay(Ellipse().fill(.white.opacity(0.5)).frame(width: 8, height: 16).offset(x: -9, y: -8))
        }
    }
}
