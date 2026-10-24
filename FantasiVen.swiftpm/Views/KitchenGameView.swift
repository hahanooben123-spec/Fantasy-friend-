import SwiftUI

struct KitchenGameView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    let friend:FantasyFriend
    @State private var loaded=false
    @State private var animationActive=true
    @State private var recipe=PizzaRecipe()
    @State private var step=0
    @State private var tool=PizzaWorkTool.shape
    @State private var spice=0
    @State private var topping=PizzaToppingKind.cheese
    @State private var history:[PizzaRecipe]=[]
    @State private var before:PizzaRecipe?
    @State private var touching=false
    @State private var interaction=0
    @State private var shaped=false
    @State private var inserted=false
    @State private var baked=0.0
    @State private var servingReveal=false
    @State private var revealPhase=0
    @State private var adjustingToppings=false
    @State private var served=false
    @State private var signal=0
    @State private var companionMoment=CompanionMoment.curious
    @State private var companionSignal=0
    @State private var companionFocus=CGPoint(x:0.85,y:-0.4)
    @State private var pouringIngredient:Int?
    @State private var pourRevision=0
    @State private var dragItem:PizzaDragItem?
    @State private var dragPoint=CGPoint.zero
    @State private var surfaceFrame=CGRect.zero
    @State private var landingID:UUID?
    @State private var landingPoint=CGPoint.zero
    @State private var landingRevision=0
    @State private var mouthful:PizzaBite?
    @State private var biteRevision=0
    @State private var lastBiteTime=0.0
    @State private var finishedEating=false

    var body:some View {
        AdventureGameShell(kind:.kitchen) {active in
            GeometryReader {proxy in
                let wide=WorkshopLayout.sidebar(proxy.size)
                let large=proxy.size.width>=650
                ZStack {
                    PizzaKitchenBackdrop()
                    VStack(spacing:8) {
                        phaseRibbon
                        PlayWorkspace(wide:wide,toolWidth:min(440,max(350,proxy.size.width*0.38)),toolHeight:panelHeight(large:large)) {
                            stage
                        } tools: {
                            controls(large:large,side:wide)
                        }
                    }.padding(.top,77).padding(.horizontal,4)
                    if step == 0 && recipe.ingredients.isEmpty && pouringIngredient == nil {
                        GestureLesson(activity:pourRevision,from:UnitPoint(x:wide ? 0.86 : 0.25,y:wide ? 0.50 : 0.78),
                            to:UnitPoint(x:surfaceFrame.midX/max(1,proxy.size.width),
                                         y:(surfaceFrame.minY+surfaceFrame.height*0.45)/max(1,proxy.size.height)))
                    }
                    dragOverlay
                    if let ingredient=pouringIngredient {
                        PizzaPourEffect(kind:ingredient,reduced:reduced)
                            .frame(width:surfaceFrame.width*0.85,height:surfaceFrame.height*0.55)
                            .position(x:surfaceFrame.midX,y:surfaceFrame.minY+surfaceFrame.height*0.205)
                            .id(pourRevision).allowsHitTesting(false)
                    }
                }.coordinateSpace(name:"pizzaWorkshop")
                    .onPreferenceChange(PizzaSurfaceFrameKey.self) {surfaceFrame=$0}
                    .onAppear {animationActive=active}
                    .onChange(of:active) {value in animationActive=value;if !value {dragItem=nil;pouringIngredient=nil;touching=false}}
                    .task(id:pourRevision) {
                        guard let ingredient=pouringIngredient else {return}
                        do {try await Task.sleep(nanoseconds:1_000_000_000)} catch {return}
                        guard active,step == 0,pouringIngredient == ingredient else {return}
                        change {$0.ingredients.insert(ingredient)}
                        pouringIngredient=nil
                        landingPoint=CGPoint(x:surfaceFrame.midX,y:surfaceFrame.minY+surfaceFrame.height*(127.0/320.0))
                        landingRevision+=1
                        notice(.proud);SoundService.shared.play(.reaction)
                    }
                    .task(id:landingID) {
                        guard landingID != nil else {return}
                        do {try await Task.sleep(nanoseconds:520_000_000)} catch {return}
                        landingID=nil
                    }
            }
            .task(id:active && servingReveal) {
                guard active,servingReveal else {return}
                withAnimation(.easeInOut(duration:0.4)) {revealPhase=1}
                do {
                    try await Task.sleep(nanoseconds:450_000_000)
                    try Task.checkCancellation()
                    withAnimation(.spring(response:0.65,dampingFraction:0.8)) {revealPhase=2}
                    notice(.proud);SoundService.shared.pizzaReveal()
                    try await Task.sleep(nanoseconds:850_000_000)
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration:0.25)) {served=true;servingReveal=false}
                } catch {return}
            }
            .task(id:active && inserted && !served) {
                guard active,inserted,!served else {return}
                do {
                    while baked<1 {
                        try await Task.sleep(nanoseconds:120_000_000)
                        try Task.checkCancellation()
                        baked=min(1,baked+0.035)
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
            .onChange(of:canContinue) {ready in
                if ready && animationActive && phase == .active {SoundService.shared.play(.reaction)}
            }
            .onChange(of:phase) {value in
                if value != .active && loaded {finish();store.savePizzaDraft(snapshot)}
            }
            .onDisappear {if loaded {finish();store.savePizzaDraft(snapshot)}}
    }
    private var snapshot:PizzaDraft {
        PizzaDraft(companion:friend,recipe:recipe,step:step,spice:spice,topping:topping,herbs:tool == .herbs,
                   inserted:inserted,baked:baked,served:served,eaten:0,workTool:tool.rawValue)
    }
    private func restore() {
        guard !loaded else {return}
        if let draft=store.sessions.pizza(for:friend.id),draft.isValid {
            recipe=draft.recipe;spice=draft.spice;topping=draft.topping
            inserted=draft.inserted;baked=draft.baked;served=draft.served
            step=inserted ? 3 : draft.step == 0 ? 0 : 1
            if draft.eaten>0 {recipe.legacySlices=draft.eaten}
            if step == 1 {
                recipe.formed=max(0.35,recipe.formed)
                tool=recipe.sauce.isEmpty ? .shape : draft.herbs ? .herbs : .toppings
                shaped=recipe.formed>=0.8
                if let raw=draft.workTool,let restoredTool=PizzaWorkTool(rawValue:raw) {
                    tool=restoredTool
                }
            }
            finishedEating=served && !recipe.hasFood
        }
        loaded=true;store.visit(.pizza,friendID:friend.id)
    }
    // Readiness offers a next step; it never interrupts a child's current gesture.
    private var canContinue:Bool {
        if step == 0 {return recipe.readyToShape && pouringIngredient == nil}
        if step == 3 {return baked>=1 && !served && !servingReveal}
        switch tool {
        case .shape:return shaped || recipe.formed>=0.8
        case .sauce:return recipe.sauceCoverage>=0.35
        case .toppings:return !recipe.toppings.isEmpty
        case .herbs:return true // Seasoning is optional.
        }
    }
    private var continueKey:String {
        if step == 0 {return "pizzaNextShape"}
        if step == 3 {return "pizzaNextTaste"}
        switch tool {
        case .shape:return "pizzaNextSauce"
        case .sauce:return "pizzaNextToppings"
        case .toppings:return "pizzaNextHerbs"
        case .herbs:return "pizzaBakeNow"
        }
    }
    private var continueIcon:String {
        if step == 0 {return "hand.draw.fill"}
        if step == 3 {return "fork.knife"}
        switch tool {
        case .shape:return "paintbrush.fill"
        case .sauce:return "circle.grid.2x2.fill"
        case .toppings:return "leaf.fill"
        case .herbs:return "flame.fill"
        }
    }
    private func continueCooking() {
        guard canContinue else {return}
        finish();dragItem=nil
        if step == 1 && tool == .herbs {bake();return}
        if step == 3 && !reduced {
            servingReveal=true;revealPhase=0;return
        }
        withAnimation(reduced ? nil : .spring(response:0.45,dampingFraction:0.8)) {
            if step == 0 {
                recipe.formed=max(0.72,recipe.formed);step=1;tool = .shape
            } else if step == 3 {served=true}
            else {
                switch tool {
                case .shape:tool = .sauce
                case .sauce:tool = .toppings
                case .toppings:tool = .herbs
                case .herbs:break
                }
            }
        }
        SoundService.shared.play(.reaction)
    }
    private var continueButton:some View {
        WorkshopNextButton(title:store.t(continueKey),icon:continueIcon,action:continueCooking)
            .accessibilityHint(store.t("pizzaContinueHint"))
            .transition(.asymmetric(insertion:.scale(scale:reduced ? 1 : 0.8).combined(with:.opacity),removal:.opacity))
    }
    private var phaseRibbon:some View {
        HStack(spacing:8) {
            ForEach(0..<3) {index in
                HStack(spacing:5) {
                    Image(systemName:["drop.fill","hand.draw.fill","flame.fill"][index])
                    Text(store.t("pizzaFlow\(index)"))
                }.font(.system(size:13,weight:.heavy,design:.rounded))
                    .frame(maxWidth:.infinity,minHeight:38)
                    .background(GameChoiceSurface(selected:(step == 0 ? 0 : step == 1 ? 1 : 2) == index))
            }
        }.accessibilityElement(children:.combine)
    }
    private func panelHeight(large:Bool)->CGFloat {
        if served {return 170}
        if step == 3 {return 155}
        if step == 0 {return large ? 295 : 270}
        if tool == .shape || tool == .toppings {return large ? 365 : 415}
        return large ? 325 : 305
    }
    private var instruction:String {
        if step == 0 {return pouringIngredient != nil ? "pizzaPouring" : recipe.ingredients.count == 3 ? "pizzaQuickStir" : "pizzaMixHint"}
        if step == 3 {return servingReveal ? "pizzaRevealHint" : served ? (finishedEating ? "pizzaAllNibbled" : "pizzaFingerEat") : "pizzaBaking"}
        switch tool {
        case .shape:return "pizzaFreeDough"
        case .sauce:return "pizzaSauceHint"
        case .toppings:return adjustingToppings ? "pizzaMoveToppingsHint" : "pizzaEndlessToppings"
        case .herbs:return "pizzaHerbHint"
        }
    }
    @ViewBuilder private var stage:some View {
        if step<3 {
            ZStack(alignment:.bottomLeading) {
            PizzaWorkSurface(recipe:$recipe,mixing:step == 0,tool:tool,spice:spice,topping:topping,
                landingID:landingID,targeted:validDropHover,adjusting:adjustingToppings,onBegin:begin,onEnd:surfaceEnded,
                onAttention:watchWork)
                .accessibilityElement(children:.ignore).accessibilityLabel(store.t(instruction))
                .accessibilityAction {assist()}
                kitchenCompanion.frame(width:110,height:118).allowsHitTesting(false)
            }
        } else if served {
            ZStack(alignment:.bottomLeading) {
                PizzaEatingSurface(recipe:recipe,active:animationActive,onBite:bite)
                kitchenCompanion.frame(width:135,height:145).allowsHitTesting(false)
                if let fragment=mouthful {
                    PizzaMouthfulFlight(active:animationActive,recipe:recipe,bite:fragment,revision:biteRevision,reduced:reduced)
                        .allowsHitTesting(false)
                }
                PlayCelebration(revision:finishedEating ? 1 : 0).allowsHitTesting(false)
            }
        } else {
            GeometryReader {proxy in
                let width=min(430,min(proxy.size.width,proxy.size.height*0.94))
                ZStack {
                    PizzaOvenArtwork(heat:baked,active:animationActive)
                        .frame(width:width,height:width*320/300)
                    PizzaHeatEffects(progress:baked,reduced:reduced || !animationActive)
                        .frame(width:width*0.9,height:width)
                    PizzaIllustration(recipe:recipe,baked:baked,board:false,serving:revealPhase>=2)
                        .frame(width:width*(revealPhase>=2 ? 0.88 : 0.55),height:width*(revealPhase>=2 ? 0.94 : 0.58))
                        .scaleEffect(x:1,y:revealPhase>=2 ? 0.85 : 0.48)
                        .offset(y:width*(revealPhase>=2 ? 0.26 : 0.07))
                    PizzaOvenDoor(open:revealPhase>0)
                        .frame(width:width,height:width*320/300)
                    if servingReveal {
                        PizzaRevealCloud(progress:revealPhase,active:animationActive)
                            .frame(width:width,height:width)
                        PlayCelebration(revision:revealPhase>=2 ? 1 : 0)
                    }
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
                    .overlay(alignment:.bottomLeading) {
                        kitchenCompanion.frame(width:110,height:118).allowsHitTesting(false)
                    }
            }
        }
    }
    private var kitchenCompanion:some View {
        LivingFriend(friend:friend,action:served ? .feed : .jump,signal:served ? signal : 0,
            feedingFood:nil,active:animationActive,greetOnArrival:true,
            focus:companionFocus,moment:companionMoment,momentSignal:companionSignal)
    }
    private func watchWork(_ point:PizzaPoint) {
        companionFocus=CGPoint(x:min(1,max(-1,(point.x-0.15)*2)),y:min(1,max(-1,(point.y-0.8)*2)))
    }
    private func notice(_ moment:CompanionMoment) {companionMoment=moment;companionSignal+=1}
    private func controls(large:Bool,side:Bool)->some View {
        VStack(spacing:10) {
            ScrollView(.vertical,showsIndicators:true) {
                VStack(spacing:12) {
                    Text(store.t(instruction)).font(.system(size:large ? 17 : 14,weight:.bold,design:.rounded))
                        .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                    if step == 0 {
                        HStack(spacing:10) {
                            ForEach(0..<3) {index in
                                Button {startPour(index)} label:{
                                    VStack(spacing:5) {
                                        PizzaIngredientArt(kind:index).frame(width:large ? 74 : 54,height:large ? 85 : 60)
                                        Text(store.t("pizzaIngredient\(index)"))
                                            .font(.system(size:large ? 16 : 14,weight:.heavy,design:.rounded))
                                    }.frame(maxWidth:.infinity,minHeight:large ? 128 : 100)
                                        .background(GameChoiceSurface(selected:recipe.ingredients.contains(index),tint:GameStyle.palette[11]))
                                }.buttonStyle(SquishStyle()).disabled(recipe.ingredients.contains(index) || pouringIngredient != nil)
                                    .highPriorityGesture(dragGesture(.ingredient(index)))
                            }
                        }
                    } else if step == 1 {
                        toolTabs(large:large,side:side)
                        if tool == .shape {shapeTray(large:large,side:side)}
                        else if tool == .sauce {
                            Button(action:assist) {
                                Label(store.t("pizzaSpreadHelp"),systemImage:"paintbrush.fill")
                                    .font(.system(size:large ? 18 : 15,weight:.heavy,design:.rounded))
                                    .frame(maxWidth:.infinity,minHeight:large ? 85 : 65)
                                    .background(CandySurface(color:.white,cornerRadius:22))
                            }.buttonStyle(SquishStyle())
                        } else {decorationTray(large:large,side:side)}
                    } else if !served {
                        ProgressView(value:baked).tint(.orange)
                    } else {
                        CandyButton(title:store.t("pizzaAgain"),icon:"arrow.clockwise",color:.orange,action:reset)
                    }
                }.padding(.horizontal,3).padding(.top,3).padding(.bottom,6)
            }
            // Navigation stays visible even when a smaller screen needs to scroll the choices.
            if !served {
                HStack(spacing:10) {
                    if step == 1 {
                        RoundButton(icon:"arrow.uturn.backward",label:store.t("undo")) {
                            finish();if let previous=history.popLast() {recipe=previous}
                            shaped=recipe.formed>=0.8
                        }.disabled(history.isEmpty)
                    }
                    ZStack {
                        Color.clear.frame(height:68)
                        if canContinue {continueButton}
                    }
                }.animation(reduced ? nil : .spring(response:0.45,dampingFraction:0.65),value:canContinue)
            }
        }.padding(14).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(StorybookShelf())
    }
    private func toolTabs(large:Bool,side:Bool)->some View {
        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:4),spacing:8) {
            ForEach(PizzaWorkTool.allCases,id:\.rawValue) {value in
                Button {
                    finish();interaction+=1;tool=value;SoundService.shared.play(.click)
                } label:{
                    VStack(spacing:4) {
                        Group {
                            switch value {
                            case .shape:PizzaDoughSwatch(form:PizzaDoughForm.allCases[0])
                            case .sauce:ToyGlyph(kind:.brush)
                            case .toppings:PizzaToppingArt(kind:.cheese)
                            case .herbs:PizzaIngredientArt(kind:0,spice:true)
                            }
                        }.frame(width:large ? 46 : 36,height:large ? 46 : 36)
                        Text(store.t("pizzaTool\(value.rawValue)"))
                            .font(.system(size:large ? 15 : 12,weight:.heavy,design:.rounded))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }.frame(maxWidth:.infinity,minHeight:large ? 82 : 66)
                        .background(GameChoiceSurface(selected:tool == value))
                }.buttonStyle(SquishStyle()).accessibilityAddTraits(tool == value ? .isSelected : [])
            }
        }
    }
    private func shapeTray(large:Bool,side:Bool)->some View {
        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:10),count:side ? 3 : large ? 6 : 3),spacing:10) {
            ForEach(PizzaDoughForm.allCases,id:\.rawValue) {form in
                Button {
                    change {$0.doughForm=form;$0.doughStretch=nil;$0.formed=1}
                    shaped=true;interaction+=1
                } label:{
                    VStack(spacing:2) {
                        PizzaDoughSwatch(form:form).frame(width:large ? 62 : 45,height:large ? 62 : 45)
                        Text(store.t("pizzaForm\(form.rawValue)"))
                            .font(.system(size:large ? 14 : 12,weight:.bold,design:.rounded))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }.frame(maxWidth:.infinity,minHeight:large ? 94 : 76)
                        .background(GameChoiceSurface(selected:recipe.doughForm == form))
                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("pizzaForm\(form.rawValue)"))
            }
        }
    }
    private func decorationTray(large:Bool,side:Bool)->some View {
        Group {
            if tool == .herbs {
                HStack(spacing:10) {
                    ForEach(0..<3) {index in
                        Button {spice=index;SoundService.shared.play(.click)} label:{
                            VStack(spacing:5) {
                                PizzaIngredientArt(kind:index,spice:true).frame(width:large ? 54 : 42,height:large ? 65 : 50)
                                Text(store.t("pizzaSpice\(index)"))
                                    .font(.system(size:large ? 15 : 13,weight:.bold,design:.rounded))
                            }.frame(maxWidth:.infinity,minHeight:large ? 110 : 84)
                                .background(GameChoiceSurface(selected:spice == index))
                        }.buttonStyle(SquishStyle()).highPriorityGesture(dragGesture(.herb(index)))
                    }
                }
            } else {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:side ? 3 : large ? 8 : 4),spacing:10) {
                    Button {
                        finish();adjustingToppings.toggle();SoundService.shared.play(.click)
                    } label:{
                        VStack(spacing:5) {
                            Image(systemName:"hand.draw.fill").font(.system(size:large ? 36 : 27,weight:.bold))
                                .frame(height:large ? 58 : 42)
                            Text(store.t("pizzaMoveToppings")).font(.system(size:large ? 14 : 12,weight:.heavy,design:.rounded))
                        }.frame(maxWidth:.infinity,minHeight:large ? 96 : 78)
                            .background(GameChoiceSurface(selected:adjustingToppings,tint:GameStyle.palette[11]))
                    }.buttonStyle(SquishStyle()).accessibilityAddTraits(adjustingToppings ? .isSelected : [])
                    ForEach(PizzaToppingKind.allCases,id:\.rawValue) {kind in
                        Button {topping=kind;adjustingToppings=false;SoundService.shared.play(.click)} label:{
                            VStack(spacing:4) {
                                ZStack {PizzaServingDish();PizzaToppingArt(kind:kind).padding(8)}
                                    .frame(width:large ? 64 : 46,height:large ? 58 : 42)
                                Text(store.t(kind.key)).font(.system(size:large ? 14 : 12,weight:.heavy,design:.rounded))
                                    .lineLimit(1).minimumScaleFactor(0.75)
                            }.frame(maxWidth:.infinity,minHeight:large ? 96 : 78)
                                .background(GameChoiceSurface(selected:topping == kind && !adjustingToppings))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(kind.key))
                            .highPriorityGesture(dragGesture(.topping(kind)))
                    }
                }
            }
        }
    }
    private var validDropHover:Bool {
        guard let item=dragItem,surfaceFrame.width>0,surfaceFrame.height>0,surfaceFrame.contains(dragPoint) else {return false}
        if case .ingredient = item {return step == 0 && pouringIngredient == nil && bowlContains(dragPoint)}
        return step == 1 && recipe.contains(surfacePoint(dragPoint))
    }
    private func surfacePoint(_ point:CGPoint)->PizzaPoint {
        PizzaPoint(x:Double((point.x-surfaceFrame.minX)/max(1,surfaceFrame.width)),
                   y:Double((point.y-surfaceFrame.minY)/max(1,surfaceFrame.height)))
    }
    private func dragGesture(_ item:PizzaDragItem)->some Gesture {
        DragGesture(minimumDistance:6,coordinateSpace:.named("pizzaWorkshop")).onChanged {value in
            guard pouringIngredient == nil else {return}
            if dragItem == nil {
                finish();SoundService.shared.play(.click)
            }
            dragItem=item;dragPoint=value.location
            if surfaceFrame.width>0 && surfaceFrame.height>0 {watchWork(surfacePoint(value.location))}
        }.onEnded {value in drop(item,at:value.location);dragItem=nil}
    }
    private func drop(_ item:PizzaDragItem,at location:CGPoint) {
        guard surfaceFrame.width>0,surfaceFrame.height>0,surfaceFrame.contains(location) else {return}
        let point=surfacePoint(location)
        switch item {
        case .ingredient(let index):
            guard step == 0,bowlContains(location) else {return};startPour(index)
        case .topping(let kind):
            guard step == 1,recipe.contains(point) else {return}
            tool = .toppings;topping=kind;adjustingToppings=false;change {$0.place(kind,at:point)}
            landingID=recipe.toppings.last?.id
        case .herb(let index):
            guard step == 1,recipe.contains(point) else {return}
            tool = .herbs;spice=index;change {$0.sprinkle(index,at:point)}
        }
        landingPoint=location;landingRevision+=1
    }
    @ViewBuilder private var dragOverlay:some View {
        if let item=dragItem {
            PizzaDragArtwork(item:item).frame(width:68,height:72)
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
        let p=surfacePoint(point)
        // Forgiving touch target surrounds the illustrated opening, not the bowl's foot.
        let dx=(p.x-0.5)/0.46,dy=(p.y-0.36)/0.19
        return dx*dx+dy*dy<=1
    }
    private func startPour(_ index:Int) {
        guard step == 0,pouringIngredient == nil,!recipe.ingredients.contains(index) else {return}
        finish();pouringIngredient=index;pourRevision+=1;notice(.curious)
        SoundService.shared.play(index == 0 ? .pourFlour : index == 1 ? .pourWater : .pourOil)
    }
    private func begin() {touching=true;if before == nil {before=recipe};notice(.curious)}
    private func finish() {
        if let old=before,old != recipe {remember(old);SoundService.shared.play(.click)}
        before=nil;touching=false
    }
    private func surfaceEnded() {
        finish();interaction+=1
        if step == 1 && tool == .shape {if !shaped {notice(.proud)};shaped=true}
    }
    private func remember(_ old:PizzaRecipe) {history.append(old);if history.count>30 {history.removeFirst()}}
    private func change(_ update:(inout PizzaRecipe)->Void) {
        finish();let old=recipe;update(&recipe)
        if old != recipe {remember(old);SoundService.shared.play(.click)}
    }
    private func assist() {
        change {value in
            if step == 0 && value.ingredients.count == 3 {value.mixed=1}
            else if step == 1 && tool == .shape {value.formed=1}
            else if step == 1 && tool == .sauce {value.spreadSauce()}
            else if step == 1 && tool == .toppings && adjustingToppings {
                if !value.toppings.isEmpty {value.toppings.removeLast()}
            }
            else if step == 1 {
                let count=tool == .herbs ? value.spices.count : value.toppings.count
                let a=Double(count)*2.4
                let point=PizzaPoint(x:0.5+cos(a)*0.15,y:0.48+sin(a)*0.15)
                if tool == .herbs {value.sprinkle(spice,at:point)} else {value.place(topping,at:point)}
            }
        }
        shaped=true;interaction+=1
    }
    private func bake() {
        finish();dragItem=nil;landingID=nil
        withAnimation(reduced ? nil : .easeInOut(duration:0.35)) {step=3;inserted=true}
        SoundService.shared.play(.oven)
    }
    private func bite(_ point:PizzaPoint) {
        let now=ProcessInfo.processInfo.systemUptime
        guard now-lastBiteTime>0.075,let piece=recipe.takeBite(at:point) else {return}
        watchWork(point)
        lastBiteTime=now;mouthful=piece;biteRevision+=1;signal+=1
        SoundService.shared.play(.munch)
        if !finishedEating && !recipe.hasFood {finishedEating=true;notice(.proud);SoundService.shared.play(.complete)}
    }
    private func reset() {
        pouringIngredient=nil;dragItem=nil;mouthful=nil;recipe=PizzaRecipe();step=0;tool = .shape
        history=[];before=nil;touching=false;shaped=false
        inserted=false;baked=0;served=false;servingReveal=false;revealPhase=0;adjustingToppings=false;signal=0;biteRevision=0;finishedEating=false;interaction+=1
    }
}


