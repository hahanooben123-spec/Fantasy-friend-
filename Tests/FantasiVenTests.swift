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
        for _ in 0..<20 { game.step(1.0 / 30, spawnX: 0.5) }
        let before = game.drops.first!.y
        game.step(3600, spawnX: 0.5)
        XCTAssertEqual(game.drops.first!.y - before, 0.08 * 0.16, accuracy: 0.00001)
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

extension FantasiVenTests {
    func testCreativeFriendsAndSavedCreationsRoundTrip() throws {
        var friend = FantasyFriend()
        friend.pieces = [CreativePiece(kind: .eye, variant: 4, x: 0.4, y: 0.3, mirrored: true, color: 5)]
        friend.bodyWidth = 1.2; friend.bodyHeight = 0.75
        friend.voice = .hum; friend.gait = .waddle
        friend.room = [RoomObject(kind: 2, x: 0.3, y: 0.6)]
        friend.track = SlideTrack(); friend.song = OrchestraPattern()
        XCTAssertTrue(friend.isValid)
        XCTAssertEqual(friend, try JSONDecoder().decode(FantasyFriend.self, from: JSONEncoder().encode(friend)))
        let copy = friend.sibling()
        XCTAssertNotEqual(copy.id, friend.id)
        XCTAssertEqual(copy.pieces, friend.pieces)
        XCTAssertEqual(copy.room, friend.room)
        friend.pieces![0].x = .nan
        XCTAssertFalse(friend.isValid)
    }
    func testCreativeMovementSnapAndPatternBounds() {
        var piece = CreativePiece(kind: .arm)
        piece.move(x: -10, y: 4, snap: false)
        XCTAssertEqual(piece.x, 0.08); XCTAssertEqual(piece.y, 0.92)
        piece.move(x: 0.423, y: 0.574, snap: true)
        XCTAssertEqual(piece.x, 0.4, accuracy: 0.001)
        XCTAssertTrue(piece.isValid)
        var track = SlideTrack()
        track.set(2, y: 4); track.set(99, y: 0.5)
        XCTAssertTrue(track.isValid)
        XCTAssertEqual(track.height(at: 0), track.heights[0])
        var song = OrchestraPattern()
        song.toggle(row: 0, beat: 3); song.toggle(row: 12, beat: -1)
        XCTAssertTrue(song.rows[0][3]); XCTAssertTrue(song.isValid)
    }
    func testKitchenAndPathHaveReachablePositiveEndings() {
        var recipe = KitchenRecipe()
        for _ in 0..<20 { recipe.add(2) }
        XCTAssertEqual(recipe.ingredients.count, 5)
        XCTAssertTrue((0..<3).contains(recipe.flavor))
        recipe.clear(); XCTAssertTrue(recipe.ingredients.isEmpty)
        for level in 1...3 {
            var puzzle = PathPuzzle(level: level)
            XCTAssertFalse(puzzle.complete)
            for i in 0..<4 {
                while puzzle.tiles[i] != puzzle.target[i] { puzzle.turn(i) }
            }
            XCTAssertTrue(puzzle.complete)
        }
    }
    func testOldSettingsGainSpeechAndSimpleChallenge() throws {
        let data = Data(#"{"language":"da","sound":false,"music":false}"#.utf8)
        let settings = try JSONDecoder().decode(GameSettings.self, from: data)
        XCTAssertTrue(settings.speechEnabled)
        XCTAssertEqual(settings.challengeLevel, 1)
        XCTAssertFalse(settings.sound)
    }
}

extension FantasiVenTests {
    @MainActor
    func testSharedPhysicsKeepsOriginalsAndLimitsSceneSize() {
        var original = FantasyFriend()
        original.pieces = [CreativePiece(kind: .arm, variant: 3, color: 4)]
        original.setPlacement(PartPlacement(rotation: 30), for: .leftArm)
        let simulation = PlayPhysics()
        simulation.configure(friends: [original], mode: .yard, reducedMotion: true)
        for _ in 0..<10 { simulation.addFriend(original) }
        for _ in 0..<20 { simulation.addToy(0) }
        XCTAssertEqual(simulation.scene.scaleMode, .fill)
        XCTAssertEqual(simulation.friendCount, 4)
        XCTAssertEqual(simulation.toyCount, 12)
        simulation.beginDrag(CGPoint(x: 180, y: 280))
        simulation.moveDrag(CGPoint(x: 450, y: 350))
        simulation.endDrag(); simulation.refresh()
        XCTAssertEqual(simulation.friends[0].x, 450)
        XCTAssertEqual(simulation.friends[0].friend.pieces, original.pieces)
        XCTAssertEqual(original.placement(for: .leftArm).rotation, 30)
        simulation.configure(friends: [original], mode: .trampoline, reducedMotion: true)
        simulation.accessibleRide(progress: 1, track: nil)
        XCTAssertFalse(simulation.arrived, "Trampoline play continues after a jump")
        XCTAssertEqual(simulation.toyCount, 0)
        simulation.setActive(false)
        XCTAssertTrue(simulation.scene.isPaused)
    }
    func testFruitVarietyAndPicnicCollectionStayBounded() {
        var game = AppleRain()
        for _ in 0..<2000 { game.step(1.0 / 30, spawnX: 0.5, level: 3) }
        XCTAssertEqual(Set(game.fruitBasket), [0, 1, 2])
        XCTAssertEqual(game.fruitBasket.count, 12)
        XCTAssertLessThanOrEqual(game.drops.count, 5)
    }
}

extension FantasiVenTests {
    func testWorkshopEditsPersistWithoutChangingIdentity() throws {
        let original = FantasyFriend.studioStarter()
        var edited = CreatorGeometry.moved(.eyes, original: original, delta: CGSize(width: 30, height: -16))
        edited = CreatorGeometry.transformed(.eyes, original: edited, rotation: 27, scale: 1.3)
        edited.hide("leftArm"); edited.hide("mouth")
        edited.mirroredParts = ["eyes", "rightArm"]
        edited.partColors = ["eyes": 4, "mouth": 2]
        XCTAssertTrue(edited.isValid)
        XCTAssertEqual(edited.id, original.id)
        XCTAssertEqual(edited.facePlacements?["eyes"]?.x ?? 0, 0.1, accuracy: 0.001)
        XCTAssertFalse(original.isHidden("leftArm"))
        let data = try JSONEncoder().encode(edited)
        XCTAssertEqual(try JSONDecoder().decode(FantasyFriend.self, from: data), edited)
    }
    func testWorkshopHitTestingIgnoresRemovedPartsAndPrefersTopPiece() {
        var friend = FantasyFriend.studioStarter()
        friend.hide("eyes")
        XCTAssertNotEqual(CreatorGeometry.hit(CGPoint(x:150,y:157), friend:friend, margin:0), .eyes)
        let piece = CreativePiece(kind:.eye, variant:0, x:0.5, y:0.5)
        friend.pieces = [piece]
        XCTAssertEqual(CreatorGeometry.hit(CGPoint(x:150,y:160), friend:friend, margin:0), .piece(piece.id))
    }
    func testWorkshopGestureUsesOriginalPoseAndRespectsLimits() {
        let original = FantasyFriend.studioStarter()
        let moved = CreatorGeometry.moved(.mouth, original:original, delta:CGSize(width:900,height:-900))
        XCTAssertEqual(moved.facePlacements?["mouth"]?.x, 0.3)
        XCTAssertEqual(moved.facePlacements?["mouth"]?.y, -0.3)
        let enlarged = CreatorGeometry.transformed(.mouth, original:moved, rotation:400, scale:7)
        XCTAssertEqual(enlarged.facePlacements?["mouth"]?.scale, 1.5)
        XCTAssertEqual(enlarged.facePlacements?["mouth"]?.rotation, 40)
        XCTAssertTrue(enlarged.isValid)
        XCTAssertNil(original.facePlacements)
    }
    func testWorkshopRejectsUnknownPartEditsAndReadsOlderFriends() throws {
        var friend = FantasyFriend.studioStarter()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(friend)) as? [String:Any])
        for key in ["hiddenParts","mirroredParts","facePlacements"] { json.removeValue(forKey:key) }
        let older = try JSONDecoder().decode(FantasyFriend.self, from:JSONSerialization.data(withJSONObject:json))
        XCTAssertTrue(older.isValid)
        friend.hiddenParts = ["unknown"]
        XCTAssertFalse(friend.isValid)
        friend.hiddenParts = nil; friend.facePlacements = ["tail": PartPlacement()]
        XCTAssertFalse(friend.isValid)
    }
}

