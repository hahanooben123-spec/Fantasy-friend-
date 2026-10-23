import SwiftUI
import SpriteKit

@MainActor
struct RagdollPlayground: View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    let friend:FantasyFriend
    let action:PlayAction
    let signal:Int
    var active=true
    @StateObject private var simulation=RagdollSimulation()
    @State private var attemptedDrag=false
    var body:some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene:simulation.scene,options:[.allowsTransparency])
                    .allowsHitTesting(false).accessibilityHidden(true)
                RagdollCharacterView(frame:simulation.frame).allowsHitTesting(false).accessibilityHidden(true)
            }.frame(width:geometry.size.width,height:geometry.size.height).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0).onChanged {value in
                    if !attemptedDrag {
                        attemptedDrag=true
                        simulation.beginDrag(at:scenePoint(value.startLocation,size:geometry.size))
                    }
                    simulation.moveDrag(to:scenePoint(value.location,size:geometry.size))
                }.onEnded {value in
                    let wasDragging=simulation.isDragging
                    simulation.endDrag();attemptedDrag=false
                    if wasDragging && hypot(value.translation.width,value.translation.height)<6 {simulation.react(.tickle)}
                    else if !wasDragging {simulation.walk(to:scenePoint(value.location,size:geometry.size))}
                })
                .accessibilityElement(children:.ignore).accessibilityLabel(friend.name)
                .accessibilityHint(store.t("ragdollHint"))
                .accessibilityAction(named:Text(store.t("jump"))) {simulation.react(.jump)}
                .accessibilityAction(named:Text(store.t("walkHere"))) {
                    simulation.walk(to:CGPoint(x:simulation.scene.size.width*0.7,y:150))
                }
                .accessibilityAction(named:Text(store.t("dance"))) {simulation.react(.dance)}
                .onAppear {resize(geometry.size)}
                .onChange(of:geometry.size) {resize($0)}
        }
        .task(id:"\(scenePhase)-\(active)") {
            simulation.setActive(scenePhase == .active && active)
            guard scenePhase == .active && active else {attemptedDrag=false;return}
            while !Task.isCancelled {
                simulation.refresh()
                do {try await Task.sleep(nanoseconds:33_333_333)} catch {return}
            }
        }
        .onChange(of:signal) {_ in simulation.react(action)}
        .onChange(of:friend) {value in simulation.configure(value,reducedMotion:reducedMotion);simulation.setActive(scenePhase == .active && active)}
        .onChange(of:reducedMotion) {value in simulation.configure(friend,reducedMotion:value);simulation.setActive(scenePhase == .active && active)}
        .onDisappear {simulation.setActive(false);attemptedDrag=false}
    }
    private func resize(_ size:CGSize) {
        simulation.resize(to:size)
        simulation.configure(friend,reducedMotion:reducedMotion)
        simulation.setActive(scenePhase == .active && active)
    }
    private func scenePoint(_ point:CGPoint,size:CGSize)->CGPoint {
        CGPoint(x:point.x/max(1,size.width)*simulation.scene.size.width,
                y:(1-point.y/max(1,size.height))*simulation.scene.size.height)
    }
}
