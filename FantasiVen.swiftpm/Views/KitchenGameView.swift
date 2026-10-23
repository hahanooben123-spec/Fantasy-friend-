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
    @State private var autoShaped=false
    @State private var autoSauced=false
    @State private var inserted=false
    @State private var baked=0.0
    @State private var served=false
    @State private var signal=0
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
                let wide=proxy.size.width>=740
                ZStack {
                    PizzaKitchenBackdrop()
                    VStack(spacing:8) {
                        phaseRibbon
                        if wide {
                            HStack(spacing:14) {
                                stage.frame(maxWidth:.infinity,maxHeight:.infinity)
                                ScrollView(.vertical,showsIndicators:false) {controls.fixedSize(horizontal:false,vertical:true)}.frame(width:290)
                            }
                        } else {
                            stage.frame(maxWidth:.infinity,maxHeight:.infinity)
                            controls.frame(height:panelHeight)
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
                    .onAppear {animationActive=active}
                    .onChange(of:active) {value in animationActive=value;if !value {dragItem=nil;pouringIngredient=nil;touching=false}}
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
            .task(id:progressKey(active)) {await advanceAutomatically(active)}
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
                    try await Task.sleep(nanoseconds:650_000_000)
                    try Task.checkCancellation()
                    withAnimation(reduced ? nil : .spring(response:0.5,dampingFraction:0.75)) {served=true}
                } catch {return}
            }
        }.onAppear(perform:restore)
            .task(id:snapshot) {
                guard loaded else {return}
                do {try await Task.sleep(nanoseconds:650_000_000)} catch {return}
                store.savePizzaDraft(snapshot)
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
        if let draft=store.sessions.pizza,draft.isValid,draft.companion.id == friend.id {
            recipe=draft.recipe;spice=draft.spice;topping=draft.topping
            inserted=draft.inserted;baked=draft.baked;served=draft.served
            step=inserted ? 3 : draft.step == 0 ? 0 : 1
            if draft.eaten>0 {recipe.legacySlices=draft.eaten}
            if step == 1 {
                recipe.formed=max(0.35,recipe.formed)
                tool=recipe.sauce.isEmpty ? .shape : draft.herbs ? .herbs : .toppings
                shaped=recipe.formed>=0.8
                if let raw=draft.workTool,let restoredTool=PizzaWorkTool(rawValue:raw) {
                    tool=restoredTool;autoShaped=true;autoSauced=true
                }
            }
            finishedEating=served && !recipe.hasFood
        }
        loaded=true;store.visit(.pizza,friendID:friend.id)
    }
    private func progressKey(_ active:Bool)->String {
        "\(active)-\(step)-\(tool.rawValue)-\(touching)-\(interaction)-\(recipe.readyToShape)-\(shaped)-\(autoShaped)-\(autoSauced)-\(recipe.sauceCoverage>=0.35)"
    }
    private func advanceAutomatically(_ active:Bool) async {
        guard active,!touching,pouringIngredient == nil else {return}
        do {
            if step == 0 && recipe.readyToShape {
                try await Task.sleep(nanoseconds:400_000_000)
                try Task.checkCancellation()
                recipe.formed=max(0.72,recipe.formed)
                withAnimation(reduced ? nil : .easeInOut(duration:0.35)) {step=1;tool = .shape}
                SoundService.shared.play(.complete)
            } else if step == 1 && tool == .shape && shaped && !autoShaped {
                try await Task.sleep(nanoseconds:2_200_000_000)
                try Task.checkCancellation()
                autoShaped=true;tool = .sauce;SoundService.shared.play(.reaction)
            } else if step == 1 && tool == .sauce && recipe.sauceCoverage>=0.35 && !autoSauced {
                try await Task.sleep(nanoseconds:1_200_000_000)
                try Task.checkCancellation()
                autoSauced=true;tool = .toppings;SoundService.shared.play(.reaction)
            }
        } catch {return}
    }
    private var phaseRibbon:some View {
        HStack(spacing:8) {
            ForEach(0..<3) {index in
                HStack(spacing:5) {
                    Image(systemName:["drop.fill","hand.draw.fill","flame.fill"][index])
                    Text(store.t("pizzaFlow\(index)"))
                }.font(.system(size:13,weight:.heavy,design:.rounded))
                    .frame(maxWidth:.infinity,minHeight:38)
                    .background(CandySurface(color:(step == 0 ? 0 : step == 1 ? 1 : 2) == index ? WorkshopLook.yellow : WorkshopLook.cream,cornerRadius:16))
            }
        }.accessibilityElement(children:.combine)
    }
    private var panelHeight:CGFloat {
        if served {return 112}
        if step == 3 {return 105}
        if step == 0 {return 210}
        return 270
    }
    private var instruction:String {
        if step == 0 {return pouringIngredient != nil ? "pizzaPouring" : recipe.ingredients.count == 3 ? "pizzaQuickStir" : "pizzaMixHint"}
        if step == 3 {return served ? (finishedEating ? "pizzaAllNibbled" : "pizzaFingerEat") : "pizzaBaking"}
        switch tool {
        case .shape:return "pizzaFreeDough"
        case .sauce:return "pizzaSauceHint"
        case .toppings:return "pizzaEndlessToppings"
        case .herbs:return "pizzaHerbHint"
        }
    }
    @ViewBuilder private var stage:some View {
        if step<3 {
            PizzaWorkSurface(recipe:$recipe,mixing:step == 0,tool:tool,spice:spice,topping:topping,
                landingID:landingID,targeted:validDropHover,onBegin:begin,onEnd:surfaceEnded)
                .accessibilityElement(children:.ignore).accessibilityLabel(store.t(instruction))
                .accessibilityAction {assist()}
        } else if served {
            ZStack(alignment:.bottomLeading) {
                PizzaEatingSurface(recipe:recipe,onBite:bite)
                LivingFriend(friend:friend,action:.feed,signal:signal,feedingFood:nil,active:animationActive)
                    .frame(width:135,height:145).allowsHitTesting(false)
                if let fragment=mouthful {
                    PizzaMouthfulFlight(recipe:recipe,bite:fragment,revision:biteRevision,reduced:reduced)
                        .allowsHitTesting(false)
                }
                PlayCelebration(revision:finishedEating ? 1 : 0).allowsHitTesting(false)
            }
        } else {
            GeometryReader {proxy in
                let width=min(430,min(proxy.size.width,proxy.size.height*0.94))
                ZStack {
                    PizzaOvenArtwork(heat:reduced ? 0 : baked).frame(width:width,height:width*320/300)
                    PizzaHeatEffects(progress:baked,reduced:reduced).frame(width:width*0.9,height:width)
                    PizzaIllustration(recipe:recipe,baked:baked,board:false)
                        .frame(width:width*0.55,height:width*0.58).scaleEffect(x:1,y:0.48).offset(y:width*0.10)
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
            }
        }
    }
    private var controls:some View {
        VStack(spacing:9) {
            Text(store.t(instruction)).font(.system(size:14,weight:.bold,design:.rounded))
                .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            if step == 0 {
                HStack(spacing:8) {
                    ForEach(0..<3) {index in
                        Button {startPour(index)} label:{
                            VStack(spacing:3) {
                                PizzaIngredientArt(kind:index).frame(width:42,height:48)
                                Text(store.t("pizzaIngredient\(index)")).font(.system(size:12,weight:.heavy,design:.rounded))
                            }.frame(maxWidth:.infinity,minHeight:80)
                                .background(CandySurface(color:recipe.ingredients.contains(index) ? GameStyle.palette[11] : .white,cornerRadius:16))
                                .overlay(alignment:.topTrailing) {
                                    if recipe.ingredients.contains(index) {Image(systemName:"checkmark.circle.fill").foregroundColor(.green).padding(5)}
                                }
                        }.buttonStyle(SquishStyle()).disabled(recipe.ingredients.contains(index) || pouringIngredient != nil)
                            .highPriorityGesture(dragGesture(.ingredient(index)))
                    }
                }
                if recipe.ingredients.count == 3 {
                    Button(action:assist) {
                        Label(store.t("pizzaStirTogether"),systemImage:"hand.draw.fill")
                            .font(.system(size:14,weight:.heavy,design:.rounded)).frame(minHeight:44)
                    }.buttonStyle(SquishStyle())
                }
            } else if step == 1 {
                toolTabs
                if tool == .shape {shapeTray}
                else if tool == .sauce {
                    Button(action:assist) {
                        Label(store.t("pizzaSpreadHelp"),systemImage:"paintbrush.fill")
                            .font(.system(size:15,weight:.heavy,design:.rounded)).frame(maxWidth:.infinity,minHeight:56)
                            .background(CandySurface(color:.white,cornerRadius:18))
                    }.buttonStyle(SquishStyle())
                } else {decorationTray}
                HStack(spacing:10) {
                    RoundButton(icon:"arrow.uturn.backward",label:store.t("undo")) {
                        finish();if let previous=history.popLast() {recipe=previous}
                        autoShaped=true;autoSauced=true
                    }.disabled(history.isEmpty)
                    CandyButton(title:store.t("pizzaBakeNow"),icon:"flame.fill",color:.orange,action:bake)
                }
            } else if !served {
                ProgressView(value:baked).tint(.orange)
            } else {
                CandyButton(title:store.t("pizzaAgain"),icon:"arrow.clockwise",color:.orange,action:reset)
            }
        }.padding(14).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(CandySurface(color:WorkshopLook.cream,cornerRadius:26))
    }
    private var toolTabs:some View {
        HStack(spacing:5) {
            ForEach(PizzaWorkTool.allCases,id:\.rawValue) {value in
                Button {
                    finish();interaction+=1;autoShaped=true
                    if value == .toppings || value == .herbs {autoSauced=true}
                    tool=value;SoundService.shared.play(.click)
                } label:{
                    VStack(spacing:4) {
                        Image(systemName:["hand.draw.fill","paintbrush.fill","circle.grid.2x2.fill","leaf.fill"][value.rawValue]).font(.system(size:20,weight:.bold))
                        Text(store.t("pizzaTool\(value.rawValue)")).font(.system(size:11,weight:.heavy,design:.rounded))
                    }.frame(maxWidth:.infinity,minHeight:52)
                        .background(RoundedRectangle(cornerRadius:16).fill(tool == value ? WorkshopLook.yellow : .white))
                }.buttonStyle(SquishStyle()).accessibilityAddTraits(tool == value ? .isSelected : [])
            }
        }
    }
    private var shapeTray:some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:10) {
                ForEach(PizzaDoughForm.allCases,id:\.rawValue) {form in
                    Button {
                        change {$0.doughForm=form;$0.doughStretch=nil;$0.formed=1}
                        shaped=true;interaction+=1
                    } label:{
                        PizzaDoughSwatch(form:form).frame(width:55,height:55).padding(4)
                            .background(RoundedRectangle(cornerRadius:16).fill(recipe.doughForm == form ? WorkshopLook.yellow.opacity(0.5) : .white))
                    }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("pizzaForm\(form.rawValue)"))
                }
            }.padding(.vertical,3)
        }
    }
    private var decorationTray:some View {
        Group {
            if tool == .herbs {
                HStack(spacing:8) {
                    ForEach(0..<3) {index in
                        Button {spice=index;SoundService.shared.play(.click)} label:{
                            VStack(spacing:3) {
                                PizzaIngredientArt(kind:index,spice:true).frame(width:31,height:37)
                                Text(store.t("pizzaSpice\(index)")).font(.system(size:11,weight:.bold,design:.rounded))
                            }.frame(maxWidth:.infinity,minHeight:67)
                                .background(CandySurface(color:spice == index ? WorkshopLook.yellow : .white,cornerRadius:17))
                        }.buttonStyle(SquishStyle()).highPriorityGesture(dragGesture(.herb(index)))
                    }
                }
            } else {
                ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:8) {
                    ForEach(PizzaToppingKind.allCases,id:\.rawValue) {kind in
                        Button {topping=kind;SoundService.shared.play(.click)} label:{
                            VStack(spacing:2) {
                                ZStack {PizzaServingDish();PizzaToppingArt(kind:kind).padding(7)}.frame(height:39)
                                Text(store.t(kind.key)).font(.system(size:10,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.65)
                            }.frame(width:74,height:67)
                                .background(RoundedRectangle(cornerRadius:16).fill(topping == kind ? WorkshopLook.yellow : .white.opacity(0.5)))
                        }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(kind.key))
                            .simultaneousGesture(dragGesture(.topping(kind)))
                    }
                }.padding(.vertical,3)
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
                if case .topping = item,abs(value.translation.width)>abs(value.translation.height)*1.1 {return}
                finish();SoundService.shared.play(.click)
            }
            dragItem=item;dragPoint=value.location
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
            tool = .toppings;topping=kind;autoSauced=true;change {$0.place(kind,at:point)}
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
        return p.x>0.06 && p.x<0.94 && p.y>0.16 && p.y<0.79
    }
    private func startPour(_ index:Int) {
        guard step == 0,pouringIngredient == nil,!recipe.ingredients.contains(index) else {return}
        finish();pouringIngredient=index;pourRevision+=1
        SoundService.shared.play(index == 0 ? .pourFlour : index == 1 ? .pourWater : .pourOil)
    }
    private func begin() {touching=true;if before == nil {before=recipe}}
    private func finish() {
        if let old=before,old != recipe {remember(old);SoundService.shared.play(.click)}
        before=nil;touching=false
    }
    private func surfaceEnded() {
        finish();interaction+=1
        if step == 1 && tool == .shape {shaped=true}
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
        lastBiteTime=now;mouthful=piece;biteRevision+=1;signal+=1
        SoundService.shared.play(.munch)
        if !finishedEating && !recipe.hasFood {finishedEating=true;SoundService.shared.play(.complete)}
    }
    private func reset() {
        pouringIngredient=nil;dragItem=nil;mouthful=nil;recipe=PizzaRecipe();step=0;tool = .shape
        history=[];before=nil;touching=false;shaped=false;autoShaped=false;autoSauced=false
        inserted=false;baked=0;served=false;signal=0;biteRevision=0;finishedEating=false;interaction+=1
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
    let onBegin:()->Void
    let onEnd:()->Void
    @State private var released=Date.distantPast
    @State private var settling=false
    @State private var last:CGPoint?
    @State private var strokeID:UUID?
    @State private var turn=0.0
    @State private var travel=0.0
    @State private var shapingBase:PizzaRecipe?
    @State private var shapingStart:PizzaPoint?
    @State private var pinchBase:Double?
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
                        PizzaIllustration(recipe:recipe,landingID:landingID,elastic:rebound)
                    }
                }
            }.frame(width:size.width,height:size.height).contentShape(Rectangle())
                .background(GeometryReader {frame in
                    Color.clear.preference(key:PizzaSurfaceFrameKey.self,value:frame.frame(in:.named("pizzaWorkshop")))
                })
                .overlay {
                    if !mixing && tool == .shape {
                        GestureLesson(activity:(recipe.dents?.count ?? 0)+(recipe.doughStretch == nil ? 0 : 1),
                            from:UnitPoint(x:0.72,y:0.50),to:UnitPoint(x:0.85,y:0.43))
                    }
                    if targeted {
                        Canvas {c,s in
                            c.scaleBy(x:s.width/300,y:s.height/320)
                            let path=mixing ? Path(ellipseIn:CGRect(x:30,y:106,width:240,height:80)) : PizzaGeometry.outline(recipe)
                            c.stroke(path,with:.color(.white),style:StrokeStyle(lineWidth:3,dash:[7,4]))
                        }.allowsHitTesting(false)
                    }
                }
                .gesture(DragGesture(minimumDistance:0).onChanged {drag($0,size:size)}.onEnded {_ in
                    if !mixing && tool == .shape,let start=shapingStart,let last=last {
                        let end=PizzaPoint(x:Double(last.x/size.width),y:Double(last.y/size.height))
                        if hypot(start.x-end.x,start.y-end.y)<0.015 {recipe.press(at:end)}
                    }
                    if !mixing && tool == .shape && !reduced {released=Date();settling=true}
                    last=nil;strokeID=nil;travel=0;shapingBase=nil;shapingStart=nil;onEnd()
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
            }.onChange(of:tool) {_ in last=nil;strokeID=nil;shapingBase=nil;shapingStart=nil}
            .onChange(of:phase) {value in
                if value != .active {
                    settling=false
                    let held=last != nil || pinchBase != nil
                    last=nil;strokeID=nil;shapingBase=nil;shapingStart=nil;pinchBase=nil;travel=0
                    if held {onEnd()}
                }
            }
    }
    private func drag(_ value:DragGesture.Value,size:CGSize) {
        let first=last == nil
        if first {onBegin()}
        let p=PizzaPoint(x:Double(value.location.x/size.width),y:Double(value.location.y/size.height))
        let distance=last.map {hypot(value.location.x-$0.x,value.location.y-$0.y)/size.width} ?? 0
        defer {last=value.location}
        if mixing {
            guard recipe.ingredients.count == 3 else {return}
            turn+=Double(distance)*440
            if distance>0.005 {SoundService.shared.play(.mix)}
            recipe.mixed=min(1,recipe.mixed+Double(distance)*3.0)
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
    let onBite:(PizzaPoint)->Void
    @EnvironmentObject private var store:FriendStore
    @State private var last:CGPoint?
    var body:some View {
        GeometryReader {proxy in
            let width=max(1,min(proxy.size.width,proxy.size.height*300/320))
            let height=width*320/300
            PizzaIllustration(recipe:recipe,baked:1)
                .frame(width:width,height:height).contentShape(Rectangle())
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
