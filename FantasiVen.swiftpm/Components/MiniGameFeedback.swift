import SwiftUI

struct OrchardCatchBurst:View {
    let revision:Int
    let fruit:Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var expanded=false
    @State private var visible=false
    var body:some View {
        ZStack {
            ForEach(0..<7) {i in
                Group {
                    if i == 0 {FruitArtwork(kind:fruit)}
                    else {StarArtwork()}
                }.frame(width:i == 0 ? 36 : 13,height:i == 0 ? 36 : 13)
                    .offset(x:reduced ? 0 : CGFloat(cos(Double(i)*Double.pi*2/7))*(expanded ? 68 : 8),
                            y:reduced ? -20 : CGFloat(sin(Double(i)*Double.pi*2/7))*(expanded ? 58 : 8)-20)
                    .rotationEffect(.degrees(reduced ? 0 : expanded ? Double(i)*19 : 0))
            }
        }.opacity(visible && !expanded ? 1 : 0).allowsHitTesting(false).accessibilityHidden(true)
            .task(id:revision) {
                var transaction=Transaction();transaction.disablesAnimations=true
                withTransaction(transaction) {expanded=false;visible=revision>0}
                guard revision>0 else {return}
                await Task.yield()
                withAnimation(.easeOut(duration:reduced ? 0.25 : 0.65)) {expanded=true}
                do {try await Task.sleep(nanoseconds:700_000_000)} catch {return}
                visible=false
            }
    }
}
struct ShakingFruitCanopy:View {
    let weather:FruitWeather
    let onShake:()->Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @EnvironmentObject private var store:FriendStore
    @State private var shake=0
    @State private var angle=0.0
    var body:some View {
        ZStack {
            FruitCanopy(weather:weather).rotationEffect(.degrees(reduced ? 0 : angle),anchor:.top)
            Color.clear.contentShape(Rectangle())
        }.frame(height:155)
            .contentShape(Rectangle()).onTapGesture {shake+=1;onShake()}
            .accessibilityElement(children:.ignore).accessibilityLabel(store.t("shakeFruitTree"))
            .accessibilityAction {shake+=1;onShake()}
            .task(id:shake) {
                guard shake>0,!reduced else {return}
                for i in 0..<4 {
                    withAnimation(.easeInOut(duration:0.10)) {angle=i.isMultiple(of:2) ? 2 : -2}
                    do {try await Task.sleep(nanoseconds:100_000_000)} catch {angle=0;return}
                }
                withAnimation(.spring(response:0.3,dampingFraction:0.5)) {angle=0}
            }
    }
}
struct MusicalNoteTrail:View {
    let revision:Int
    let row:Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var lifted=false
    var body:some View {
        ZStack {
            ForEach(0..<3) {i in
                ToyGlyph(kind:.music).frame(width:22,height:27)
                    .rotationEffect(.degrees(Double(i-1)*18))
                    .offset(x:CGFloat(i-1)*(lifted ? 30 : 12),y:lifted && !reduced ? -85-CGFloat(i)*12 : -16)
            }
        }.opacity(revision>0 && !lifted ? 1 : 0)
            .allowsHitTesting(false).accessibilityHidden(true)
            .task(id:revision) {
                var transaction=Transaction();transaction.disablesAnimations=true
                withTransaction(transaction) {lifted=false}
                guard revision>0 else {return}
                await Task.yield()
                withAnimation(.easeOut(duration:reduced ? 0.2 : 0.7)) {lifted=true}
            }
    }
}
