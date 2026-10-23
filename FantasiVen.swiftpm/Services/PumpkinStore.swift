import SwiftUI

@MainActor
final class PumpkinStore:ObservableObject {
    @Published private(set) var lanterns:[PumpkinLantern]=[]
    @Published private(set) var draft:PumpkinLantern?
    @Published var errorKey:String?
    private let directory:URL
    private var readable=true
    private struct Archive:Codable {
        var version=1
        var lanterns:[PumpkinLantern]
        var draft:PumpkinLantern?
    }
    init(directory:URL? = nil) {
        self.directory=directory ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("FantasiVen",isDirectory:true)
        let file=self.directory.appendingPathComponent("lanterns.json")
        guard FileManager.default.fileExists(atPath:file.path) else {return}
        do {
            let archive=try JSONDecoder().decode(Archive.self,from:Data(contentsOf:file))
            guard archive.version == 1,archive.lanterns.allSatisfy(\.isValid),
                  Set(archive.lanterns.map(\.id)).count == archive.lanterns.count,
                  archive.draft?.isValid ?? true else {throw CocoaError(.fileReadCorruptFile)}
            lanterns=archive.lanterns;draft=archive.draft
        } catch {readable=false;errorKey="lanternLoadError"}
    }
    private func write(_ values:[PumpkinLantern],draft:PumpkinLantern?)->Bool {
        guard readable else {errorKey="lanternLoadError";return false}
        guard values.allSatisfy(\.isValid),draft?.isValid ?? true else {errorKey="lanternSaveError";return false}
        do {
            try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
            let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
            let archive=Archive(lanterns:values,draft:draft)
            try encoder.encode(archive).write(to:directory.appendingPathComponent("lanterns.json"),options:.atomic)
            lanterns=values;self.draft=draft;return true
        } catch {errorKey="lanternSaveError";return false}
    }
    @discardableResult func saveDraft(_ value:PumpkinLantern)->Bool {write(lanterns,draft:value)}
    @discardableResult func save(_ value:PumpkinLantern)->Bool {
        var updated=lanterns
        var copy=value
        if let i=updated.firstIndex(where:{$0.id == value.id}) {
            copy.gardenX=updated[i].gardenX;copy.gardenY=updated[i].gardenY;copy.gardenScale=updated[i].gardenScale
            updated[i]=copy
        } else {
            let slot=updated.count%6
            copy.gardenX=[0.18,0.5,0.82][slot%3];copy.gardenY=slot<3 ? 0.28 : 0.65
            updated.insert(copy,at:0)
        }
        return write(updated,draft:nil)
    }
    @discardableResult func arrange(_ value:PumpkinLantern)->Bool {
        guard value.isValid,let i=lanterns.firstIndex(where:{$0.id == value.id}) else {return false}
        var updated=lanterns
        updated[i].gardenX=value.gardenX;updated[i].gardenY=value.gardenY
        updated[i].gardenScale=value.gardenScale;updated[i].lit=value.lit
        return write(updated,draft:draft)
    }
    @discardableResult func delete(_ id:UUID)->Bool {
        write(lanterns.filter {$0.id != id},draft:draft?.id == id ? nil : draft)
    }
}
