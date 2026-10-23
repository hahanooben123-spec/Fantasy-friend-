import SwiftUI

struct PumpkinWorkshopView:View {
    @EnvironmentObject private var words:FriendStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    let original:PumpkinLantern
    @ObservedObject var library:PumpkinStore
    let onGarden:()->Void
    let onClose:()->Void
    @State private var lantern:PumpkinLantern
    @State private var history:[PumpkinLantern]=[]
    @State private var future:[PumpkinLantern]=[]
    @State private var transaction:PumpkinLantern?
    @State private var tool=PumpkinTool.stamp
    @State private var stamp=PumpkinCutKind.triangle
    @State private var selected:UUID?
    @State private var warning=false
    @State private var revealing=false
    @State private var saved=false
    @State private var prompt:Int?
    @State private var cheer=0
    @State private var puff=0
    @State private var lid:CGFloat=0
    private var step:PumpkinStep {PumpkinStep(rawValue:lantern.step) ?? .choose}
    init(original:PumpkinLantern,library:PumpkinStore,onGarden:@escaping()->Void,onClose:@escaping()->Void) {
        self.original=original;self.library=library;self.onGarden=onGarden;self.onClose=onClose
        _lantern=State(initialValue:original)
    }
    var body:some View {
        GeometryReader {proxy in
            let wide=proxy.size.width>=740
            ZStack {
                PumpkinBackdrop(darkness:lantern.darkness)
                VStack(spacing:8) {
                    header
                    if wide {
                        HStack(spacing:0) {
                            workspace
                            controls.frame(width:300)
                        }
                    } else {
                        workspace.frame(maxWidth:.infinity,maxHeight:.infinity)
                        controls.frame(height:step == .light ? 235 : step == .carve ? 184 : step == .choose ? 170 : 112)
                    }
                }
                if revealing {reveal.transition(.opacity)}
            }
        }.foregroundColor(PumpkinLook.ink).navigationBarHidden(true).statusBar(hidden:true)
            .task(id:lantern) {
                guard !saved else {return}
                do {try await Task.sleep(nanoseconds:650_000_000)} catch {return}
                library.saveDraft(lantern)
            }
            .onChange(of:phase) {value in if value != .active && !saved {library.saveDraft(lantern)}}
            .task(id:warning) {
                guard warning else {return}
                do {try await Task.sleep(nanoseconds:2_800_000_000)} catch {return}
                warning=false
            }
    }
    private var header:some View {
        HStack(spacing:8) {
            CreatorToolButton(mark:.close,label:words.t("close")) {if library.saveDraft(lantern) {onClose()}}
            CreatorToolButton(mark:.undo,label:words.t("undo"),action:undo).disabled(history.isEmpty)
            CreatorToolButton(mark:.redo,label:words.t("redo"),action:redo).disabled(future.isEmpty)
            Spacer(minLength:0)
            RoundButton(icon:"leaf.fill",label:words.t("lanternGarden")) {if library.saveDraft(lantern) {onGarden()}}
            CreatorToolButton(mark:.done,label:words.t("lanternReveal"),tint:.orange) {showReveal()}
        }.padding(.horizontal,12).padding(.top,8)
    }
    private var workspace:some View {
        VStack(spacing:4) {
            HStack(spacing:8) {
                ForEach(PumpkinStep.allCases,id:\.rawValue) {item in
                    Button {go(item)} label:{
                        Text(["🍊","🥄","✂️","🕯️"][item.rawValue]).font(.system(size:24))
                            .frame(maxWidth:.infinity,minHeight:46)
                            .background(Capsule().fill(step == item ? PumpkinLook.cream : .white.opacity(0.35)))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("lanternStep\(item.rawValue)"))
                        .accessibilityAddTraits(step == item ? .isSelected : [])
                }
            }.padding(.horizontal,14)
            if warning || prompt != nil {
                Text(words.t(warning ? (lantern.cuts.count>=80 ? "lanternCutLimit" : "lanternCloseStroke") : "lanternIdea\(prompt ?? 0)"))
                    .font(.system(size:13,weight:.bold,design:.rounded)).multilineTextAlignment(.center)
                    .padding(10).background(Capsule().fill(PumpkinLook.cream)).padding(.horizontal,12)
            }
            PumpkinEditorStage(lantern:$lantern,step:step,tool:tool,stamp:stamp,selected:$selected,onBegin:begin,onEnd:finish,onWarning:{warning=true})
                .frame(maxWidth:.infinity,maxHeight:.infinity)
            HStack(spacing:14) {
                PlayToken(symbol:"💡",label:words.t("lanternIdea")) {
                    if let current=prompt {prompt=current>=5 ? nil : current+1} else {prompt=0}
                }
                Text(words.t(step == .carve ? "lanternCarveHint" : "lanternStep\(step.rawValue)"))
                    .font(.system(size:12,weight:.bold,design:.rounded)).multilineTextAlignment(.center)
                Spacer(minLength:0)
                if step == .carve,selected != nil {
                    CreatorToolButton(mark:.duplicate,label:words.t("copyPiece"),action:duplicate)
                } else if step != .light {
                    CreatorToolButton(mark:.done,label:words.t("continue"),tint:PumpkinLook.cream) {
                        go(PumpkinStep(rawValue:min(3,step.rawValue+1)) ?? .light)
                    }
                }
            }.padding(.horizontal,16).padding(.bottom,8).foregroundColor(lantern.darkness>0.5 ? PumpkinLook.cream : PumpkinLook.ink)
        }
    }
    @ViewBuilder private var controls:some View {
        VStack(spacing:10) {
            switch step {
            case .choose:
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:9) {
                        ForEach(PumpkinForm.allCases,id:\.rawValue) {form in
                            Button {change {$0.form=form}} label:{
                                PumpkinIllustration(lantern:preview(form),animated:false)
                                    .frame(width:65,height:70).padding(3)
                                    .background(RoundedRectangle(cornerRadius:19).fill(form == lantern.form ? Color.orange.opacity(0.35) : .white))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("lanternForm\(form.rawValue)"))
                        }
                    }.padding(.horizontal,14)
                }
                HStack(spacing:6) {
                    ForEach(0..<6) {index in
                        Button {change {$0.color=index}} label:{
                            Circle().fill(PumpkinLook.skin[index]).frame(width:36,height:36)
                                .overlay(Circle().stroke(lantern.color == index ? PumpkinLook.ink : .white,lineWidth:3))
                                .frame(width:44,height:44).contentShape(Rectangle())
                        }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("color")+" \(index+1)")
                    }
                }
            case .scoop:
                ProgressView(value:lantern.scooped).tint(.orange).padding(.horizontal,24)
                Button {change {$0.scooped=1};go(.carve)} label:{
                    Label(words.t("lanternSkipScoop"),systemImage:"arrow.right").font(.system(.headline,design:.rounded)).frame(minHeight:48)
                }.buttonStyle(SquishStyle())
            case .carve:
                HStack(spacing:7) {
                    ForEach(PumpkinTool.allCases,id:\.rawValue) {item in
                        PlayToken(symbol:["🔺","✏️","✋","🍊"][item.rawValue],label:words.t("lanternTool\(item.rawValue)"),selected:tool == item) {finish();tool=item}
                    }
                    Spacer(minLength:0)
                    PlayToken(symbol:"😊",label:words.t("lanternFace")) {change {$0.addFace()};tool = .move}
                        .disabled(lantern.cuts.count>77)
                }.padding(.horizontal,14)
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:10) {
                        ForEach(PumpkinCutKind.allCases.filter {$0 != .freehand},id:\.rawValue) {kind in
                            Button {stamp=kind;tool = .stamp} label:{
                                Canvas {context,size in
                                    let path=PumpkinGeometry.stencil(kind).applying(CGAffineTransform(a:size.width-14,b:0,c:0,d:size.height-14,tx:7,ty:7))
                                    context.fill(path,with:.color(PumpkinLook.ink))
                                }.frame(width:54,height:54)
                                    .background(RoundedRectangle(cornerRadius:17).fill(stamp == kind && tool == .stamp ? .orange.opacity(0.4) : .white))
                            }.buttonStyle(SquishStyle()).disabled(lantern.cuts.count>=80)
                                .accessibilityLabel(words.t("lanternStamp\(kind.rawValue)"))
                        }
                    }.padding(.horizontal,14)
                }
            case .light:
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:5) {
                    ForEach(PumpkinLight.allCases,id:\.rawValue) {kind in
                        Button {change {$0.light=kind;$0.lit=true};SoundService.shared.instrument(1,beat:kind.rawValue)} label:{
                            VStack(spacing:1) {
                                Circle().fill(PumpkinLook.light(kind,time:2)).frame(width:28,height:28)
                                    .overlay(Text(kind == .candle ? "🕯️" : kind == .fireflies ? "✦" : kind == .rainbow ? "🌈" : "").font(.system(size:20)))
                                Text(words.t(kind.key)).font(.system(size:10,weight:.bold,design:.rounded)).lineLimit(1)
                            }.frame(maxWidth:.infinity,minHeight:51)
                                .background(RoundedRectangle(cornerRadius:15).fill(lantern.light == kind ? .orange.opacity(0.25) : .white))
                        }.buttonStyle(SquishStyle())
                    }
                    Button {change {$0.lit.toggle()}} label:{
                        Text(lantern.lit ? "💡" : "🌑").font(.system(size:28)).frame(maxWidth:.infinity,minHeight:51)
                    }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("lanternToggle"))
                }.padding(.horizontal,14)
                HStack {Text("☀️");Slider(value:Binding(get:{lantern.darkness},set:{value in lantern.darkness=value}),in:0...1,onEditingChanged:{editing in if editing {begin()} else {finish()}});Text("🌙")}
                    .padding(.horizontal,18).accessibilityLabel(words.t("lanternNight"))
                HStack {Text("◔");Slider(value:Binding(get:{lantern.brightness},set:{lantern.brightness=$0}),in:0.2...1,onEditingChanged:{editing in if editing {begin()} else {finish()}});Text("☀︎")}
                    .padding(.horizontal,18).accessibilityLabel(words.t("lanternBrightness"))
            }
        }.padding(.vertical,12).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(RoundedRectangle(cornerRadius:26).fill(LinearGradient(colors:[
                Color(red:1,green:0.98,blue:0.87),PumpkinLook.cream,Color(red:1,green:0.84,blue:0.53)],
                startPoint:.topLeading,endPoint:.bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius:26).stroke(Color.white.opacity(0.7),lineWidth:2).allowsHitTesting(false))
            .shadow(color:PumpkinLook.ink.opacity(0.22),radius:12,x:0,y:6)
    }
    private var reveal:some View {
        GeometryReader {proxy in
            ZStack {
                PumpkinBackdrop(darkness:1)
                VStack(spacing:8) {
                    HStack {
                        RoundButton(icon:"chevron.left",label:words.t("lanternBackToCut")) {revealing=false}
                        Spacer()
                        Text(words.t("pumpkinTitle")).font(.system(.title2,design:.rounded).weight(.heavy)).foregroundColor(PumpkinLook.cream)
                    }.padding(16)
                    PumpkinIllustration(lantern:lantern,animated:true,lidLift:lid)
                        .frame(maxWidth:600,maxHeight:.infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {cheer+=1;SoundService.shared.react(voice:2)}
                        .gesture(DragGesture(minimumDistance:35).onEnded {value in
                            if abs(value.translation.width)>45 {lantern.lit=false;puff+=1}
                        })
                    Text(words.t(lantern.lit ? "lanternRevealHint" : "lanternPuff")).font(.system(.headline,design:.rounded)).foregroundColor(PumpkinLook.cream)
                    CandyButton(title:words.t("lanternSave"),icon:"leaf.fill",color:.orange) {
                        if library.save(lantern) {saved=true;SoundService.shared.play(.complete);onGarden()}
                    }.frame(maxWidth:400).padding(20)
                }
                PlayCelebration(revision:cheer)
            }
        }
        .task(id:cheer) {
            guard cheer>0,!reduced else {return}
            withAnimation(.spring(response:0.3,dampingFraction:0.55)) {lid=28}
            do {try await Task.sleep(nanoseconds:350_000_000)} catch {return}
            withAnimation(.spring(response:0.4,dampingFraction:0.6)) {lid=0}
        }
        .task(id:puff) {
            guard puff>0 else {return}
            do {try await Task.sleep(nanoseconds:1_600_000_000)} catch {return}
            lantern.lit=true;SoundService.shared.instrument(1,beat:lantern.light.rawValue)
        }
    }
    private func preview(_ form:PumpkinForm)->PumpkinLantern {var p=PumpkinLantern();p.form=form;p.color=lantern.color;p.lit=false;return p}
    private func begin() {if transaction == nil {transaction=lantern}}
    private func finish() {
        if let before=transaction,before != lantern {remember(before);SoundService.shared.play(.click)}
        transaction=nil
    }
    private func remember(_ before:PumpkinLantern) {history.append(before);if history.count>60 {history.removeFirst()};future=[]}
    private func change(_ update:(inout PumpkinLantern)->Void) {
        finish();let before=lantern;update(&lantern)
        if before != lantern {remember(before);SoundService.shared.play(.click)}
    }
    private func undo() {finish();guard let p=history.popLast() else {return};future.append(lantern);lantern=p;selected=nil}
    private func redo() {guard let p=future.popLast() else {return};history.append(lantern);lantern=p;selected=nil}
    private func go(_ value:PumpkinStep) {finish();lantern.step=value.rawValue;if value.rawValue>1 {lantern.scooped=1};selected=nil}
    private func showReveal() {
        finish();lantern.step=3;lantern.scooped=1;lantern.lit=true
        withAnimation(reduced ? nil : .easeInOut(duration:0.9)) {lantern.darkness=1;revealing=true}
        cheer+=1;SoundService.shared.play(.complete)
    }
    private func duplicate() {
        guard lantern.cuts.count<80,let id=selected,let source=lantern.cuts.first(where:{$0.id == id}) else {return}
        var copy=source;copy.id=UUID();copy.move(x:copy.x+0.12,y:copy.y)
        change {$0.cuts.append(copy)};selected=copy.id;tool = .move
    }
}
