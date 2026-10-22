import SwiftUI

struct BuilderView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    let original: FantasyFriend
    let existing: Bool
    @State private var friend: FantasyFriend
    @State private var history: [FantasyFriend] = []
    @State private var part: Part = .body
    @State private var naming = false
    @State private var celebration = false
    @State private var discard = false
    @State private var revision = 0
    private let symbols = ["circle.hexagongrid.fill", "paintpalette.fill", "drop.fill", "eye.fill", "face.smiling.fill", "hand.wave.fill", "figure.walk", "sparkles"]

    init(original: FantasyFriend, existing: Bool) {
        self.original = original; self.existing = existing
        _friend = State(initialValue: original)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WorldBackdrop(world: friend.world)
                VStack(spacing: 12) {
                    HStack {
                        RoundButton(icon: "xmark", label: store.t("close")) {
                            if friend != original { discard = true } else { presentation.wrappedValue.dismiss() }
                        }
                        Spacer()
                        Text(store.t("create")).font(.system(.title3, design: .rounded).weight(.bold))
                        Spacer()
                        RoundButton(icon: "arrow.uturn.backward", label: store.t("undo")) {
                            if let previous = history.popLast() { withAnimation { friend = previous }; revision += 1 }
                        }.disabled(history.isEmpty).opacity(history.isEmpty ? 0.4 : 1)
                    }.padding(.horizontal, 20)
                    LivingFriend(friend: friend, action: .hug, signal: revision)
                        .frame(height: max(140, min(geometry.size.height * 0.39, 330)))
                    HStack {
                        Text(store.t(Words.partKeys[part.rawValue])).font(.system(.title2, design: .rounded).weight(.heavy))
                        Spacer()
                        RoundButton(icon: "shuffle", label: store.t("random")) {
                            change { value in
                                var random = FantasyFriend.random()
                                random.id = value.id; random.name = value.name; random.world = value.world
                                value = random
                            }
                        }
                    }.padding(.horizontal, 24)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Part.allCases, id: \.rawValue) { item in
                                        Button { part = item; SoundService.shared.play(.click) } label: {
                                            VStack(spacing: 5) {
                                                Image(systemName: symbols[item.rawValue]).font(.system(size: 23, weight: .semibold))
                                                Text(store.t(Words.partKeys[item.rawValue])).font(.system(size: 10, weight: .bold, design: .rounded))
                                            }.foregroundColor(item == part ? .white : GameStyle.ink)
                                                .frame(width: 73, height: 66)
                                                .background(RoundedRectangle(cornerRadius: 20).fill(item == part ? GameStyle.purple : .white.opacity(0.8)))
                                        }.buttonStyle(SquishStyle()).accessibilityAddTraits(item == part ? .isSelected : [])
                                    }
                                }.padding(.horizontal, 24)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<optionCount, id: \.self) { index in option(index) }
                                }.padding(.horizontal, 24).padding(.vertical, 5)
                            }.id(part)
                        }.padding(.bottom, 8)
                    }
                    CandyButton(title: store.t("save"), icon: "checkmark", color: GameStyle.purple) { naming = true }
                        .padding(.horizontal, 24).padding(.bottom, 12)
                }.padding(.top, 8).frame(maxWidth: 600).frame(maxWidth: .infinity)
                if celebration {
                    Color.white.opacity(0.94).ignoresSafeArea()
                    VStack(spacing: 24) {
                        Text("✦ ✧ ✦").font(.system(size: 42)).foregroundColor(.orange)
                        LivingFriend(friend: friend, action: .hug, signal: 1).frame(height: 280)
                        Text(store.t(existing ? "updated" : "created")).font(.system(.title, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                        Text(friend.name).font(.system(.title2, design: .rounded)).foregroundColor(GameStyle.purple)
                        CandyButton(title: store.t("continue"), icon: "checkmark") { presentation.wrappedValue.dismiss() }
                    }.padding(30).frame(maxWidth: 500)
                }
            }
        }.foregroundColor(GameStyle.ink)
        .sheet(isPresented: $naming) {
            NamingView(friend: $friend) {
                if store.save(friend) {
                    naming = false; celebration = true; SoundService.shared.play(.complete)
                }
            }.environmentObject(store)
        }
        .alert(store.t("discard"), isPresented: $discard) {
            Button(store.t("cancel"), role: .cancel) {}
            Button(store.t("leave"), role: .destructive) { presentation.wrappedValue.dismiss() }
        } message: { Text(store.t("discardHint")) }
    }

    private var optionCount: Int {
        switch part { case .body, .arms, .legs: return 8; case .color, .accent: return 16; case .eyes: return 12; case .mouth: return 10; case .extras: return 15 }
    }
    private func selected(_ index: Int) -> Bool {
        switch part {
        case .body: return friend.body.rawValue == index
        case .color: return friend.color == index
        case .accent: return friend.accent == index
        case .eyes: return friend.eyes == index
        case .mouth: return friend.mouth == index
        case .arms: return friend.arms == index
        case .legs: return friend.legs == index
        case .extras: return friend.accessories.contains(index)
        }
    }
    private func preview(_ index: Int) -> FantasyFriend {
        var value = friend
        apply(index, to: &value)
        if part == .extras { value.accessories = [index] }
        return value
    }
    private func apply(_ index: Int, to value: inout FantasyFriend) {
        switch part {
        case .body: value.body = BodyKind(rawValue: index) ?? .round
        case .color: value.color = index
        case .accent: value.accent = index
        case .eyes: value.eyes = index
        case .mouth: value.mouth = index
        case .arms: value.arms = index
        case .legs: value.legs = index
        case .extras:
            if value.accessories.contains(index) { value.accessories.remove(index) } else { value.accessories.insert(index) }
        }
    }
    private func change(_ update: (inout FantasyFriend) -> Void) {
        history.append(friend)
        if history.count > 60 { history.removeFirst() }
        update(&friend); revision += 1
        SoundService.shared.play(.click)
    }
    private func option(_ index: Int) -> some View {
        let label: String = part == .body ? store.t(Words.bodyKeys[index]) : (part == .extras ? store.t(Words.extraKeys[index]) : "\(store.t(Words.partKeys[part.rawValue])) \(index + 1)")
        return Button { change { apply(index, to: &$0) } } label: {
            VStack(spacing: 2) {
                if part == .color || part == .accent {
                    Circle().fill(GameStyle.palette[index]).frame(width: 50, height: 50)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                } else {
                    CharacterView(friend: preview(index)).frame(width: 80, height: 86)
                }
                if part == .body || part == .extras { Text(label).font(.system(size: 10, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7) }
                if selected(index) { Image(systemName: "checkmark.circle.fill").foregroundColor(GameStyle.purple).font(.system(size: 16)) }
            }
            .frame(width: part == .color || part == .accent ? 68 : 91, height: part == .color || part == .accent ? 91 : 126)
            .background(RoundedRectangle(cornerRadius: 23).fill(.white.opacity(0.75)))
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(selected(index) ? GameStyle.purple : .clear, lineWidth: 3))
        }.buttonStyle(SquishStyle()).accessibilityLabel(label).accessibilityAddTraits(selected(index) ? .isSelected : [])
    }
}

