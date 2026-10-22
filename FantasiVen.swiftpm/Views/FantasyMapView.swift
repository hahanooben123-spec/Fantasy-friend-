import SwiftUI

struct FantasyMapView: View {
    @EnvironmentObject private var store: FriendStore
    let onCreate: () -> Void
    let onEdit: (FantasyFriend, Bool) -> Void
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145, maximum: 260), spacing: 18)], spacing: 25) {
            Button(action: onCreate) { door("create", color: StudioStyle.colors[0]) { DestinationArt(kind: .studio) } }
            NavigationLink(destination: GalleryView(onEdit: onEdit)) { door("friendVillage", color: StudioStyle.colors[1]) { DestinationArt(kind: .village) } }
            NavigationLink(destination: PlaygroundView(onCreate: onCreate)) { door("playRoom", color: StudioStyle.colors[2]) { DestinationArt(kind: .playground) } }
            NavigationLink(destination: MiniGamesView(onCreate: onCreate)) { door("adventureTree", color: StudioStyle.colors[6]) { AdventureTreeArt() } }
        }.buttonStyle(SquishStyle()).padding(.vertical, 12)
    }
    private func door<Art: View>(_ key: String, color: Color, @ViewBuilder art: () -> Art) -> some View {
        VStack(spacing: -4) {
            art().frame(height: 120)
            Text(store.t(key)).font(.system(size: 18, weight: .heavy, design: .rounded)).lineLimit(2).minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 49).padding(.horizontal, 7)
                .background(CandySurface(color: color, cornerRadius: 22))
        }.foregroundColor(GameStyle.ink).contentShape(Rectangle())
    }
}

struct AdventureTreeArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.65, green: 0.35, blue: 0.16)).frame(width: 46, height: 85).offset(y: 25)
            ForEach(0..<3) { i in
                Circle().fill(StudioStyle.colors[i == 1 ? 6 : 2]).frame(width: 90, height: 90)
                    .overlay(Circle().stroke(GameStyle.ink.opacity(0.7), lineWidth: 2))
                    .offset(x: CGFloat(i-1)*43, y: i == 1 ? -20 : 0)
            }
            MiniGameArt(kind: .apples).scaleEffect(0.35).offset(x: -43, y: 1)
            MiniGameArt(kind: .bubbles).scaleEffect(0.35).offset(x: 43, y: 4)
            Text("★").font(.system(size: 40)).foregroundColor(.yellow).offset(y: -25)
        }.accessibilityHidden(true)
    }
}
