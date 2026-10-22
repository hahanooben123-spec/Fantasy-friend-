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
    var onMove: (Attachment, PartPlacement) -> Void
    var onDropPart: (PartDragChoice, CGPoint, CGSize) -> Void
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
        guard let drag = drag else { return friend }
        var result = friend
        result.setPlacement(AttachmentLayout.moved(drag.attachment, in: friend, by: drag.translation, stageSize: size), for: drag.attachment)
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
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(targeted ? 0.55 : 0.16))
                .overlay(RoundedRectangle(cornerRadius: 32)
                    .stroke(GameStyle.purple.opacity(targeted ? 0.85 : 0.18), style: StrokeStyle(lineWidth: targeted ? 3 : 1, dash: [7, 7])))
            CharacterView(friend: shown).allowsHitTesting(false)
            if let selection = selection, AttachmentLayout.attachments(in: friend).contains(selection) {
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
            .updating($drag) { value, state, _ in
                if let attachment = state?.attachment ?? hit(value.startLocation, size: size) {
                    state = WorkshopDrag(attachment: attachment, translation: value.translation)
                }
            }
            .onChanged { value in
                if let attachment = drag?.attachment ?? hit(value.startLocation, size: size) { selection = attachment }
            }
            .onEnded { value in
                guard let attachment = drag?.attachment ?? hit(value.startLocation, size: size) else { return }
                selection = attachment
                guard hypot(value.translation.width, value.translation.height) > 2 else { return }
                onMove(attachment, AttachmentLayout.moved(attachment, in: friend, by: value.translation, stageSize: size))
            })
        .onDrop(of: [PartDragChoice.contentType.identifier], isTargeted: $targeted) { providers, point in
            guard !providers.isEmpty, let choice = draggedChoice else { return false }
            onDropPart(choice, point, size)
            draggedChoice = nil
            return true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.t("workshop"))
        .accessibilityHint(store.t("dragHint"))
    }
}
