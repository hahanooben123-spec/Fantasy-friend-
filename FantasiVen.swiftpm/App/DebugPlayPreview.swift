#if DEBUG
import SwiftUI

enum PlayPreviewSeed {
    static var friend: FantasyFriend {
        var value = FantasyFriend()
        value.name = "Bimse"; value.color = 4; value.accent = 2; value.accessories = [0, 1]
        value.pieces = [CreativePiece(kind: .eye, variant: 4, x: 0.5, y: 0.34, color: 4)]
        value.room = [RoomObject(kind: 0, x: 0.3, y: 0.7), RoomObject(kind: 1, x: 0.8, y: 0.6), RoomObject(kind: 2, x: 0.7, y: 0.45)]
        var song = OrchestraPattern()
        for beat in [0, 2, 4, 6] { song.toggle(row: 0, beat: beat) }
        for beat in [1, 5] { song.toggle(row: 1, beat: beat) }
        for beat in [3, 7] { song.toggle(row: 2, beat: beat) }
        value.song = song
        return value
    }
}
struct DebugPlayPreview: View {
    let route: String
    @State var friend: FantasyFriend
    var body: some View {
        NavigationView {
            Group {
                if route == "free" { BuilderView(original: friend, existing: false) }
                else if route == "ride" { PhysicsAdventureView(kind: .slide, friend: friend, previewRide: true) }
                else if route == "bounce" { PhysicsAdventureView(kind: .trampoline, friend: friend, previewRide: true) }
                else if route == "playground" {PlaygroundView(initialID:friend.id,onCreate:{})}
                else if route == "yard" { SharedToyYardView(initialFriend: friend) }
                else if route == "room" { FriendRoomView(friendID: friend.id) }
                else if route == "hub" { MiniGamesView(onCreate: {}) }
                else if let kind = MiniGameKind(rawValue: route) { GameDestinationView(kind: kind, friend: friend) }
                else { HomeView() }
            }
        }.navigationViewStyle(.stack)
    }
}
#endif
