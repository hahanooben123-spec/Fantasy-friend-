import SwiftUI

struct PumpkinGardenView:View {
    @EnvironmentObject private var words:FriendStore
    @ObservedObject var library:PumpkinStore
    let onEdit:(PumpkinLantern)->Void
    let onNew:()->Void
    let onResume:()->Void
    let onClose:()->Void
    @State private var page=0
    @State private var selected:UUID?
    @State private var positions:[UUID:CGPoint]=[:]
    @State private var scales:[UUID:Double]=[:]
    @State private var dragOrigin:CGPoint?
    @State private var dark=true
    @State private var parent=false
    @State private var gatePassed=false
    @State private var confirming=false
    @State private var lightShow=false
    @State private var glowingID:UUID?
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    private var pages:Int {max(1,(library.lanterns.count+5)/6)}
    private var visible:[PumpkinLantern] {
        let start=min(page*6,library.lanterns.count)
        return Array(library.lanterns[start..<min(start+6,library.lanterns.count)])
    }
    private var choice:PumpkinLantern? {library.lanterns.first {$0.id == selected}}
    var body:some View {
        ZStack {
            PumpkinBackdrop(darkness:dark ? 1 : 0,garden:true)
            VStack(spacing:8) {
                HStack(spacing:10) {
                    RoundButton(icon:"chevron.left",label:words.t("close"),action:onClose)
                    Text(words.t("lanternGarden")).font(.system(size:20,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.7)
                    Spacer(minLength:0)
                    RoundButton(icon:lightShow ? "stop.fill" : "wand.and.stars",label:words.t("lanternMagic")) {
                        lightShow.toggle()
                    }.disabled(library.lanterns.isEmpty)
                    RoundButton(icon:"plus",label:words.t("lanternNew"),action:onNew)
                }.padding(.horizontal,14).padding(.top,8).foregroundColor(PumpkinLook.cream)
                HStack {
                    if library.draft != nil {
                        Button(action:onResume) {
                            Text(words.t("lanternResume")).font(.system(size:13,weight:.heavy,design:.rounded))
                                .padding(12).background(Capsule().fill(PumpkinLook.cream))
                        }.buttonStyle(SquishStyle())
                    }
                    Spacer()
                    Text("\(page+1) / \(pages)").font(.system(size:14,weight:.bold,design:.rounded)).foregroundColor(PumpkinLook.cream)
                    RoundButton(icon:dark ? "sun.max.fill" : "moon.fill",label:words.t("lanternNight")) {dark.toggle()}
                }.padding(.horizontal,14)
                if library.lanterns.isEmpty {
                    Spacer()
                    Text(words.t("lanternEmpty")).font(.system(.title2,design:.rounded).weight(.heavy))
                        .foregroundColor(PumpkinLook.cream).multilineTextAlignment(.center).padding(30)
                    CandyButton(title:words.t("lanternNew"),icon:"plus",color:.orange,action:onNew).padding(25)
                    Spacer()
                } else {
                    garden
                }
                PlayDock(spacing:6) {
                    PlayToken(symbol:"✏️",label:words.t("edit")) {if let choice=choice {onEdit(choice)}}.disabled(choice == nil)
                    PlayToken(symbol:"↔️",label:words.t("lanternSize"),action:resize).disabled(choice == nil)
                    RoundButton(icon:"trash",label:words.t("lanternDeleteAction")) {parent=true}.disabled(choice == nil)
                    RoundButton(icon:"chevron.left",label:words.t("lanternPrevious")) {page=max(0,page-1);selected=nil}.disabled(page == 0)
                    RoundButton(icon:"chevron.right",label:words.t("lanternNext")) {page=min(pages-1,page+1);selected=nil}.disabled(page>=pages-1)
                }
            }
        }.navigationBarHidden(true).statusBar(hidden:true)
            .onChange(of:library.lanterns.count) {_ in page=min(page,pages-1)}
            .onChange(of:page) {_ in lightShow=false;glowingID=nil}
            .onChange(of:phase) {if $0 != .active {lightShow=false;glowingID=nil}}
            .task(id:lightShow) {await playLights()}
            .sheet(isPresented:$parent,onDismiss:{confirming=gatePassed;gatePassed=false}) {
                ParentGate {gatePassed=true;parent=false}.environmentObject(words)
            }
            .alert(words.t("lanternDelete"),isPresented:$confirming) {
                Button(words.t("cancel"),role:.cancel) {}
                Button(words.t("lanternDeleteAction"),role:.destructive) {if let selected=selected,library.delete(selected) {self.selected=nil}}
            }
    }
    private var garden:some View {
        GeometryReader {proxy in
            ZStack {
                ForEach(visible) {value in
                    let position=positions[value.id] ?? CGPoint(x:value.gardenX,y:value.gardenY)
                    let scale=scales[value.id] ?? value.gardenScale
                    PumpkinIllustration(lantern:displayed(value),animated:true)
                        .frame(width:min(230,proxy.size.width*0.30)*scale,height:min(245,proxy.size.width*0.32)*scale)
                        .overlay(RoundedRectangle(cornerRadius:24).stroke(selected == value.id ? PumpkinLook.cream.opacity(0.7) : .clear,lineWidth:2))
                        .overlay {
                            if glowingID == value.id {
                                Image(systemName:"sparkles").font(.system(size:34,weight:.bold))
                                    .foregroundColor(PumpkinLook.cream).offset(x:35,y:-45)
                                    .transition(.scale.combined(with:.opacity)).allowsHitTesting(false)
                            }
                        }
                        .scaleEffect(glowingID == value.id && !reduced ? 1.08 : 1)
                        .contentShape(Rectangle())
                        .position(x:position.x*proxy.size.width,y:position.y*proxy.size.height)
                        .onTapGesture {
                            lightShow=false;glowingID=nil;selected=value.id
                            var updated=value;updated.lit.toggle()
                            if library.arrange(updated) {SoundService.shared.instrument(1,beat:value.color)}
                        }
                        .gesture(DragGesture(minimumDistance:5).onChanged {event in
                            lightShow=false;glowingID=nil;selected=value.id
                            if dragOrigin == nil {dragOrigin=position}
                            guard let start=dragOrigin else {return}
                            positions[value.id]=CGPoint(x:min(0.92,max(0.08,start.x+event.translation.width/proxy.size.width)),
                                y:min(0.85,max(0.12,start.y+event.translation.height/proxy.size.height)))
                        }.onEnded {_ in
                            var updated=value
                            if let p=positions[value.id] {updated.gardenX=p.x;updated.gardenY=p.y}
                            if library.arrange(updated) {positions[value.id]=nil}
                            dragOrigin=nil
                        })
                        .simultaneousGesture(MagnificationGesture().onChanged {factor in
                            selected=value.id;scales[value.id]=min(1.4,max(0.65,value.gardenScale*factor))
                        }.onEnded {_ in
                            var updated=value;updated.gardenScale=scales[value.id] ?? value.gardenScale
                            if library.arrange(updated) {scales[value.id]=nil}
                        })
                        .accessibilityElement(children:.ignore).accessibilityLabel(words.t("pumpkinTitle"))
                        .accessibilityHint(words.t("lanternGardenHint"))
                        .accessibilityAction(named:Text(words.t("edit"))) {onEdit(value)}
                        .accessibilityAdjustableAction {direction in
                            var updated=value;updated.gardenScale=min(1.4,max(0.65,value.gardenScale+(direction == .increment ? 0.1 : -0.1)))
                            library.arrange(updated)
                        }
                }
            }.frame(width:proxy.size.width,height:proxy.size.height)
        }
    }
    private func displayed(_ value:PumpkinLantern)->PumpkinLantern {
        var p=value;p.darkness=dark ? 1 : 0
        if lightShow {
            p.darkness=1;p.lit=glowingID == value.id
            if p.lit {p.brightness=1}
        }
        return p
    }
    @MainActor private func playLights() async {
        guard lightShow else {glowingID=nil;return}
        // Temporary performance only: the child's saved light choices stay intact.
        let lamps=visible.sorted {$0.gardenX == $1.gardenX ? $0.gardenY<$1.gardenY : $0.gardenX<$1.gardenX}
        guard !lamps.isEmpty else {lightShow=false;return}
        dark=true
        for beat in 0..<(lamps.count*2) {
            guard !Task.isCancelled,lightShow else {return}
            let lamp=lamps[beat%lamps.count]
            withAnimation(reduced ? nil : .spring(response:0.3,dampingFraction:0.65)) {glowingID=lamp.id}
            SoundService.shared.instrument(1,beat:beat%8,voice:lamp.color%3)
            do {try await Task.sleep(nanoseconds:520_000_000)} catch {return}
        }
        withAnimation(reduced ? nil : .easeOut(duration:0.3)) {glowingID=nil;lightShow=false}
    }
    private func resize() {
        guard var copy=choice else {return}
        copy.gardenScale=copy.gardenScale<0.9 ? 1.05 : copy.gardenScale<1.3 ? 1.4 : 0.65
        library.arrange(copy)
    }
}
