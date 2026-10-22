import XCTest
@testable import FantasiVen

final class FantasiVenTests: XCTestCase {
    func testAllRandomFriendsCanRoundTrip() throws {
        for _ in 0..<500 {
            let friend = FantasyFriend.random()
            XCTAssertTrue(friend.isValid)
            let data = try JSONEncoder().encode(friend)
            XCTAssertEqual(friend, try JSONDecoder().decode(FantasyFriend.self, from: data))
        }
    }

    @MainActor
    func testSaveEditReloadAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FriendStore(directory: directory)
        var friend = FantasyFriend.random(); friend.name = "Bimse"
        XCTAssertTrue(store.save(friend))
        friend.name = "Pjuske"; friend.accessories = [0, 3, 8]
        friend.setPlacement(PartPlacement(x: 0.1, y: -0.1, rotation: 30, scale: 0.9), for: .crown)
        XCTAssertTrue(store.save(friend))
        let reloaded = FriendStore(directory: directory)
        XCTAssertEqual(reloaded.friends, [friend])
        XCTAssertTrue(reloaded.delete(friend))
        XCTAssertTrue(FriendStore(directory: directory).friends.isEmpty)
    }

    @MainActor
    func testCorruptCollectionIsPreserved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = Data("broken archive".utf8)
        let file = directory.appendingPathComponent("friends.json")
        try original.write(to: file)
        let store = FriendStore(directory: directory)
        XCTAssertNotNil(store.error)
        XCTAssertFalse(store.save(FantasyFriend()))
        XCTAssertEqual(try Data(contentsOf: file), original)
    }

    @MainActor
    func testWriteFailureDoesNotCommitInMemory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not a directory".utf8).write(to: directory)
        let store = FriendStore(directory: directory)
        XCTAssertFalse(store.save(FantasyFriend()))
        XCTAssertTrue(store.friends.isEmpty)
        XCTAssertNotNil(store.error)
    }

    @MainActor
    func testSettingsPersistAndInvalidPartsAreRejected() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FriendStore(directory: directory)
        store.updateSettings { $0.language = .en; $0.sound = false }
        let reloaded = FriendStore(directory: directory)
        XCTAssertEqual(reloaded.settings.language, .en)
        XCTAssertFalse(reloaded.settings.sound)
        var friend = FantasyFriend(); friend.eyes = 99
        XCTAssertFalse(store.save(friend))
        XCTAssertTrue(store.friends.isEmpty)
    }

    func testFriendsFromBeforeFreePlacementStillDecode() throws {
        let friend = FantasyFriend()
        let data = try JSONEncoder().encode(friend)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "placements")
        let decoded = try JSONDecoder().decode(FantasyFriend.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.placements)
        XCTAssertEqual(decoded.placement(for: .leftArm), PartPlacement())
        XCTAssertTrue(decoded.isValid)
    }

    func testEachLimbAndAccessoryHasIndependentPlacement() throws {
        var friend = FantasyFriend()
        friend.setPlacement(PartPlacement(x: -0.1, y: 0.03, rotation: -30, scale: 0.8), for: .leftArm)
        friend.setPlacement(PartPlacement(x: 0.1, y: -0.04, rotation: 45, scale: 1.1), for: .hat)
        let restored = try JSONDecoder().decode(FantasyFriend.self, from: JSONEncoder().encode(friend))
        XCTAssertEqual(restored, friend)
        XCTAssertEqual(restored.placement(for: .rightArm), PartPlacement())
        friend.setPlacement(PartPlacement(), for: .leftArm)
        XCTAssertNotNil(friend.placements?["hat"])
        XCTAssertNil(friend.placements?["leftArm"])
    }

    func testMovementIsIndependentOfDeviceSize() {
        let friend = FantasyFriend()
        let small = AttachmentLayout.moved(.leftArm, in: friend, by: CGSize(width: 20, height: -10), stageSize: CGSize(width: 300, height: 320))
        let large = AttachmentLayout.moved(.leftArm, in: friend, by: CGSize(width: 40, height: -20), stageSize: CGSize(width: 600, height: 640))
        XCTAssertEqual(small, large)
        XCTAssertEqual(small.x, 20.0 / 300, accuracy: 0.0001)
    }

    func testRotatedAndScaledPartsStayInsideDrawing() {
        for body in BodyKind.allCases {
            var friend = FantasyFriend(); friend.body = body
            for attachment in Attachment.allCases {
                for angle in stride(from: -180.0, through: 180, by: 30) {
                    let proposed = PartPlacement(x: 0.9, y: -0.9, rotation: angle, scale: 1.5)
                    let pose = AttachmentLayout.constrained(proposed, for: attachment, friend: friend)
                    XCTAssertTrue(pose.isValid)
                    friend.setPlacement(pose, for: attachment)
                    let bounds = AttachmentLayout.visualBounds(for: attachment, friend: friend)
                    XCTAssertGreaterThanOrEqual(bounds.minX, 5.99)
                    XCTAssertGreaterThanOrEqual(bounds.minY, 5.99)
                    XCTAssertLessThanOrEqual(bounds.maxX, 294.01)
                    XCTAssertLessThanOrEqual(bounds.maxY, 314.01)
                }
            }
        }
    }

    func testDropPlacesTheChosenPartAtFinger() {
        let friend = FantasyFriend()
        let pose = AttachmentLayout.placed(.hat, in: friend, at: CGPoint(x: 150, y: 100), stageSize: CGSize(width: 300, height: 320))
        var changed = friend; changed.setPlacement(pose, for: .hat)
        let center = AttachmentLayout.center(for: .hat, friend: changed)
        XCTAssertEqual(center.x, 150, accuracy: 0.001)
        XCTAssertEqual(center.y, 100, accuracy: 0.001)
    }

    func testInvalidPlacementsAreRejected() {
        var friend = FantasyFriend()
        friend.placements = ["unknownPart": PartPlacement()]
        XCTAssertFalse(friend.isValid)
        friend.placements = ["hat": PartPlacement(x: .infinity)]
        XCTAssertFalse(friend.isValid)
        friend.placements = ["hat": PartPlacement(scale: 4)]
        XCTAssertFalse(friend.isValid)
    }

    @MainActor
    func testReducedMotionRagdollCanBeMovedAndPaused() {
        var friend = FantasyFriend()
        friend.setPlacement(PartPlacement(x: 0.03, y: 0.02, rotation: 30, scale: 0.9), for: .leftArm)
        let simulation = RagdollSimulation()
        simulation.configure(friend, reducedMotion: true)
        simulation.beginDrag(at: CGPoint(x: 300, y: 235))
        XCTAssertTrue(simulation.isDragging)
        simulation.moveDrag(to: CGPoint(x: 340, y: 265))
        simulation.refresh()
        XCTAssertEqual(simulation.frame.position.x, 340, accuracy: 0.001)
        XCTAssertEqual(simulation.frame.position.y, 265, accuracy: 0.001)
        XCTAssertEqual(simulation.frame.friend.placement(for: .leftArm).x, 0.03, accuracy: 0.001)
        XCTAssertEqual(simulation.frame.friend.placement(for: .leftArm).rotation, 30, accuracy: 0.001)
        simulation.setActive(false)
        XCTAssertTrue(simulation.scene.isPaused)
        XCTAssertFalse(simulation.isDragging)
    }

    @MainActor
    func testRagdollResetReplacesBodiesAndPreservesSavedFriend() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FriendStore(directory: directory)
        var friend = FantasyFriend(); friend.name = "Zippi"
        friend.setPlacement(PartPlacement(x: 0.1, rotation: 45), for: .hat)
        XCTAssertTrue(store.save(friend))
        let simulation = RagdollSimulation()
        simulation.configure(friend, reducedMotion: false)
        simulation.beginDrag(at: CGPoint(x: 300, y: 235))
        XCTAssertTrue(simulation.isDragging)
        simulation.react(.dance)
        simulation.configure(friend, reducedMotion: false)
        XCTAssertFalse(simulation.isDragging)
        XCTAssertEqual(simulation.scene.children.count, 6)
        XCTAssertEqual(FriendStore(directory: directory).friends, [friend])
        XCTAssertEqual(simulation.frame.friend.placement(for: .hat), friend.placement(for: .hat))
        simulation.setActive(false)
    }

    func testPaintRoundTripsAndOldFriendsHaveBlankCanvas() throws {
        var friend = FantasyFriend()
        let old = try JSONDecoder().decode(FantasyFriend.self, from: JSONEncoder().encode(friend))
        XCTAssertNil(old.doodles)
        friend.doodles = [DoodleStroke(points: [DoodlePoint(x: 0.3, y: 0.4), DoodlePoint(x: 0.6, y: 0.7)], color: 4, width: 9)]
        XCTAssertTrue(friend.isValid)
        let restored = try JSONDecoder().decode(FantasyFriend.self, from: JSONEncoder().encode(friend))
        XCTAssertEqual(restored, friend)
        friend.doodles = [DoodleStroke(points: [DoodlePoint(x: -0.1, y: 0.5)], color: 4, width: 9)]
        XCTAssertFalse(friend.isValid)
    }

    @MainActor
    func testPaintPersistsThroughSaveAndReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FriendStore(directory: directory)
        var friend = FantasyFriend()
        friend.doodles = [DoodleStroke(points: [DoodlePoint(x: 0.5, y: 0.6)], color: 10, width: 17)]
        XCTAssertTrue(store.save(friend))
        XCTAssertEqual(FriendStore(directory: directory).friends.first?.doodles, friend.doodles)
        friend.doodles = nil
        XCTAssertTrue(store.save(friend))
        XCTAssertNil(FriendStore(directory: directory).friends.first?.doodles)
    }
}

