import SwiftUI

@MainActor
final class FriendStore: ObservableObject {
    @Published private(set) var friends: [FantasyFriend] = []
    @Published private(set) var settings = GameSettings()
    @Published var error: String?
    private let directory: URL
    private var collectionReadable = true
    private struct Archive: Codable {
        var version = 1
        var friends: [FantasyFriend]
    }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FantasiVen", isDirectory: true)
        load()
        SoundService.shared.configure(settings)
    }
    func t(_ key: String) -> String { Words.text(key, settings.language) }

    private func load() {
        let settingsURL = directory.appendingPathComponent("settings.json")
        if FileManager.default.fileExists(atPath: settingsURL.path) {
            do { settings = try JSONDecoder().decode(GameSettings.self, from: Data(contentsOf: settingsURL)) }
            catch { self.error = t("loadError") }
        }
        let url = directory.appendingPathComponent("friends.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let archive = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: url))
            guard archive.version == 1, archive.friends.allSatisfy(\.isValid), Set(archive.friends.map(\.id)).count == archive.friends.count else {
                throw CocoaError(.fileReadCorruptFile)
            }
            friends = archive.friends
        } catch {
            collectionReadable = false
            self.error = t("loadError")
        }
    }

    private func write<T: Encodable>(_ value: T, to file: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: directory.appendingPathComponent(file), options: .atomic)
    }

    @discardableResult
    func save(_ friend: FantasyFriend) -> Bool {
        guard collectionReadable else { error = t("loadError"); return false }
        guard friend.isValid else { error = t("error"); return false }
        var updated = friends
        if let index = updated.firstIndex(where: { $0.id == friend.id }) { updated[index] = friend }
        else { updated.insert(friend, at: 0) }
        do { try write(Archive(friends: updated), to: "friends.json"); friends = updated; return true }
        catch { self.error = t("error"); return false }
    }

    @discardableResult
    func delete(_ friend: FantasyFriend) -> Bool {
        guard collectionReadable else { error = t("loadError"); return false }
        let updated = friends.filter { $0.id != friend.id }
        do { try write(Archive(friends: updated), to: "friends.json"); friends = updated; return true }
        catch { self.error = t("error"); return false }
    }

    func updateSettings(_ update: (inout GameSettings) -> Void) {
        var updated = settings
        update(&updated)
        do { try write(updated, to: "settings.json"); settings = updated; SoundService.shared.configure(updated) }
        catch { self.error = t("error") }
    }
}
