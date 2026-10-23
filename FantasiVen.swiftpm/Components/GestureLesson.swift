import SwiftUI

/// Two short demonstrations; disappears immediately after the child acts.
struct GestureLesson:View {
    let activity:Int
    var from=UnitPoint(x:0.3,y:0.7)
    var to=UnitPoint(x:0.55,y:0.45)
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    @State private var visible=false
    @State private var moved=false
    var body:some View {
        GeometryReader {proxy in
            Image(systemName:"hand.point.up.left.fill")
                .font(.system(size:38,weight:.bold)).foregroundColor(.white)
                .shadow(color:WorkshopLook.sea,radius:3)
                .position(x:(moved ? to.x : from.x)*proxy.size.width,
                          y:(moved ? to.y : from.y)*proxy.size.height)
                .opacity(visible ? 0.9 : 0)
        }.allowsHitTesting(false).accessibilityHidden(true)
            .task(id:"\(activity)-\(phase)") {
                visible=false;moved=false
                guard activity == 0,phase == .active,!reduced else {return}
                do {
                    try await Task.sleep(nanoseconds:3_000_000_000)
                    visible=true
                    for _ in 0..<2 {
                        moved=false
                        try await Task.sleep(nanoseconds:200_000_000)
                        withAnimation(.easeInOut(duration:1.05)) {moved=true}
                        try await Task.sleep(nanoseconds:1_200_000_000)
                    }
                    visible=false
                } catch {visible=false}
            }
    }
}
