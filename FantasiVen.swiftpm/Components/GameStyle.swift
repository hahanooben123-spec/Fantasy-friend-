import SwiftUI

enum GameStyle {
    static let ink = Color(red: 0.23, green: 0.19, blue: 0.36)
    static let purple = Color(red: 0.43, green: 0.28, blue: 0.73)
    static let palette: [Color] = [
        Color(red: 0.65, green: 0.49, blue: 0.88), Color(red: 0.96, green: 0.58, blue: 0.70),
        Color(red: 0.99, green: 0.73, blue: 0.46), Color(red: 0.98, green: 0.85, blue: 0.43),
        Color(red: 0.63, green: 0.82, blue: 0.51), Color(red: 0.39, green: 0.76, blue: 0.67),
        Color(red: 0.45, green: 0.75, blue: 0.90), Color(red: 0.49, green: 0.59, blue: 0.86),
        Color(red: 0.85, green: 0.65, blue: 0.91), Color(red: 0.97, green: 0.77, blue: 0.79),
        Color(red: 0.95, green: 0.59, blue: 0.48), Color(red: 0.72, green: 0.87, blue: 0.78),
        Color(red: 0.66, green: 0.84, blue: 0.95), Color(red: 0.87, green: 0.80, blue: 0.67),
        Color(red: 0.74, green: 0.67, blue: 0.85), Color(red: 0.97, green: 0.91, blue: 0.79)
    ]
}

struct CandyButton: View {
    let title: String
    let icon: String
    var color: Color = GameStyle.purple
    var action: () -> Void
    var body: some View {
        Button(action: { SoundService.shared.play(.click); action() }) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 23, weight: .bold)).frame(width: 30)
                Text(title).font(.system(.headline, design: .rounded)).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .heavy))
            }
            .foregroundColor(.white).padding(.horizontal, 21).frame(minHeight: 64)
            .background(RoundedRectangle(cornerRadius: 27).fill(LinearGradient(colors: [color.opacity(0.88), color], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 27).stroke(Color.white.opacity(0.35), lineWidth: 2))
            .shadow(color: color.opacity(0.25), radius: 0, y: 6)
        }.buttonStyle(SquishStyle())
    }
}

struct SquishStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reducedMotion ? 0.94 : 1)
            .animation(reducedMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct RoundButton: View {
    let icon: String
    let label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 21, weight: .bold))
                .foregroundColor(GameStyle.ink).frame(width: 50, height: 50)
                .background(Circle().fill(Color.white.opacity(0.94)))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: GameStyle.purple.opacity(0.1), radius: 0, y: 3)
        }.buttonStyle(SquishStyle()).accessibilityLabel(label)
    }
}
