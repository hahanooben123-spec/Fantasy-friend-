import SwiftUI

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
    @State private var brushWidth = 14.0
    @State private var secondary = false
    @State private var trying=false
    @State private var naming = false
    @State private var starters = false
    @State private var personality = false
    @State private var celebration = false
    @State private var discard = false
    @State private var revision = 0
    @State private var advancedDestination:Int?
    @State private var molding=false
    @State private var erasing=false
    @State private var page=0
    @State private var extraGroup=0
    @State private var moreTools=false
    private let categories: [Part] = [.body,.color,.eyes,.arms,.legs,.extras]

    init(original: FantasyFriend, existing: Bool, resuming:Bool=false) {
        self.original=original;self.existing=existing;self.resuming=resuming
        _friend=State(initialValue:original.simplifiedForCreator())
    }
    var body: some View {
        GeometryReader { geometry in
            let wide=WorkshopLayout.sidebar(geometry.size)
            let large=geometry.size.width>=650
            ZStack {
                StorybookWorkshopWall().ignoresSafeArea()
                VStack(spacing:0) {
                    header(wide:wide)
                    PlayWorkspace(wide:wide,toolWidth:min(430,max(365,geometry.size.width*0.38)),
                        toolHeight:large ? (part == .color || part == .paint ? 340 : 315) : (geometry.size.height<650 ? 335 : (part == .color || part == .paint ? 425 : 370))) {
                        scene
                    } tools: {toolTray(large:large,side:wide)}
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
        }.foregroundColor(WorkshopLook.sea).overlay(LocalSaveStatus())
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
                if value != .active && !celebration {incoming=nil;finishGesture();store.saveEditorDraft(friend,existing:existing)}
            }
            .onDisappear {if !celebration {store.saveEditorDraft(friend,existing:existing)}}
            .fullScreenCover(isPresented:$trying) {
                CreatorTryRoom(friend:friend,onReturn:{trying=false}).environmentObject(store)
            }
            .sheet(isPresented:$moreTools,onDismiss:{
                let destination=advancedDestination;advancedDestination=nil
                if destination == 0 {starters=true}
                else if destination == 1 {trying=true}
                else if destination == 2 {personality=true}
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
            RoundButton(icon:"play.fill",label:store.t("creatorTryTitle")) {finishGesture();trying=true}
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
            CreatorStage(friend:$friend,selection:$selection,incoming:$incoming,part:part,
                brush:part == .paint ? PaintTool(color:paintColor,width:brushWidth,erasing:erasing) : nil,
                revision:revision,onBegin:beginGesture,onEnd:{
                    finishGesture()
                    if phase != .active && !celebration {store.saveEditorDraft(friend,existing:existing)}
                },onDrop:{_,_ in},molding:molding)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
        }
    }
    private var activeCategory:Part {part == .mouth ? .eyes : part == .paint ? .color : part}
    private func choosePart(_ value:Part) {
        finishGesture();part=value;page=0;selection=nil;molding=false
        SoundService.shared.play(.click)
    }
    private func toolTray(large:Bool,side:Bool)->some View {
        VStack(spacing:10) {
            LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:7),count:side || !large ? 3 : 6),spacing:7) {
                ForEach(categories,id:\.rawValue) {item in
                    Button {choosePart(item)} label:{
                        VStack(spacing:2) {
                            CreatorCategoryIcon(part:item).frame(width:large ? 46 : 35,height:large ? 43 : 33)
                            Text(store.t(item == .eyes ? "creatorFace" : Words.partKeys[item.rawValue]))
                                .font(.system(size:large ? 14 : 12,weight:.heavy,design:.rounded))
                        }.frame(maxWidth:.infinity,minHeight:large ? 72 : 57)
                            .background(GameChoiceSurface(selected:activeCategory == item,tint:StudioStyle.color(item)))
                    }.buttonStyle(SquishStyle()).accessibilityAddTraits(activeCategory == item ? .isSelected : [])
                }
            }
            ScrollView(.vertical,showsIndicators:true) {
                VStack(spacing:10) {
                    subTools(large:large)
                    if part == .color || part == .paint {colorGrid(large:large,side:side)}
                    else if molding {moldingTools}
                    else {optionGrid(large:large,side:side)}
                    if part == .arms || part == .legs {limbSizes}
                }.padding(.horizontal,3).padding(.vertical,4)
            }
        }.padding(12).background(StorybookShelf())
    }
    @ViewBuilder private func subTools(large:Bool)->some View {
        if activeCategory == .eyes {
            HStack(spacing:10) {
                smallMode(.eyes,"eyes",selected:part == .eyes) {choosePart(.eyes)}
                smallMode(.mouth,"mouth",selected:part == .mouth) {choosePart(.mouth)}
            }
        } else if activeCategory == .color {
            HStack(spacing:8) {
                Button {choosePart(.color);secondary=false} label:{
                    Circle().fill(GameStyle.palette[friend.color]).frame(width:30,height:30)
                        .frame(maxWidth:.infinity,minHeight:48)
                        .background(GameChoiceSurface(selected:part == .color && !secondary))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("color"))
                Button {choosePart(.color);secondary=true} label:{
                    ZStack {Circle().fill(GameStyle.palette[friend.color]);Capsule().fill(GameStyle.palette[friend.accent]).padding(8)}
                        .frame(width:30,height:30).frame(maxWidth:.infinity,minHeight:48)
                        .background(GameChoiceSurface(selected:part == .color && secondary))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("accent"))
                smallMode(.paint,"brush",selected:part == .paint && !erasing) {choosePart(.paint);erasing=false}
                Button {choosePart(.paint);erasing=true} label:{
                    CreatorEraserIcon().frame(width:32,height:30)
                        .frame(maxWidth:.infinity,minHeight:48).background(GameChoiceSurface(selected:part == .paint && erasing))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("creatorEraser"))
            }
        } else if part == .body {
            HStack(spacing:10) {
                smallMode(.body,"creatorShapes",selected:!molding) {finishGesture();molding=false;selection=nil}
                Button {finishGesture();molding=true;selection = .body} label:{
                    Label(store.t("creatorMold"),systemImage:"hand.draw.fill")
                        .font(.system(size:14,weight:.heavy,design:.rounded)).frame(maxWidth:.infinity,minHeight:48)
                        .background(GameChoiceSurface(selected:molding))
                }.buttonStyle(SquishStyle())
            }
        } else if part == .extras {
            HStack(spacing:8) {
                ForEach(0..<3) {group in
                    Button {extraGroup=group;page=0;SoundService.shared.play(.click)} label:{
                        HStack(spacing:4) {
                            CreativePieceView(piece:CreativePiece(kind:.extra,variant:[8,9,3][group],color:friend.color,accent:friend.accent))
                                .frame(width:30,height:28)
                            Text(store.t("creatorExtraGroup\(group)"))
                                .font(.system(size:large ? 13 : 11,weight:.heavy,design:.rounded)).lineLimit(1)
                            let count=extras(group).filter {friend.accessories.contains($0)}.count
                            if count>0 {Text("\(count)").font(.system(size:11,weight:.black,design:.rounded))}
                        }.frame(maxWidth:.infinity,minHeight:48).background(GameChoiceSurface(selected:extraGroup == group))
                    }.buttonStyle(SquishStyle())
                }
            }
        }
    }
    private func smallMode(_ value:Part,_ key:String,selected:Bool,action:@escaping()->Void)->some View {
        Button(action:action) {
            HStack(spacing:5) {
                CreatorCategoryIcon(part:value).frame(width:27,height:28)
                Text(store.t(key)).font(.system(size:13,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth:.infinity,minHeight:48).background(GameChoiceSurface(selected:selected))
        }.buttonStyle(SquishStyle())
    }
    private func extras(_ group:Int)->[Int] {
        switch group {case 0:return [0,1,2,5,6,7,8,11,12];case 1:return [9,10,13,14];default:return [3,4]}
    }
    private func optionGrid(large:Bool,side:Bool)->some View {
        let values=part == .extras ? extras(extraGroup) : Array(0..<optionCount)
        let capacity=large ? 6 : 3
        let pages=max(1,(values.count+capacity-1)/capacity)
        let current=min(page,pages-1)
        let shown=Array(values.dropFirst(current*capacity).prefix(capacity))
        return VStack(spacing:8) {
            if pages>1 {
                HStack {
                    pageArrow("chevron.left",label:"back",enabled:current>0) {page=current-1}
                    Spacer()
                    HStack(spacing:7) {ForEach(0..<pages,id:\.self) {index in
                        Circle().fill(index == current ? GameStyle.purple : GameStyle.purple.opacity(0.2)).frame(width:9,height:9)
                    }}.accessibilityLabel("\(current+1) / \(pages)")
                    Spacer()
                    pageArrow("chevron.right",label:"creatorMoreChoices",enabled:current<pages-1) {page=current+1}
                }
            }
            LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:10),count:side || !large ? 3 : 6),spacing:10) {
                ForEach(shown,id:\.self) {index in
                    Button {apply(CreatorPick(part:part,index:index),at:nil)} label:{
                        choiceArt(index).frame(height:large ? 84 : 65).padding(6)
                            .frame(maxWidth:.infinity)
                            .background(GameChoiceSurface(selected:chosen(index)))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(Words.partKeys[part.rawValue])+" \(index+1)")
                        .accessibilityAddTraits(chosen(index) ? .isSelected : [])
                }
            }
        }
    }
    private func pageArrow(_ icon:String,label:String,enabled:Bool,action:@escaping()->Void)->some View {
        Button {action();SoundService.shared.play(.click)} label:{
            Image(systemName:icon).font(.system(size:19,weight:.heavy)).frame(width:48,height:44)
                .background(CandySurface(color:WorkshopLook.yellow,cornerRadius:20))
        }.buttonStyle(SquishStyle()).disabled(!enabled).opacity(enabled ? 1 : 0.3).accessibilityLabel(store.t(label))
    }
    @ViewBuilder private func choiceArt(_ index:Int)->some View {
        if part == .arms || part == .legs {
            HStack(spacing:0) {
                CreativePieceView(piece:CreativePiece(kind:part == .arms ? .arm : .leg,variant:index,color:friend.color,accent:friend.accent))
                    .scaleEffect(x:-1,y:1)
                CreativePieceView(piece:CreativePiece(kind:part == .arms ? .arm : .leg,variant:index,color:friend.color,accent:friend.accent))
            }
        } else if part == .extras {
            CreativePieceView(piece:CreativePiece(kind:.extra,variant:index,color:friend.partColors?[Attachment.extra(index).rawValue] ?? friend.color,accent:friend.accent))
        } else {
            CharacterView(friend:sample(index),detail:part == .eyes || part == .mouth ? part : nil)
        }
    }
    private func sample(_ index:Int)->FantasyFriend {
        var f=friend
        if part == .body {f.body=BodyKind(rawValue:index) ?? .round;f.bodySculpt=nil;f.bodyWidth=nil;f.bodyHeight=nil}
        if part == .eyes {f.eyes=index;f.facePlacements?.removeValue(forKey:"eyes");f.show("eyes")}
        if part == .mouth {f.mouth=index;f.facePlacements?.removeValue(forKey:"mouth");f.show("mouth")}
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
    private func colorGrid(large:Bool,side:Bool)->some View {
        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:9),count:large && !side ? 8 : 4),spacing:9) {
            ForEach(0..<16) {index in
                let active=part == .paint ? (!erasing && paintColor == index) : (secondary ? friend.accent : friend.color) == index
                Button {
                    if part == .paint {paintColor=index;erasing=false;SoundService.shared.play(.click)}
                    else {tint(index)}
                } label:{
                    RoundedRectangle(cornerRadius:18).fill(GameStyle.palette[index])
                        .frame(height:large ? 52 : 44)
                        .overlay(RoundedRectangle(cornerRadius:18).strokeBorder(active ? GameStyle.ink : .white,lineWidth:active ? 4 : 2))
                        .overlay {
                            if active {Image(systemName:"checkmark").font(.system(size:19,weight:.heavy)).foregroundColor(.white)
                                .shadow(color:GameStyle.ink,radius:2)}
                        }
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("color")+" \(index+1)")
                    .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
    }
    private var activeLimbSize:Double {part == .arms ? (friend.armSize ?? 1) : (friend.legSize ?? 1)}
    private var limbSizes:some View {
        HStack(spacing:8) {
            ForEach(Array([0.75,1.0,1.25].enumerated()),id:\.offset) {index,size in
                Button {change {$0.resizeLimbs(part,size:size)}} label:{
                    HStack(spacing:4) {
                        CreatorCategoryIcon(part:part).frame(width:CGFloat(25)*CGFloat(size),height:30)
                        Text(store.t("creatorSize\(index)")).font(.system(size:12,weight:.heavy,design:.rounded))
                    }.frame(maxWidth:.infinity,minHeight:48).background(GameChoiceSurface(selected:abs(activeLimbSize-size)<0.02))
                }.buttonStyle(SquishStyle())
            }
        }
    }
    private var moldingTools:some View {
        VStack(spacing:10) {
            HStack(spacing:8) {
                ForEach(Array([0.85,1.0,1.15].enumerated()),id:\.offset) {index,size in
                    Button {change {$0.bodyWidth=size;$0.bodyHeight=size}} label:{
                        CreatorCategoryIcon(part:.body).frame(width:CGFloat(42)*CGFloat(size),height:54)
                            .frame(maxWidth:.infinity,minHeight:70).background(GameChoiceSurface(selected:abs(friend.widthFactor-size)<0.02))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("creatorSize\(index)"))
                }
            }
            Button {change {$0.bodySculpt=nil;$0.bodyWidth=nil;$0.bodyHeight=nil}} label:{
                Label(store.t("creatorResetClay"),systemImage:"arrow.counterclockwise")
                    .font(.system(size:14,weight:.heavy,design:.rounded)).frame(maxWidth:.infinity,minHeight:48)
            }.buttonStyle(SquishStyle())
        }
    }
    private var advancedTools:some View {
        ScrollView {
        VStack(spacing:22) {
            HStack {Text(store.t("roomMore")).font(.title2.bold());Spacer()
                RoundButton(icon:"xmark",label:store.t("close")) {moreTools=false}}
            CharacterView(friend:friend).frame(height:160)
            CandyButton(title:store.t("starterButton"),icon:"sparkles",color:StorybookStyle.teal) {advancedDestination=0;moreTools=false}
            CandyButton(title:store.t("creatorTryTitle"),icon:"play.fill",color:StorybookStyle.teal) {advancedDestination=1;moreTools=false}
            CandyButton(title:store.t("surprise"),icon:"shuffle",color:StorybookStyle.teal) {surprise();moreTools=false}
            CandyButton(title:store.t("clearPaint"),icon:"trash",color:StorybookStyle.teal) {change {$0.doodles=nil};moreTools=false}
                .disabled(friend.doodles?.isEmpty ?? true)
            CandyButton(title:store.t("personality"),icon:"music.note") {
                advancedDestination=2;moreTools=false
            }
            CandyButton(title:store.t("redo"),icon:"arrow.uturn.forward") {redo();moreTools=false}
                .disabled(future.isEmpty)
            Spacer(minLength:0)
        }.padding(26).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.background(StorybookShelf()).foregroundColor(GameStyle.ink)
    }
    private func finishFriend() {
        if friend.room == nil {
            var home=RoomLayout.starter(friend.color%3).forLittleHands()
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
            change { $0.body=BodyKind(rawValue:pick.index) ?? .round;$0.bodySculpt=nil;$0.bodyWidth=nil;$0.bodyHeight=nil };selection=nil
        case .eyes,.mouth:
            change { value in
                let key=pick.part == .eyes ? "eyes" : "mouth"
                if pick.part == .eyes { value.eyes=pick.index } else { value.mouth=pick.index }
                value.show(key);value.facePlacements?.removeValue(forKey:key)
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
            value=random.simplifiedForCreator()
        };selection = .body
    }
    private var celebrationView:some View {
        FriendRevealView(friend:friend,updated:existing,onFinish:{presentation.wrappedValue.dismiss()})
            .environmentObject(store)
    }
}

private struct NamingView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.presentationMode) private var presentation
    @Binding var friend:FantasyFriend
    var save:()->Void
    @State private var editingName=false
    @FocusState private var nameFocused:Bool
    var body:some View {
        ZStack {
            StudioBackdrop()
            ScrollView {
                VStack(spacing:22) {
                    HStack {
                        RoundButton(icon:"chevron.left",label:store.t("back")) {presentation.wrappedValue.dismiss()}
                        Spacer()
                    }
                    LivingFriend(friend:friend,greetOnArrival:true).frame(height:260)
                    if editingName {
                        TextField(store.t("name"),text:Binding(get:{friend.name},set:{friend.name=String($0.prefix(30))}))
                            .font(.system(size:30,weight:.heavy,design:.rounded)).multilineTextAlignment(.center)
                            .padding(16).background(StorybookPanel()).focused($nameFocused).submitLabel(.done)
                            .onAppear {nameFocused=true}
                            .onSubmit {nameFocused=false;editingName=false;ensureName()}
                    } else {
                        VillageCaption(title:friend.name,size:36)
                    }
                    HStack(spacing:12) {
                        Button {editingName.toggle();if !editingName {nameFocused=false;ensureName()}} label:{
                            Label(store.t("creatorRename"),systemImage:"pencil")
                                .font(.system(size:15,weight:.heavy,design:.rounded)).frame(maxWidth:.infinity,minHeight:56)
                                .background(CandySurface(color:WorkshopLook.cream,cornerRadius:24))
                        }.buttonStyle(SquishStyle())
                        RoundButton(icon:"shuffle",label:store.t("suggest")) {
                            friend.name=Words.names.filter {$0 != friend.name}.randomElement() ?? "Bimse"
                            SoundService.shared.play(.reaction)
                        }
                    }
                    CandyButton(title:store.t("creatorReady"),icon:"heart.fill",color:StorybookStyle.teal) {
                        nameFocused=false;ensureName();save()
                    }
                    if let error=store.error {Text(error).font(.system(.body,design:.rounded)).accessibilityAddTraits(.updatesFrequently)}
                }.padding(24).frame(maxWidth:520).frame(maxWidth:.infinity)
            }
        }.foregroundColor(GameStyle.ink).onAppear(perform:ensureName)
    }
    private func ensureName() {
        friend.name=friend.name.trimmingCharacters(in:.whitespacesAndNewlines)
        if friend.name.isEmpty {friend.name=Words.names.randomElement() ?? "Bimse"}
    }
}