private struct PizzaWorkSurface:View {
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Binding var recipe:PizzaRecipe
    let mixing:Bool
    let tool:PizzaWorkTool
    let spice:Int
    let topping:PizzaToppingKind
    let landingID:UUID?
    let targeted:Bool
    let adjusting:Bool
    let onBegin:()->Void
    let onEnd:()->Void
    var onAttention:(PizzaPoint)->Void = {_ in}
    @State private var released=Date.distantPast
    @State private var settling=false
    @State private var last:CGPoint?
    @State private var strokeID:UUID?
    @State private var turn=0.0
    @State private var lastStirTime:Double?
    @State private var travel=0.0
    @State private var shapingBase:PizzaRecipe?
    @State private var shapingStart:PizzaPoint?
    @State private var pinchBase:Double?
    @State private var movingTopping:UUID?
    @State private var releasedPoint:PizzaPoint?
    var body:some View {
        GeometryReader {proxy in
            let width=max(1,min(proxy.size.width,proxy.size.height*300/320))
            let size=CGSize(width:width,height:width*320/300)
            Group {
                if mixing {PizzaMixingBowl(recipe:recipe,turn:turn)}
                else {
                    TimelineView(.animation(minimumInterval:1.0/30,paused:reduced || !settling || phase != .active)) {frame in
                        let t=max(0,frame.date.timeIntervalSince(released))
                        let rebound=settling && !reduced ? sin(t*21)*exp(-t*5) : 0
                        ZStack {
                            PizzaIllustration(recipe:recipe,landingID:landingID,elastic:rebound)
                            if let point=last.map({PizzaPoint(x:Double($0.x/size.width),y:Double($0.y/size.height))}) ?? releasedPoint,
                               tool == .shape || tool == .sauce {
                                PizzaTouchFeedback(point:point,tool:tool,pressed:last != nil,
                                    release:reduced ? 1 : min(1,t/0.7))
                            }
                        }
                    }
                }
            }.frame(width:size.width,height:size.height).contentShape(Rectangle())
                .background(GeometryReader {frame in
                    Color.clear.preference(key:PizzaSurfaceFrameKey.self,value:frame.frame(in:.named("pizzaWorkshop")))
                })
                .overlay {
                    if mixing && recipe.ingredients.count == 3 {
                        GestureLesson(activity:recipe.mixed>0 ? 1 : 0,
                            from:UnitPoint(x:0.38,y:0.46),to:UnitPoint(x:0.64,y:0.50))
                    }
                    if !mixing && tool == .sauce {
                        GestureLesson(activity:recipe.sauce.isEmpty ? 0 : 1,
                            from:UnitPoint(x:0.40,y:0.40),to:UnitPoint(x:0.65,y:0.55))
                    }
                    if !mixing && tool == .shape {
                        GestureLesson(activity:(recipe.dents?.count ?? 0)+(recipe.doughStretch == nil ? 0 : 1),
                            from:UnitPoint(x:0.72,y:0.50),to:UnitPoint(x:0.85,y:0.43))
                    }
                    if let id=movingTopping,let item=recipe.toppings.first(where:{$0.id == id}) {
                        Circle().stroke(Color.white,lineWidth:3)
                            .shadow(color:GameStyle.purple.opacity(0.5),radius:2)
                            .frame(width:size.width*0.12,height:size.width*0.12)
                            .position(x:CGFloat(item.point.x)*size.width,y:CGFloat(item.point.y)*size.height)
                            .allowsHitTesting(false)
                    }
                    if targeted {
                        Canvas {c,s in
                            c.scaleBy(x:s.width/300,y:s.height/320)
                            let path=mixing ? Path(ellipseIn:PizzaBowlLayout.opening) : PizzaGeometry.outline(recipe)
                            c.stroke(path,with:.color(.white),style:StrokeStyle(lineWidth:3,dash:[7,4]))
                        }.allowsHitTesting(false)
                    }
                }
                .gesture(DragGesture(minimumDistance:0).onChanged {drag($0,size:size)}.onEnded {_ in
                    if !mixing && tool == .shape,let start=shapingStart,let last=last {
                        let end=PizzaPoint(x:Double(last.x/size.width),y:Double(last.y/size.height))
                        if hypot(start.x-end.x,start.y-end.y)<0.015 {recipe.press(at:end)}
                    }
                    if !mixing && tool == .toppings && adjusting,let id=movingTopping,let last=last {
                        let end=PizzaPoint(x:Double(last.x/size.width),y:Double(last.y/size.height))
                        if !recipe.contains(end) {recipe.toppings.removeAll {$0.id == id};SoundService.shared.play(.bubble)}
                    }
                    if !mixing && (tool == .shape || tool == .sauce) {
                        releasedPoint=last.map {PizzaPoint(x:Double($0.x/size.width),y:Double($0.y/size.height))}
                        released=Date();settling = !reduced
                    }
                    last=nil;lastStirTime=nil;strokeID=nil;travel=0;shapingBase=nil;shapingStart=nil;movingTopping=nil;onEnd()
                })
                .simultaneousGesture(MagnificationGesture().onChanged {scale in
                    guard !mixing,tool == .shape else {return}
                    if pinchBase == nil {pinchBase=recipe.formed;onBegin()}
                    recipe.formed=min(1,max(0.35,(pinchBase ?? recipe.formed)*Double(scale)))
                }.onEnded {_ in
                    guard pinchBase != nil else {return}
                    pinchBase=nil
                    if !reduced {released=Date();settling=true}
                    onEnd()
                })
                .position(x:proxy.size.width/2,y:proxy.size.height/2)
        }.task(id:released) {
                guard settling else {return}
                do {try await Task.sleep(nanoseconds:1_100_000_000)} catch {return}
                settling=false
            }.onChange(of:tool) {_ in last=nil;strokeID=nil;shapingBase=nil;shapingStart=nil;movingTopping=nil;releasedPoint=nil;settling=false}
            .onChange(of:adjusting) {_ in last=nil;movingTopping=nil;onEnd()}
            .onChange(of:phase) {value in
                if value != .active {
                    settling=false
                    let held=last != nil || pinchBase != nil
                    last=nil;lastStirTime=nil;strokeID=nil;shapingBase=nil;shapingStart=nil;pinchBase=nil;travel=0;movingTopping=nil;releasedPoint=nil
                    if held {onEnd()}
                }
            }
    }
    private func drag(_ value:DragGesture.Value,size:CGSize) {
        let first=last == nil
        if first {onBegin()}
        let p=PizzaPoint(x:Double(value.location.x/size.width),y:Double(value.location.y/size.height))
        onAttention(p)
        let distance=last.map {hypot(value.location.x-$0.x,value.location.y-$0.y)/size.width} ?? 0
        defer {last=value.location}
        if mixing {
            guard recipe.ingredients.count == 3 else {return}
            let now=ProcessInfo.processInfo.systemUptime
            // Count moving time, not distance: fast swipes cannot finish mixing instantly.
            // Cap gaps so holding still or pausing does not count as stirring.
            let elapsed=min(0.1,max(0,now-(lastStirTime ?? now)))
            lastStirTime=now
            turn+=Double(distance)*440
            if distance>0.0005 {
                recipe.mixed=min(1,recipe.mixed+elapsed/2.5)
                SoundService.shared.play(.mix)
            }
        } else if tool == .shape {
            if shapingBase == nil {
                shapingBase=recipe
                shapingStart=PizzaPoint(x:Double(value.startLocation.x/size.width),y:Double(value.startLocation.y/size.height))
            }
            if var base=shapingBase,let start=shapingStart {
                base.deform(from:start,to:p);recipe=base
            }
        } else if tool == .sauce && recipe.contains(p) {
            if strokeID == nil {
                let stroke=PizzaSauceStroke(points:[p]);recipe.sauce.append(stroke);strokeID=stroke.id
            } else if let id=strokeID,let i=recipe.sauce.firstIndex(where:{$0.id == id}),distance>0.006 {
                if recipe.sauce[i].points.count>=300 {
                    recipe.sauce[i].points=recipe.sauce[i].points.enumerated().filter {$0.offset.isMultiple(of:2)}.map(\.element)
                }
                recipe.sauce[i].points.append(p)
            }
        } else if tool == .toppings && adjusting {
            if first {
                movingTopping=recipe.toppings.reversed().first {hypot($0.point.x-p.x,$0.point.y-p.y)<0.10}?.id
            }
            if let id=movingTopping,recipe.contains(p),let index=recipe.toppings.firstIndex(where:{$0.id == id}) {
                recipe.toppings[index].point=p
            }
        } else if tool == .toppings || tool == .herbs {
            travel+=Double(distance)
            if recipe.contains(p) && (first || travel>(tool == .herbs ? 0.016 : 0.055)) {
                if tool == .herbs {recipe.sprinkle(spice,at:p)} else {recipe.place(topping,at:p)}
                SoundService.shared.play(.click);travel=0
            }
        }
    }
}