extension FantasiVenTests {
    func testAppleCatchesAndMissesAreGentleAndBounded() {
        var catching = AppleRain()
        for _ in 0..<900 { catching.step(1.0 / 30, spawnX: 0.5) }
        XCTAssertGreaterThan(catching.caught, 10)
        XCTAssertTrue(catching.flowers.isEmpty)
        XCTAssertLessThanOrEqual(catching.drops.count, 5)

        var missing = AppleRain()
        missing.move(to: 1)
        for _ in 0..<1800 { missing.step(1.0 / 30, spawnX: 0.17) }
        XCTAssertEqual(missing.caught, 0)
        XCTAssertEqual(missing.flowers.count, 8)
        XCTAssertLessThanOrEqual(missing.drops.count, 5)
    }

    func testAppleClockDoesNotCatchUpAfterAnInterruption() {
        var game = AppleRain()
        game.move(to: -20)
        XCTAssertEqual(game.playerX, 0.14)
        game.move(to: .nan)
        XCTAssertEqual(game.playerX, 0.14)
        for _ in 0..<12 { game.step(1.0 / 30, spawnX: 0.5) }
        let before = game.drops.first!.y
        game.step(3600, spawnX: 0.5)
        XCTAssertEqual(game.drops.first!.y - before, 0.08 * 0.18, accuracy: 0.00001)
        game.step(.infinity, spawnX: 0.5)
        XCTAssertEqual(game.caught, 0)
        XCTAssertTrue(game.flowers.isEmpty)
    }

