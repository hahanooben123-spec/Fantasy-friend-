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
        RoundedRectangle(cornerRadius:cornerRadius)
            .fill(LinearGradient(stops:[
                .init(color:GameStyle.mixed(color,with:.white,amount:0.43),location:0),
                .init(color:GameStyle.mixed(color,with:.white,amount:0.1),location:0.28),
                .init(color:color,location:0.62),
                .init(color:GameStyle.mixed(color,with:GameStyle.ink,amount:0.28),location:1)],
                startPoint:.topLeading,endPoint:.bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius:cornerRadius).strokeBorder(
                GameStyle.mixed(color,with:GameStyle.ink,amount:0.6),lineWidth:1.5))
            .overlay(RoundedRectangle(cornerRadius:max(4,cornerRadius-3)).strokeBorder(
                LinearGradient(colors:[.white.opacity(0.72),.white.opacity(0.04)],startPoint:.top,endPoint:.bottom),
                lineWidth:1.5).padding(3))
            .overlay(alignment:.top) {
                Capsule().fill(LinearGradient(colors:[.white.opacity(0.35),.clear],startPoint:.top,endPoint:.bottom))
                    .frame(height:14).padding(.horizontal,cornerRadius*0.65).padding(.top,6)
            }
            .shadow(color:GameStyle.mixed(color,with:GameStyle.ink,amount:0.5),radius:0,y:4)
            .shadow(color:GameStyle.ink.opacity(0.2),radius:6,x:0,y:7)
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
        configuration.label.scaleEffect(configuration.isPressed && !reducedMotion ? 0.95 : 1)
            .offset(y:configuration.isPressed && !reducedMotion ? 2 : 0)
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

/// Shared soft vinyl material for characters, accessories and game props.
enum ToyFinish {
    static func paint(_ context:GraphicsContext,path:Path,color:Color,edge:CGFloat=2) {
        let r=path.boundingRect
        guard r.width>0,r.height>0 else {return}
        let key=CGPoint(x:r.minX+r.width*0.29,y:r.minY+r.height*0.22)
        let light=GameStyle.mixed(color,with:Color(red:1,green:0.96,blue:0.83),amount:0.35)
        let shade=GameStyle.mixed(color,with:Color(red:0.14,green:0.10,blue:0.28),amount:0.46)
        context.fill(path,with:.radialGradient(Gradient(stops:[
            .init(color:light,location:0),.init(color:color,location:0.48),
            .init(color:shade,location:1)]),center:key,startRadius:0,endRadius:max(r.width,r.height)*0.88))
        var clipped=context;clipped.clip(to:path)
        clipped.stroke(path.applying(CGAffineTransform(translationX:2,y:3)),
            with:.color(.white.opacity(0.22)),lineWidth:3)
        context.stroke(path,with:.color(GameStyle.mixed(color,with:GameStyle.ink,amount:0.66)),lineWidth:edge)
    }
}
