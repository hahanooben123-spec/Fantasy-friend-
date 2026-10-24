import SwiftUI
import UIKit

/// Only immutable value snapshots cross this boundary. The app passes Codable structs.
private final class EncodingSnapshot<Value:Encodable>: @unchecked Sendable {
    let value:Value
    init(_ value:Value) {self.value=value}
    func data() throws -> Data {
        let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        return try encoder.encode(value)
    }
}
private struct SaveRequest:Sendable {
    let id:UUID
    let url:URL
    let encode:@Sendable () throws -> Data
}

/// One ordered writer shared by collections, drafts and settings.
@MainActor
final class LocalSaveQueue:ObservableObject {
    static let shared=LocalSaveQueue()
    @Published private(set) var saving=false
    @Published private(set) var failed=false
    private let worker=DispatchQueue(label:"FantasiVen.local-saves",qos:.utility)
    private var waiting:[URL:SaveRequest]=[:]
    private var latest:[URL:UUID]=[:]
    private var snapshots:[URL:Any]=[:]
    private var unsuccessful:[URL:SaveRequest]=[:]
    private var deadlines:[URL:Task<Void,Never>]=[:]
    private var running=0
    private var backgroundTask=UIBackgroundTaskIdentifier.invalid

    func enqueue<Value:Encodable>(_ value:Value,to url:URL) {
        let snapshot=EncodingSnapshot(value)
        let request=SaveRequest(id:UUID(),url:url,encode:{try snapshot.data()})
        latest[url]=request.id;snapshots[url]=value
        waiting[url]=request;unsuccessful[url]=nil;failed = !unsuccessful.isEmpty;saving=true
        deadlines[url]?.cancel()
        deadlines[url]=Task { [weak self] in
            do {try await Task.sleep(nanoseconds:180_000_000)} catch {return}
            self?.submit(url)
        }
        if UIApplication.shared.applicationState != .active {flush()}
    }
    func flush() {
        if backgroundTask == .invalid && (!waiting.isEmpty || running>0) {
            backgroundTask=UIApplication.shared.beginBackgroundTask(withName:"Save creations") { [weak self] in
                Task { @MainActor in self?.endBackgroundTask() }
            }
        }
        for url in Array(waiting.keys) {submit(url)}
    }
    func retry() {
        for (url,request) in unsuccessful {waiting[url]=request}
        unsuccessful=[:];failed=false;flush()
    }
    private func submit(_ url:URL) {
        deadlines[url]?.cancel();deadlines[url]=nil
        guard let request=waiting.removeValue(forKey:url) else {return}
        running+=1;saving=true
        worker.async { [weak self] in
            var succeeded=false
            do {
                let data=try request.encode()
                let manager=FileManager.default
                try manager.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
                if manager.fileExists(atPath:url.path) {
                    let old=try Data(contentsOf:url)
                    // Never replace a usable backup with an unreadable JSON file.
                    if (try? JSONSerialization.jsonObject(with:old)) != nil {
                        try old.write(to:url.appendingPathExtension("bak"),options:.atomic)
                    }
                }
                try data.write(to:url,options:.atomic);succeeded=true
            } catch {succeeded=false}
            let result=succeeded
            Task { @MainActor [weak self] in self?.completed(request,success:result) }
        }
    }
    private func completed(_ request:SaveRequest,success:Bool) {
        running-=1
        if latest[request.url] == request.id {
            if success {unsuccessful[request.url]=nil} else {unsuccessful[request.url]=request}
        }
        failed = !unsuccessful.isEmpty;saving=running>0 || !waiting.isEmpty
        if !saving {endBackgroundTask()}
    }
    private func endBackgroundTask() {
        if backgroundTask != .invalid {UIApplication.shared.endBackgroundTask(backgroundTask);backgroundTask = .invalid}
    }
    func hasSnapshot(_ url:URL)->Bool {snapshots[url] != nil}
    static func read<Value:Decodable>(_ type:Value.Type,from url:URL,valid:(Value)->Bool)->Value? {
        if let value=shared.snapshots[url] as? Value,valid(value) {return value}
        for candidate in [url,url.appendingPathExtension("bak")] {
            guard let data=try? Data(contentsOf:candidate),let value=try? JSONDecoder().decode(type,from:data),valid(value) else {continue}
            if candidate != url {try? data.write(to:url,options:.atomic)}
            return value
        }
        return nil
    }
}

/// Save failures stay visible until retry succeeds; accepting an edit isn't a disk-success claim.
struct LocalSaveStatus:View {
    @ObservedObject private var queue=LocalSaveQueue.shared
    @EnvironmentObject private var store:FriendStore
    @State private var showSaving=false
    var body:some View {
        VStack {
            Spacer()
            if queue.failed {
                Button {queue.retry()} label:{
                    Label(store.t("saveRetry"),systemImage:"arrow.clockwise")
                        .font(.system(size:15,weight:.heavy,design:.rounded)).padding(16)
                        .background(CandySurface(color:StorybookStyle.honey))
                }.buttonStyle(SquishStyle()).padding(12)
            } else if showSaving {
                HStack(spacing:8) {ProgressView();Text(store.t("savingLocal"))}
                    .font(.system(size:12,weight:.bold,design:.rounded)).padding(8)
                    .background(StorybookPanel(cornerRadius:16)).padding(8).allowsHitTesting(false)
            }
        }.task(id:queue.saving) {
            showSaving=false
            guard queue.saving else {return}
            do {try await Task.sleep(nanoseconds:700_000_000)} catch {return}
            showSaving=queue.saving
        }
    }
}
