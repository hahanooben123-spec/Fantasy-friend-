import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FriendStore
    var body: some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            ScrollView {
                VStack(spacing: 24) {
                    CharacterView(friend: FantasyFriend()).frame(height: 180)
                    VStack(spacing: 22) {
                        Toggle(store.t("sound"), isOn: Binding(get: { store.settings.sound }, set: { value in store.updateSettings { $0.sound = value } }))
                        Toggle(store.t("music"), isOn: Binding(get: { store.settings.music }, set: { value in store.updateSettings { $0.music = value } }))
                        Picker(store.t("language"), selection: Binding(get: { store.settings.language }, set: { value in store.updateSettings { $0.language = value } })) {
                            Text("Dansk").tag(Language.da)
                            Text("English").tag(Language.en)
                        }.pickerStyle(.segmented)
                    }.font(.system(.headline, design: .rounded)).padding(24)
                        .background(RoundedRectangle(cornerRadius: 28).fill(.white.opacity(0.8)))
                    Label(store.t("privacy"), systemImage: "heart.fill")
                        .font(.system(.footnote, design: .rounded)).multilineTextAlignment(.center).padding(.horizontal, 20)
                    Text("FantasiVen · 1.0").font(.system(.caption, design: .rounded)).opacity(0.5)
                }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
            }
        }.foregroundColor(GameStyle.ink).tint(GameStyle.purple)
            .navigationTitle(store.t("settings")).navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
    }
}
