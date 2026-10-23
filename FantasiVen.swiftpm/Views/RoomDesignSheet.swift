import SwiftUI

struct RoomDesignSheet:View {
    @EnvironmentObject private var words:FriendStore
    let design:RoomDesign
    let onDesign:(RoomDesign)->Void
    let onPreset:(Int)->Void
    let onClose:()->Void
    @State private var proposed:Int?
    var body:some View {
        ZStack {
            WorkshopLook.cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    HStack {
                        Text(words.t("roomStyle")).font(.system(.title,design:.rounded).weight(.heavy))
                        Spacer();RoundButton(icon:"xmark",label:words.t("close"),action:onClose)
                    }
                    Text(words.t("roomWallpaper")).font(.system(.headline,design:.rounded))
                    LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3),spacing:12) {
                        ForEach(0..<6) {index in
                            Button {var next=design;next.wallpaper=index;onDesign(next)} label:{
                                RoomInterior(design:sample(index)).frame(height:90).clipShape(RoundedRectangle(cornerRadius:18))
                                    .overlay(RoundedRectangle(cornerRadius:18).stroke(design.wallpaper == index ? GameStyle.purple : .white,lineWidth:3))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("roomWall\(index)"))
                        }
                    }
                    Text(words.t("roomFloor")).font(.system(.headline,design:.rounded))
                    HStack(spacing:12) {
                        ForEach(0..<4) {index in
                            Button {var next=design;next.floor=index;onDesign(next)} label:{
                                RoundedRectangle(cornerRadius:16).fill(LinearGradient(colors:[
                                    GameStyle.mixed(RoomPalette.floors[index],with:.white,amount:0.2),RoomPalette.floors[index]],
                                    startPoint:.topLeading,endPoint:.bottomTrailing))
                                    .frame(maxWidth:.infinity,minHeight:65)
                                    .overlay(RoundedRectangle(cornerRadius:16).stroke(design.floor == index ? GameStyle.purple : .white,lineWidth:3))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(words.t("roomFloor")+" \(index+1)")
                        }
                    }
                    CandyButton(title:words.t(design.night ? "roomMorning" : "roomEvening"),
                        icon:design.night ? "sun.max.fill" : "moon.stars.fill",color:GameStyle.palette[6]) {
                        var next=design;next.night.toggle();onDesign(next)
                    }
                    Text(words.t("roomTemplates")).font(.system(.headline,design:.rounded))
                    Text(words.t("roomTemplateHint")).font(.system(.subheadline,design:.rounded))
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:16) {
                            ForEach(0..<3) {index in
                                Button {proposed=index} label:{
                                    VStack(spacing:6) {
                                        template(index).frame(width:190,height:150).clipShape(RoundedRectangle(cornerRadius:20))
                                        Text(words.t("roomTemplate\(index)")).font(.system(size:14,weight:.heavy,design:.rounded))
                                    }.padding(10).background(CandySurface(color:.white,cornerRadius:24))
                                }.buttonStyle(SquishStyle())
                            }
                        }.padding(.vertical,6)
                    }
                }.padding(24).frame(maxWidth:720).frame(maxWidth:.infinity)
            }
        }.foregroundColor(GameStyle.ink)
            .alert(words.t("roomReplace"),isPresented:Binding(get:{proposed != nil},set:{if !$0 {proposed=nil}})) {
                Button(words.t("cancel"),role:.cancel) {proposed=nil}
                Button(words.t("roomChooseTemplate")) {if let index=proposed {onPreset(index)};proposed=nil}
            } message:{Text(words.t("roomReplaceHint"))}
    }
    private func sample(_ index:Int)->RoomDesign {var next=design;next.wallpaper=index;return next}
    private func template(_ index:Int)->some View {
        let value=RoomLayout.starter(index)
        return ZStack {
            RoomInterior(design:value.design)
            ForEach(value.objects) {item in
                RoomFurniture(kind:item.kind,tint:item.color).frame(width:52,height:57)
                    .position(x:item.x*190,y:item.y*150)
            }
        }
    }
}
