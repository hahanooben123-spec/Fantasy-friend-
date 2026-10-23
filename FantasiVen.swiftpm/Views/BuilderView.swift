import SwiftUI
import UniformTypeIdentifiers

struct BuilderView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    let original: FantasyFriend
    let existing: Bool
    var resuming=false
    @Environment(\.scenePhase) private var phase
    @State private var friend: FantasyFriend
    @State private var history: [FantasyFriend] = []
    @State private var future: [FantasyFriend] = []
    @State private var transaction: FantasyFriend?
    @State private var part = Part.body
    @State private var selection: CreatorSelection? = .body
    @State private var incoming: CreatorPick?
    @State private var paintColor = 1
    @State private var brushWidth = 9.0
    @State private var secondary = false
    @State private var naming = false
    @State private var starters = false
    @State private var personality = false
    @State private var celebration = false
    @State private var discard = false
    @State private var revision = 0
    @State private var moreTools=false
    @State private var dragPick:CreatorPick?
    @State private var dragPoint=CGPoint.zero
    @State private var stageFrame=CGRect.zero
    private let categories: [Part] = [.body,.color,.eyes,.mouth,.arms,.legs,.extras,.paint]

    init(original: FantasyFriend, existing: Bool, resuming:Bool=false) {
        self.original=original;self.existing=existing;self.resuming=resuming
        _friend=State(initialValue:original)
    }
    var body: some View {
        GeometryReader { geometry in
            let wide=geometry.size.width>=740
            ZStack {
                StorybookWorkshopWall().ignoresSafeArea()
                VStack(spacing:0) {
                    header(wide:wide)
                    if wide {
                        HStack(spacing:0) {
                            categoryRail(vertical:true).frame(width:84)
                            scene
                            drawer(wide:true).frame(width:min(320,geometry.size.width*0.3))
                        }
                    } else {
                        scene.frame(maxWidth:.infinity,maxHeight:.infinity)
                        categoryRail(vertical:false).frame(height:78)
                        drawer(wide:false).frame(height:min(220,max(164,geometry.size.height*0.28)))
                    }
                }
                if let pick=dragPick {
                    choiceArt(pick.index).frame(width:92,height:94)
                        .shadow(color:GameStyle.ink.opacity(0.25),radius:8,y:8)
                        .position(dragPoint).allowsHitTesting(false)
                }
                if celebration { celebrationView }
                if let message=store.error {
                    VStack {
                        Spacer()
                        HStack(spacing:12) {
                            Text(message).font(.system(.subheadline,design:.rounded)).fixedSize(horizontal:false,vertical:true)
                            Button("OK") {store.error=nil}.font(.headline).frame(minWidth:48,minHeight:48)
                        }.padding(16).background(CandySurface(color:WorkshopLook.cream,cornerRadius:24))
                            .padding(18)
                    }.foregroundColor(GameStyle.ink)
                }
            }.coordinateSpace(name:"creatorWorkshop")
                .onPreferenceChange(CreatorStageFrameKey.self) {stageFrame=$0}
        }.foregroundColor(WorkshopLook.sea)
            .sheet(isPresented:$starters) {
                StarterFriendsSheet(onChoose:chooseStarter,onClose:{starters=false}).environmentObject(store)
            }
            .task {if !existing && !resuming {starters=true}}
            .task(id:friend) {
                guard !celebration else {return}
                do {try await Task.sleep(nanoseconds:650_000_000)} catch {return}
                guard !celebration else {return}
                store.saveEditorDraft(friend,existing:existing)
            }
            .onChange(of:phase) {value in
                if value != .active && !celebration {dragPick=nil;incoming=nil;finishGesture();store.saveEditorDraft(friend,existing:existing)}
            }
            .onDisappear {if !celebration {store.saveEditorDraft(friend,existing:existing)}}
            .sheet(isPresented:$moreTools) {advancedTools}
            .sheet(isPresented:$naming) {
                NamingView(friend:$friend) {
                    if store.save(friend) { naming=false;celebration=true;store.clearEditorDraft(friend.id) }
                }.environmentObject(store)
            }
            .sheet(isPresented:$personality) {
                CreatorPersonalitySheet(friend:Binding(get:{friend},set:{value in change { $0=value }})).environmentObject(store)
            }
            .alert(store.t("discard"),isPresented:$discard) {
                Button(store.t("cancel"),role:.cancel) {}
                Button(store.t("leave"),role:.destructive) { presentation.wrappedValue.dismiss() }
            } message: { Text(store.t("discardHint")) }
    }
    private func header(wide:Bool)->some View {
        HStack(spacing:10) {
            CreatorToolButton(mark:.close,label:store.t("close")) {
                finishGesture()
                if store.saveEditorDraft(friend,existing:existing) {presentation.wrappedValue.dismiss()}
            }
            if wide {
                VStack(alignment:.leading,spacing:2) {
                    Text(store.t("creatorTitle")).font(.system(size:22,weight:.heavy,design:.rounded))
                    Text(store.t("creatorTagline")).font(.system(size:12,weight:.medium,design:.rounded))
                }.foregroundColor(.white)
            }
            Spacer(minLength:2)
            CreatorToolButton(mark:.undo,label:store.t("undo"),action:undo).disabled(history.isEmpty).opacity(history.isEmpty ? 0.35 : 1)
            CreatorToolButton(mark:.redo,label:store.t("redo"),action:redo).disabled(future.isEmpty).opacity(future.isEmpty ? 0.35 : 1)
            CreatorToolButton(mark:.voice,label:store.t("personality")) { personality=true }
            CreatorToolButton(mark:.done,label:store.t("save"),tint:WorkshopLook.yellow) { finishGesture();naming=true }
        }.padding(.horizontal,14).padding(.vertical,10)
    }
    private var scene: some View {
        ZStack {
            CreatorRoomArtwork()
            VStack(spacing:0) {
                HStack {
                    Button {finishGesture();starters=true} label:{
                        Label(store.t("starterButton"),systemImage:"sparkles")
                            .font(.system(size:14,weight:.bold,design:.rounded))
                            .padding(.horizontal,16).padding(.vertical,12)
                            .background(CandySurface(color:WorkshopLook.cream,cornerRadius:22))
                    }.buttonStyle(SquishStyle())
                    Spacer()
                    CreatorToolButton(mark:.shuffle,label:store.t("surprise"),tint:WorkshopLook.yellow) { surprise() }
                }.padding(.horizontal,18).padding(.top,12)
                CreatorStage(friend:$friend,selection:$selection,incoming:$incoming,part:part,
                    brush:part == .paint ? PaintTool(color:paintColor,width:brushWidth) : nil,
                    revision:revision,onBegin:beginGesture,onEnd:finishGesture,onDrop:{ pick, point in apply(pick,at:point) })
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                selectionTools.padding(.bottom,12)
            }
        }
    }
    @ViewBuilder private func categoryRail(vertical:Bool)->some View {
        if vertical {
            ScrollView(.vertical,showsIndicators:false) {
                VStack(spacing:6) { categoryButtons }.padding(.vertical,14)
            }
        } else {
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:5) { categoryButtons }.padding(.horizontal,10).padding(.vertical,6)
            }
        }
    }
    private var categoryButtons: some View {
        ForEach(categories,id:\.rawValue) { item in
            Button {
                finishGesture();part=item;incoming=nil
                if item == .body { selection = .body }
                if item == .eyes { selection = .eyes }
                if item == .mouth { selection = .mouth }
                if item == .paint { selection=nil }
                SoundService.shared.play(.click)
            } label: {
                VStack(spacing:1) {
                    CreatorCategoryIcon(part:item).frame(width:43,height:42)
                    Text(store.t(Words.partKeys[item.rawValue])).font(.system(size:10,weight:.heavy,design:.rounded)).lineLimit(1)
                }.foregroundColor(part == item ? WorkshopLook.sea : .white)
                    .frame(width:67,height:65)
                    .background {if part == item {CandySurface(color:WorkshopLook.yellow,cornerRadius:18)}}
                    .contentShape(Rectangle())
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(Words.partKeys[item.rawValue]))
                .accessibilityAddTraits(part == item ? .isSelected : [])
        }
    }
    private func drawer(wide:Bool)->some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {
                Text(store.t(Words.partKeys[part.rawValue])).font(.system(size:20,weight:.heavy,design:.rounded))
                Spacer()
                if part == .eyes {
                    CreatorToolButton(mark:.add,label:store.t("creatorExtraEye"),tint:WorkshopLook.yellow) {
                        addPiece(.eye,index:friend.eyes,at:CGPoint(x:150,y:105))
                    }.scaleEffect(0.85).frame(width:42,height:42)
                } else if part == .color {
                    Button { secondary.toggle() } label: {
                        Text(store.t(secondary ? "accent" : "color")).font(.system(size:12,weight:.bold,design:.rounded))
                            .padding(10).background(Capsule().fill(WorkshopLook.yellow))
                    }.buttonStyle(SquishStyle())
                } else {
                    Text(store.t("creatorTrayHint")).font(.system(size:11,weight:.semibold,design:.rounded)).opacity(0.6)
                }
            }.frame(height:36).padding(.horizontal,16)
            if part == .color || part == .paint {
                colors(wide:wide)
                if part == .paint { brushTools }
            } else {
                ScrollView(wide ? .vertical : .horizontal,showsIndicators:false) {
                    if wide {
                        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                            choices(wide:wide)
                        }.padding(12)
                    } else {
                        HStack(alignment:.center,spacing:14) { choices(wide:wide) }.padding(.horizontal,16).padding(.vertical,5)
                    }
                }.id(part)
            }
        }.padding(.top,12).padding(.bottom,10).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(StorybookShelf())
    }
    private func choices(wide:Bool)->some View {
        ForEach(0..<optionCount,id:\.self) { index in
            Button { apply(CreatorPick(part:part,index:index),at:nil) } label: {
                VStack(spacing:2) {
                    choiceArt(index).frame(width:87,height:83)
                    if part == .body {
                        Text(store.t(Words.bodyKeys[index])).font(.system(size:11,weight:.bold,design:.rounded))
                    }
                }.foregroundColor(WorkshopLook.sea).padding(7)
                    .background(CandySurface(color:chosen(index) ? WorkshopLook.yellow : StorybookStyle.cream,cornerRadius:23))
                    .overlay(RoundedRectangle(cornerRadius:23).stroke(chosen(index) ? WorkshopLook.blue : WorkshopLook.sea.opacity(0.12),lineWidth:chosen(index) ? 3 : 1))
                    .contentShape(Rectangle())
            }.buttonStyle(SquishStyle())
                .accessibilityLabel(store.t(Words.partKeys[part.rawValue])+" \(index+1)")
                .simultaneousGesture(pickGesture(CreatorPick(part:part,index:index),wide:wide))
        }
    }
    @ViewBuilder private func choiceArt(_ index:Int)->some View {
        if part == .arms || part == .legs || part == .extras {
            CreativePieceView(piece:CreativePiece(kind:part == .arms ? .arm : part == .legs ? .leg : .extra,variant:index,color:friend.color,accent:friend.accent))
        } else {
            CharacterView(friend:sample(index),detail:part == .eyes || part == .mouth ? part : nil)
        }
    }
    private func sample(_ index:Int)->FantasyFriend {
        var f=friend;f.pieces=nil;f.doodles=nil;f.placements=nil;f.facePlacements=nil;f.hiddenParts=nil;f.mirroredParts=nil
        if part == .body { f.body=BodyKind(rawValue:index) ?? .round;f.accessories=[] }
        if part == .eyes { f.eyes=index }
        if part == .mouth { f.mouth=index }
        return f
    }
    private var optionCount:Int {
        switch part { case .body,.arms,.legs:return 8;case .eyes:return 12;case .mouth:return 10;case .extras:return 15;default:return 16 }
    }
    private func chosen(_ index:Int)->Bool {
        switch part {
        case .body:return friend.body.rawValue==index
        case .eyes:return friend.eyes==index && !friend.isHidden("eyes")
        case .mouth:return friend.mouth==index && !friend.isHidden("mouth")
        default:return false
        }
    }
    private func colors(wide:Bool)->some View {
        ScrollView(wide ? .vertical : .horizontal,showsIndicators:false) {
            if wide {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:14) { colorChoices }.padding(14)
            } else {
                HStack(spacing:13) { colorChoices }.padding(.horizontal,18).padding(.vertical,8)
            }
        }
    }
    private var colorChoices: some View {
        ForEach(0..<16) { index in
            Button {
                if part == .paint { paintColor=index;SoundService.shared.play(.click) }
                else { tint(index) }
            } label: {
                RoundedRectangle(cornerRadius:17).fill(GameStyle.palette[index]).frame(width:48,height:48)
                    .overlay(Ellipse().fill(.white.opacity(0.45)).frame(width:20,height:8).offset(x:-6,y:-12))
                    .rotationEffect(.degrees(index.isMultiple(of:2) ? -7 : 6))
                    .overlay(RoundedRectangle(cornerRadius:17).stroke(WorkshopLook.sea.opacity(0.3),lineWidth:2))
                    .padding(3).contentShape(Rectangle())
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("color")+" \(index+1)")
        }
    }
    private var brushTools: some View {
        HStack(spacing:12) {
            ForEach([4.0,9.0,17.0],id:\.self) { width in
                Button { brushWidth=width } label: {
                    Circle().fill(GameStyle.palette[paintColor]).frame(width:width+6,height:width+6)
                        .frame(width:44,height:44).background(Circle().fill(brushWidth==width ? WorkshopLook.yellow : .white))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("brushSize")+" \(Int(width))")
            }
            Spacer()
            CreatorToolButton(mark:.trash,label:store.t("clearPaint")) { change { $0.doodles=nil } }.disabled(friend.doodles?.isEmpty ?? true)
        }.padding(.horizontal,16)
    }
    private var selectionTools: some View {
        HStack(spacing:12) {
            if selection != nil && selection != .body && part != .paint {
                Button {moreTools=true} label:{
                    Label(store.t("roomMore"),systemImage:"ellipsis")
                        .font(.system(size:14,weight:.heavy,design:.rounded))
                        .frame(width:88,height:52).background(CandySurface(color:.white,cornerRadius:18))
                }.buttonStyle(SquishStyle())
                CreatorToolButton(mark:.trash,label:store.t("removePart"),action:removeSelection)
                Button { part = .color } label: {
                    ZStack { Circle().fill(GameStyle.palette[friend.color]).frame(width:26,height:26).offset(x:-6);Circle().fill(GameStyle.palette[friend.accent]).frame(width:23,height:23).offset(x:8,y:7) }
                        .frame(width:48,height:48).background(RoundedRectangle(cornerRadius:17).fill(.white))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("color"))
            } else {
                Text(store.t(part == .paint ? "paintHint" : "creatorTouchHint"))
                    .font(.system(size:12,weight:.bold,design:.rounded))
                    .padding(.horizontal,15).padding(.vertical,9).background(Capsule().fill(.white.opacity(0.9)))
            }
        }.frame(height:48).frame(maxWidth:.infinity)
    }
    private func pickGesture(_ pick:CreatorPick,wide:Bool)->some Gesture {
        DragGesture(minimumDistance:12,coordinateSpace:.named("creatorWorkshop")).onChanged {value in
            if dragPick == nil {
                let across=abs(value.translation.width),up=abs(value.translation.height)
                guard wide ? across>up*0.7 : up>across*0.7 else {return}
                finishGesture();SoundService.shared.play(.click)
            }
            dragPick=pick;incoming=pick;dragPoint=value.location
        }.onEnded {value in
            defer {dragPick=nil;incoming=nil}
            guard dragPick != nil,stageFrame.width>0,stageFrame.height>0,stageFrame.contains(value.location) else {return}
            var point=CGPoint(x:((value.location.x-stageFrame.minX)/stageFrame.width-0.5)/1.1*300+150,
                              y:((value.location.y-stageFrame.minY)/stageFrame.height-0.5)/1.1*320+160)
            let anchors:[CGPoint]
            switch pick.part {
            case .eyes:anchors=[CGPoint(x:150,y:157)]
            case .mouth:anchors=[CGPoint(x:151,y:207)]
            case .arms:anchors=[CGPoint(x:74,y:181),CGPoint(x:226,y:181)]
            case .legs:anchors=[CGPoint(x:117,y:265),CGPoint(x:183,y:265)]
            default:anchors=[]
            }
            if let nearest=anchors.min(by:{hypot($0.x-point.x,$0.y-point.y)<hypot($1.x-point.x,$1.y-point.y)}),
               hypot(nearest.x-point.x,nearest.y-point.y)<13 {point=nearest}
            apply(pick,at:point)
        }
    }
    private var advancedTools:some View {
        VStack(spacing:22) {
            HStack {Text(store.t("roomMore")).font(.title2.bold());Spacer()
                RoundButton(icon:"xmark",label:store.t("close")) {moreTools=false}}
            CharacterView(friend:friend).frame(height:200)
            CandyButton(title:store.t("copyPiece"),icon:"square.on.square") {duplicate();moreTools=false}
                .disabled(selection == .mouth || selection == .body)
            CandyButton(title:store.t("mirror"),icon:"arrow.left.and.right") {mirror();moreTools=false}
                .disabled(selection == .body)
            Text(store.t("creatorHandleHint")).font(.system(.body,design:.rounded)).multilineTextAlignment(.center)
            Spacer(minLength:0)
        }.padding(26).background(StorybookShelf()).foregroundColor(GameStyle.ink)
    }
    private func beginGesture() { if transaction == nil { transaction=friend } }
    private func finishGesture() {
        if let before=transaction,before != friend { remember(before);revision+=1;SoundService.shared.play(.click) }
        transaction=nil
    }
    private func remember(_ before:FantasyFriend) {
        history.append(before);if history.count>60 { history.removeFirst() };future.removeAll()
    }
    private func change(_ update:(inout FantasyFriend)->Void) {
        finishGesture();let before=friend;update(&friend)
        guard before != friend else { return }
        remember(before);revision+=1;SoundService.shared.play(.click)
    }
    private func undo() {
        finishGesture();guard let old=history.popLast() else { return }
        future.append(friend);friend=old;selection=nil;revision+=1
    }
    private func redo() {
        guard let next=future.popLast() else { return }
        history.append(friend);friend=next;selection=nil;revision+=1
    }
    private func apply(_ pick:CreatorPick,_ point:CGPoint) { apply(pick,at:point) }
    private func apply(_ pick:CreatorPick,at point:CGPoint?) {
        switch pick.part {
        case .body:
            change { $0.body=BodyKind(rawValue:pick.index) ?? .round };selection = .body
        case .eyes,.mouth:
            change { value in
                let key=pick.part == .eyes ? "eyes" : "mouth"
                if pick.part == .eyes { value.eyes=pick.index } else { value.mouth=pick.index }
                value.show(key)
                if let point=point {
                    let center=pick.part == .eyes ? CGPoint(x:150,y:157) : CGPoint(x:151,y:207)
                    var pose=PartPlacement()
                    pose.x=min(0.3,max(-0.3,(point.x-center.x)/300));pose.y=min(0.3,max(-0.3,(point.y-center.y)/320))
                    var values=value.facePlacements ?? [:];values[key]=pose;value.facePlacements=values
                }
            };selection = pick.part == .eyes ? .eyes : .mouth
        case .arms: addPiece(.arm,index:pick.index,at:point ?? CGPoint(x:74,y:181))
        case .legs: addPiece(.leg,index:pick.index,at:point ?? CGPoint(x:183,y:265))
        case .extras:
            let a=Attachment.extra(pick.index)
            let rect=AttachmentLayout.bounds(for:a,friend:friend)
            addPiece(.extra,index:pick.index,at:point ?? CGPoint(x:rect.midX,y:rect.midY))
        default:break
        }
    }
    private func addPiece(_ kind:PieceKind,index:Int,at point:CGPoint) {
        guard (friend.pieces ?? []).count<64 else { return }
        var piece=CreativePiece(kind:kind,variant:index,color:friend.color,accent:friend.accent)
        piece.move(x:point.x/300,y:point.y/320,snap:false)
        change { var parts=$0.pieces ?? [];parts.append(piece);$0.pieces=parts }
        selection = .piece(piece.id)
    }
    private func tint(_ color:Int) {
        change { value in
            switch selection {
            case .piece(let id):
                if let i=value.pieces?.firstIndex(where:{$0.id==id}) {
                    if secondary { value.pieces?[i].accent=color } else { value.pieces?[i].color=color }
                }
            case .attachment(let a):
                var colors=value.partColors ?? [:];colors[a.rawValue]=color;value.partColors=colors
            case .eyes,.mouth:
                let key=selection == .eyes ? "eyes" : "mouth"
                var colors=value.partColors ?? [:];colors[key]=color;value.partColors=colors
            default:if secondary { value.accent=color } else { value.color=color }
            }
        }
    }
    private func duplicate() {
        guard let selected=selection else { return }
        switch selected {
        case .piece(let id):
            guard let source=friend.pieces?.first(where:{$0.id==id}),(friend.pieces ?? []).count<64 else { return }
            var copy=source;copy.id=UUID();copy.move(x:copy.x+0.1,y:copy.y+0.04,snap:false)
            change { var parts=$0.pieces ?? [];parts.append(copy);$0.pieces=parts };selection = .piece(copy.id)
        case .attachment(let a):
            let kind:PieceKind = a.category == .arms ? .arm : a.category == .legs ? .leg : .extra
            let index=a.extraIndex ?? (kind == .arm ? friend.arms : friend.legs)
            let center=AttachmentLayout.center(for:a,friend:friend)
            addPiece(kind,index:index,at:CGPoint(x:center.x+24,y:center.y))
        case .eyes:addPiece(.eye,index:friend.eyes,at:CGPoint(x:150,y:110))
        default:break
        }
    }
    private func mirror() {
        guard let selected=selection else { return }
        change { value in
            if case .piece(let id)=selected,let i=value.pieces?.firstIndex(where:{$0.id==id}) { value.pieces?[i].mirrored.toggle() }
            else {
                let key:String
                switch selected { case .attachment(let a):key=a.rawValue;case .eyes:key="eyes";case .mouth:key="mouth";default:return }
                var set=value.mirroredParts ?? [];if set.contains(key) { set.remove(key) } else { set.insert(key) };value.mirroredParts=set
            }
        }
    }
    private func removeSelection() {
        guard let selected=selection else { return }
        change { value in
            switch selected {
            case .piece(let id):value.pieces?.removeAll {$0.id==id}
            case .attachment(let a):value.hide(a.rawValue)
            case .eyes:value.hide("eyes")
            case .mouth:value.hide("mouth")
            case .body:break
            }
        };selection=nil
    }
    private func chooseStarter(_ seed:FriendSeed) {
        change {value in
            var replacement=seed.make()
            replacement.id=value.id
            let defaultName=FriendSeed.allCases.map(\.title).contains(value.name)
            replacement.name=value.name.isEmpty || (!existing && defaultName) ? seed.title : value.name
            replacement.world=value.world;replacement.room=value.room;replacement.roomDesign=value.roomDesign
            replacement.song=value.song;replacement.track=value.track
            value=replacement
        }
        selection = .body;incoming=nil;starters=false
        SoundService.shared.react(voice:friend.voice?.rawValue ?? 0)
    }
    private func surprise() {
        change { value in
            var random=FantasyFriend.random();random.id=value.id;random.name=value.name;random.world=value.world
            random.room=value.room;random.roomDesign=value.roomDesign;random.song=value.song;random.track=value.track
            value=random
        };selection = .body
    }
    private var celebrationView:some View {
        FriendRevealView(friend:friend,updated:existing,onFinish:{presentation.wrappedValue.dismiss()})
            .environmentObject(store)
    }
}

