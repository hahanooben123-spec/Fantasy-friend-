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
        case .studio: return UnitPoint(x:0.25,y:0.19)
        case .pizza: return UnitPoint(x:0.75,y:0.19)
        case .games: return UnitPoint(x:0.25,y:0.49)
        case .homes: return UnitPoint(x:0.75,y:0.49)
        case .pumpkins: return UnitPoint(x:0.25,y:0.79)
        }
    }
}

/// Painted sprites and their live doors are shared between map and journey.
struct VillageBuilding: View, Animatable {
    let place: VillagePlace
    nonisolated var opening=0.0
    var tint:Color?
    nonisolated var animatableData:Double {
        get {opening}
        set {opening=newValue}
    }
    var body:some View {
        PaintedVillageBuilding(place:place,opening:opening,rug:tint)
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
    var destination:VillagePlace?
    var onReach:()->Void = {}
    @State private var approaching=false
    var body: some View {
        GeometryReader { proxy in
            let s=proxy.size
            let buildingWidth=min(wide ? 320 : 270,min(s.width*(wide ? 0.29 : 0.45),s.height*(wide ? 0.42 : 0.30)-(wide ? 0 : 30)))
            let target=destination?.point(wide:wide)
            let homePoint=CGPoint(x:s.width*(wide ? 0.50 : 0.75),y:s.height*(wide ? 0.66 : 0.81))
            let walkingPoint=CGPoint(x:s.width*(target?.x ?? 0.5),y:s.height*(target?.y ?? 0.5)+buildingWidth*0.28)
            let friendWidth=min(wide ? 210 : 170,min(s.width*0.34,s.height*(wide ? 0.28 : 0.25)))
            ZStack {
                VillageLandscape(wide:wide,dusk:dusk,active:active)
                ForEach(VillagePlace.allCases) { place in
                    let point=place.point(wide:wide)
                    Button {visit(place)} label: {
                        VStack(spacing:-4) {
                            VillageBuilding(place:place,tint:place == .homes ?
                                RoomPalette.walls[friend.roomDesign?.wallpaper ?? 0] : nil)
                            VillageCaption(title:store.t("villageShort_\(place.rawValue)"),size:wide ? 24 : 20)
                                .padding(.top,2).padding(.bottom,5)
                        }.frame(width:buildingWidth)
                            // The artwork is decorative; this label owns one continuous house-sized hit target.
                            .background(Color.white.opacity(0.001))
                            .contentShape(Rectangle())
                    }.buttonStyle(VillageHousePressStyle()).accessibilityLabel(store.t(place.titleKey))
                        .accessibilityHint(store.t("villageEnter"))
                        .position(x:s.width*point.x,y:s.height*point.y)
                }
                keepsakes(size:s,width:buildingWidth)
                VStack(spacing:0) {
                    LivingFriend(friend:friend,audible:true,locomotion:destination == nil ? 0 : 0.8,active:active,greetOnArrival:true)
                        .frame(width:friendWidth,height:friendWidth*CGFloat(320)/CGFloat(300))
                    Button(action:chooseFriend) {
                        HStack(spacing:6) {
                            VillageCaption(title:friend.name.isEmpty ? store.t("chooseFriend") : friend.name,size:15)
                            Image(systemName:"arrow.triangle.2.circlepath")
                                .font(.system(size:15,weight:.heavy)).foregroundColor(.white)
                                .shadow(color:GameStyle.purple,radius:0,y:2)
                        }.padding(.horizontal,10).frame(minHeight:44).contentShape(Rectangle())
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("chooseFriend"))
                        .opacity(destination == nil ? 1 : 0).disabled(destination != nil)
                }.scaleEffect(approaching ? 0.70 : 1,anchor:.bottom)
                    .position(approaching ? walkingPoint : homePoint)
                    .allowsHitTesting(destination == nil)

            }
        }.foregroundColor(GameStyle.ink)
            .task(id:destination) {
                guard destination != nil else {approaching=false;return}
                if reduced {onReach();return}
                withAnimation(.easeInOut(duration:0.72)) {approaching=true}
                do {try await Task.sleep(nanoseconds:740_000_000);try Task.checkCancellation()} catch {return}
                onReach()
            }
    }

    @ViewBuilder private func keepsakes(size s:CGSize,width:CGFloat) -> some View {
        let garden=VillagePlace.pumpkins.point(wide:wide)
        ForEach(Array(lanterns.prefix(2).enumerated()),id:\.element.id) { index, lantern in
            PumpkinIllustration(lantern:lantern,animated:false)
                .frame(width:48,height:55).rotationEffect(.degrees(Double(index)*12-6))
                .position(x:s.width*garden.x+(CGFloat(index)-0.5)*43,y:s.height*garden.y+width*0.21)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        if let pizza=pizza,pizza.served {
            let shop=VillagePlace.pizza.point(wide:wide)
            PizzaIllustration(recipe:pizza.recipe,baked:1)
                .frame(width:65,height:69).rotationEffect(.degrees(9))
                .position(x:s.width*shop.x+width*0.32,y:s.height*shop.y+width*0.15)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        let homes=VillagePlace.homes.point(wide:wide)
        ForEach(Array(store.friends.filter {$0.id != friend.id}.prefix(1).enumerated()),id:\.element.id) { index, other in
            CharacterView(friend:other)
                .frame(width:52,height:57)
                .position(x:s.width*homes.x+CGFloat(index == 0 ? -1 : 1)*width*0.32,
                          y:s.height*homes.y+width*0.18)
                .allowsHitTesting(false).accessibilityHidden(true)
        }

    }
}

struct VillageLandscape: View {
    var wide: Bool
    var dusk: Bool
    var active=true
    var body: some View {
        ZStack {
            PaintedVillageBackdrop(dusk:dusk,active:active)
            Canvas { c,s in
                let hub=CGPoint(x:s.width*0.5,y:s.height*(wide ? 0.64 : 0.82))
                for place in VillagePlace.allCases {
                    let point=place.point(wide:wide)
                    let end=CGPoint(x:s.width*point.x,y:s.height*point.y+min(75,s.width*0.15))
                    var trail=Path();trail.move(to:hub)
                    trail.addQuadCurve(to:end,control:CGPoint(x:s.width*0.5,y:end.y))
                    c.stroke(trail,with:.color(StorybookStyle.timber.opacity(0.12)),
                        style:StrokeStyle(lineWidth:wide ? 38 : 28,lineCap:.round))
                    c.stroke(trail,with:.linearGradient(Gradient(colors:[
                        Color(red:0.98,green:0.85,blue:0.59).opacity(0.52),
                        Color(red:0.85,green:0.64,blue:0.37).opacity(0.40)]),
                        startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)),
                        style:StrokeStyle(lineWidth:wide ? 32 : 23,lineCap:.round))
                    for i in 0..<6 {
                        let t=CGFloat(i+1)/7
                        let x=(1-t)*(1-t)*hub.x+2*(1-t)*t*s.width*0.5+t*t*end.x
                        let y=(1-t)*(1-t)*hub.y+2*(1-t)*t*end.y+t*t*end.y
                        c.fill(Path(ellipseIn:CGRect(x:x-3,y:y-1,width:6,height:3)),
                            with:.color(StorybookStyle.cream.opacity(0.2)))
                    }
                }
            }.allowsHitTesting(false)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}


/// Short outlined lettering belongs to the scene, without a separate UI bubble.
struct VillageCaption:View {
    let title:String
    var size:CGFloat=18
    var body:some View {
        Text(title).font(.system(size:size,weight:.black,design:.rounded))
            .foregroundColor(GameStyle.purple)
            .lineLimit(1).minimumScaleFactor(0.7)
            .shadow(color:.white,radius:0,x:-2,y:0)
            .shadow(color:.white,radius:0,x:2,y:0)
            .shadow(color:.white,radius:0,x:0,y:-2)
            .shadow(color:.white,radius:0,x:0,y:2)
            .shadow(color:GameStyle.ink.opacity(0.18),radius:1,y:3)
    }
}


/// A house is a big toy button, including its roof, door and caption.
private struct VillageHousePressStyle:ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduced
    func makeBody(configuration:Configuration)->some View {
        configuration.label
            .background {
                Ellipse().fill(StorybookStyle.honey.opacity(configuration.isPressed ? 0.35 : 0))
                    .blur(radius:12).padding(.horizontal,12)
            }
            .scaleEffect(configuration.isPressed && !reduced ? 0.93 : 1)
            .rotationEffect(.degrees(configuration.isPressed && !reduced ? -2 : 0))
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(reduced ? nil : .spring(response:0.28,dampingFraction:0.55),value:configuration.isPressed)
    }
}
