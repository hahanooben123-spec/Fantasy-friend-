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
                        .contentShape(Rectangle())
                        .position(x:position.x*proxy.size.width,y:position.y*proxy.size.height)
                        .onTapGesture {
                            selected=value.id
                            var updated=value;updated.lit.toggle()
                            if library.arrange(updated) {SoundService.shared.instrument(1,beat:value.color)}
                        }
                        .gesture(DragGesture(minimumDistance:5).onChanged {event in
                            selected=value.id
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
    private func displayed(_ value:PumpkinLantern)->PumpkinLantern {var p=value;p.darkness=dark ? 1 : 0;return p}
    private func resize() {
        guard var copy=choice else {return}
        copy.gardenScale=copy.gardenScale<0.9 ? 1.05 : copy.gardenScale<1.3 ? 1.4 : 0.65
        library.arrange(copy)
    }
}
