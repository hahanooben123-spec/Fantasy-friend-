import SwiftUI

enum VillagePlace: Int, CaseIterable, Identifiable {
    case studio, pizza, games, homes, pumpkins
    var id: Int { rawValue }
    var titleKey: String {
        switch self {
        case .studio: return "villageStudio"
        case .pizza: return "villagePizza"
        case .games: return "villageGames"
        case .homes: return "villageHomes"
        case .pumpkins: return "villagePumpkins"
        }
    }
    var color: Color {
        switch self {
        case .studio: return Color(red:1,green:0.64,blue:0.24)
        case .pizza: return Color(red:0.94,green:0.34,blue:0.25)
        case .games: return Color(red:0.13,green:0.70,blue:0.78)
        case .homes: return Color(red:0.67,green:0.43,blue:0.85)
        case .pumpkins: return Color(red:0.96,green:0.60,blue:0.17)
        }
    }
    func point(wide: Bool) -> UnitPoint {
        if wide {
            switch self {
            case .studio: return UnitPoint(x:0.17,y:0.25)
            case .pizza: return UnitPoint(x:0.50,y:0.23)
            case .games: return UnitPoint(x:0.83,y:0.25)
            case .homes: return UnitPoint(x:0.24,y:0.73)
            case .pumpkins: return UnitPoint(x:0.77,y:0.73)
            }
        }
        switch self {
        case .studio: return UnitPoint(x:0.25,y:0.17)
        case .pizza: return UnitPoint(x:0.75,y:0.17)
        case .games: return UnitPoint(x:0.25,y:0.49)
        case .homes: return UnitPoint(x:0.75,y:0.49)
        case .pumpkins: return UnitPoint(x:0.25,y:0.81)
        }
    }
}

/// The same original building is used on the map and while entering its doorway.
struct VillageBuilding: View, Animatable {
    let place: VillagePlace
    var opening = 0.0
    var tint:Color?
    var animatableData:Double {
        get {opening}
        set {opening=newValue}
    }
    var body: some View {
        ZStack {
            Canvas { c, s in
                c.scaleBy(x:s.width/240,y:s.height/200)
                c.fill(Path(ellipseIn:CGRect(x:17,y:167,width:208,height:22)),
                    with:.color(StorybookStyle.plum.opacity(0.2)))
                let roof=GameStyle.mixed(tint ?? place.color,with:StorybookStyle.plum,amount:0.36)
                HomeCottage.draw(c,x:42,y:26,width:156,height:150,color:tint ?? place.color,roof:roof)
                if place == .pizza {
                    ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:157,y:7,width:24,height:41),cornerRadius:5),
                        color:Color(red:0.76,green:0.34,blue:0.24))
                    for row in 0..<3 {
                        var seam=Path();seam.move(to:CGPoint(x:158,y:17+CGFloat(row)*10))
                        seam.addLine(to:CGPoint(x:180,y:17+CGFloat(row)*10))
                        c.stroke(seam,with:.color(StorybookStyle.cream.opacity(0.6)),lineWidth:2)
                    }
                    for i in 0..<8 {
                        let x=CGFloat(i)*20+40
                        ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:x,y:88,width:21,height:20),cornerRadius:6),
                            color:i%2 == 0 ? StorybookStyle.cream : Color(red:0.94,green:0.25,blue:0.22),edge:1)
                    }
                }
                if place == .pumpkins {
                    var vine=Path();vine.move(to:CGPoint(x:20,y:177))
                    vine.addCurve(to:CGPoint(x:215,y:175),control1:CGPoint(x:47,y:120),control2:CGPoint(x:185,y:203))
                    c.stroke(vine,with:.color(Color(red:0.24,green:0.44,blue:0.2)),style:StrokeStyle(lineWidth:6,lineCap:.round))
                    for i in 0..<5 {
                        let x=CGFloat(i)*39+25
                        let leaf=Path(ellipseIn:CGRect(x:x,y:159+CGFloat(i%2)*11,width:24,height:12))
                        ToyFinish.paint(c,path:leaf,color:Color(red:0.40,green:0.65,blue:0.21),edge:1)
                    }
                }
                // A warm doorway is visible behind two independently opening door leaves.
                let doorway=CGRect(x:100,y:115,width:43,height:62)
                c.fill(Path(roundedRect:doorway,cornerRadius:18),with:.linearGradient(
                    Gradient(colors:[StorybookStyle.honey,StorybookStyle.cream]),
                    startPoint:CGPoint(x:120,y:115),endPoint:CGPoint(x:120,y:177)))
                let leafWidth=max(0.5,21.5*(1-opening))
                for side in 0..<2 {
                    let x=side == 0 ? doorway.minX : doorway.maxX-leafWidth
                    ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:x,y:115,width:leafWidth,height:62),cornerRadius:6),
                        color:StorybookStyle.teal,edge:1.5)
                    c.fill(Path(ellipseIn:CGRect(x:side == 0 ? x+leafWidth-5 : x+2,y:149,width:3,height:4)),
                        with:.color(StorybookStyle.honey))
                }
                ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:89,y:175,width:66,height:9),cornerRadius:4),
                    color:Color(red:0.80,green:0.57,blue:0.35),edge:1)
            }
            GeometryReader { proxy in
                badge.frame(width:proxy.size.width*0.26,height:proxy.size.height*0.30)
                    .position(x:proxy.size.width*0.5,y:proxy.size.height*0.36)
            }
        }.aspectRatio(1.2,contentMode:.fit).allowsHitTesting(false).accessibilityHidden(true)
    }
    @ViewBuilder private var badge: some View {
        switch place {
        case .studio: ToyGlyph(kind:.brush).rotationEffect(.degrees(-15))
        case .pizza: PizzaIllustration(recipe:.sample,baked:1,board:false)
        case .games: ToyGlyph(kind:.music)
        case .homes: ToyGlyph(kind:.heart)
        case .pumpkins: PumpkinIllustration(lantern:PumpkinDoor.sample,animated:false)
        }
    }
}

