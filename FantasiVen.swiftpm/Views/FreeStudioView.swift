import SwiftUI
import UniformTypeIdentifiers

struct FreeStudioView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @Binding var friend: FantasyFriend
    @State private var showHelp=false
    @State private var selected: UUID?
    @State private var kind = PieceKind.eye
    @State private var variant = 0
    @State private var pending = true
    @State private var snap = false
    @State private var reaction = 0
    @State private var localHistory: [FantasyFriend] = []
    @State private var moving: CreativePiece?
    @State private var shapeBefore: FantasyFriend?
    private var pieces: [CreativePiece] { friend.pieces ?? [] }
    private var selectedPiece: CreativePiece? { pieces.first { $0.id == selected } }
    private var count: Int { kind == .extra ? 15 : kind == .eye ? 12 : 8 }

    var body: some View {
        ZStack {
            StudioBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        Text(store.t("freeStudio")).font(.system(.title2, design: .rounded).weight(.heavy))
                        Spacer()
                        RoundButton(icon: "arrow.uturn.backward", label: store.t("undo")) {
                            if let old = localHistory.popLast() { friend = old }
                        }.disabled(localHistory.isEmpty)
                        RoundButton(icon: "hand.draw.fill", label: store.t("help")) { showHelp=true }
                        RoundButton(icon: "checkmark", label: store.t("done")) { presentation.wrappedValue.dismiss() }
                    }
                    Text(store.t(pending ? "tapPlace" : "freeHint")).font(.system(.subheadline, design: .rounded).weight(.bold)).multilineTextAlignment(.center)
                    stage.frame(height: 360).overlay(StudioBurst(revision: reaction)).overlay(TouchDemonstration(activity: reaction))
                    if selectedPiece != nil { pieceTools }
                    HStack {
                        ForEach(PieceKind.allCases) { item in
                            Button { kind = item; variant = 0; pending = true } label: {
                                Text(store.t(item.key)).font(.system(.caption, design: .rounded).weight(.heavy))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(CandySurface(color: kind == item ? StudioStyle.colors[0] : .white, cornerRadius: 18))
                                    .contentShape(Rectangle())
                            }.buttonStyle(SquishStyle())
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<count, id: \.self) { index in
                                let value = CreativePiece(kind: kind, variant: index, color: friend.color, accent: friend.accent)
                                Button { variant = index; pending = true } label: {
                                    CreativePieceView(piece: value).frame(width: 66, height: 70).padding(5)
                                        .background(CandySurface(color: variant == index ? StudioStyle.colors[2] : .white, cornerRadius: 20))
                                        .contentShape(Rectangle())
                                }.buttonStyle(SquishStyle())
                                    .accessibilityLabel(store.t(kind.key) + " \(index + 1)")
                                    .onDrag { variant = index; pending = true; return NSItemProvider(object: "fantasiven-piece" as NSString) }
                            }
                        }.padding(6)
                    }
                    Toggle(store.t("snapHelp"), isOn: $snap).font(.system(.subheadline, design: .rounded).weight(.bold))
                    bodyTools
                    personalityTools
                    HStack(spacing: 10) {
                        ForEach(0..<4) { template in
                            Button { applyTemplate(template) } label: {
                                Text(["🟣", "🥚", "☁️", "🧸"][template]).font(.system(size: 32))
                                    .frame(maxWidth: .infinity, minHeight: 60).background(CandySurface(color: .white, cornerRadius: 20)).contentShape(Rectangle())
                            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("startShape") + " \(template + 1)")
                        }
                    }
                }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
            }
        }.foregroundColor(GameStyle.ink)
            .sheet(isPresented:$showHelp) {
                VStack(spacing:20) {
                    HStack {
                        Text(store.t("help")).font(.system(.title2,design:.rounded).weight(.heavy))
                        Spacer()
                        RoundButton(icon:"xmark",label:store.t("close")) {showHelp=false}
                    }
                    CharacterView(friend:friend).frame(height:220)
                        .overlay(TouchDemonstration(activity:0))
                    Text(store.t("tapPlace")).font(.system(.title3,design:.rounded).weight(.bold))
                        .multilineTextAlignment(.center)
                    CandyButton(title:store.t("done"),icon:"checkmark") {showHelp=false}
                }.padding(28).background(StorybookShelf())
            }
    }

    private var stage: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width, proxy.size.height * 300 / 320)
            let height = width * 320 / 300
            ZStack {
                RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.86))
                CharacterView(friend: shownFriend, happy: false)
                    .allowsHitTesting(false)
                ForEach(pieces) { piece in
                    Color.clear.frame(width: 60, height: 60)
                        .background(selected == piece.id ? Color.white.opacity(0.15) : .clear)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected == piece.id ? GameStyle.purple : .clear, style: StrokeStyle(lineWidth: 3, dash: [5, 3])))
                        .contentShape(Rectangle())
                        .position(x: (moving?.id == piece.id ? moving!.x : piece.x) * width, y: (moving?.id == piece.id ? moving!.y : piece.y) * height)
                        .highPriorityGesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("sculpt"))
                            .onChanged { value in
                                selected = piece.id; pending = false
                                var copy = piece
                                copy.move(x: value.location.x / width, y: (value.location.y - (reducedMotion ? 0 : 18)) / height, snap: snap)
                                moving = copy
                            }
                            .onEnded { value in
                                defer { moving = nil }
                                selected = piece.id; pending = false
                                if hypot(value.translation.width, value.translation.height) > 4, let moved = moving {
                                    updatePiece(moved)
                                }
                            })
                        .accessibilityLabel(store.t(piece.kind.key))
                }
                stretchHandle(horizontal: true, width: width, height: height)
                stretchHandle(horizontal: false, width: width, height: height)
            }.frame(width: width, height: height).coordinateSpace(name: "sculpt").contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { value in
                    guard pending, hypot(value.translation.width, value.translation.height) < 12 else { return }
                    add(at: value.location, width: width, height: height)
                })
                .onDrop(of: [UTType.text.identifier], isTargeted: nil) { _, point in
                    add(at: point, width: width, height: height); return true
                }
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
    private var shownFriend: FantasyFriend {
        var copy = friend
        if let moving = moving, let i = copy.pieces?.firstIndex(where: { $0.id == moving.id }) { copy.pieces?[i] = moving }
        return copy
    }
    private func stretchHandle(horizontal: Bool, width: CGFloat, height: CGFloat) -> some View {
        Image(systemName: horizontal ? "arrow.left.and.right" : "arrow.up.and.down")
            .font(.system(size: 18, weight: .heavy)).frame(width: 44, height: 44).background(Circle().fill(StudioStyle.colors[0]))
            .position(x: horizontal ? width * 0.86 : width * 0.5, y: horizontal ? height * 0.55 : height * 0.88)
            .gesture(DragGesture(coordinateSpace: .named("sculpt")).onChanged { value in
                if shapeBefore == nil { shapeBefore = friend }
                var copy = friend
                if horizontal { copy.bodyWidth = min(1.2, max(0.75, abs(value.location.x / width - 0.5) / 0.3)) }
                else { copy.bodyHeight = min(1.2, max(0.75, abs(value.location.y / height - 0.53) / 0.3)) }
                friend = copy
            }.onEnded { _ in
                finishShape()
            })
            .accessibilityLabel(store.t(horizontal ? "bodyWidth" : "bodyHeight"))
    }
    private var pieceTools: some View {
        VStack(spacing: 12) {
            HStack {
                tool("plus.square.on.square", "copyPiece") { piece in
                    guard pieces.count < 64 else { return }
                    var copy = piece; copy.id = UUID(); copy.move(x: piece.x + 0.08, y: piece.y + 0.05, snap: snap)
                    var value = friend; value.pieces = pieces + [copy]; commit(value); selected = copy.id
                }
                tool("arrow.left.and.right.righttriangle.left.righttriangle.right", "mirror") { var p = $0; p.mirrored.toggle(); updatePiece(p) }
                tool("rotate.left", "rotateLeft") { var p = $0; p.rotation = p.rotation <= -180 ? 165 : p.rotation - 15; updatePiece(p) }
                tool("plus.magnifyingglass", "bigger") { var p = $0; p.scale = p.scale >= 1.5 ? 0.5 : min(1.5, p.scale + 0.1); updatePiece(p) }
                tool("trash", "removePart") { piece in
                    var copy = friend; copy.pieces = pieces.filter { $0.id != piece.id }; commit(copy); selected = nil
                }
            }
            ForEach(0..<2) { channel in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<16) { color in
                            Button {
                                guard var p = selectedPiece else { return }
                                if channel == 0 { p.color = color } else { p.accent = color }; updatePiece(p)
                            } label: {
                                Circle().fill(GameStyle.palette[color]).frame(width: 38, height: 38).padding(4)
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }.accessibilityLabel(store.t(channel == 0 ? "color" : "accent") + " \(color + 1)")
                        }
                    }
                }
            }
        }
    }
    private func tool(_ icon: String, _ key: String, action: @escaping (CreativePiece) -> Void) -> some View {
        RoundButton(icon: icon, label: store.t(key)) { if let p = selectedPiece { action(p) } }
    }
    private var bodyTools: some View {
        VStack(alignment: .leading) {
            Text(store.t("bodyWidth")).font(.headline)
            bodySlider(horizontal: true)
            Text(store.t("bodyHeight")).font(.headline)
            bodySlider(horizontal: false)
        }.padding().background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.9)))
    }
    private func bodySlider(horizontal: Bool) -> some View {
        Slider(value: Binding(get: { horizontal ? friend.widthFactor : friend.heightFactor }, set: { value in
            if shapeBefore == nil { shapeBefore = friend }
            var copy = friend
            if horizontal { copy.bodyWidth = value } else { copy.bodyHeight = value }
            friend = copy
        }), in: 0.75...1.2, onEditingChanged: { editing in if !editing { finishShape() } })
    }
    private func finishShape() {
        if let previous = shapeBefore {
            localHistory.append(previous)
            if localHistory.count > 40 { localHistory.removeFirst() }
        }
        shapeBefore = nil; reaction += 1
        SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
    }
    private var personalityTools: some View {
        VStack(spacing: 12) {
            Text(store.t("personality")).font(.system(.title3, design: .rounded).weight(.heavy))
            HStack {
                ForEach(VoiceKind.allCases, id: \.rawValue) { voice in
                    Button {
                        var copy = friend; copy.voice = voice; commit(copy)
                        SoundService.shared.react(voice: voice.rawValue)
                    } label: {
                        Text(store.t("voice_\(voice.rawValue)")).font(.system(.caption, design: .rounded).weight(.heavy))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(CandySurface(color: friend.voice == voice ? StudioStyle.colors[1] : .white, cornerRadius: 18)).contentShape(Rectangle())
                    }.buttonStyle(SquishStyle())
                }
            }
            HStack {
                ForEach(GaitKind.allCases, id: \.rawValue) { gait in
                    Button { var copy = friend; copy.gait = gait; commit(copy) } label: {
                        Text(store.t("gait_\(gait.rawValue)")).font(.system(.caption, design: .rounded).weight(.heavy))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(CandySurface(color: friend.gait == gait ? StudioStyle.colors[2] : .white, cornerRadius: 18)).contentShape(Rectangle())
                    }.buttonStyle(SquishStyle())
                }
            }
            LivingFriend(friend: friend, action: .dance, signal: reaction).frame(height: 125)
        }
    }
    private func add(at point: CGPoint, width: CGFloat, height: CGFloat) {
        guard pieces.count < 64 else { return }
        var piece = CreativePiece(kind: kind, variant: variant, color: friend.color, accent: friend.accent)
        piece.move(x: point.x / max(1, width), y: point.y / max(1, height), snap: snap)
        var copy = friend; copy.pieces = pieces + [piece]; commit(copy)
        selected = piece.id; pending = false
    }
    private func updatePiece(_ piece: CreativePiece) {
        var copy = friend
        guard let index = copy.pieces?.firstIndex(where: { $0.id == piece.id }) else { return }
        copy.pieces?[index] = piece; commit(copy)
    }
    private func commit(_ copy: FantasyFriend) {
        guard copy != friend else { return }
        localHistory.append(friend); if localHistory.count > 40 { localHistory.removeFirst() }
        friend = copy; reaction += 1
        SoundService.shared.react(voice: friend.voice?.rawValue ?? 0)
    }
    private func applyTemplate(_ index: Int) {
        var copy = friend
        copy.body = [BodyKind.round, .oval, .cloud, .chubby][index]
        copy.pieces = nil; copy.doodles = nil; copy.placements = nil; copy.partColors = nil
        copy.accessories = index == 3 ? [1, 6] : []
        copy.eyes = index == 1 ? 1 : index == 2 ? 3 : 0; copy.mouth = 0
        selected = nil; pending = true
        copy.bodyWidth = nil; copy.bodyHeight = nil
        commit(copy)
    }
}
