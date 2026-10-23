import SwiftUI

struct KitchenGameView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend:FantasyFriend
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
                            controls.frame(height:step == 0 || (step == 3 && !inserted) ? 205 : step == 2 ? 255 : 175)
                        }
                    }.padding(.top,77).padding(.horizontal,12).padding(.bottom,12)
                }
            }
            .task(id:active && inserted && baked<1 && !served) {
                guard active,inserted,baked<1,!served else {return}
                do {
                    while baked<1 {
                        try await Task.sleep(nanoseconds:120_000_000)
                        try Task.checkCancellation()
                        baked=min(1,baked+0.025)
                    }
                    SoundService.shared.play(.complete)
                } catch {return}
            }
        }
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
            PizzaWorkSurface(recipe:$recipe,step:step,spice:spice,topping:topping,herbs:herbs,onBegin:begin,onEnd:finish)
                .accessibilityElement(children:.ignore).accessibilityLabel(store.t(instruction))
                .accessibilityAction {assist()}
        } else if served {
            GeometryReader {proxy in
                ZStack(alignment:.bottomLeading) {
                    PizzaIllustration(recipe:recipe,baked:1,eaten:eaten)
                        .frame(maxWidth:.infinity,maxHeight:.infinity).contentShape(Rectangle()).onTapGesture(perform:eat)
                    LivingFriend(friend:friend,action:.feed,signal:signal)
                        .frame(width:min(150,proxy.size.width*0.34),height:min(160,proxy.size.width*0.36))
                        .allowsHitTesting(false)
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
                    PizzaIllustration(recipe:recipe,baked:baked,board:false)
                        .frame(width:width*0.53,height:width*0.56).scaleEffect(x:1,y:0.48)
                        .offset(y:width*0.10)
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
        if step == 0 {return recipe.readyToShape ? "pizzaShapeHint" : "pizzaMixHint"}
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
                        Button {change {$0.ingredients.insert(index)}} label:{
                            HStack(spacing:3) {
                                PizzaIngredientArt(kind:index).frame(width:23,height:30)
                                Text(store.t("pizzaIngredient\(index)")).font(.system(size:12,weight:.heavy,design:.rounded)).lineLimit(1)
                                if recipe.ingredients.contains(index) {Image(systemName:"checkmark").font(.system(size:9,weight:.heavy))}
                            }.frame(maxWidth:.infinity,minHeight:44)
                                .background(CandySurface(color:recipe.ingredients.contains(index) ? GameStyle.palette[11] : .white,cornerRadius:15))
                        }.buttonStyle(SquishStyle()).disabled(recipe.ingredients.contains(index))
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
                    }.disabled(history.isEmpty)
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
                CandyButton(title:store.t("pizzaTakeOut"),icon:"checkmark",color:.orange) {served=true;SoundService.shared.play(.complete)}
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
                        }.buttonStyle(SquishStyle())
                    }
                }
            } else {
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:8) {
                        ForEach(PizzaToppingKind.allCases,id:\.rawValue) {kind in
                            Button {topping=kind;SoundService.shared.play(.click)} label:{
                                VStack(spacing:2) {
                                    PizzaToppingArt(kind:kind).frame(width:36,height:34)
                                    Text(store.t(kind.key)).font(.system(size:10,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.75)
                                }.frame(width:69,height:60)
                                    .background(CandySurface(color:topping == kind ? WorkshopLook.yellow : .white,cornerRadius:16))
                            }.buttonStyle(SquishStyle()).accessibilityLabel(store.t(kind.key))
                                .accessibilityAddTraits(topping == kind ? .isSelected : [])
                        }
                    }.padding(.bottom,5).padding(.horizontal,2)
                }.frame(height:67)
            }
        }
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
    private func eat() {guard eaten<8 else {return};eaten+=1;signal+=1}
    private func reset() {
        recipe=PizzaRecipe();step=0;herbs=false;topping = .cheese;spice=0;history=[];before=nil;inserted=false;baked=0;served=false;eaten=0;signal=0
    }
}

private struct PizzaWorkSurface:View {
    @Binding var recipe:PizzaRecipe
    let step:Int
    let spice:Int
    let topping:PizzaToppingKind
    let herbs:Bool
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
                else {PizzaIllustration(recipe:recipe)}
            }.frame(width:size.width,height:size.height).contentShape(Rectangle())
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
