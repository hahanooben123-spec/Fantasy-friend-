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
}
