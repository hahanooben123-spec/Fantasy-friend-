import SwiftUI

@main
struct FantasiVenApp: App {
    @StateObject private var store: FriendStore
    init() {
        #if DEBUG
        let preview = ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("--preview-play=") }
        let value = FriendStore(directory: preview ? FileManager.default.temporaryDirectory.appendingPathComponent("FantasiVen-preview-" + UUID().uuidString) : nil)
        if preview { value.save(PlayPreviewSeed.friend) }
        _store = StateObject(wrappedValue: value)
        #else
        _store = StateObject(wrappedValue: FriendStore())
        #endif
    }
    @ViewBuilder private var root: some View {
        #if DEBUG
        if let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--preview-play=") }) {
            DebugPlayPreview(route: String(argument.dropFirst("--preview-play=".count)), friend: store.friends.first ?? PlayPreviewSeed.friend)
        } else { HomeView() }
        #else
        HomeView()
        #endif
    }
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            root.overlay(LocalSaveStatus().environmentObject(store)).environmentObject(store)
                .environment(\.locale, Locale(identifier: store.settings.language.rawValue))
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) {
                    SoundService.shared.setActive($0 == .active)
                    if $0 != .active {LocalSaveQueue.shared.flush()}
                }
        }
    }
}