extension FantasiVenTests {
    func testGoldenFruitAndStreakArePlayOnlyAndBounded() {
        var game=AppleRain()
        for _ in 0..<1800 {game.step(1.0/30,spawnX:0.5)}
        XCTAssertGreaterThan(game.goldenCaught,0)
        XCTAssertEqual(game.streak,game.caught)
        XCTAssertLessThanOrEqual(game.fruitBasket.count,12)
        game.move(to:0.86)
        for _ in 0..<600 {game.step(1.0/30,spawnX:0.17)}
        XCTAssertEqual(game.streak,0)
        XCTAssertLessThanOrEqual(game.drops.count,5)
    }
    func testStarTrailCannotCollectSameStarTwiceAndCanContinue() {
        var trail=StarTrail()
        let first=trail.stars[0]
        XCTAssertTrue(trail.collect(x:first.x,y:first.y,radius:0.01))
        XCTAssertFalse(trail.collect(x:first.x,y:first.y,radius:0.01))
        XCTAssertEqual(trail.collected,1)
        XCTAssertFalse(trail.collect(x:.nan,y:0))
        let oldIDs=Set(trail.stars.map(\.id))
        trail.reseed()
        XCTAssertTrue(oldIDs.isDisjoint(with:Set(trail.stars.map(\.id))))
        XCTAssertEqual(trail.stars.count,5)
        XCTAssertEqual(trail.collected,1)
        let track=SlideTrack()
        trail.follow(track)
        XCTAssertEqual(trail.stars[2].y,0.2+track.heights[2]*0.6-0.09,accuracy:0.00001)
    }
    @MainActor
    func testRagdollWorldMatchesTallViewportAndKeepsItsFigure() {
        let friend=FantasyFriend.studioStarter()
        let simulation=RagdollSimulation()
        simulation.resize(to:CGSize(width:400,height:900))
        simulation.configure(friend,reducedMotion:true)
        XCTAssertEqual(simulation.scene.size.width,400)
        XCTAssertEqual(simulation.scene.size.height,900)
        XCTAssertEqual(simulation.frame.canvasSize,simulation.scene.size)
        let start=simulation.frame.position
        simulation.beginDrag(at:start)
        simulation.moveDrag(to:CGPoint(x:210,y:700))
        simulation.refresh()
        XCTAssertEqual(simulation.frame.position.y,700,accuracy:0.001)
        XCTAssertEqual(simulation.frame.friend.id,friend.id)
        simulation.endDrag()
        simulation.setActive(false)
        XCTAssertTrue(simulation.scene.isPaused)
        XCTAssertEqual(simulation.scene.children.count,6)
    }
    @MainActor
    func testToyCanBePlacedAtTouchAndStillRespectsSceneLimit() {
        let simulation=PlayPhysics()
        simulation.configure(friends:[FantasyFriend()],mode:.yard,reducedMotion:true)
        simulation.addToy(0,at:CGPoint(x:250,y:300))
        XCTAssertEqual(simulation.toys.first?.x,250)
        XCTAssertEqual(simulation.toys.first?.y,300)
        for _ in 0..<20 {simulation.addToy(1,at:CGPoint(x:100,y:100))}
        XCTAssertEqual(simulation.toyCount,12)
        simulation.setActive(false)
    }
}

