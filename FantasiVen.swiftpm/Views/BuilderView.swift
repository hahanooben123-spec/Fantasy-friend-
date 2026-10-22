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
    @State private var attachment: Attachment?
    @State private var draggedChoice: PartDragChoice?
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
                            if let previous = history.popLast() { withAnimation { friend = previous } }
                        }.disabled(history.isEmpty).opacity(history.isEmpty ? 0.4 : 1)
                    }.padding(.horizontal, 20)
                    CharacterWorkshop(friend: friend, category: part, selection: $attachment, draggedChoice: $draggedChoice,
                        onMove: { target, pose in change { $0.setPlacement(pose, for: target) } },
                        onDropPart: drop)
                        .frame(height: max(170, min(geometry.size.height * 0.43, 390)))
                    Label(store.t("dragHint"), systemImage: "hand.draw.fill")
                        .font(.system(.caption, design: .rounded)).foregroundColor(GameStyle.purple)
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
                            if [.arms, .legs, .extras].contains(part) {
                                attachmentPicker
                                if let attachment = attachment { placementTools(attachment) }
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
        .onChange(of: part) { value in
            if attachment?.category != value {
                attachment = AttachmentLayout.attachments(in: friend).first { $0.category == value }
            }
        }
        .onChange(of: friend) { value in
            if let selected = attachment, !AttachmentLayout.attachments(in: value).contains(selected) {
                attachment = AttachmentLayout.attachments(in: value).first { $0.category == part }
            }
        }
        .onChange(of: attachment) { value in
            if let value = value { part = value.category }
        }
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

    private func thumbnailAttachment(_ index: Int) -> Attachment? {
        switch part {
        case .arms: return .leftArm
        case .legs: return .leftLeg
        case .extras: return .extra(index)
        default: return nil
        }
    }

    private func drop(_ choice: PartDragChoice, at point: CGPoint, size: CGSize) {
        let target = choice.attachment(at: point, stageSize: size)
        change { value in
            switch choice.category {
            case .arms: value.arms = choice.index
            case .legs: value.legs = choice.index
            case .extras: value.accessories.insert(choice.index)
            default: return
            }
            value.setPlacement(AttachmentLayout.placed(target, in: value, at: point, stageSize: size), for: target)
        }
        attachment = target
        part = target.category
    }

    private var attachmentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AttachmentLayout.attachments(in: friend).filter { $0.category == part }) { target in
                    Button { attachment = target } label: {
                        Text(store.t(target.rawValue))
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .padding(.horizontal, 16).frame(minHeight: 44)
                            .background(Capsule().fill(attachment == target ? GameStyle.purple : Color.white.opacity(0.8)))
                            .foregroundColor(attachment == target ? .white : GameStyle.ink)
                    }.buttonStyle(SquishStyle()).accessibilityAddTraits(attachment == target ? .isSelected : [])
                }
            }.padding(.horizontal, 24)
        }
    }

    private func adjust(_ target: Attachment, update: (inout PartPlacement) -> Void) {
        var pose = friend.placement(for: target)
        update(&pose)
        pose = AttachmentLayout.constrained(pose, for: target, friend: friend)
        change { $0.setPlacement(pose, for: target) }
    }

    private func placementTools(_ target: Attachment) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                RoundButton(icon: "arrow.left", label: store.t("moveLeft")) { adjust(target) { $0.x = max(-1, $0.x - 0.025) } }
                RoundButton(icon: "arrow.right", label: store.t("moveRight")) { adjust(target) { $0.x = min(1, $0.x + 0.025) } }
                RoundButton(icon: "arrow.up", label: store.t("moveUp")) { adjust(target) { $0.y = max(-1, $0.y - 0.025) } }
                RoundButton(icon: "arrow.down", label: store.t("moveDown")) { adjust(target) { $0.y = min(1, $0.y + 0.025) } }
                RoundButton(icon: "rotate.left", label: store.t("rotateLeft")) {
                    adjust(target) { $0.rotation = $0.rotation <= -180 ? 165 : $0.rotation - 15 }
                }
                RoundButton(icon: "rotate.right", label: store.t("rotateRight")) {
                    adjust(target) { $0.rotation = $0.rotation >= 180 ? -165 : $0.rotation + 15 }
                }
                RoundButton(icon: "minus.magnifyingglass", label: store.t("smaller")) { adjust(target) { $0.scale = max(0.5, $0.scale - 0.1) } }
                RoundButton(icon: "plus.magnifyingglass", label: store.t("bigger")) { adjust(target) { $0.scale = min(1.5, $0.scale + 0.1) } }
                RoundButton(icon: "arrow.counterclockwise", label: store.t("resetPart")) { change { $0.setPlacement(PartPlacement(), for: target) } }
                if let index = target.extraIndex {
                    RoundButton(icon: "trash", label: store.t("removePart")) {
                        change { $0.accessories.remove(index); $0.setPlacement(PartPlacement(), for: target) }
                        attachment = nil
                    }
                }
            }.padding(.horizontal, 24)
        }
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
        value.placements = nil
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
            value.accessories.insert(index)
        }
    }
    private func change(_ update: (inout FantasyFriend) -> Void) {
        var updated = friend
        update(&updated)
        for target in AttachmentLayout.attachments(in: updated) {
            let pose = updated.placement(for: target)
            if pose != PartPlacement() { updated.setPlacement(AttachmentLayout.constrained(pose, for: target, friend: updated), for: target) }
        }
        guard updated != friend else { return }
        history.append(friend)
        if history.count > 60 { history.removeFirst() }
        friend = updated
        SoundService.shared.play(.click)
    }
    private func option(_ index: Int) -> some View {
        let label: String = part == .body ? store.t(Words.bodyKeys[index]) : (part == .extras ? store.t(Words.extraKeys[index]) : "\(store.t(Words.partKeys[part.rawValue])) \(index + 1)")
        return optionWithDrag(index, label: label)
    }

    @ViewBuilder
    private func optionWithDrag(_ index: Int, label: String) -> some View {
        if [.arms, .legs, .extras].contains(part) {
            optionButton(index, label: label)
                .onDrag {
                    let choice = PartDragChoice(category: part, index: index)
                    draggedChoice = choice
                    return choice.provider()
                }
        } else {
            optionButton(index, label: label)
        }
    }

    private func optionButton(_ index: Int, label: String) -> some View {
        Button {
            if part != .extras || !friend.accessories.contains(index) { change { apply(index, to: &$0) } }
            if part == .extras { attachment = .extra(index) }
            else if part == .arms { attachment = .leftArm }
            else if part == .legs { attachment = .leftLeg }
        } label: {
            VStack(spacing: 2) {
                if part == .color || part == .accent {
                    Circle().fill(GameStyle.palette[index]).frame(width: 50, height: 50)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                } else {
                    CharacterView(friend: preview(index), piece: thumbnailAttachment(index)).frame(width: 80, height: 86)
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
