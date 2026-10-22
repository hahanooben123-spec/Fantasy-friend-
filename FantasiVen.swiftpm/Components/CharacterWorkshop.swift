import SwiftUI
import UniformTypeIdentifiers

struct PartDragChoice {
    let category: Part
    let index: Int
    static let contentType = UTType(exportedAs: "dk.fantasiven.character-part")

    func provider() -> NSItemProvider {
        let data = Data("\(category.rawValue):\(index)".utf8)
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: Self.contentType.identifier, visibility: .ownProcess) { completion in
            completion(data, nil)
            return nil
        }
        return provider
    }

    func attachment(at point: CGPoint, stageSize: CGSize) -> Attachment {
        switch category {
        case .arms: return point.x < stageSize.width / 2 ? .leftArm : .rightArm
        case .legs: return point.x < stageSize.width / 2 ? .leftLeg : .rightLeg
        default: return .extra(index)
        }
    }
}

private struct WorkshopDrag {
    let attachment: Attachment
    let translation: CGSize
}

struct CharacterWorkshop: View {
    @EnvironmentObject private var store: FriendStore
    let friend: FantasyFriend
    let category: Part
    @Binding var selection: Attachment?
    @Binding var draggedChoice: PartDragChoice?
    var paintTool: PaintTool? = nil
    var onMove: (Attachment, PartPlacement) -> Void
    var onDropPart: (PartDragChoice, CGPoint, CGSize) -> Void
    var onPaint: (DoodleStroke) -> Void
    @State private var draftStroke: DoodleStroke?
    @GestureState private var touching = false
    @GestureState private var drag: WorkshopDrag?
    @State private var targeted = false

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, min(geometry.size.width - 24, geometry.size.height * 300 / 320))
            let size = CGSize(width: width, height: width * 320 / 300)
            stage(size: size)
                .frame(width: size.width, height: size.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private func preview(size: CGSize) -> FantasyFriend {
        var result = friend
        if let draftStroke = draftStroke {
            var strokes = result.doodles ?? []; strokes.append(draftStroke); result.doodles = strokes
        }
        if let drag = drag {
            result.setPlacement(AttachmentLayout.moved(drag.attachment, in: friend, by: drag.translation, stageSize: size), for: drag.attachment)
        }
        return result
    }

    private func hit(_ point: CGPoint, size: CGSize) -> Attachment? {
        let point = CGPoint(x: point.x / size.width * 300, y: point.y / size.height * 320)
        let all = AttachmentLayout.attachments(in: friend)
        func contains(_ attachment: Attachment) -> Bool {
            let rect = AttachmentLayout.visualBounds(for: attachment, friend: friend)
            // At least a 48 pt touch target even for freckles and short limbs.
            let marginX = max(8, (48 * 300 / size.width - rect.width) / 2)
            let marginY = max(8, (48 * 320 / size.height - rect.height) / 2)
            return rect.insetBy(dx: -marginX, dy: -marginY).contains(point)
        }
        if let selection = selection, all.contains(selection), contains(selection) { return selection }
        let matches = all.filter(contains)
        let preferred = matches.filter { $0.category == category }
        return (preferred.isEmpty ? matches : preferred).min {
            let a = AttachmentLayout.center(for: $0, friend: friend)
            let b = AttachmentLayout.center(for: $1, friend: friend)
            return hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
        }
    }

    private func stage(size: CGSize) -> some View {
        let shown = preview(size: size)
        return ZStack {
            RoundedRectangle(cornerRadius: 36)
                .fill(LinearGradient(colors: [Color.white.opacity(0.85), StudioStyle.color(category).opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 36).stroke(targeted ? GameStyle.purple : .clear, lineWidth: 4))
            Ellipse().fill(StudioStyle.color(category).opacity(0.23))
                .frame(width: size.width * 0.55, height: size.height * 0.05)
                .position(x: size.width * 0.5, y: size.height * 0.92).allowsHitTesting(false)
            CharacterView(friend: shown).allowsHitTesting(false)
            if paintTool == nil, let selection = selection, AttachmentLayout.attachments(in: friend).contains(selection) {
                let rect = AttachmentLayout.visualBounds(for: selection, friend: shown)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(GameStyle.purple, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .frame(width: max(30, rect.width * size.width / 300 + 8),
                           height: max(30, rect.height * size.height / 320 + 8))
                    .position(x: rect.midX * size.width / 300, y: rect.midY * size.height / 320)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .updating($drag) { value, state, _ in
                guard paintTool == nil else { return }
                if let attachment = state?.attachment ?? hit(value.startLocation, size: size) {
                    state = WorkshopDrag(attachment: attachment, translation: value.translation)
                }
            }
            .onChanged { value in
                if let tool = paintTool {
                    appendPaint(value.location, start: value.startLocation, tool: tool, size: size)
                    return
                }
                if let attachment = drag?.attachment ?? hit(value.startLocation, size: size) { selection = attachment }
            }
            .onEnded { value in
                if let tool = paintTool {
                    appendPaint(value.location, start: value.startLocation, tool: tool, size: size)
                    if let stroke = draftStroke, stroke.isValid { onPaint(stroke) }
                    draftStroke = nil
                    return
                }
                guard let attachment = drag?.attachment ?? hit(value.startLocation, size: size) else { return }
                selection = attachment
                guard hypot(value.translation.width, value.translation.height) > 2 else { return }
                onMove(attachment, AttachmentLayout.moved(attachment, in: friend, by: value.translation, stageSize: size))
            })
        .onChange(of: touching) { active in if !active { draftStroke = nil } }
        .onChange(of: paintTool) { _ in draftStroke = nil }
        .onDisappear { draftStroke = nil }
        .onDrop(of: [PartDragChoice.contentType.identifier], isTargeted: $targeted) { providers, point in
            guard !providers.isEmpty, let choice = draggedChoice else { return false }
            onDropPart(choice, point, size)
            draggedChoice = nil
            return true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.t("workshop"))
        .accessibilityHint(store.t(paintTool == nil ? "dragHint" : "paintHint"))
    }

    private func appendPaint(_ point: CGPoint, start: CGPoint, tool: PaintTool, size: CGSize) {
        func normalized(_ value: CGPoint) -> DoodlePoint {
            DoodlePoint(x: min(1, max(0, Double(value.x / size.width))),
                        y: min(1, max(0, Double(value.y / size.height))))
        }
        var stroke = draftStroke ?? DoodleStroke(points: [normalized(start)], color: tool.color, width: tool.width)
        let next = normalized(point)
        if let last = stroke.points.last, hypot(last.x - next.x, last.y - next.y) > 0.005 {
            if stroke.points.count >= 600 { stroke.points = stroke.points.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element) }
            stroke.points.append(next)
        }
        draftStroke = stroke
    }
}