extension FantasiVenTests {
    func testCuratedMenuAndPlaygroundHaveSeparateActivities() {
        XCTAssertEqual(MiniGameKind.menuGames.map(\.rawValue),["apples","bubbles","kitchen","orchestra"])
        XCTAssertEqual(MiniGameKind.playgroundToys.map(\.rawValue),["slide","trampoline"])
        let visible=Set((MiniGameKind.menuGames+MiniGameKind.playgroundToys).map(\.rawValue))
        XCTAssertFalse(visible.contains("hide"));XCTAssertFalse(visible.contains("path"))
    }
    func testIngredientsMakeSixDistinctVisibleDiscoveries() {
        let samples:[[Int]]=[[0,4],[1],[2],[0,3],[1,5],[0,1,2,4]]
        let expected:[DishFeeling]=[.berry,.creamy,.crunchy,.fizzy,.bouncy,.rainbow]
        for (ingredients,feeling) in zip(samples,expected) {
            let dish=FantasyDish.make(ingredients)
            XCTAssertEqual(dish.feeling,feeling)
            XCTAssertTrue([dish.red,dish.green,dish.blue].allSatisfy {(0...1).contains($0)})
        }
        let strawberry=FantasyDish.make([0]),blueberry=FantasyDish.make([4])
        XCTAssertNotEqual(strawberry.red,blueberry.red)
        XCTAssertNotEqual(strawberry.blue,blueberry.blue)
        XCTAssertEqual(FantasyDish.make([-1,99]),FantasyDish.make([]))
    }
    func testKitchenKeepsLatestIngredientsForContinuedExperimenting() {
        var recipe=KitchenRecipe()
        for ingredient in 0..<6 {recipe.add(ingredient)}
        XCTAssertEqual(recipe.ingredients,[1,2,3,4,5])
        recipe.add(-1);XCTAssertEqual(recipe.ingredients.count,5)
        recipe.clear();XCTAssertTrue(recipe.ingredients.isEmpty)
    }
    func testFruitWeatherChangesPatternsAndKeepsObjectsInBounds() {
        var game=AppleRain()
        XCTAssertEqual(game.weather,.orchard)
        for frame in 0..<540 {
            game.step(0.08,spawnX:0.5,adventurous:true)
            XCTAssertLessThanOrEqual(game.drops.count,5)
            XCTAssertTrue(game.drops.allSatisfy {$0.x.isFinite && (0.14...0.86).contains($0.x)})
            if frame == 179 {XCTAssertEqual(game.weather,.breeze)}
            if frame == 359 {XCTAssertEqual(game.weather,.rainbow)}
        }
        XCTAssertEqual(game.weather,.orchard)
        let before=game.time
        game.step(.infinity,spawnX:.nan,adventurous:true)
        XCTAssertEqual(game.time,before)
    }
    func testInstrumentVoicesProduceDistinctBoundedPCMFiles() throws {
        let drum=InstrumentSynth.render(row:0,beat:0,voice:0)
        let bell=InstrumentSynth.render(row:1,beat:0,voice:0)
        let voice=InstrumentSynth.render(row:2,beat:0,voice:0)
        XCTAssertNotEqual(drum,bell);XCTAssertNotEqual(bell,voice)
        XCTAssertNotEqual(voice,InstrumentSynth.render(row:2,beat:0,voice:1))
        for sound in [drum,bell,voice] {
            XCTAssertEqual(String(data:sound.prefix(4),encoding:.utf8),"RIFF")
            XCTAssertEqual(String(data:sound[8..<12],encoding:.utf8),"WAVE")
            XCTAssertGreaterThan(sound.count,1000)
            XCTAssertEqual((sound.count-44)%2,0)
            let bytes=[UInt8](sound)
            for i in stride(from:44,to:bytes.count-1,by:2) {
                let bits=UInt16(bytes[i]) | (UInt16(bytes[i+1])<<8)
                XCTAssertLessThanOrEqual(abs(Int(Int16(bitPattern:bits))),11000)
            }
        }
    }
    func testRhythmSuggestionsAreDistinctAndCanStillBeSaved() throws {
        let patterns=(0..<4).map {OrchestraPattern.preset($0)}
        XCTAssertTrue(patterns.allSatisfy(\.isValid))
        let encoded=try patterns.map {try JSONEncoder().encode($0)}
        XCTAssertEqual(Set(encoded).count,4)
        for data in encoded {XCTAssertTrue(try JSONDecoder().decode(OrchestraPattern.self,from:data).isValid)}
    }
}

