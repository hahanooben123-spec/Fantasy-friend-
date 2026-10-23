import SwiftUI

@MainActor
struct PumpkinGameView:View {
    @EnvironmentObject private var words:FriendStore
    @Environment(\.presentationMode) private var presentation
    @StateObject private var library:PumpkinStore
    @State private var editing:PumpkinLantern
    @State private var showGarden:Bool
    init(directory:URL? = nil,previewMode:Int=0) {
        let value=PumpkinStore(directory:directory)
        if previewMode == 1 {
            var p=PumpkinDoor.sample;p.step=3;p.scooped=1;p.light = .green
            p.cuts.append(PumpkinCut(kind:.star,x:0.5,y:0.17,width:0.13,height:0.16))
            value.saveDraft(p)
        }
        if previewMode == 2 {
            for i in 0..<6 {
                var p=PumpkinDoor.sample;p.form=PumpkinForm(rawValue:i) ?? .round
                p.color=i;p.light=PumpkinLight(rawValue:i) ?? .candle;p.step=3
                value.save(p)
            }
        }
        _library=StateObject(wrappedValue:value)
        _editing=State(initialValue:value.draft ?? PumpkinLantern())
        _showGarden=State(initialValue:value.draft == nil && !value.lanterns.isEmpty)
    }
    var body:some View {
        Group {
            if showGarden {
                PumpkinGardenView(library:library,onEdit:edit,onNew:newLantern,onResume:resume,onClose:{presentation.wrappedValue.dismiss()})
            } else {
                PumpkinWorkshopView(original:editing,library:library,onGarden:{showGarden=true},onClose:{
                    if library.lanterns.isEmpty {presentation.wrappedValue.dismiss()} else {showGarden=true}
                }).id(editing.id)
            }
        }.alert(words.t("error"),isPresented:Binding(get:{library.errorKey != nil},set:{if !$0 {library.errorKey=nil}})) {
            Button("OK") {library.errorKey=nil}
        } message:{Text(words.t(library.errorKey ?? "lanternSaveError"))}
            .onAppear {SoundService.shared.setWorld(.castle)}
            .onDisappear {SoundService.shared.stopSpeech()}
    }
    private func newLantern() {
        if let pending=library.draft,!library.save(pending) {return}
        let value=PumpkinLantern()
        guard library.saveDraft(value) else {return}
        editing=value;showGarden=false
    }
    private func edit(_ value:PumpkinLantern) {
        if let pending=library.draft,pending.id != value.id,!library.save(pending) {return}
        var copy=value;copy.step=2
        guard library.saveDraft(copy) else {return}
        editing=copy;showGarden=false
    }
    private func resume() {if let draft=library.draft {editing=draft;showGarden=false}}
}
