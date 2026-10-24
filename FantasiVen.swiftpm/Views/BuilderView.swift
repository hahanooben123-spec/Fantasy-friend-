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
    @State private var trying=false
    @State private var naming = false
    @State private var starters = false
    @State private var personality = false
    @State private var celebration = false
    @State private var discard = false
    @State private var revision = 0
    @State private var personalityAfterMore=false
    @State private var moreTools=false
    @State private var dragPick:CreatorPick?
    @State private var dragPoint=CGPoint.zero
    @State private var stageFrame=CGRect.zero
    private let categories: [Part] = [.body,.color,.eyes,.mouth,.arms,.legs,.extras,.paint]

    init(original: FantasyFriend, existing: Bool, resuming:Bool=false) {
        self.original=original;self.existing=existing;self.resuming=resuming
        _friend=State(initialValue:original.simplifiedForCreator())
    }
    var body: some View {
        GeometryReader { geometry in
            let wide=geometry.size.width>=740
            ZStack {
                StorybookWorkshopWall().ignoresSafeArea()
                VStack(spacing:0) {
                    header(wide:wide)
                    PlayWorkspace(wide:wide,toolWidth:min(310,geometry.size.width*0.35),toolHeight:244) {
                        scene
                    } tools: {
                        VStack(spacing:0) {
                            categoryRail(vertical:false).frame(height:74)
                            drawer(wide:wide)
                        }.background(StorybookShelf())
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
            .onAppear {SoundService.shared.setWorld(.castle)}
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
            .fullScreenCover(isPresented:$trying) {
                CreatorTryRoom(friend:friend,onReturn:{trying=false}).environmentObject(store)
            }
            .sheet(isPresented:$moreTools,onDismiss:{
                if personalityAfterMore {personalityAfterMore=false;personality=true}
            }) {advancedTools}
            .sheet(isPresented:$naming) {
                NamingView(friend:$friend) {
                    finishFriend()
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
        HStack(spacing:8) {
            RoundButton(icon:"chevron.left",label:store.t("back")) {
                finishGesture()
                if store.saveEditorDraft(friend,existing:existing) {presentation.wrappedValue.dismiss()}
            }
            if wide {VillageCaption(title:store.t("creatorTitle"),size:23)}
            Spacer(minLength:2)
            CreatorToolButton(mark:.undo,label:store.t("undo"),action:undo).disabled(history.isEmpty).opacity(history.isEmpty ? 0.35 : 1)
            RoundButton(icon:"ellipsis",label:store.t("roomMore")) {finishGesture();moreTools=true}
            Button {finishGesture();naming=true} label:{
                HStack(spacing:6) {
                    Image(systemName:"checkmark").font(.system(size:21,weight:.heavy))
                    Text(store.t("done")).font(.system(size:15,weight:.heavy,design:.rounded))
                }.padding(.horizontal,16).frame(minHeight:52)
                    .background(CandySurface(color:StorybookStyle.honey,cornerRadius:25))
            }.buttonStyle(SquishStyle())
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
                    RoundButton(icon:"play.fill",label:store.t("creatorTryTitle")) {
                        finishGesture();selection=nil;trying=true
                    }
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
                if item == .paint || item == .arms || item == .legs || item == .extras || item == .color {selection=nil}
                SoundService.shared.play(.click)
            } label: {
                VStack(spacing:1) {
                    CreatorCategoryIcon(part:item).frame(width:43,height:42)
                    Text(store.t(Words.partKeys[item.rawValue])).font(.system(size:10,weight:.heavy,design:.rounded)).lineLimit(1)
                }.foregroundColor(WorkshopLook.sea)
                    .frame(width:67,height:59)
                    .background(GameChoiceSurface(selected:part == item,tint:StudioStyle.color(item)))
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
                if part == .color {
                    Button { secondary.toggle() } label: {
                        Text(store.t(secondary ? "accent" : "color")).font(.system(size:12,weight:.bold,design:.rounded))
                            .padding(10).background(Capsule().fill(WorkshopLook.yellow))
                    }.buttonStyle(SquishStyle())
                } else if part == .body {
                    Button {change {$0.bodySculpt=nil;$0.bodyWidth=nil;$0.bodyHeight=nil}} label:{
                        Image(systemName:"arrow.counterclockwise").font(.system(size:18,weight:.bold))
                            .frame(width:44,height:44).background(StorybookPanel(cornerRadius:16))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("creatorResetClay"))
                }
            }.frame(height:48).padding(.horizontal,16)
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
    }
    private func choices(wide:Bool)->some View {
        ForEach(0..<optionCount,id:\.self) { index in
            Button { apply(CreatorPick(part:part,index:index),at:nil) } label: {
                VStack(spacing:2) {
                    choiceArt(index).frame(width:wide ? 87 : 72,height:wide ? 83 : 67)
                    if part == .body {
                        Text(store.t(Words.bodyKeys[index])).font(.system(size:11,weight:.bold,design:.rounded))
                    }
                }.foregroundColor(WorkshopLook.sea).padding(7)
                    .background(GameChoiceSurface(selected:chosen(index)))
                    .contentShape(Rectangle())
            }.buttonStyle(SquishStyle())
                .accessibilityLabel(store.t(Words.partKeys[part.rawValue])+" \(index+1)")
                .accessibilityAddTraits(chosen(index) ? .isSelected : [])
        }
    }
    @ViewBuilder private func choiceArt(_ index:Int)->some View {
        if part == .arms || part == .legs {
            HStack(spacing:0) {
                CreativePieceView(piece:CreativePiece(kind:part == .arms ? .arm : .leg,variant:index,color:friend.color,accent:friend.accent))
                    .scaleEffect(x:-1,y:1)
                CreativePieceView(piece:CreativePiece(kind:part == .arms ? .arm : .leg,variant:index,color:friend.color,accent:friend.accent))
            }
        } else if part == .extras {
            CreativePieceView(piece:CreativePiece(kind:.extra,variant:index,color:friend.color,accent:friend.accent))
        } else {
            CharacterView(friend:sample(index),detail:part == .eyes || part == .mouth ? part : nil)
        }
    }
    private func sample(_ index:Int)->FantasyFriend {
        var f=friend;f.pieces=nil;f.doodles=nil;f.placements=nil;f.facePlacements=nil;f.hiddenParts=nil;f.mirroredParts=nil
        if part == .body { f.body=BodyKind(rawValue:index) ?? .round;f.bodySculpt=nil;f.bodyWidth=nil;f.bodyHeight=nil;f.accessories=[] }
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
        case .arms:return friend.arms==index
        case .legs:return friend.legs==index
        case .extras:return friend.accessories.contains(index)
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
    private var activeLimbSize:Double {part == .arms ? (friend.armSize ?? 1) : (friend.legSize ?? 1)}
    private var selectionTools: some View {
        HStack(spacing:10) {
            if part == .arms || part == .legs {
                ForEach(Array([0.75,1.0,1.25].enumerated()),id:\.offset) {index,size in
                    Button {change {$0.resizeLimbs(part,size:size)}} label:{
                        VStack(spacing:3) {
                            CreatorCategoryIcon(part:part).frame(width:CGFloat(31)*CGFloat(size),height:CGFloat(31)*CGFloat(size))
                                .frame(height:38)
                            Text(store.t("creatorSize\(index)")).font(.system(size:11,weight:.heavy,design:.rounded))
                        }.frame(width:78,height:64)
                            .background(GameChoiceSurface(selected:abs(activeLimbSize-size)<0.02))
                            .contentShape(Rectangle())
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("creatorLimbSize")+" "+store.t("creatorSize\(index)"))
                }
            } else {
                Text(store.t(part == .body ? "creatorClayHint" : part == .paint ? "paintHint" : "creatorChooseHint"))
                    .font(.system(size:12,weight:.bold,design:.rounded))
                    .multilineTextAlignment(.center).foregroundColor(GameStyle.ink)
                    .padding(.horizontal,15).padding(.vertical,8)
            }
        }.frame(height:66).frame(maxWidth:.infinity)
    }
    private var advancedTools:some View {
        ScrollView {
        VStack(spacing:22) {
            HStack {Text(store.t("roomMore")).font(.title2.bold());Spacer()
                RoundButton(icon:"xmark",label:store.t("close")) {moreTools=false}}
            CharacterView(friend:friend).frame(height:200)
            CandyButton(title:store.t("personality"),icon:"music.note") {
                personalityAfterMore=true;moreTools=false
            }
            CandyButton(title:store.t("redo"),icon:"arrow.uturn.forward") {redo();moreTools=false}
                .disabled(future.isEmpty)
            Spacer(minLength:0)
        }.padding(26).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.background(StorybookShelf()).foregroundColor(GameStyle.ink)
    }
    private func finishFriend() {
        if friend.room == nil {
            var home=RoomLayout.starter(friend.color%3)
            home.design.wallpaper=friend.color%6
            friend.room=home.objects;friend.roomDesign=home.design
        }
        if store.save(friend) {naming=false;celebration=true;store.clearEditorDraft(friend.id)}
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
        case .arms: change {$0.chooseLimb(.arms,index:pick.index)};selection=nil
        case .legs: change {$0.chooseLimb(.legs,index:pick.index)};selection=nil
        case .extras:
            let a=Attachment.extra(pick.index)
            change {value in
                value.pieces?.removeAll {$0.kind == .extra && $0.variant == pick.index}
                if value.accessories.contains(pick.index) {value.accessories.remove(pick.index)}
                else {value.accessories.insert(pick.index);value.show(a.rawValue)}
                value.setPlacement(PartPlacement(),for:a)
            }
            selection=friend.accessories.contains(pick.index) ? .attachment(a) : nil
        default:break
        }
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
    private func chooseStarter(_ seed:FriendSeed) {
        change {value in
            var replacement=seed.make()
            replacement.id=value.id
            let defaultName=FriendSeed.allCases.map(\.title).contains(value.name)
            replacement.name=value.name.isEmpty || (!existing && defaultName) ? seed.title : value.name
            replacement.world=value.world;replacement.room=value.room;replacement.roomDesign=value.roomDesign
            replacement.song=value.song;replacement.track=value.track
            value=replacement.simplifiedForCreator()
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
