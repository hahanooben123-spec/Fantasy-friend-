import SwiftUI

struct FriendRoomView: View {
    @EnvironmentObject private var store: FriendStore
    let friendID: UUID
    @State private var moving: RoomObject?
    @State private var selected: UUID?
    @State private var history: [[RoomObject]] = []
    @State private var friendPoint = CGPoint(x: 0.52, y: 0.72)
    @State private var lit = true
    private var friend: FantasyFriend? { store.friends.first { $0.id == friendID } }

    var body: some View {
        ZStack {
            WorldBackdrop(world: .castle)
            VStack(spacing: 12) {
                AdventureHeading(title: store.t("myRoom"), subtitle: store.t("roomHint"))
                if let friend = friend {
                    ScrollView {
                        VStack(spacing: 18) {
                            GeometryReader { proxy in
                                let size = proxy.size
                                ZStack {
                                    LinearGradient(colors: [GameStyle.palette[friend.accent], .white], startPoint: .top, endPoint: .bottom)
                                    Rectangle().fill(Color(red: 0.85, green: 0.61, blue: 0.34)).frame(height: size.height * 0.35).position(x: size.width / 2, y: size.height * 0.825)
                                    ForEach(friend.room ?? []) { object in
                                        let shown = moving?.id == object.id ? moving! : object
                                        RoomFurniture(kind: object.kind)
                                            .frame(width: 95, height: 110)
                                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected == object.id ? Color.white : .clear, lineWidth: 3))
                                            .contentShape(Rectangle())
                                            .position(x: shown.x * size.width, y: shown.y * size.height)
                                            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("room")).onChanged { value in
                                                selected = object.id
                                                var copy = object
                                                copy.x = min(0.9, max(0.1, value.location.x / size.width))
                                                copy.y = min(0.9, max(0.2, value.location.y / size.height))
                                                moving = copy
                                            }.onEnded { value in
                                                defer { moving = nil }
                                                if hypot(value.translation.width, value.translation.height) < 5, object.kind == 2 { lit.toggle(); SoundService.shared.play(.click) }
                                                guard let moved = moving, let index = friend.room?.firstIndex(where: { $0.id == object.id }) else { return }
                                                var objects = friend.room ?? []; objects[index] = moved; save(objects)
                                            })
                                            .accessibilityLabel(store.t("furniture_\(object.kind)"))
                                    }
                                    LivingFriend(friend: friend).frame(width: 145, height: 155)
                                        .position(x: friendPoint.x * size.width, y: friendPoint.y * size.height)
                                        .simultaneousGesture(DragGesture(coordinateSpace: .named("room")).onChanged { value in
                                            friendPoint = CGPoint(x: min(0.85, max(0.15, value.location.x / size.width)), y: min(0.85, max(0.25, value.location.y / size.height)))
                                        })
                                    if !lit { Color.indigo.opacity(0.35).allowsHitTesting(false) }
                                }.coordinateSpace(name: "room").clipShape(RoundedRectangle(cornerRadius: 32))
                            }.frame(height: 430)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<6) { kind in
                                        Button {
                                            var objects = friend.room ?? []
                                            guard objects.count < 32 else { return }
                                            let object = RoomObject(kind: kind, x: 0.3 + Double(objects.count % 3) * 0.2, y: 0.55)
                                            objects.append(object); save(objects); selected = object.id
                                        } label: {
                                            VStack {
                                                RoomFurniture(kind: kind).frame(width: 65, height: 70)
                                                Text(store.t("furniture_\(kind)")).font(.system(.caption, design: .rounded).weight(.bold))
                                            }.frame(width: 100, height: 110).background(CandySurface(color: .white, cornerRadius: 24)).contentShape(Rectangle())
                                        }.buttonStyle(SquishStyle())
                                    }
                                }.padding(6)
                            }
                            HStack {
                                RoundButton(icon: "arrow.uturn.backward", label: store.t("undo")) {
                                    if let previous = history.popLast() { var copy = friend; copy.room = previous; store.save(copy) }
                                }.disabled(history.isEmpty)
                                RoundButton(icon: "trash", label: store.t("removePart")) {
                                    save((friend.room ?? []).filter { $0.id != selected }); selected = nil
                                }.disabled(selected == nil)
                            }
                        }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
                    }
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
            .alert(store.t("error"), isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
    }
    private func save(_ objects: [RoomObject]) {
        guard var copy = friend else { return }
        let old = copy.room ?? []; copy.room = objects
        if store.save(copy) { history.append(old); if history.count > 40 { history.removeFirst() }; SoundService.shared.play(.click) }
    }
}

struct RoomFurniture: View {
    let kind: Int
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 100, y: size.height / 110)
            func box(_ r: CGRect, _ c: Color, _ radius: CGFloat = 8) {
                let p = Path(roundedRect: r, cornerRadius: radius)
                context.fill(p, with: .color(c)); context.stroke(p, with: .color(GameStyle.ink), lineWidth: 2)
            }
            switch kind {
            case 0:
                box(CGRect(x: 7, y: 49, width: 86, height: 43), StudioStyle.colors[3])
                box(CGRect(x: 11, y: 39, width: 78, height: 22), StudioStyle.colors[1])
                box(CGRect(x: 14, y: 35, width: 27, height: 18), .white)
                box(CGRect(x: 12, y: 88, width: 9, height: 14), GameStyle.ink)
                box(CGRect(x: 79, y: 88, width: 9, height: 14), GameStyle.ink)
            case 1:
                box(CGRect(x: 30, y: 66, width: 40, height: 32), StudioStyle.colors[4])
                for i in 0..<5 {
                    let r = CGRect(x: 23 + i % 3 * 12, y: 22 + i / 3 * 22, width: 29, height: 40)
                    context.fill(Path(ellipseIn: r), with: .color(StudioStyle.colors[6]))
                }
            case 2:
                box(CGRect(x: 45, y: 37, width: 10, height: 57), StudioStyle.colors[4])
                box(CGRect(x: 23, y: 16, width: 54, height: 39), StudioStyle.colors[0], 16)
                box(CGRect(x: 28, y: 92, width: 44, height: 8), GameStyle.purple)
            case 3:
                box(CGRect(x: 12, y: 14, width: 76, height: 85), StudioStyle.colors[4])
                for i in 0..<3 {
                    box(CGRect(x: 17, y: 20 + i * 25, width: 66, height: 19), GameStyle.palette[15], 2)
                    for j in 0..<4 { box(CGRect(x: 23 + j * 13, y: 22 + i * 25, width: 9, height: 16), StudioStyle.colors[(i+j)%9], 2) }
                }
            case 4:
                let rug = Path(ellipseIn: CGRect(x: 5, y: 45, width: 90, height: 45))
                context.fill(rug, with: .color(StudioStyle.colors[1]))
                context.stroke(rug, with: .color(.white), lineWidth: 5)
            default:
                box(CGRect(x: 12, y: 11, width: 76, height: 83), .white)
                box(CGRect(x: 19, y: 18, width: 62, height: 69), StudioStyle.colors[5])
                box(CGRect(x: 47, y: 18, width: 6, height: 69), .white, 0)
                box(CGRect(x: 19, y: 50, width: 62, height: 6), .white, 0)
            }
        }.accessibilityHidden(true)
    }
}
