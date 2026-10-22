import SwiftUI

struct TouchDemonstration: View {
    let activity: Int
    var slide = true
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var visible = false
    @State private var drift = false
    var body: some View {
        GeometryReader { proxy in
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 39, weight: .bold)).foregroundColor(.white)
                .shadow(color: GameStyle.ink, radius: 2)
                .position(x: proxy.size.width * (drift && slide ? 0.62 : 0.38), y: proxy.size.height * (drift && slide ? 0.35 : 0.6))
                .scaleEffect(drift && !slide ? 0.85 : 1)
                .opacity(visible ? 0.9 : 0)
        }.allowsHitTesting(false).accessibilityHidden(true)
            .task(id: activity) {
                visible = false; drift = false
                guard activity == 0 else { return }
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    visible = true
                    if !reduced { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { drift = true } }
                    try await Task.sleep(nanoseconds: 4_000_000_000)
                    visible = false
                } catch { visible = false }
            }
    }
}
