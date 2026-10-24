import SwiftUI

@MainActor
final class FriendStore: ObservableObject {
    @Published private(set) var friends: [FantasyFriend] = []
    @Published private(set) var settings = GameSettings()
    @Published var error: String?
    @Published private(set) var sessions=PlaySessions()
    private let guestCompanion=FriendSeed.bimse.make()
    var companion:FantasyFriend {
        friends.first {$0.id == sessions.companionID} ?? friends.first ?? guestCompanion
    }
    func selectCompanion(_ id:UUID) {
        guard friends.contains(where:{$0.id == id}) else {return}
        updateSessions {$0.companionID=id}
    }
    private var sessionsReadable=true
    private let directory: URL
    private var collectionReadable = true
    private struct Archive: Codable {
        var version = 1
        var friends: [FantasyFriend]
    }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FantasiVen", isDirectory: true)
        load()
        loadSessions()
        SoundService.shared.configure(settings)
    }
    func t(_ key: String) -> String { Words.text(key, settings.language) }

    private func load() {
        let settingsURL = directory.appendingPathComponent("settings.json")
        if LocalSaveQueue.shared.hasSnapshot(settingsURL) || FileManager.default.fileExists(atPath:settingsURL.path) || FileManager.default.fileExists(atPath:settingsURL.appendingPathExtension("bak").path) {
            if let value=LocalSaveQueue.read(GameSettings.self,from:settingsURL,valid:{_ in true}) {settings=value}
            else {self.error=t("loadError")}
        }
        let url = directory.appendingPathComponent("friends.json")
        guard LocalSaveQueue.shared.hasSnapshot(url) || FileManager.default.fileExists(atPath: url.path) || FileManager.default.fileExists(atPath:url.appendingPathExtension("bak").path) else { return }
        do {
            guard let archive=LocalSaveQueue.read(Archive.self,from:url,valid:{
                $0.version == 1 && $0.friends.allSatisfy(\.isValid) && Set($0.friends.map(\.id)).count == $0.friends.count
            }) else {throw CocoaError(.fileReadCorruptFile)}
            friends = archive.friends
        } catch {
            collectionReadable = false
            self.error = t("loadError")
        }
    }


    private func loadSessions() {
        let url=directory.appendingPathComponent("sessions.json")
        guard LocalSaveQueue.shared.hasSnapshot(url) || FileManager.default.fileExists(atPath:url.path) || FileManager.default.fileExists(atPath:url.appendingPathExtension("bak").path) else {return}
        do {
            guard let value=LocalSaveQueue.read(PlaySessions.self,from:url,valid:{$0.isValid}) else {throw CocoaError(.fileReadCorruptFile)}
            sessions=value
        } catch {sessionsReadable=false;self.error=t("loadError")}
    }
    @discardableResult private func updateSessions(_ update:(inout PlaySessions)->Void)->Bool {
        guard sessionsReadable else {error=t("loadError");return false}
        var next=sessions;update(&next)
        guard next != sessions else {return true}
        guard next.isValid else {error=t("error");return false}
        do {try write(next,to:"sessions.json");sessions=next;return true}
        catch {self.error=t("error");return false}
    }
    @discardableResult func saveEditorDraft(_ friend:FantasyFriend,existing:Bool)->Bool {
        updateSessions {
            $0.editorDrafts=$0.allEditors.filter {$0.friend.id != friend.id}
            $0.editor=EditorDraft(friend:friend,existing:existing)
            $0.recent=ActivityBookmark(kind:.creator,friendID:friend.id)
        }
    }
    func clearEditorDraft(_ id:UUID) {
        updateSessions {
            $0.editorDrafts=$0.allEditors.filter {$0.friend.id != id}
            if $0.editor?.friend.id == id {$0.editor=$0.editorDrafts?.first}
            $0.recent=ActivityBookmark(kind:.playground,friendID:id)
        }
    }
    @discardableResult func savePizzaDraft(_ draft:PizzaDraft)->Bool {
        updateSessions {
            $0.pizzaDrafts=$0.allPizzas.filter {$0.companion.id != draft.companion.id}
            $0.pizza=draft;$0.recent=ActivityBookmark(kind:.pizza,friendID:draft.companion.id)
        }
    }
    @discardableResult func recordAppleStreak(_ streak:Int)->Bool {
        guard streak>(sessions.appleBestStreak ?? 0) else {return true}
        return updateSessions {$0.appleBestStreak=streak}
    }
    func visit(_ kind:ActivityKind,friendID:UUID?=nil) {
        updateSessions {
            $0.recent=ActivityBookmark(kind:kind,friendID:friendID)
            if let id=friendID,friends.contains(where:{$0.id == id}) {$0.companionID=id}
        }
    }

    private func write<T: Encodable>(_ value: T, to file: String) throws {
        LocalSaveQueue.shared.enqueue(value,to:directory.appendingPathComponent(file))
    }

    @discardableResult
    func save(_ friend: FantasyFriend) -> Bool {
        guard collectionReadable else { error = t("loadError"); return false }
        guard friend.isValid else { error = t("error"); return false }
        var updated = friends
        if let index = updated.firstIndex(where: { $0.id == friend.id }) { updated[index] = friend }
        else { updated.insert(friend, at: 0) }
        do { try write(Archive(friends: updated), to: "friends.json"); friends = updated; selectCompanion(friend.id); return true }
        catch { self.error = t("error"); return false }
    }

    @discardableResult
    func delete(_ friend: FantasyFriend) -> Bool {
        guard collectionReadable else { error = t("loadError"); return false }
        let updated = friends.filter { $0.id != friend.id }
        do { try write(Archive(friends: updated), to: "friends.json"); friends = updated
            updateSessions {
                $0.editorDrafts=$0.allEditors.filter {$0.friend.id != friend.id}
                $0.pizzaDrafts=$0.allPizzas.filter {$0.companion.id != friend.id}
                if $0.editor?.friend.id == friend.id {$0.editor=$0.editorDrafts?.first}
                if $0.pizza?.companion.id == friend.id {$0.pizza=$0.pizzaDrafts?.first}
                if $0.companionID == friend.id {$0.companionID=updated.first?.id}
                if $0.recent?.friendID == friend.id {$0.recent=nil}
            }
            return true }
        catch { self.error = t("error"); return false }
    }

    func updateSettings(_ update: (inout GameSettings) -> Void) {
        var updated = settings
        update(&updated)
        do { try write(updated, to: "settings.json"); settings = updated; SoundService.shared.configure(updated) }
        catch { self.error = t("error") }
    }
}