struct VillageSquare: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend: FantasyFriend
    let lanterns: [PumpkinLantern]
    let pizza: PizzaDraft?
    let wide: Bool
    let dusk: Bool
    let active: Bool
    let visit: (VillagePlace) -> Void
    let chooseFriend: () -> Void
    @State private var flower = 0
    var body: some View {
        GeometryReader { proxy in
            let s=proxy.size
            let buildingWidth=min(wide ? 285 : 255,s.width*(wide ? 0.29 : 0.47))
            ZStack {
                VillageLandscape(wide:wide,dusk:dusk)
                ForEach(VillagePlace.allCases) { place in
                    let point=place.point(wide:wide)
                    Button {visit(place)} label: {
                        VStack(spacing:-4) {
                            VillageBuilding(place:place,tint:place == .homes ?
                                RoomPalette.walls[friend.roomDesign?.wallpaper ?? 0] : nil)
                            Text(store.t(place.titleKey))
                                .font(.system(size:wide ? 19 : 16,weight:.heavy,design:.rounded))
                                .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
                                .padding(.horizontal,12).padding(.vertical,8)
                                .background(StorybookPanel(cornerRadius:18))
                        }.frame(width:buildingWidth)
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(place.titleKey))
                        .position(x:s.width*point.x,y:s.height*point.y)
                }
                keepsakes(size:s,width:buildingWidth)
                VStack(spacing:0) {
                    LivingFriend(friend:friend,audible:true,active:active)
                        .frame(width:min(wide ? 180 : 155,s.width*0.37),height:wide ? 190 : 160)
                    Button(action:chooseFriend) {
                        HStack(spacing:6) {
                            Text(friend.name.isEmpty ? store.t("villageCompanion") : friend.name)
                                .font(.system(size:14,weight:.heavy,design:.rounded)).lineLimit(1)
                            Image(systemName:"arrow.triangle.2.circlepath").font(.system(size:13,weight:.bold))
                        }.padding(.horizontal,12).frame(minHeight:44)
                            .background(StorybookPanel(cornerRadius:20))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("chooseFriend"))
                }.position(x:s.width*(wide ? 0.50 : 0.75),y:s.height*(wide ? 0.66 : 0.81))
                Button {
                    flower += 1;SoundService.shared.play(.bubble)
                } label: {
                    FlowerArtwork(index:flower%7).frame(width:48,height:54)
                        .rotationEffect(.degrees(Double(flower%2)*18-9))
                        .animation(reduced ? nil : .spring(response:0.35,dampingFraction:0.45),value:flower)
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("villageFlower"))
                    .position(x:s.width*(wide ? 0.42 : 0.49),y:s.height*0.93)
            }
        }.foregroundColor(GameStyle.ink)
    }

    @ViewBuilder private func keepsakes(size s:CGSize,width:CGFloat) -> some View {
        let garden=VillagePlace.pumpkins.point(wide:wide)
        ForEach(Array(lanterns.prefix(3).enumerated()),id:\.element.id) { index, lantern in
            PumpkinIllustration(lantern:lantern,animated:false)
                .frame(width:48,height:55).rotationEffect(.degrees(Double(index-1)*9))
                .position(x:s.width*garden.x+CGFloat(index-1)*43,y:s.height*garden.y+width*0.47)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        if let pizza=pizza,pizza.served {
            let shop=VillagePlace.pizza.point(wide:wide)
            PizzaIllustration(recipe:pizza.recipe,baked:1)
                .frame(width:65,height:69).rotationEffect(.degrees(9))
                .position(x:s.width*shop.x+width*0.32,y:s.height*shop.y+width*0.24)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        let homes=VillagePlace.homes.point(wide:wide)
        ForEach(Array(store.friends.filter {$0.id != friend.id}.prefix(2).enumerated()),id:\.element.id) { index, other in
            CharacterView(friend:other)
                .frame(width:52,height:57)
                .position(x:s.width*homes.x+CGFloat(index == 0 ? -1 : 1)*width*0.32,
                          y:s.height*homes.y+width*0.24)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        if !(friend.doodles ?? []).isEmpty {
            let studio=VillagePlace.studio.point(wide:wide)
            CharacterView(friend:friend).padding(3).frame(width:41,height:48)
                .background(StorybookPanel(cornerRadius:6)).rotationEffect(.degrees(-8))
                .position(x:s.width*studio.x-width*0.33,y:s.height*studio.y+width*0.20)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

struct VillageLandscape: View {
    var wide: Bool
    var dusk: Bool
    var body: some View {
        Canvas { c,s in
            let grass=GameStyle.mixed(Color(red:0.37,green:0.73,blue:0.37),
                with:Color(red:0.15,green:0.32,blue:0.34),amount:dusk ? 0.7 : 0)
            c.fill(Path(CGRect(origin:.zero,size:s)),with:.linearGradient(Gradient(colors:[
                GameStyle.mixed(grass,with:StorybookStyle.cream,amount:0.3),grass,
                GameStyle.mixed(grass,with:StorybookStyle.teal,amount:0.30)]),
                startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)))
            let hub=CGPoint(x:s.width*0.5,y:s.height*(wide ? 0.64 : 0.82))
            for place in VillagePlace.allCases {
                let point=place.point(wide:wide)
                let end=CGPoint(x:s.width*point.x,y:s.height*point.y+min(75,s.width*0.15))
                var trail=Path();trail.move(to:hub)
                trail.addQuadCurve(to:end,control:CGPoint(x:s.width*0.5,y:end.y))
                c.stroke(trail,with:.color(StorybookStyle.timber.opacity(0.16)),
                    style:StrokeStyle(lineWidth:wide ? 45 : 33,lineCap:.round))
                c.stroke(trail,with:.linearGradient(Gradient(colors:[
                    Color(red:0.98,green:0.85,blue:0.59),Color(red:0.85,green:0.64,blue:0.37)]),
                    startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)),
                    style:StrokeStyle(lineWidth:wide ? 38 : 27,lineCap:.round))
            }
            for i in 0..<42 {
                let x=CGFloat((i*71+11)%997)/997*s.width
                let y=CGFloat((i*53+47)%499)/499*s.height
                var blades=Path();blades.move(to:CGPoint(x:x-3,y:y+6))
                blades.addQuadCurve(to:CGPoint(x:x-7,y:y-5),control:CGPoint(x:x,y:y-5))
                blades.move(to:CGPoint(x:x,y:y+6));blades.addQuadCurve(to:CGPoint(x:x+5,y:y-7),control:CGPoint(x:x-3,y:y-3))
                c.stroke(blades,with:.color(StorybookStyle.teal.opacity(0.18)),
                    style:StrokeStyle(lineWidth:2,lineCap:.round))
            }
        }.storybookScene(night:dusk,foliage:true).allowsHitTesting(false).accessibilityHidden(true)
    }
}
