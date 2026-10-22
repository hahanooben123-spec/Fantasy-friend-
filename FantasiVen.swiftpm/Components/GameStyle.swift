import SwiftUI
import UIKit

enum GameStyle {
    static let ink = Color(red: 0.16, green: 0.11, blue: 0.25)
    static let purple = Color(red: 0.47, green: 0.16, blue: 0.79)
    // Keep hue order stable so existing friends and brush strokes retain their identity.
    static let palette: [Color] = [
        Color(red: 0.59, green: 0.24, blue: 0.94), Color(red: 1, green: 0.30, blue: 0.54),
        Color(red: 1, green: 0.52, blue: 0.08), Color(red: 1, green: 0.81, blue: 0.04),
        Color(red: 0.52, green: 0.82, blue: 0.06), Color(red: 0.03, green: 0.71, blue: 0.48),
        Color(red: 0.05, green: 0.65, blue: 0.98), Color(red: 0.26, green: 0.38, blue: 0.91),
        Color(red: 0.82, green: 0.27, blue: 0.92), Color(red: 1, green: 0.55, blue: 0.68),
        Color(red: 1, green: 0.30, blue: 0.19), Color(red: 0.22, green: 0.84, blue: 0.64),
        Color(red: 0.31, green: 0.80, blue: 1), Color(red: 0.77, green: 0.53, blue: 0.29),
        Color(red: 0.58, green: 0.39, blue: 0.79), Color(red: 1, green: 0.91, blue: 0.65)
    ]

    /// Opaque paint mixing gives shadows depth without washing colors out with transparency.
    static func mixed(_ color: Color, with other: Color, amount: CGFloat) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a),
              UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return color }
        let t = min(1, max(0, amount))
        return Color(red: Double(r + (r2-r)*t), green: Double(g + (g2-g)*t), blue: Double(b + (b2-b)*t))
    }
}

/// A solid toy-like rim, gloss and contact shadow; never intercepts a child's touch.
struct CandySurface: View {
    var color: Color
    var cornerRadius: CGFloat = 27
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(colors: [GameStyle.mixed(color, with: .white, amount: 0.28), color, GameStyle.mixed(color, with: GameStyle.ink, amount: 0.12)], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: max(8, cornerRadius - 7))
                    .fill(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 22).padding(7)
            }
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(GameStyle.ink.opacity(0.65), lineWidth: 2))
            .shadow(color: GameStyle.mixed(color, with: GameStyle.ink, amount: 0.45), radius: 0, y: 5)
            .allowsHitTesting(false)
    }
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
            .foregroundColor(.white).shadow(color: GameStyle.ink.opacity(0.35), radius: 0, y: 1)
            .padding(.horizontal, 21).frame(minHeight: 64)
            .background(CandySurface(color: color))
            .contentShape(RoundedRectangle(cornerRadius: 27))
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
                .background(CandySurface(color: Color(red: 1, green: 0.91, blue: 0.48), cornerRadius: 25))
                .contentShape(Circle())
        }.buttonStyle(SquishStyle()).accessibilityLabel(label)
    }
}
