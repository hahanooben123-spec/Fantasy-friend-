import SwiftUI

struct KitchenGameView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend:FantasyFriend
    @Environment(\.scenePhase) private var phase
    @State private var loaded=false
    @State private var recipe=PizzaRecipe()
    @State private var step=0
    @State private var spice=0
    @State private var topping=PizzaToppingKind.cheese
    @State private var herbs=false
    @State private var history:[PizzaRecipe]=[]
    @State private var before:PizzaRecipe?
    @State private var inserted=false
    @State private var baked=0.0
    @State private var served=false
    @State private var eaten=0
    @State private var signal=0
    @State private var ovenDrag=CGSize.zero
    @State private var pouringIngredient:Int?
    @State private var pourRevision=0
    @State private var biteRevision=0
    @State private var dragItem:PizzaDragItem?
    @State private var dragPoint=CGPoint.zero
    @State private var surfaceFrame=CGRect.zero
    @State private var landingID:UUID?
    @State private var landingPoint=CGPoint.zero
    @State private var landingRevision=0
    private var canContinue:Bool {step == 0 ? recipe.readyForSauce : step == 1 ? !recipe.sauce.isEmpty : true}
    var body:some View {
        AdventureGameShell(kind:.kitchen) {active in
            GeometryReader {proxy in
                let wide=proxy.size.width>=740
                ZStack {
                    PizzaKitchenBackdrop()
                    VStack(spacing:8) {
                        steps
                        if wide {
                            HStack(spacing:16) {
                                stage.frame(maxWidth:.infinity,maxHeight:.infinity)
                                controls.frame(width:280)
                            }
                        } else {
                            stage.frame(maxWidth:.infinity,maxHeight:.infinity)
                            controls.frame(height:step == 0 || (step == 3 && !inserted) ? 245 : step == 2 ? (herbs ? 255 : 320) : 175)
                        }
                    }.padding(.top,77).padding(.horizontal,12).padding(.bottom,12)
                    if step == 0 && recipe.ingredients.isEmpty && pouringIngredient == nil {
                        GestureLesson(activity:pourRevision,from:UnitPoint(x:wide ? 0.86 : 0.25,y:wide ? 0.50 : 0.78),
                            to:UnitPoint(x:surfaceFrame.midX/max(1,proxy.size.width),
                                         y:(surfaceFrame.minY+surfaceFrame.height*0.45)/max(1,proxy.size.height)))
                    }
                    dragOverlay
                    if let ingredient=pouringIngredient {
                        PizzaPourEffect(kind:ingredient,reduced:reduced)
                            .frame(width:surfaceFrame.width*0.85,height:surfaceFrame.height*0.55)
                            .position(x:surfaceFrame.midX,y:surfaceFrame.minY+surfaceFrame.height*0.30)
                            .id(pourRevision).allowsHitTesting(false)
                    }
                }.coordinateSpace(name:"pizzaWorkshop")
                    .onPreferenceChange(PizzaSurfaceFrameKey.self) {surfaceFrame=$0}
                    .onChange(of:active) {if !$0 {dragItem=nil;pouringIngredient=nil}}
                    .onChange(of:step) {_ in dragItem=nil;landingID=nil;pouringIngredient=nil}
                    .task(id:pourRevision) {
                        guard let ingredient=pouringIngredient else {return}
                        do {try await Task.sleep(nanoseconds:1_000_000_000)} catch {return}
                        guard active,step == 0,pouringIngredient == ingredient else {return}
                        change {$0.ingredients.insert(ingredient)}
                        pouringIngredient=nil
                        landingPoint=CGPoint(x:surfaceFrame.midX,y:surfaceFrame.minY+surfaceFrame.height*0.47)
                        landingRevision+=1
                        SoundService.shared.play(.reaction)
                    }
                    .task(id:landingID) {
                        guard landingID != nil else {return}
                        do {try await Task.sleep(nanoseconds:520_000_000)} catch {return}
                        landingID=nil
                    }
            }
            .task(id:active && inserted && baked<1 && !served) {
                guard active,inserted,baked<1,!served else {return}
                do {
                    while baked<1 {
                        try await Task.sleep(nanoseconds:120_000_000)
                        try Task.checkCancellation()
                        baked=min(1,baked+0.025)
                        SoundService.shared.play(.oven)
                    }
                    SoundService.shared.play(.complete)
                } catch {return}
            }
        }.onAppear(perform:restore)
            .task(id:snapshot) {
                guard loaded else {return}
                do {try await Task.sleep(nanoseconds:650_000_000)} catch {return}
                store.savePizzaDraft(snapshot)
            }
            .onChange(of:phase) {value in if value != .active && loaded {store.savePizzaDraft(snapshot)}}
            .onDisappear {if loaded {store.savePizzaDraft(snapshot)}}
    }

    private var snapshot:PizzaDraft {
        PizzaDraft(companion:friend,recipe:recipe,step:step,spice:spice,topping:topping,herbs:herbs,
                   inserted:inserted,baked:baked,served:served,eaten:eaten)
    }
    private func restore() {
        guard !loaded else {return}
        if let draft=store.sessions.pizza,draft.isValid,draft.companion.id == friend.id {
            recipe=draft.recipe;step=draft.step;spice=draft.spice;topping=draft.topping;herbs=draft.herbs
            inserted=draft.inserted;baked=draft.baked;served=draft.served;eaten=draft.eaten
        }
        loaded=true;store.visit(.pizza,friendID:friend.id)
    }

    private var steps:some View {
        HStack(spacing:6) {
            ForEach(0..<4) {index in
                Text("\(index+1). "+store.t("pizzaStep\(index)"))
                    .font(.system(size:12,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.65)
                    .frame(maxWidth:.infinity,minHeight:42)
                    .background(CandySurface(color:index == step ? WorkshopLook.yellow : WorkshopLook.cream,cornerRadius:16))
            }
        }
    }
    @ViewBuilder private var stage:some View {
        if step<3 {
            PizzaWorkSurface(recipe:$recipe,step:step,spice:spice,topping:topping,herbs:herbs,landingID:landingID,targeted:validDropHover,onBegin:begin,onEnd:finish)
                .accessibilityElement(children:.ignore).accessibilityLabel(store.t(instruction))
                .accessibilityAction {assist()}
        } else if served {
            GeometryReader {proxy in
                ZStack(alignment:.bottomLeading) {
                    PizzaIllustration(recipe:recipe,baked:1,eaten:eaten)
                        .frame(maxWidth:.infinity,maxHeight:.infinity).contentShape(Rectangle()).onTapGesture(perform:eat)
                    LivingFriend(friend:friend,action:.feed,signal:signal,feedingFood:nil)
                        .frame(width:min(150,proxy.size.width*0.34),height:min(160,proxy.size.width*0.36))
                        .allowsHitTesting(false)
                    if biteRevision>0 {
                        PizzaBiteFlight(recipe:recipe,revision:biteRevision,reduced:reduced)
                            .allowsHitTesting(false)
                    }
                    if eaten == 0 {
                        VStack {Text(store.t("pizzaChefMoment"))
                            .font(.system(size:24,weight:.heavy,design:.rounded))
                            .foregroundColor(.white).shadow(color:.orange,radius:8)
                            .padding(.top,10);Spacer()}
                            .allowsHitTesting(false)
                    }
                    PlayCelebration(revision:signal).allowsHitTesting(false)
                }
            }
        } else {oven}
    }
    private var oven:some View {
        GeometryReader {proxy in
            let width=min(420,min(proxy.size.width,proxy.size.height*0.95))
            ZStack {
                PizzaOvenArtwork(heat:reduced ? 0 : baked).frame(width:width,height:width*320/300)
                if inserted {
                    PizzaHeatEffects(progress:baked,reduced:reduced)
                        .frame(width:width*0.85,height:width)
                        .allowsHitTesting(false)
                    PizzaIllustration(recipe:recipe,baked:baked,board:false)
                        .frame(width:width*0.53,height:width*0.56).scaleEffect(x:1,y:0.48)
                        .offset(y:width*0.10)
                    if baked>=1 {
                        VStack {
                            Text(store.t("pizzaReady"))
                                .font(.system(size:22,weight:.heavy,design:.rounded))
                                .foregroundColor(.white).padding(.horizontal,20).padding(.vertical,10)
                                .background(Capsule().fill(Color.orange))
                                .shadow(color:.yellow.opacity(0.5),radius:12)
                            Spacer()
                        }.frame(height:width*0.95).allowsHitTesting(false)
                    }
                    PlayCelebration(revision:baked>=1 ? 1 : 0).allowsHitTesting(false)
                } else {
                    PizzaIllustration(recipe:recipe,board:true)
                        .frame(width:width*0.62,height:width*0.66).scaleEffect(x:1,y:0.66)
                        .offset(x:ovenDrag.width,y:width*0.29+ovenDrag.height)
                        .gesture(DragGesture().onChanged {ovenDrag=$0.translation}.onEnded {value in
                            if value.translation.height < -25 {insert()}
                            ovenDrag = .zero
                        })
                }
            }.frame(maxWidth:.infinity,maxHeight:.infinity)
        }
    }
    private var instruction:String {
        if step == 0 {return pouringIngredient != nil ? "pizzaPouring" : recipe.readyToShape ? "pizzaShapeHint" : recipe.ingredients.count == 3 ? "pizzaStirHint" : "pizzaMixHint"}
        if step == 1 {return "pizzaSauceHint"}
        if step == 2 {return herbs ? "pizzaHerbHint" : "pizzaToppingHint"}
        return served ? "pizzaEatHint" : inserted ? (baked>=1 ? "pizzaReady" : "pizzaBaking") : "pizzaOvenHint"
    }
    private var controls:some View {
        VStack(spacing:9) {
            Text(store.t(instruction)).font(.system(size:13,weight:.bold,design:.rounded))
                .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            if step == 0 {
                HStack(spacing:8) {
                    ForEach(0..<3) {index in
                        Button {startPour(index)} label:{
                            VStack(spacing:3) {
                                PizzaIngredientArt(kind:index).frame(width:42,height:48)
                                Text(store.t("pizzaIngredient\(index)")).font(.system(size:12,weight:.heavy,design:.rounded)).lineLimit(1)
                                if recipe.ingredients.contains(index) {Image(systemName:"checkmark").font(.system(size:9,weight:.heavy))}
                            }.frame(maxWidth:.infinity,minHeight:80)
                                .background(CandySurface(color:recipe.ingredients.contains(index) ? GameStyle.palette[11] : .white,cornerRadius:15))
                        }.buttonStyle(SquishStyle()).disabled(recipe.ingredients.contains(index) || pouringIngredient != nil)
                            .highPriorityGesture(dragGesture(.ingredient(index)))
                    }
                }
                ProgressView(value:recipe.readyToShape ? recipe.formed : recipe.mixed).tint(.orange)
            } else if step == 2 {
                decorationTray
            } else if step == 3 && inserted && !served {
                ProgressView(value:baked).tint(.orange).accessibilityLabel(store.t("pizzaBaking"))
            }
            if step<3 {
                HStack(spacing:8) {
                    RoundButton(icon:"arrow.uturn.backward",label:store.t("undo")) {
                        if let previous=history.popLast() {recipe=previous}
                    }.disabled(history.isEmpty || pouringIngredient != nil)
                    RoundButton(icon:"chevron.left",label:store.t("back")) {step=max(0,step-1)}.disabled(step == 0)
                    RoundButton(icon:step == 0 ? "hand.draw.fill" : step == 1 ? "paintbrush.fill" : "sparkles",label:store.t("pizzaAssist"),action:assist)
                        .disabled(step == 0 && recipe.ingredients.count<3)
                    RoundButton(icon:"arrow.right",label:store.t("continue")) {step+=1}
                        .disabled(!canContinue).opacity(canContinue ? 1 : 0.5)
                }
            } else if served {
                HStack(spacing:8) {
                    if eaten<8 {CandyButton(title:store.t("pizzaTaste"),icon:"heart.fill",color:.orange,action:eat)}
                    CandyButton(title:store.t("pizzaAgain"),icon:"arrow.clockwise",color:GameStyle.palette[6],action:reset)
                }
            } else if !inserted {
                Button {step=2} label:{
                    Label(store.t("pizzaBack"),systemImage:"chevron.left")
                        .font(.system(size:13,weight:.bold,design:.rounded)).frame(minHeight:44)
                }.buttonStyle(SquishStyle())
                CandyButton(title:store.t("pizzaInsert"),icon:"arrow.up",color:.orange,action:insert)
            } else if baked>=1 {
                CandyButton(title:store.t("pizzaTakeOut"),icon:"checkmark",color:.orange) {withAnimation(reduced ? nil : .spring(response:0.5,dampingFraction:0.75)) {served=true};SoundService.shared.play(.complete)}
            }
        }.padding(14).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(CandySurface(color:WorkshopLook.cream,cornerRadius:26))
    }
    private var decorationTray:some View {
        VStack(spacing:7) {
            HStack(spacing:7) {
                Button {finish();herbs=false} label:{
                    Text(store.t("pizzaToppings")).font(.system(size:12,weight:.heavy,design:.rounded))
                        .frame(maxWidth:.infinity,minHeight:44)
                        .background(Capsule().fill(herbs ? .white : WorkshopLook.yellow))
                }.buttonStyle(SquishStyle()).accessibilityAddTraits(herbs ? [] : .isSelected)
                Button {finish();herbs=true} label:{
                    Text(store.t("pizzaHerbs")).font(.system(size:12,weight:.heavy,design:.rounded))
                        .frame(maxWidth:.infinity,minHeight:44)
                        .background(Capsule().fill(herbs ? WorkshopLook.yellow : .white))
                }.buttonStyle(SquishStyle()).accessibilityAddTraits(herbs ? .isSelected : [])
            }
            if herbs {
                HStack(spacing:8) {
                    ForEach(0..<3) {index in
                        Button {spice=index;SoundService.shared.play(.click)} label:{
                            VStack(spacing:2) {
                                PizzaIngredientArt(kind:index,spice:true).frame(width:25,height:30)
                                Text(store.t("pizzaSpice\(index)")).font(.system(size:10,weight:.bold,design:.rounded))
                            }.frame(maxWidth:.infinity,minHeight:60)
                                .background(CandySurface(color:spice == index ? WorkshopLook.yellow : .white,cornerRadius:16))
                        }.buttonStyle(SquishStyle()).highPriorityGesture(dragGesture(.herb(index)))
                    }
                }
            } else {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:6),count:4),spacing:9) {
                    ForEach(PizzaToppingKind.allCases,id:\.rawValue) {kind in
                        Button {topping=kind;SoundService.shared.play(.click)} label:{
                            VStack(spacing:2) {
                                ZStack {
                                    PizzaServingDish()
                                    PizzaToppingArt(kind:kind).padding(7)
                                }.frame(height:42)
                                Text(store.t(kind.key)).font(.system(size:10,weight:.heavy,design:.rounded))
                                    .lineLimit(1).minimumScaleFactor(0.65)
                            }.padding(.horizontal,3).frame(maxWidth:.infinity,minHeight:64)
                                .background(RoundedRectangle(cornerRadius:17).fill(topping == kind ? WorkshopLook.yellow.opacity(0.7) : .white.opacity(0.35)))
                                .overlay(RoundedRectangle(cornerRadius:17).stroke(topping == kind ? Color.orange : .white.opacity(0.55),lineWidth:1.5))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(kind.key))
                            .accessibilityAddTraits(topping == kind ? .isSelected : [])
                            .highPriorityGesture(dragGesture(.topping(kind)))
                    }
                }
            }
        }
    }

    private var validDropHover:Bool {
        guard let item=dragItem,surfaceFrame.width>0,surfaceFrame.height>0,
              surfaceFrame.contains(dragPoint) else {return false}
        if case .ingredient = item {return step == 0 && pouringIngredient == nil && bowlContains(dragPoint)}
        let point=PizzaPoint(x:Double((dragPoint.x-surfaceFrame.minX)/surfaceFrame.width),
                             y:Double((dragPoint.y-surfaceFrame.minY)/surfaceFrame.height))
        return step == 2 && point.onDough
    }
    private func dragGesture(_ item:PizzaDragItem)->some Gesture {
        DragGesture(minimumDistance:6,coordinateSpace:.named("pizzaWorkshop"))
            .onChanged {value in
                guard pouringIngredient == nil else {return}
                if dragItem == nil {finish();SoundService.shared.play(.click)}
                dragItem=item;dragPoint=value.location
            }.onEnded {value in
                drop(item,at:value.location);dragItem=nil
            }
    }
    private func drop(_ item:PizzaDragItem,at location:CGPoint) {
        guard surfaceFrame.width>0,surfaceFrame.height>0,surfaceFrame.contains(location) else {return}
        let point=PizzaPoint(x:Double((location.x-surfaceFrame.minX)/surfaceFrame.width),
                             y:Double((location.y-surfaceFrame.minY)/surfaceFrame.height))
        switch item {
        case .ingredient(let index):
            guard step == 0,!recipe.ingredients.contains(index) else {return}
            guard bowlContains(location) else {return}
            startPour(index)
        case .topping(let kind):
            guard step == 2,point.onDough,recipe.toppings.count<120 else {return}
            topping=kind;change {$0.place(kind,at:point)}
            landingID=recipe.toppings.last?.id
        case .herb(let index):
            guard step == 2,point.onDough else {return}
            spice=index;change {$0.sprinkle(index,at:point)}
        }
        landingPoint=location;landingRevision+=1
    }
    @ViewBuilder private var dragOverlay:some View {
        if let item=dragItem {
            PizzaDragArtwork(item:item)
                .frame(width:68,height:72)
                .rotationEffect(.degrees(reduced ? 0 : -9))
                .shadow(color:GameStyle.ink.opacity(0.3),radius:9,x:0,y:12)
                .position(dragPoint).allowsHitTesting(false)
        }
        if landingRevision>0 {
            PizzaLandingSpark(revision:landingRevision,reduced:reduced)
                .frame(width:75,height:75).position(landingPoint).allowsHitTesting(false)
        }
    }
    private func bowlContains(_ point:CGPoint)->Bool {
        let x=(point.x-surfaceFrame.minX)/max(1,surfaceFrame.width)
        let y=(point.y-surfaceFrame.minY)/max(1,surfaceFrame.height)
        return x>0.06 && x<0.94 && y>0.16 && y<0.79
    }
    private func startPour(_ index:Int) {
        guard step == 0,pouringIngredient == nil,!recipe.ingredients.contains(index) else {return}
        finish();pouringIngredient=index;pourRevision+=1
        SoundService.shared.play(index == 0 ? .pourFlour : index == 1 ? .pourWater : .pourOil)
    }
    private func begin() {if before == nil {before=recipe}}
    private func finish() {
        if let old=before,old != recipe {remember(old);SoundService.shared.play(.click)}
        before=nil
    }
    private func remember(_ old:PizzaRecipe) {history.append(old);if history.count>30 {history.removeFirst()}}
    private func change(_ update:(inout PizzaRecipe)->Void) {
        finish();let old=recipe;update(&recipe)
        if old != recipe {remember(old);SoundService.shared.play(.click)}
    }
    private func assist() {
        change {value in
            if step == 0 {
                guard value.ingredients.count == 3 else {return}
                if value.mixed<1 {value.mixed=min(1,value.mixed+0.25)}
                else {value.formed=min(1,value.formed+0.25)}
            } else if step == 1 {value.spreadSauce()}
            else if step == 2 {
                let count=herbs ? value.spices.count : value.toppings.count
                let a=Double(count)*2.4
                let point=PizzaPoint(x:0.5+cos(a)*0.2,y:0.48+sin(a)*0.2)
                if herbs {value.sprinkle(spice,at:point)} else {value.place(topping,at:point)}
            }
        }
    }
    private func insert() {finish();inserted=true;ovenDrag = .zero;SoundService.shared.play(.click)}
    private func eat() {guard eaten<8 else {return};eaten+=1;signal+=1;biteRevision+=1;SoundService.shared.play(.munch)}
    private func reset() {
        pouringIngredient=nil;biteRevision=0;recipe=PizzaRecipe();step=0;herbs=false;topping = .cheese;spice=0;history=[];before=nil;inserted=false;baked=0;served=false;eaten=0;signal=0
    }
}

