import SwiftUI

private enum LittleRoomChoice:Int,CaseIterable {
    case bed,rug,lamp,toys,picture,walls
    var item:RoomItem {
        switch self {case .bed:return .bed;case .rug:return .rug;case .lamp:return .lamp
        case .toys:return .toybox;case .picture:return .picture;case .walls:return .window}
    }
    static func choice(for item:RoomItem)->Self {
        allCases.first {$0.item == item} ?? .walls
    }
}

struct FriendRoomView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.presentationMode) private var presentation
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    let friendID:UUID
    @State private var layout=RoomLayout()
    @State private var loaded=false
    @State private var decorating=false
    @State private var choice=LittleRoomChoice.bed
    @State private var history:[RoomLayout]=[]
    @State private var friendPreview:CGPoint?
    @State private var toyPreview:RoomPlaything?
    @State private var moving:RoomObject?
    @State private var action=PlayAction.jump
    @State private var signal=0
    @State private var activeID:UUID?
    @State private var pulse=0
    @State private var full=false
    @StateObject private var pumpkins=PumpkinStore()
    @State private var pizzaOpen=false
    @State private var lanternOpen:PumpkinLantern?
    private let paints=[9,11,6,3]
    private var friend:FantasyFriend? {store.friends.first {$0.id == friendID}}
    private var chosenObject:RoomObject? {layout.objects.first {$0.kind == choice.item.rawValue}}

    var body:some View {
        GeometryReader {proxy in
            let large=proxy.size.width>=650
            VStack(spacing:0) {
                header
                if let friend=friend {
                    RoomScene(friend:friend,layout:layout,editing:decorating,selected:decorating ? chosenObject?.id : nil,
                        moving:moving,friendPreview:friendPreview,action:action,signal:signal,activeID:activeID,pulse:pulse,pending:nil,
                        onSelect:{_ in},onTap:tap,onMove:move,onFriendMove:moveFriend,
                        onDropItem:{_,_ in},toyPreview:toyPreview,onSpawnToy:spawnToy,onMoveToy:moveToy,
                        onUseToy:useToy,onCover:cover,pumpkins:pumpkins,onPizza:{pizzaOpen=true},onLantern:{lanternOpen=$0},fixedLayout:true)
                        .frame(maxWidth:.infinity,maxHeight:.infinity)
                    if decorating {decorationTray(large:large).frame(height:large ? 230 : 285)}
                    else {playTray}
                } else {
                    Spacer();Text(store.t("roomMissing")).foregroundColor(.white).padding(30);Spacer()
                }
            }.background(StorybookWorkshopWall().ignoresSafeArea())
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .onAppear {load();pumpkins.reload();store.visit(.room,friendID:friendID);SoundService.shared.setWorld(layout.design.night ? .stars : .castle)}
            .onChange(of:phase) {value in
                if value != .active {friendPreview=nil;toyPreview=nil;moving=nil}
            }
            .onChange(of:layout.design.night) {night in SoundService.shared.setWorld(night ? .stars : .castle)}
            .fullScreenCover(isPresented:$pizzaOpen) {
                NavigationView {KitchenGameView(friend:friend ?? store.companion)}.navigationViewStyle(.stack).environmentObject(store)
            }
            .fullScreenCover(item:$lanternOpen) {lantern in
                PumpkinWorkshopView(original:lantern,library:pumpkins,onGarden:{lanternOpen=nil},onClose:{lanternOpen=nil}).environmentObject(store)
            }
            .alert(store.t("error"),isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error=nil}})) {
                Button("OK") {store.error=nil}
            } message:{Text(store.error ?? "")}
    }
    private var header:some View {
        HStack(spacing:10) {
            RoundButton(icon:"chevron.left",label:store.t("back")) {presentation.wrappedValue.dismiss()}
            if decorating {
                RoundButton(icon:"arrow.uturn.backward",label:store.t("undo"),action:undo).disabled(history.isEmpty)
            }
            Spacer(minLength:0)
            RoundButton(icon:layout.design.night ? "moon.stars.fill" : "sun.max.fill",label:store.t("roomDayNight")) {
                var next=layout;next.design.night.toggle();commit(next)
            }
            Button {
                decorating.toggle();friendPreview=nil;toyPreview=nil;moving=nil
                if !decorating {action = .hug;signal+=1}
                SoundService.shared.play(.click)
            } label:{
                Label(store.t(decorating ? "done" : "roomLittleDecorate"),systemImage:decorating ? "checkmark" : "paintbrush.fill")
                    .font(.system(size:17,weight:.heavy,design:.rounded)).padding(.horizontal,17).frame(minHeight:54)
                    .background(CandySurface(color:StorybookStyle.honey,cornerRadius:27))
            }.buttonStyle(SquishStyle())
        }.padding(.horizontal,10).padding(.vertical,8)
    }
    private func decorationTray(large:Bool)->some View {
        VStack(spacing:10) {
            LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:7),count:large ? 6 : 3),spacing:7) {
                ForEach(LittleRoomChoice.allCases,id:\.rawValue) {value in
                    Button {choice=value;SoundService.shared.play(.click)} label:{
                        HStack(spacing:4) {
                            RoomFurniture(kind:value.item.rawValue).frame(width:large ? 52 : 38,height:large ? 54 : 43)
                            Text(store.t(value == .walls ? "roomLittleWalls" : value.item.key))
                                .font(.system(size:large ? 14 : 12,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.75)
                        }.frame(maxWidth:.infinity,minHeight:large ? 76 : 62)
                            .background(GameChoiceSurface(selected:choice == value))
                    }.buttonStyle(SquishStyle()).accessibilityAddTraits(choice == value ? .isSelected : [])
                }
            }
            HStack(spacing:10) {
                ForEach(0..<4) {index in
                    Button {decorate(index)} label:{
                        Group {
                            if choice == .walls {
                                RoomInterior(design:previewDesign(index)).clipShape(RoundedRectangle(cornerRadius:19))
                            } else {
                                RoomFurniture(kind:choice.item.rawValue,tint:paints[index],isOn:true)
                                    .padding(5)
                            }
                        }.frame(height:large ? 95 : 77).frame(maxWidth:.infinity)
                            .background(GameChoiceSurface(selected:choice == .walls ? layout.design.wallpaper == index : chosenObject?.color == paints[index],tint:GameStyle.palette[paints[index]]))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("roomLittleLook")+" \(index+1)")
                }
            }
        }.padding(12).background(StorybookShelf())
    }
    private var playTray:some View {
        HStack(spacing:12) {
            playButton("heart.fill","hug",color:GameStyle.palette[1]) {react(.hug)}
            playButton("music.note","dance",color:GameStyle.palette[6]) {react(.dance)}
            playButton("circle.fill","roomToy_bubbles",color:GameStyle.palette[11]) {
                if let toy=layout.design.playthings?.first(where:{$0.kind == .bubbles}) {useToy(toy)}
                else {spawnToy(.bubbles,CGPoint(x:0.56,y:0.82));react(.tickle)}
            }
        }.padding(12).frame(maxWidth:700).frame(maxWidth:.infinity)
    }
    private func playButton(_ icon:String,_ key:String,color:Color,action:@escaping()->Void)->some View {
        Button(action:action) {
            VStack(spacing:4) {
                Group {
                    if key == "roomToy_bubbles" {RoomToyArtwork(kind:.bubbles).frame(width:35,height:35)}
                    else {Image(systemName:icon).font(.system(size:27,weight:.bold)).frame(height:35)}
                }
                Text(store.t(key)).font(.system(size:14,weight:.heavy,design:.rounded))
            }.frame(maxWidth:.infinity,minHeight:72).background(CandySurface(color:color,cornerRadius:24))
        }.buttonStyle(SquishStyle())
    }
    private func previewDesign(_ index:Int)->RoomDesign {var next=layout.design;next.wallpaper=index;next.floor=index%4;return next}
    private func decorate(_ index:Int) {
        var next=layout
        if choice == .walls {next.design=previewDesign(index)}
        else if let i=next.objects.firstIndex(where:{$0.kind == choice.item.rawValue}) {
            next.objects[i].color=paints[index];activeID=next.objects[i].id;pulse+=1
        }
        if commit(next) {action = .hug;signal+=1}
    }
    private func load() {
        guard !loaded,let friend=friend else {return};loaded=true
        let saved=RoomLayout(objects:friend.room ?? [],design:friend.roomDesign ?? RoomDesign())
        // Keep every saved object, its identity and appearance. Only arrange it on fixed places.
        layout=saved.forLittleHands()
        if friend.room == nil {persist(layout)}
    }
    @discardableResult private func persist(_ next:RoomLayout)->Bool {
        guard var current=friend else {return false}
        current.room=next.objects;current.roomDesign=next.design;return store.save(current)
    }
    @discardableResult private func commit(_ next:RoomLayout)->Bool {
        guard next != layout else {return true}
        guard persist(next) else {return false}
        history.append(layout);if history.count>40 {history.removeFirst()}
        withAnimation(reduced ? nil : .spring(response:0.4,dampingFraction:0.8)) {layout=next}
        SoundService.shared.play(.click);return true
    }
    private func undo() {
        guard let previous=history.last,persist(previous) else {return}
        history.removeLast();layout=previous;friendPreview=nil;toyPreview=nil
    }
    private func tap(_ value:RoomObject) {
        if decorating {choice=LittleRoomChoice.choice(for:RoomItem(rawValue:value.kind) ?? .window);SoundService.shared.play(.click)}
        else {use(value)}
    }
    private func move(_ value:RoomObject,_ finished:Bool) {
        guard !decorating,value.kind == RoomItem.ball.rawValue else {return}
        guard finished else {moving=value;return};defer {moving=nil}
        guard let i=layout.objects.firstIndex(where:{$0.id == value.id}) else {return}
        var next=layout;next.objects[i]=value;commit(next)
    }
    private func moveFriend(_ point:CGPoint,_ finished:Bool) {
        guard !decorating else {return}
        guard finished else {friendPreview=point;return}
        var next=layout;next.design.friendX=Double(point.x);next.design.friendY=Double(point.y);next.design.sleepingBed=nil
        if commit(next) {action = .hug;signal+=1};friendPreview=nil
    }
    private func use(_ value:RoomObject) {
        activeID=value.id;pulse+=1
        guard let kind=RoomItem(rawValue:value.kind) else {return}
        switch kind {
        case .lamp,.toybox:
            var next=layout
            if let i=next.objects.firstIndex(where:{$0.id == value.id}) {next.objects[i].on = !value.isOn;commit(next)}
        case .bed:
            var next=layout
            if next.design.sleepingBed == value.id {
                next.design.sleepingBed=nil
                next.design.friendX=min(0.9,max(0.1,value.x+0.12))
                next.design.friendY=min(0.9,max(0.2,value.y))
                if commit(next) {action = .hug;signal+=1}
            } else {
                next.design.sleepingBed=value.id;next.design.blanket=0.25
                if commit(next) {action = .sleep;signal+=1}
            }
        case .window:
            var next=layout;next.design.curtainsClosed = !(next.design.curtainsClosed ?? false);commit(next)
        case .sofa,.cushion:react(.hug,near:value)
        case .snack,.table:react(.feed,near:value)
        case .music:
            react(.dance);SoundService.shared.instrument(1,beat:pulse%8)
        case .ball,.stool:react(.jump)
        case .shelf:
            react(.hug);SoundService.shared.instrument(1,beat:pulse%8)
        case .plant:react(.tickle)
        default:SoundService.shared.instrument(1,beat:value.kind%8)
        }
    }
    private func react(_ value:PlayAction,near object:RoomObject?=nil) {
        var next=layout
        if value != .sleep {next.design.sleepingBed=nil}
        if let object=object {
            next.design.friendX=min(0.9,max(0.1,object.x))
            next.design.friendY=min(0.9,max(0.2,object.y-0.04))
        }
        if commit(next) {action=value;signal+=1}
    }
    private func spawnToy(_ kind:RoomToyKind,_ point:CGPoint) {
        if kind != .blocks,let existing=layout.design.playthings?.first(where:{$0.kind == kind}) {useToy(existing);return}
        var next=layout
        var toys=next.design.playthings ?? []
        guard toys.count<24 else {full=true;return}
        var toy=RoomPlaything(kind:kind,color:(toys.count*3)%16)
        toy.move(x:Double(point.x),y:Double(point.y))
        toys.append(toy);next.design.playthings=toys
        if commit(next) {SoundService.shared.play(.bounce)}
    }
    private func moveToy(_ toy:RoomPlaything,_ finished:Bool) {
        guard finished else {toyPreview=toy;return}
        defer {toyPreview=nil}
        var next=layout
        guard var toys=next.design.playthings,let index=toys.firstIndex(where:{$0.id == toy.id}) else {return}
        var placed=toy
        if toy.kind == .blocks,let base=toys.first(where:{
            $0.id != toy.id && $0.kind == .blocks && abs($0.x-toy.x)<0.055 && abs($0.y-toy.y)<0.09
        }) {placed.move(x:base.x,y:base.y-0.065)}
        toys[index]=placed;next.design.playthings=toys;commit(next)
    }
    private func useToy(_ toy:RoomPlaything) {
        switch toy.kind {
        case .flashlight:
            var next=layout
            guard var toys=next.design.playthings,let index=toys.firstIndex(where:{$0.id == toy.id}) else {return}
            toys[index].on.toggle();next.design.playthings=toys;commit(next)
        case .bubbles:react(.tickle)
        case .blocks:react(.jump);SoundService.shared.play(.bounce)
        }
    }
    private func cover(_ amount:Double) {
        var next=layout;next.design.blanket=min(1,max(0,amount));commit(next)
    }
    private func putAwayToys() {
        var next=layout;next.design.playthings=[]
        for index in next.objects.indices where next.objects[index].kind == RoomItem.toybox.rawValue {
            next.objects[index].on=false
        }
        commit(next)
    }
}
