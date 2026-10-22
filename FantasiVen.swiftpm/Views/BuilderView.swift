import SwiftUI

struct BuilderView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    let original: FantasyFriend
    let existing: Bool
    @State private var friend: FantasyFriend
    @State private var history: [FantasyFriend] = []
    @State private var future: [FantasyFriend] = []
    @State private var part: Part = .body
    @State private var naming = false
    @State private var celebration = false
    @State private var discard = false
    @State private var attachment: Attachment?
    @State private var draggedChoice: PartDragChoice?
    @State private var paintColor = 10
    @State private var brushWidth: Double = 9
    @State private var revision = 0

    init(original: FantasyFriend, existing: Bool) {
        self.original = original; self.existing = existing
        _friend = State(initialValue: original)
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700
            ZStack {
                StudioBackdrop()
                VStack(spacing: 12) {
                    header(wide: wide)
                    if wide {
                        HStack(alignment: .top, spacing: 20) {
                            workspace
                            inventory(wide: true).frame(width: min(360, geometry.size.width * 0.4))
                        }.padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 12) {
                            workspace.frame(height: max(210, min(geometry.size.height * 0.47, 450)))
                            inventory(wide: false)
                        }.padding(.horizontal, 12)
                    }
                }.padding(.top, 8).padding(.bottom, 12)
                if celebration { celebrationView }
            }
        }.foregroundColor(GameStyle.ink)
        .onChange(of: part) { value in
            if attachment?.category != value { attachment = AttachmentLayout.attachments(in: friend).first { $0.category == value } }
        }
        .onChange(of: friend) { value in
            if let selected = attachment, !AttachmentLayout.attachments(in: value).contains(selected) {
                attachment = AttachmentLayout.attachments(in: value).first { $0.category == part }
            }
        }
        .onChange(of: attachment) { value in if let value = value { part = value.category } }
        .sheet(isPresented: $naming) {
            NamingView(friend: $friend) {
                if store.save(friend) { naming = false; celebration = true; SoundService.shared.play(.complete) }
            }.environmentObject(store)
        }
        .alert(store.t("discard"), isPresented: $discard) {
            Button(store.t("cancel"), role: .cancel) {}
            Button(store.t("leave"), role: .destructive) { presentation.wrappedValue.dismiss() }
        } message: { Text(store.t("discardHint")) }
    }

    private func header(wide: Bool) -> some View {
        HStack(spacing: 7) {
            RoundButton(icon: "xmark", label: store.t("close")) {
                if friend != original { discard = true } else { presentation.wrappedValue.dismiss() }
            }
            Text(store.t("creativeStudio"))
                .font(.system(size: wide ? 27 : 17, weight: .heavy, design: .rounded))
                .lineLimit(2).minimumScaleFactor(0.7).frame(maxWidth: .infinity, alignment: .leading)
            RoundButton(icon: "arrow.uturn.backward", label: store.t("undo"), action: undo)
                .disabled(history.isEmpty).opacity(history.isEmpty ? 0.35 : 1)
            RoundButton(icon: "arrow.uturn.forward", label: store.t("redo"), action: redo)
                .disabled(future.isEmpty).opacity(future.isEmpty ? 0.35 : 1)
            Button { naming = true } label: {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark").font(.system(size: 21, weight: .heavy))
                    if wide { Text(store.t("done")).font(.system(.headline, design: .rounded)) }
                }.foregroundColor(.white).padding(.horizontal, 17).frame(minHeight: 50)
                    .background(Capsule().fill(GameStyle.purple))
                    .shadow(color: GameStyle.purple.opacity(0.3), radius: 0, y: 4)
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("save"))
        }.padding(.horizontal, 12)
    }

    private var workspace: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.t("studioHint")).font(.system(.headline, design: .rounded).weight(.heavy))
                    Text(store.t(part == .paint ? "paintHint" : "piecesHint")).font(.system(.caption, design: .rounded))
                }.minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                RoundButton(icon: "paintpalette.fill", label: store.t("colorMagic")) {
                    change { $0.color = ($0.color + Int.random(in: 1..<16)) % 16; $0.accent = ($0.accent + Int.random(in: 1..<16)) % 16 }
                }
                RoundButton(icon: "sparkles", label: store.t("surprise")) {
                    change { value in
                        var random = FantasyFriend.random()
                        random.id = value.id; random.name = value.name; random.world = value.world
                        value = random
                    }
                }
            }.padding(.horizontal, 8)
            CharacterWorkshop(friend: friend, category: part, selection: $attachment, draggedChoice: $draggedChoice,
                paintTool: part == .paint ? PaintTool(color: paintColor, width: brushWidth) : nil,
                onMove: { target, pose in change { $0.setPlacement(pose, for: target) } },
                onDropPart: drop, onPaint: { stroke in change { value in
                    var strokes = value.doodles ?? []; strokes.append(stroke); value.doodles = strokes
                } })
                .overlay(StudioBurst(revision: revision))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let attachment = attachment, part != .paint { placementTools(attachment).frame(height: 54) }
        }
        .padding(8).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 36).fill(Color.white.opacity(0.32)))
    }

    private func inventory(wide: Bool) -> some View {
        VStack(spacing: 12) {
            categoryDock(wide: wide)
            HStack {
                Text(store.t(Words.partKeys[part.rawValue])).font(.system(.title3, design: .rounded).weight(.heavy))
                Spacer()
                if part != .paint {
                    Text("\(optionCount)").font(.system(.caption, design: .rounded).weight(.heavy))
                        .padding(8).background(Circle().fill(StudioStyle.color(part).opacity(0.35)))
                }
            }.padding(.horizontal, 14)
            if part == .paint { paintPanel }
            else {
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 12) {
                        if [.arms, .legs, .extras].contains(part) { attachmentPicker }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: part == .color || part == .accent ? 64 : 83), spacing: 10)], spacing: 12) {
                            ForEach(0..<optionCount, id: \.self) { index in option(index) }
                        }.padding(.horizontal, 12).padding(.vertical, 5)
                    }.padding(.bottom, 16)
                }.id(part)
            }
        }.padding(.top, 12).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 32).fill(Color.white.opacity(0.87)))
            .overlay(RoundedRectangle(cornerRadius: 32).stroke(StudioStyle.color(part).opacity(0.45), lineWidth: 3))
    }

    private var categorySample: FantasyFriend {
        var sample = friend
        sample.accessories = []; sample.placements = nil; sample.doodles = nil
        sample.color = 0; sample.accent = 3
        return sample
    }

    @ViewBuilder private func categoryDock(wide: Bool) -> some View {
        if wide {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 9) {
                ForEach(Part.allCases, id: \.rawValue) { item in categoryTile(item) }
            }.padding(.horizontal, 12)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(Part.allCases, id: \.rawValue) { item in categoryTile(item).frame(width: 75) }
                }.padding(.horizontal, 12).padding(.vertical, 5)
            }
        }
    }

    private func categoryTile(_ item: Part) -> some View {
        StudioCategoryTile(part: item, title: store.t(Words.partKeys[item.rawValue]), selected: item == part, sample: categorySample) {
            part = item; SoundService.shared.play(.click)
        }
    }

    private var paintPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 4), spacing: 12) {
                    ForEach(0..<16) { index in
                        Button { paintColor = index } label: {
                            Circle().fill(GameStyle.palette[index]).frame(width: 48, height: 48)
                                .overlay(Circle().stroke(paintColor == index ? GameStyle.ink : Color.white, lineWidth: 3))
                                .overlay(Group { if paintColor == index { Image(systemName: "checkmark").font(.headline).foregroundColor(GameStyle.ink) } })
                        }.buttonStyle(SquishStyle()).accessibilityLabel("\(store.t("color")) \(index + 1)")
                            .accessibilityAddTraits(paintColor == index ? .isSelected : [])
                    }
                }
                HStack(spacing: 14) {
                    ForEach([4.0, 9.0, 17.0], id: \.self) { width in
                        Button { brushWidth = width } label: {
                            Circle().fill(GameStyle.palette[paintColor]).frame(width: width + 8, height: width + 8)
                                .frame(width: 52, height: 52).background(Circle().fill(brushWidth == width ? StudioStyle.colors[0].opacity(0.5) : Color.white))
                                .overlay(Circle().stroke(brushWidth == width ? GameStyle.purple : .clear, lineWidth: 3))
                        }.buttonStyle(SquishStyle()).accessibilityLabel("\(store.t("brushSize")) \(Int(width))")
                            .accessibilityAddTraits(brushWidth == width ? .isSelected : [])
                    }
                }
                Button { change { $0.doodles = nil } } label: {
                    Label(store.t("clearPaint"), systemImage: "drop.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold)).padding(14)
                        .frame(maxWidth: .infinity).background(Capsule().fill(StudioStyle.colors[2].opacity(0.3)))
                }.buttonStyle(SquishStyle()).disabled(friend.doodles?.isEmpty ?? true)
            }.padding(14)
        }
    }

    private func undo() {
        guard let previous = history.popLast() else { return }
        future.append(friend); friend = previous; revision += 1
    }
    private func redo() {
        guard let next = future.popLast() else { return }
        history.append(friend); friend = next; revision += 1
    }

    private var celebrationView: some View {
        ZStack {
            Color.white.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("✦ ✧ ✦").font(.system(size: 42)).foregroundColor(.orange)
                LivingFriend(friend: friend, action: .hug, signal: 1).frame(height: 280)
                Text(store.t(existing ? "updated" : "created")).font(.system(.title, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                Text(friend.name).font(.system(.title2, design: .rounded)).foregroundColor(GameStyle.purple)
                CandyButton(title: store.t("continue"), icon: "checkmark") { presentation.wrappedValue.dismiss() }
            }.padding(30).frame(maxWidth: 500)
        }
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
        switch part { case .body, .arms, .legs: return 8; case .color, .accent: return 16; case .eyes: return 12; case .mouth: return 10; case .extras: return 15; case .paint: return 0 }
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
        case .paint: return false
        }
    }
    private func preview(_ index: Int) -> FantasyFriend {
        var value = friend
        value.placements = nil
        value.doodles = nil
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
        case .paint: break
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
        future.removeAll()
        friend = updated
        revision += 1
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
        let swatch = part == .color || part == .accent
        let tint = StudioStyle.color(part)
        return Button {
            if part != .extras || !friend.accessories.contains(index) { change { apply(index, to: &$0) } }
            if part == .extras { attachment = .extra(index) }
            else if part == .arms { attachment = .leftArm }
            else if part == .legs { attachment = .leftLeg }
        } label: {
            VStack(spacing: 3) {
                if swatch {
                    Circle().fill(GameStyle.palette[index]).frame(width: 52, height: 52)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(color: GameStyle.palette[index].opacity(0.4), radius: 0, y: 4)
                } else {
                    CharacterView(friend: preview(index), piece: thumbnailAttachment(index), detail: part == .eyes || part == .mouth ? part : nil)
                        .frame(height: 75)
                }
                HStack(spacing: 3) {
                    if selected(index) { Image(systemName: "checkmark.circle.fill").foregroundColor(GameStyle.purple) }
                    if part == .body || part == .extras { Text(label).lineLimit(1).minimumScaleFactor(0.7) }
                }.font(.system(size: 10, weight: .heavy, design: .rounded)).frame(height: 16)
            }
            .foregroundColor(GameStyle.ink).padding(7).frame(maxWidth: .infinity).frame(height: swatch ? 89 : 114)
            .background(RoundedRectangle(cornerRadius: 25).fill(tint.opacity(selected(index) ? 0.35 : 0.13)))
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(selected(index) ? GameStyle.purple : Color.white, lineWidth: selected(index) ? 3 : 2))
            .rotationEffect(.degrees(selected(index) ? (index.isMultiple(of: 2) ? -2 : 2) : 0))
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
