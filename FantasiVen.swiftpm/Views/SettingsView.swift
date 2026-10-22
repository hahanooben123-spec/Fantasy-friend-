import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FriendStore
    var body: some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            VStack(spacing: 12) {
                AdventureHeading(title: store.t("settings"), subtitle: store.t("settingsHint"))
                ScrollView {
                    VStack(spacing: 22) {
                        HStack(spacing: 16) {
                            CharacterView(friend: FantasyFriend()).frame(width: 115, height: 125)
                            Text(store.t("settingsGreeting")).font(.system(.title3, design: .rounded).weight(.heavy))
                        }
                        VStack(spacing: 18) {
                            Toggle(isOn: Binding(get: { store.settings.sound }, set: { value in store.updateSettings { $0.sound = value } })) {
                                HStack(spacing: 14) {
                                    ToyGlyph(kind: .feather).frame(width: 48, height: 48).background(Circle().fill(StudioStyle.colors[3].opacity(0.25)))
                                    Text(store.t("sound")).font(.system(.headline, design: .rounded))
                                }
                            }
                            Divider().opacity(0.3)
                            Toggle(isOn: Binding(get: { store.settings.music }, set: { value in store.updateSettings { $0.music = value } })) {
                                HStack(spacing: 14) {
                                    ToyGlyph(kind: .music).frame(width: 48, height: 48).background(Circle().fill(StudioStyle.colors[1].opacity(0.25)))
                                    Text(store.t("music")).font(.system(.headline, design: .rounded))
                                }
                            }
                        }.toggleStyle(SwitchToggleStyle(tint: GameStyle.purple)).padding(22).background(RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.9)))
                        VStack(alignment: .leading, spacing: 12) {
                            Text(store.t("language")).font(.system(.headline, design: .rounded))
                            HStack(spacing: 14) {
                                languageCard(.da, title: "Dansk", flag: "🇩🇰")
                                languageCard(.en, title: "English", flag: "🇬🇧")
                            }
                        }
                        HStack(spacing: 12) {
                            ToyGlyph(kind: .heart).frame(width: 38, height: 38)
                            Text(store.t("privacy")).font(.system(.footnote, design: .rounded))
                        }.padding(18).background(RoundedRectangle(cornerRadius: 28).fill(.white.opacity(0.55)))
                        Text("FantasiVen · 1.0").font(.system(.caption, design: .rounded)).opacity(0.55)
                    }.padding(22).frame(maxWidth: 570).frame(maxWidth: .infinity)
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
    }

    private func languageCard(_ language: Language, title: String, flag: String) -> some View {
        Button { store.updateSettings { $0.language = language } } label: {
            HStack {
                Text(flag).font(.system(size: 30))
                Text(title).font(.system(.headline, design: .rounded))
                Spacer(minLength: 0)
                if store.settings.language == language { Image(systemName: "checkmark.circle.fill").foregroundColor(GameStyle.purple) }
            }.padding(15).frame(maxWidth: .infinity).frame(minHeight: 76)
                .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(store.settings.language == language ? GameStyle.purple : .clear, lineWidth: 3))
        }.buttonStyle(SquishStyle()).accessibilityAddTraits(store.settings.language == language ? .isSelected : [])
    }
}