private struct PizzaWorkSurface:View {
    @Binding var recipe:PizzaRecipe
    let step:Int
    let spice:Int
    let topping:PizzaToppingKind
    let herbs:Bool
    let landingID:UUID?
    let targeted:Bool
    let onBegin:()->Void
    let onEnd:()->Void
    @State private var last:CGPoint?
    @State private var strokeID:UUID?
    @State private var turn=0.0
    @State private var sprinkleTravel=0.0
    var body:some View {
        GeometryReader {proxy in
            let width=max(1,min(proxy.size.width,proxy.size.height*300/320))
            let size=CGSize(width:width,height:width*320/300)
            Group {
                if step == 0 && !recipe.readyToShape {PizzaMixingBowl(recipe:recipe,turn:turn)}
                else {PizzaIllustration(recipe:recipe,landingID:landingID)}
            }.frame(width:size.width,height:size.height).contentShape(Rectangle())
                .background(GeometryReader {frame in
                    Color.clear.preference(key:PizzaSurfaceFrameKey.self,value:frame.frame(in:.named("pizzaWorkshop")))
                })
                .overlay {
                    if targeted {
                        Ellipse().stroke(.white.opacity(0.9),style:StrokeStyle(lineWidth:3,dash:[7,4]))
                            .frame(width:size.width*0.77,height:size.height*(step == 0 && !recipe.readyToShape ? 0.26 : 0.72))
                            .shadow(color:Color.yellow.opacity(0.8),radius:7)
                            .position(x:size.width*0.5,y:size.height*0.48).allowsHitTesting(false)
                    }
                }
                .gesture(DragGesture(minimumDistance:0).onChanged {drag($0,size:size)}.onEnded {_ in
                    last=nil;strokeID=nil;sprinkleTravel=0;onEnd()
                })
                .position(x:proxy.size.width/2,y:proxy.size.height/2)
        }.onChange(of:step) {_ in last=nil;strokeID=nil}
    }
    private func drag(_ value:DragGesture.Value,size:CGSize) {
        if last == nil {onBegin()}
        let p=PizzaPoint(x:Double(value.location.x/size.width),y:Double(value.location.y/size.height))
        let distance=last.map {hypot(value.location.x-$0.x,value.location.y-$0.y)/size.width} ?? 0.015
        defer {last=value.location}
        if step == 0 {
            guard recipe.ingredients.count == 3 else {return}
            turn+=Double(distance)*300
            if distance>0.005 {SoundService.shared.play(.mix)}
            if !recipe.readyToShape {recipe.mixed=min(1,recipe.mixed+Double(distance)*0.9)}
            else if p.onDough {recipe.formed=min(1,recipe.formed+Double(distance)*0.6)}
        } else if step == 1 && p.onDough {
            if strokeID == nil,recipe.sauce.count<60 {
                let stroke=PizzaSauceStroke(points:[p]);recipe.sauce.append(stroke);strokeID=stroke.id
            } else if let id=strokeID,let i=recipe.sauce.firstIndex(where:{$0.id == id}) {
                if recipe.sauce[i].points.count>=300 {
                    recipe.sauce[i].points=recipe.sauce[i].points.enumerated().filter {$0.offset.isMultiple(of:2)}.map(\.element)
                }
                if distance>0.006 {recipe.sauce[i].points.append(p)}
            }
        } else if step == 2 {
            sprinkleTravel+=Double(distance)
            if p.onDough && (last == nil || sprinkleTravel>(herbs ? 0.013 : 0.06)) {
                if herbs {recipe.sprinkle(spice,at:p)} else {recipe.place(topping,at:p)}
                sprinkleTravel=0
            }
        }
    }
}
