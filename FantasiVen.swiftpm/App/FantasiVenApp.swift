import SwiftUI

@main
struct FantasiVenApp: App {
    @StateObject private var store = FriendStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(store)
                .environment(\.locale, Locale(identifier: store.settings.language.rawValue))
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { SoundService.shared.setActive($0 == .active) }
        }
    }
}