    func testBubblesRejectRepeatedAndInvalidTaps() {
        var game = BubbleGarden()
        XCTAssertTrue(game.pop(slot: 2, generation: 0))
        XCTAssertFalse(game.pop(slot: 2, generation: 0))
        XCTAssertFalse(game.pop(slot: -1, generation: 0))
        XCTAssertFalse(game.pop(slot: 6, generation: 0))
        XCTAssertTrue(game.pop(slot: 2, generation: 1))
        XCTAssertEqual(game.popped, 2)
        XCTAssertEqual(game.generations.count, 6)
        for _ in 0..<1000 {
            XCTAssertTrue(game.pop(slot: 2, generation: game.generations[2]))
        }
        XCTAssertEqual(game.generations.count, 6)
    }

    func testHideAndSeekHasThreeFriendsAndNoPenaltyForFlowers() {
        var game = HideAndSeek(spots: [5, 2, 1, 0, 3, 4])
        XCTAssertEqual(game.hiding, [5, 2, 1])
        XCTAssertFalse(game.reveal(0))
        XCTAssertEqual(game.found, 0)
        XCTAssertFalse(game.reveal(99))
        XCTAssertTrue(game.reveal(5))
        XCTAssertFalse(game.reveal(5))
        XCTAssertEqual(game.found, 1)
        XCTAssertTrue(game.reveal(1))
        XCTAssertTrue(game.reveal(2))
        XCTAssertTrue(game.complete)
        XCTAssertEqual(game.opened.count, 4)
        let fresh = HideAndSeek(spots: [-1, 8, 2, 2])
        XCTAssertEqual(fresh.hiding.count, 3)
        XCTAssertTrue(fresh.opened.isEmpty)
        XCTAssertFalse(fresh.complete)
    }
}