private struct NamingView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    @Binding var friend: FantasyFriend
    var save: () -> Void
    var body: some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            ScrollView {
                VStack(spacing: 22) {
                    HStack { Spacer(); RoundButton(icon: "xmark", label: store.t("close")) { presentation.wrappedValue.dismiss() } }
                    CharacterView(friend: friend).frame(height: 190)
                    Text(store.t("name")).font(.system(.title2, design: .rounded).weight(.heavy))
                    TextField(store.t("name"), text: Binding(get: { friend.name }, set: { friend.name = String($0.prefix(30)) }))
                        .font(.system(.title2, design: .rounded)).multilineTextAlignment(.center)
                        .padding(18).background(RoundedRectangle(cornerRadius: 20).fill(.white))
                        .submitLabel(.done)
                    CandyButton(title: store.t("suggest"), icon: "shuffle", color: Color(red: 0.28, green: 0.66, blue: 0.60)) {
                        friend.name = Words.names.filter { $0 != friend.name }.randomElement() ?? "Bimse"
                    }
                    CandyButton(title: store.t("save"), icon: "checkmark") {
                        friend.name = friend.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if friend.name.isEmpty { friend.name = Words.names.randomElement() ?? "Bimse" }
                        save()
                    }
                    if let error = store.error { Text(error).font(.system(.body, design: .rounded)).foregroundColor(GameStyle.ink).accessibilityAddTraits(.updatesFrequently) }
                }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
            }
        }.foregroundColor(GameStyle.ink)
    }
}
