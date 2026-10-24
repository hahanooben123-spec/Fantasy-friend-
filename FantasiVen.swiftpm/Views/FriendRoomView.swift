import SwiftUI

struct FriendRoomView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.presentationMode) private var presentation
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    let friendID:UUID
    @State private var layout=RoomLayout()
    @State private var loaded=false
    @State private var decorating=false
    @State private var selected:UUID?
    @State private var adding=false
    @State private var colorPicking=false
    @State private var history:[RoomLayout]=[]
    @State private var friendPreview:CGPoint?
    @State private var toyPreview:RoomPlaything?
    @State private var moving:RoomObject?
    @State private var action=PlayAction.jump
    @State private var signal=0
    @State private var activeID:UUID?
    @State private var pulse=0
    @State private var full=false
    private let paints=[9,11,6,3]
    private var friend:FantasyFriend? {store.friends.first {$0.id == friendID}}
    private var chosenObject:RoomObject? {layout.objects.first {$0.id == selected}}
    private let furniture:[RoomItem]=[.bed,.rug,.lamp,.toybox,.picture,.plant,.window,.cushion]

    var body:some View {
        GeometryReader {proxy in
            let large=proxy.size.width>=650
            VStack(spacing:0) {
                header
                if let friend=friend {
                    if decorating {
                        PlayWorkspace(wide:WorkshopLayout.sidebar(proxy.size),toolWidth:330,toolHeight:large ? 245 : 290) {
                            roomScene(friend)
                        } tools:{
                            ScrollView(.vertical,showsIndicators:true) {decorationTray(large:false)}.background(StorybookShelf())
                        }
                    } else {
                        roomScene(friend).frame(maxWidth:.infinity,maxHeight:.infinity)
                        playTray
                    }
                } else {
                    Spacer();Text(store.t("roomMissing")).foregroundColor(.white).padding(30);Spacer()
                }
            }.background(StorybookWorkshopWall().ignoresSafeArea())
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true).statusBar(hidden:true)
            .onAppear {load();store.visit(.room,friendID:friendID);SoundService.shared.setWorld(layout.design.night ? .stars : .castle)}
            .onChange(of:phase) {value in
                if value != .active {friendPreview=nil;toyPreview=nil;moving=nil}
            }
            .onChange(of:layout.design.night) {night in SoundService.shared.setWorld(night ? .stars : .castle)}
            .alert(store.t("error"),isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error=nil}})) {
                Button("OK") {store.error=nil}
            } message:{Text(store.error ?? "")}
    }
    private func roomScene(_ friend:FantasyFriend)->some View {
        RoomScene(friend:friend,layout:layout,editing:decorating,selected:decorating ? selected : nil,
                        moving:moving,friendPreview:friendPreview,action:action,signal:signal,activeID:activeID,pulse:pulse,pending:nil,
                        onSelect:{selected=$0},onTap:tap,onMove:move,onFriendMove:moveFriend,
                        onDropItem:{_,_ in},toyPreview:toyPreview,onSpawnToy:spawnToy,onMoveToy:moveToy,
                        onUseToy:useToy,onCover:cover,fixedLayout:false)
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
                decorating.toggle();friendPreview=nil;toyPreview=nil;moving=nil;selected=nil;adding=decorating;colorPicking=false
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
            HStack(spacing:10) {
                roomTool("plus","roomAdd",selected:adding) {adding.toggle();colorPicking=false}
                roomTool("paintpalette.fill",chosenObject == nil ? "roomLittleWalls" : "color",selected:colorPicking) {colorPicking.toggle();adding=false}
                roomTool("tray.and.arrow.down.fill","roomPutAway",selected:false,action:putAway)
                    .disabled(chosenObject == nil).opacity(chosenObject == nil ? 0.4 : 1)
            }
            if adding {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:large ? 8 : 4),spacing:8) {
                    ForEach(furniture,id:\.rawValue) {item in
                        Button {addFurniture(item)} label:{
                            VStack(spacing:2) {
                                RoomFurniture(kind:item.rawValue).frame(height:large ? 78 : 48)
                                Text(store.t(item.key)).font(.system(size:large ? 14 : 11,weight:.heavy,design:.rounded))
                                    .lineLimit(1).minimumScaleFactor(0.75)
                            }.padding(4).frame(maxWidth:.infinity,minHeight:large ? 110 : 76)
                                .background(GameChoiceSurface(selected:false))
                        }.buttonStyle(SquishStyle())
                    }
                }
            } else if colorPicking {
                HStack(spacing:10) {
                    ForEach(0..<4) {index in
                        Button {decorate(index)} label:{
                            Group {
                                if let object=chosenObject {RoomFurniture(kind:object.kind,tint:paints[index],isOn:object.isOn).padding(5)}
                                else {RoomInterior(design:previewDesign(index)).clipShape(RoundedRectangle(cornerRadius:20))}
                            }.frame(height:large ? 100 : 90).frame(maxWidth:.infinity)
                                .background(GameChoiceSurface(selected:chosenObject.map {$0.color == paints[index]} ?? (layout.design.wallpaper == index),tint:GameStyle.palette[paints[index]]))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("roomLittleLook")+" \(index+1)")
                    }
                }
            } else {
                HStack(spacing:12) {
                    Image(systemName:"hand.draw.fill").font(.system(size:32,weight:.bold))
                    Text(store.t(full ? "roomFull" : "roomArrangeHint"))
                        .font(.system(size:16,weight:.heavy,design:.rounded)).multilineTextAlignment(.center)
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
            }
            Spacer(minLength:0)
        }.padding(12).background(StorybookShelf())
    }
    private func roomTool(_ icon:String,_ key:String,selected:Bool,action:@escaping()->Void)->some View {
        Button(action:action) {
            HStack(spacing:6) {
                Image(systemName:icon).font(.system(size:23,weight:.bold))
                Text(store.t(key)).font(.system(size:14,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth:.infinity,minHeight:58).background(GameChoiceSurface(selected:selected))
        }.buttonStyle(SquishStyle())
    }
    private func addFurniture(_ kind:RoomItem) {
        guard layout.objects.count<32 else {full=true;adding=false;return}
        let count=layout.objects.filter {$0.kind == kind.rawValue}.count
        var object=RoomObject(kind:kind.rawValue,x:kind.isWall ? 0.4 : 0.35,y:kind.isWall ? 0.3 : 0.73)
        object.x=min(0.8,object.x+Double(count%3)*0.16)
        object.color=chosenObject?.color ?? paints[0]
        var next=layout;next.objects.append(object)
        if commit(next) {selected=object.id;adding=false;colorPicking=false;full=false;activeID=object.id;pulse+=1}
    }
    private func putAway() {
        guard let id=selected else {return}
        var next=layout;next.objects.removeAll {$0.id == id}
        if next.design.sleepingBed == id {next.design.sleepingBed=nil}
        if commit(next) {selected=nil;adding=false;colorPicking=false;full=false}
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
        if let id=selected,let i=next.objects.firstIndex(where:{$0.id == id}) {
            next.objects[i].color=paints[index];activeID=id;pulse+=1
        } else {next.design=previewDesign(index)}
        if commit(next) {action = .hug;signal+=1}
    }
    private func load() {
        guard !loaded,let friend=friend else {return};loaded=true
        layout=RoomLayout(objects:friend.room ?? RoomLayout.starter(0).objects,design:friend.roomDesign ?? RoomDesign())
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
        history.removeLast();layout=previous;friendPreview=nil;toyPreview=nil;selected=nil
    }
    private func tap(_ value:RoomObject) {
        if decorating {selected=value.id;adding=false;colorPicking=false;SoundService.shared.play(.click)}
        else {use(value)}
    }
    private func move(_ value:RoomObject,_ finished:Bool) {
        guard decorating || value.kind == RoomItem.ball.rawValue else {return}
        if decorating {selected=value.id}
        guard finished else {moving=value;return};defer {moving=nil}
        guard let i=layout.objects.firstIndex(where:{$0.id == value.id}) else {return}
        var next=layout;next.objects[i]=value
        if commit(next) {activeID=value.id;pulse+=1;SoundService.shared.play(.bounce)}
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