private struct PizzaEatingSurface:View {
    let recipe:PizzaRecipe
    var active=true
    let onBite:(PizzaPoint)->Void
    @EnvironmentObject private var store:FriendStore
    @Environment(\.scenePhase) private var phase
    @State private var last:CGPoint?
    var body:some View {
        GeometryReader {proxy in
            let width=max(1,min(proxy.size.width,proxy.size.height*300/320))
            let height=width*320/300
            PizzaIllustration(recipe:recipe,baked:1,serving:true)
                .frame(width:width,height:height).contentShape(Rectangle())
                .overlay(PizzaServingSteam(active:active && phase == .active,visible:recipe.hasFood))
                .overlay(GestureLesson(activity:(recipe.bites?.count ?? 0)+(recipe.legacySlices ?? 0),
                    from:UnitPoint(x:0.55,y:0.43),to:UnitPoint(x:0.67,y:0.56)))
                .gesture(DragGesture(minimumDistance:0).onChanged {value in
                    if let previous=last,hypot(value.location.x-previous.x,value.location.y-previous.y)<width*0.055 {return}
                    onBite(PizzaPoint(x:Double(value.location.x/width),y:Double(value.location.y/height)))
                    last=value.location
                }.onEnded {_ in last=nil})
                .position(x:proxy.size.width/2,y:proxy.size.height/2)
                .accessibilityElement(children:.ignore).accessibilityLabel(store.t("pizzaFingerEat"))
                .accessibilityAction {
                    if let point=recipe.nextBitePoint {onBite(point)}
                }
        }
    }
}
