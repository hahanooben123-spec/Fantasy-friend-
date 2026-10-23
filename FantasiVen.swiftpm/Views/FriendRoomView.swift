import SwiftUI

struct FriendRoomView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.presentationMode) private var presentation
    let friendID:UUID
    @State private var layout=RoomLayout()
    @State private var loaded=false
    @State private var selected:UUID?
    @State private var moving:RoomObject?
    @State private var friendPreview:CGPoint?
    @State private var pending:RoomItem?
    @State private var history:[RoomLayout]=[]
    @State private var future:[RoomLayout]=[]
    @State private var editing=true
    @State private var category=0
    @State private var trayOpen=false
    @State private var trayDragged=false
    @Environment(\.scenePhase) private var phase
    @State private var extras=false
    @State private var draggingItem:RoomItem?
    @State private var dragPoint=CGPoint.zero
    @State private var roomFrame=CGRect.zero
    @State private var styles=false
    @State private var colors=false
    @State private var action=PlayAction.jump
    @State private var signal=0
    @State private var activeID:UUID?
    @State private var pulse=0
    @State private var full=false
    private var friend:FantasyFriend? {store.friends.first {$0.id == friendID}}
    private var choice:RoomObject? {layout.objects.first {$0.id == selected}}
    var body:some View {
        GeometryReader {proxy in
            let wide=proxy.size.width>=740
            ZStack {
                StorybookWorkshopWall().ignoresSafeArea()
                VStack(spacing:0) {
                    header(wide)
                    if let friend=friend {
                        if wide && editing && trayOpen {
                            HStack(spacing:0) {
                                room(friend).frame(maxWidth:.infinity,maxHeight:.infinity)
                                tray(vertical:true).frame(width:270)
                            }
                        } else {
                            room(friend).frame(maxWidth:.infinity,maxHeight:.infinity)
                            if editing && trayOpen {tray(vertical:false).frame(height:245)}
                        }
                        if editing {selectionTools}
                        else {playTools}
                    } else {
                        Spacer()
                        Text(store.t("roomMissing")).foregroundColor(.white).padding(30)
                        Spacer()
                    }
                }
                if let item=draggingItem {
                    RoomFurniture(kind:item.rawValue).frame(width:92,height:102)
                        .shadow(color:GameStyle.ink.opacity(0.3),radius:8,x:0,y:10)
                        .position(dragPoint).allowsHitTesting(false)
                }
            }.coordinateSpace(name:"roomWorkshop")
                .onPreferenceChange(RoomSurfaceFrameKey.self) {roomFrame=$0}
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .onAppear {load();store.visit(.room,friendID:friendID)}
            .onChange(of:phase) {value in if value != .active {draggingItem=nil;trayDragged=false;moving=nil;friendPreview=nil}}
            .task(id:draggingItem == nil && trayDragged) {
                guard draggingItem == nil,trayDragged else {return}
                do {try await Task.sleep(nanoseconds:220_000_000)} catch {return}
                trayDragged=false
            }
            .onDisappear {SoundService.shared.stopSpeech()}
            .sheet(isPresented:$styles) {
                RoomDesignSheet(design:layout.design,onDesign:{value in
                    var next=layout;next.design=value;commit(next)
                },onPreset:{index in
                    if commit(RoomLayout.starter(index)) {selected=nil;styles=false;editing=true;action = .jump;signal+=1}
                },onClose:{styles=false}).environmentObject(store)
            }
            .sheet(isPresented:$colors) {colorSheet}
            .sheet(isPresented:$extras) {extraTools}
            .alert(store.t("error"),isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error=nil}})) {
                Button("OK") {store.error=nil}
            } message:{Text(store.error ?? "")}
            .task(id:full) {
                guard full else {return}
                do {try await Task.sleep(nanoseconds:2_800_000_000)} catch {return}
                full=false
            }
    }
    private func header(_ wide:Bool)->some View {
        HStack(spacing:6) {
            RoundButton(icon:"chevron.left",label:store.t("close")) {presentation.wrappedValue.dismiss()}
            if wide {Text(store.t("myRoom")).font(.system(size:20,weight:.heavy,design:.rounded)).foregroundColor(.white).lineLimit(1)}
            CreatorToolButton(mark:.undo,label:store.t("undo"),action:undo).disabled(history.isEmpty)
            if !future.isEmpty {CreatorToolButton(mark:.redo,label:store.t("redo"),action:redo)}
            Spacer(minLength:0)
            HStack(spacing:3) {modeButton(build:true,wide:wide);modeButton(build:false,wide:wide)}
                .padding(3).background(StorybookPanel(cornerRadius:25))
        }.padding(.horizontal,10).padding(.vertical,8)
    }
    private func modeButton(build:Bool,wide:Bool)->some View {
        Button {
            moving=nil;friendPreview=nil;pending=nil;draggingItem=nil;selected=nil
            editing=build;if !build {trayOpen=false}
        } label:{
            VStack(spacing:1) {
                Image(systemName:build ? "paintbrush.fill" : "play.fill").font(.system(size:17,weight:.bold))
                Text(store.t(build ? "roomBuild" : "roomPlayShort")).font(.system(size:11,weight:.heavy,design:.rounded))
            }.frame(width:wide ? 74 : 58,height:46)
                .background(Capsule().fill(editing == build ? WorkshopLook.yellow : .clear))
        }.buttonStyle(SquishStyle()).accessibilityAddTraits(editing == build ? .isSelected : [])
    }
    private func room(_ friend:FantasyFriend)->some View {
        ZStack(alignment:.top) {
            RoomScene(friend:friend,layout:layout,editing:editing,selected:selected,moving:moving,
                friendPreview:friendPreview,action:action,signal:signal,activeID:activeID,pulse:pulse,pending:pending,
                onSelect:{selected=$0},onTap:tap,onMove:move,onFriendMove:moveFriend,
                onDropItem:{item,point in add(item,at:point)})
            Text(store.t(full ? "roomFull" : editing ? (draggingItem != nil ? "roomDropHere" : choice != nil && !trayOpen ? "roomSelectedHint" : "roomSimpleHint") : "roomPlayHint"))
                .font(.system(size:12,weight:.bold,design:.rounded)).multilineTextAlignment(.center)
                .padding(.horizontal,14).padding(.vertical,9)
                .background(StorybookPanel(cornerRadius:24)).padding(10).allowsHitTesting(false)
        }.background(GeometryReader {proxy in
            Color.clear.preference(key:RoomSurfaceFrameKey.self,value:proxy.frame(in:.named("roomWorkshop")))
        })
    }
    private func tray(vertical:Bool)->some View {
        VStack(spacing:6) {
            HStack(spacing:5) {
                ForEach(0..<3) {index in
                    Button {category=index;pending=nil} label:{
                        VStack(spacing:0) {
                            RoomFurniture(kind:[6,1,13][index]).frame(width:36,height:36)
                            Text(store.t("roomCategory\(index)")).font(.system(size:11,weight:.heavy,design:.rounded)).lineLimit(1)
                        }.frame(maxWidth:.infinity,minHeight:59)
                            .background(CandySurface(color:category == index ? WorkshopLook.yellow : StorybookStyle.cream,cornerRadius:17))
                    }.buttonStyle(SquishStyle()).accessibilityAddTraits(category == index ? .isSelected : [])
                }
            }.padding(.horizontal,10)
            ScrollView(.vertical,showsIndicators:false) {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:vertical ? 2 : 4),spacing:10) {
                    items(vertical:vertical)
                }.padding(10)
            }
        }.padding(.top,8).background(StorybookShelf())
    }
    private func items(vertical:Bool)->some View {
        ForEach(RoomItem.allCases.filter {$0.category == category},id:\.rawValue) {item in
            Button {if !trayDragged {add(item,at:nil)}} label:{
                VStack(spacing:0) {
                    RoomFurniture(kind:item.rawValue).frame(height:vertical ? 76 : 47)
                    Text(store.t(item.key)).font(.system(size:vertical ? 12 : 10,weight:.bold,design:.rounded))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }.padding(5).frame(maxWidth:.infinity).frame(height:vertical ? 108 : 74)
                    .background(CandySurface(color:.white,cornerRadius:20))
            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(item.key))
                .simultaneousGesture(DragGesture(minimumDistance:8,coordinateSpace:.named("roomWorkshop")).onChanged {value in
                    if draggingItem == nil {
                        if vertical {guard abs(value.translation.width)>abs(value.translation.height)*0.65 else {return}}
                    }
                    trayDragged=true;draggingItem=item;dragPoint=value.location
                }.onEnded {value in
                    defer {draggingItem=nil}
                    guard draggingItem != nil,roomFrame.contains(value.location),roomFrame.width>0,roomFrame.height>0 else {return}
                    let point=CGPoint(x:(value.location.x-roomFrame.minX)/roomFrame.width,
                        y:(value.location.y-roomFrame.minY)/roomFrame.height)
                    add(item,at:point)
                })
        }
    }
    private var selectionTools:some View {
        HStack(spacing:10) {
            if trayOpen {
                Image(systemName:"hand.draw.fill").font(.system(size:23,weight:.bold)).foregroundColor(.white)
                Text(store.t("roomTrayHint")).font(.system(size:12,weight:.bold,design:.rounded)).foregroundColor(.white)
                Spacer(minLength:0)
                simpleTool("checkmark","roomDone") {trayOpen=false}.frame(maxWidth:160)
            } else if choice != nil {
                simpleTool("paintpalette.fill","color") {colors=true}
                simpleTool("tray.and.arrow.down.fill","roomPutAway") {
                    guard let id=selected else {return}
                    var next=layout;next.objects.removeAll {$0.id == id}
                    if commit(next) {selected=nil}
                }
                simpleTool("ellipsis","roomMore") {extras=true}
                simpleTool("plus","roomAdd") {selected=nil;trayOpen=true}
            } else {
                Button {trayOpen=true} label:{
                    Label(store.t("roomAddThings"),systemImage:"plus.circle.fill")
                        .font(.system(size:16,weight:.heavy,design:.rounded)).frame(maxWidth:.infinity,minHeight:56)
                        .background(CandySurface(color:WorkshopLook.yellow,cornerRadius:22))
                }.buttonStyle(SquishStyle())
                Button {styles=true} label:{
                    Label(store.t("roomColors"),systemImage:"paintpalette.fill")
                        .font(.system(size:14,weight:.heavy,design:.rounded)).frame(maxWidth:.infinity,minHeight:56)
                        .background(CandySurface(color:WorkshopLook.cream,cornerRadius:22))
                }.buttonStyle(SquishStyle())
            }
        }.padding(.horizontal,12).padding(.vertical,10).frame(maxWidth:680).frame(maxWidth:.infinity)
    }
    private func simpleTool(_ icon:String,_ key:String,action:@escaping()->Void)->some View {
        Button(action:action) {
            VStack(spacing:3) {
                Image(systemName:icon).font(.system(size:23,weight:.bold))
                Text(store.t(key)).font(.system(size:12,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth:.infinity,minHeight:55)
                .background(CandySurface(color:WorkshopLook.cream,cornerRadius:19))
        }.buttonStyle(SquishStyle())
    }
    private var extraTools:some View {
        ScrollView {
            VStack(spacing:20) {
                HStack {
                    Text(store.t("roomMore")).font(.system(.title,design:.rounded).weight(.heavy))
                    Spacer();RoundButton(icon:"xmark",label:store.t("close")) {extras=false}
                }
                if let choice=choice {RoomFurniture(kind:choice.kind,tint:choice.color).frame(width:150,height:165)}
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:14) {
                    simpleTool("square.on.square","copyPiece") {duplicate()}
                    simpleTool("arrow.left.and.right","roomMirror") {transform {$0.mirrored = !($0.mirrored ?? false)}}
                    simpleTool("plus.magnifyingglass","roomBigger") {transform {$0.scale=min(1.6,$0.sizeFactor+0.15)}}
                    simpleTool("minus.magnifyingglass","roomSmaller") {transform {$0.scale=max(0.6,$0.sizeFactor-0.15)}}
                    simpleTool("square.3.layers.3d","roomFront") {transform {$0.layer=2}}
                    simpleTool("square.3.layers.3d.bottom.filled","roomBack") {transform {$0.layer = -1}}
                }
            }.padding(24)
        }.background(StorybookShelf())
    }
    private var playTools:some View {
        HStack(spacing:12) {
            simpleTool("heart.fill","hug") {react(.hug)}
            simpleTool("music.note","dance") {react(.dance)}
            simpleTool("sun.max.fill","roomDayNight") {var next=layout;next.design.night.toggle();commit(next)}
        }.padding(12).frame(maxWidth:500).frame(maxWidth:.infinity)
    }
    private var colorSheet:some View {
        VStack(spacing:20) {
            HStack {
                Text(store.t("color")).font(.system(.title,design:.rounded).weight(.heavy))
                Spacer();RoundButton(icon:"xmark",label:store.t("close")) {colors=false}
            }
            if let choice=choice {RoomFurniture(kind:choice.kind,tint:choice.color,isOn:choice.isOn).frame(width:150,height:165)}
            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:16) {
                ForEach(0..<16) {index in
                    Button {transform {$0.color=index};colors=false} label:{
                        Circle().fill(GameStyle.palette[index]).frame(width:48,height:48)
                            .overlay(Circle().stroke(choice?.color == index ? GameStyle.ink : .white,lineWidth:3))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("color")+" \(index+1)")
                }
            }
            Spacer(minLength:0)
        }.padding(26).background(StorybookShelf())
    }
    private func load() {
        guard !loaded,let friend=friend else {return}
        loaded=true
        if let objects=friend.room {layout=RoomLayout(objects:objects,design:friend.roomDesign ?? RoomDesign())}
        else {
            let starter=RoomLayout.starter(0)
            if persist(starter) {layout=starter}
        }
    }
    @discardableResult private func persist(_ next:RoomLayout)->Bool {
        guard var current=friend else {return false}
        current.room=next.objects;current.roomDesign=next.design
        return store.save(current)
    }
    @discardableResult private func commit(_ next:RoomLayout)->Bool {
        guard next != layout else {return true}
        guard persist(next) else {return false}
        history.append(layout);if history.count>50 {history.removeFirst()}
        future=[];layout=next;SoundService.shared.play(.click);return true
    }
    private func undo() {
        guard let previous=history.last,persist(previous) else {return}
        future.append(layout);layout=previous;history.removeLast()
        moving=nil;friendPreview=nil;selected=nil
    }
    private func redo() {
        guard let next=future.last,persist(next) else {return}
        history.append(layout);layout=next;future.removeLast()
        moving=nil;friendPreview=nil;selected=nil
    }
    private func add(_ item:RoomItem,at point:CGPoint?) {
        pending=nil
        guard layout.objects.count<32 else {full=true;return}
        var next=layout
        let slot=Double(next.objects.count%4)
        var value=RoomObject(kind:item.rawValue,x:0.25+slot*0.16,y:item.isWall ? 0.32 : 0.73)
        if let point=point {value.move(x:Double(point.x),y:Double(point.y))}
        next.objects.append(value)
        if commit(next) {selected=value.id}
    }
    private func move(_ value:RoomObject,_ finished:Bool) {
        selected=value.id
        guard finished else {moving=value;return}
        defer {moving=nil}
        guard let i=layout.objects.firstIndex(where:{$0.id == value.id}) else {return}
        var next=layout;next.objects[i]=value;commit(next)
    }
    private func moveFriend(_ point:CGPoint,_ finished:Bool) {
        guard finished else {friendPreview=point;return}
        var next=layout;next.design.friendX=Double(point.x);next.design.friendY=Double(point.y)
        commit(next);friendPreview=nil
    }
    private func tap(_ value:RoomObject) {
        pending=nil
        if editing {
            selected=value.id
            if !trayOpen {use(value)}
            else {SoundService.shared.play(.click)}
        } else {use(value)}
    }
    private func transform(_ update:(inout RoomObject)->Void) {
        guard let selected=selected,let i=layout.objects.firstIndex(where:{$0.id == selected}) else {return}
        var next=layout;update(&next.objects[i]);commit(next)
    }
    private func duplicate() {
        guard var value=choice else {return}
        guard layout.objects.count<32 else {full=true;return}
        value.id=UUID();value.move(x:value.x+0.1,y:value.y+0.04)
        var next=layout;next.objects.append(value)
        if commit(next) {selected=value.id}
    }
    private func use(_ value:RoomObject) {
        activeID=value.id;pulse+=1
        guard let kind=RoomItem(rawValue:value.kind) else {return}
        switch kind {
        case .lamp,.toybox:
            var next=layout
            if let i=next.objects.firstIndex(where:{$0.id == value.id}) {next.objects[i].on = !value.isOn;commit(next)}
        case .bed:react(.sleep,near:value)
        case .sofa,.cushion:react(.hug,near:value)
        case .snack,.table:react(.feed,near:value)
        case .music:
            react(.dance);SoundService.shared.instrument(1,beat:pulse%8)
        case .ball,.stool:react(.jump)
        case .shelf:
            SoundService.shared.speak(store.t("roomStory"),language:store.settings.language);react(.hug)
        case .plant:react(.tickle)
        default:SoundService.shared.instrument(1,beat:value.kind%8)
        }
    }
    private func react(_ value:PlayAction,near object:RoomObject?=nil) {
        action=value;signal+=1
        if let object=object {
            var next=layout
            next.design.friendX=min(0.9,max(0.1,object.x))
            next.design.friendY=min(0.9,max(0.2,object.y-0.04))
            commit(next)
        }
    }
}