private struct NamingView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    @Binding var friend: FantasyFriend
    var save: () -> Void
    var body: some View {
        ZStack {
            StudioBackdrop()
            ScrollView {
                VStack(spacing: 22) {
                    HStack { Spacer(); RoundButton(icon: "xmark", label: store.t("close")) { presentation.wrappedValue.dismiss() } }
                    LivingFriend(friend: friend).frame(height: 210)
                    Text(store.t("name")).font(.system(.title2, design: .rounded).weight(.heavy))
                    TextField(store.t("name"), text: Binding(get: { friend.name }, set: { friend.name = String($0.prefix(30)) }))
                        .font(.system(.title2, design: .rounded)).multilineTextAlignment(.center)
                        .padding(18).background(RoundedRectangle(cornerRadius: 20).fill(.white))
                        .submitLabel(.done)
                    HStack(spacing: 9) {
                        ForEach(Array(Words.names.prefix(4)), id: \.self) { suggestion in
                            Button { friend.name = suggestion } label: {
                                Text(suggestion).font(.system(.caption, design: .rounded).weight(.heavy))
                                    .padding(.horizontal, 10).frame(minHeight: 44)
                                    .background(Capsule().fill(StudioStyle.colors[0].opacity(0.4)))
                            }.buttonStyle(SquishStyle())
                        }
                    }
                    CandyButton(title: store.t("suggest"), icon: "shuffle", color: Color(red: 0.28, green: 0.66, blue: 0.60)) {
                        friend.name = Words.names.filter { $0 != friend.name }.randomElement() ?? "Bimse"
                    }
                    CandyButton(title: store.t("save"), icon: "checkmark") {
                        friend.name = friend.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if friend.name.isEmpty { friend.name = Words.names.randomElement() ?? "Bimse" }
                        save()
                    }
                    if let error = store.error { Text(error).font(.system(.body, design: .rounded)).foregroundColor(GameStyle.ink).accessibilityAddTraits(.updatesFrequently) }
                }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
            }
        }.foregroundColor(GameStyle.ink)
    }
}