extension FantasiVenTests {
    func testLanternVariantsRoundTripWithRealCuts() throws {
        for form in PumpkinForm.allCases {
            for light in PumpkinLight.allCases {
                var lantern=PumpkinLantern()
                lantern.form=form;lantern.light=light;lantern.color=form.rawValue
                lantern.addFace()
                lantern.cuts.append(try XCTUnwrap(PumpkinCut.fromStroke([
                    PumpkinPoint(x:0.2,y:0.2),PumpkinPoint(x:0.4,y:0.2),
                    PumpkinPoint(x:0.4,y:0.4),PumpkinPoint(x:0.2,y:0.4),PumpkinPoint(x:0.21,y:0.21)])))
                XCTAssertTrue(lantern.isValid)
                XCTAssertEqual(lantern,try JSONDecoder().decode(PumpkinLantern.self,from:JSONEncoder().encode(lantern)))
            }
        }
    }
    func testCarvingNeedsAClosedAreaAndNormalizesItsOutline() throws {
        let square=[PumpkinPoint(x:0.2,y:0.3),PumpkinPoint(x:0.6,y:0.3),
                    PumpkinPoint(x:0.6,y:0.7),PumpkinPoint(x:0.2,y:0.7),PumpkinPoint(x:0.21,y:0.31)]
        let cut=try XCTUnwrap(PumpkinCut.fromStroke(square))
        XCTAssertTrue(cut.isValid);XCTAssertEqual(cut.width,0.4,accuracy:0.001)
        XCTAssertEqual(cut.x,0.4,accuracy:0.001)
        XCTAssertTrue(cut.outline.allSatisfy(\.isValid))
        XCTAssertNil(PumpkinCut.fromStroke(Array(square.prefix(4))))
        XCTAssertNil(PumpkinCut.fromStroke(Array(square.prefix(3))))
        XCTAssertNil(PumpkinCut.fromStroke(Array(repeating:PumpkinPoint(x:0.5,y:0.5),count:5)))
        var invalid=square;invalid[0].x = .nan
        XCTAssertNil(PumpkinCut.fromStroke(invalid))
    }
    func testInvalidLanternGeometryAndDuplicateCutsAreRejected() {
        var lantern=PumpkinLantern();lantern.addFace()
        lantern.cuts.append(lantern.cuts[0]);XCTAssertFalse(lantern.isValid)
        lantern=PumpkinLantern();lantern.brightness=0;XCTAssertFalse(lantern.isValid)
        lantern=PumpkinLantern();lantern.gardenX = .infinity;XCTAssertFalse(lantern.isValid)
        lantern=PumpkinLantern();lantern.cuts=[PumpkinCut(kind:.circle,width:-1)]
        XCTAssertFalse(lantern.isValid)
    }
    func testCutHitGeometryFollowsEveryPumpkinForm() {
        for form in PumpkinForm.allCases {
            var lantern=PumpkinLantern();lantern.form=form
            var cut=PumpkinCut(kind:.circle)
            cut.move(x:-4,y:8);XCTAssertEqual(cut.x,0.05);XCTAssertEqual(cut.y,0.95)
            cut.move(x:.nan,y:0);XCTAssertEqual(cut.y,0.95)
            cut.move(x:0.4,y:0.6);cut.rotation=35
            lantern.cuts=[cut]
            let r=PumpkinGeometry.rect(form)
            let center=CGPoint(x:r.minX+r.width*0.4,y:r.minY+r.height*0.6)
            XCTAssertEqual(PumpkinGeometry.hit(center,lantern:lantern),cut.id)
            XCTAssertNil(PumpkinGeometry.hit(CGPoint(x:-100,y:-100),lantern:lantern))
        }
    }
    @MainActor
    func testLanternDraftGardenAndEditsPersistIndependently() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let store=PumpkinStore(directory:directory)
        var lantern=PumpkinLantern();lantern.addFace()
        XCTAssertTrue(store.saveDraft(lantern))
        XCTAssertEqual(PumpkinStore(directory:directory).draft,lantern)
        XCTAssertTrue(store.save(lantern));XCTAssertNil(store.draft)
        var placed=try XCTUnwrap(store.lanterns.first)
        placed.gardenX=0.7;placed.gardenY=0.4;placed.gardenScale=1.3;placed.lit=false
        XCTAssertTrue(store.arrange(placed))
        lantern.color=3;lantern.light = .rainbow
        XCTAssertTrue(store.save(lantern))
        let reloaded=PumpkinStore(directory:directory)
        let saved=try XCTUnwrap(reloaded.lanterns.first)
        XCTAssertEqual(saved.color,3);XCTAssertEqual(saved.light,.rainbow)
        XCTAssertEqual(saved.gardenX,0.7);XCTAssertEqual(saved.gardenY,0.4)
        XCTAssertEqual(saved.gardenScale,1.3);XCTAssertNil(reloaded.draft)
    }
    @MainActor
    func testBrokenOrFutureLanternArchivesCannotBeOverwritten() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let file=directory.appendingPathComponent("lanterns.json")
        for text in ["broken archive","{\"version\":99,\"lanterns\":[]}"] {
            let original=Data(text.utf8);try original.write(to:file)
            let store=PumpkinStore(directory:directory)
            XCTAssertEqual(store.errorKey,"lanternLoadError")
            XCTAssertFalse(store.save(PumpkinLantern()))
            XCTAssertFalse(store.saveDraft(PumpkinLantern()))
            XCTAssertEqual(try Data(contentsOf:file),original)
        }
    }
    @MainActor
    func testLanternWriteFailureDoesNotCommitState() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        try Data("not a directory".utf8).write(to:directory)
        let store=PumpkinStore(directory:directory)
        XCTAssertFalse(store.save(PumpkinLantern()))
        XCTAssertFalse(store.saveDraft(PumpkinLantern()))
        XCTAssertTrue(store.lanterns.isEmpty);XCTAssertNil(store.draft)
        XCTAssertEqual(store.errorKey,"lanternSaveError")
    }
    @MainActor
    func testGardenHasNoSmallCollectionLimitAndDeleteKeepsOtherLanterns() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let store=PumpkinStore(directory:directory)
        for _ in 0..<75 {XCTAssertTrue(store.save(PumpkinLantern()))}
        XCTAssertEqual(store.lanterns.count,75)
        let removed=try XCTUnwrap(store.lanterns.first)
        let remaining=Array(store.lanterns.dropFirst())
        XCTAssertTrue(store.saveDraft(removed));XCTAssertTrue(store.delete(removed.id))
        let reloaded=PumpkinStore(directory:directory)
        XCTAssertEqual(reloaded.lanterns,remaining);XCTAssertNil(reloaded.draft)
    }
    @MainActor
    func testLanternsAndFriendsShareDirectoryWithoutSharingFiles() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let friends=FriendStore(directory:directory),lanterns=PumpkinStore(directory:directory)
        let friend=FantasyFriend.random()
        XCTAssertTrue(friends.save(friend));XCTAssertTrue(lanterns.save(PumpkinLantern()))
        let file=directory.appendingPathComponent("lanterns.json"),before=try Data(contentsOf:file)
        XCTAssertTrue(friends.delete(friend))
        XCTAssertEqual(try Data(contentsOf:file),before)
        XCTAssertEqual(PumpkinStore(directory:directory).lanterns.count,1)
    }
}
