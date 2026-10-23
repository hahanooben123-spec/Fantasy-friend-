import SwiftUI
import UniformTypeIdentifiers

struct KitchenGameView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend:FantasyFriend
    @State private var recipe=KitchenRecipe()
    @State private var mixed=false
    @State private var tasted=false
    @State private var turns=0.0
    @State private var signal=0
    @State private var incoming:Int?
    @State private var stirring:CGPoint?
    @State private var stirDistance=0.0
    @State private var celebration=0
    @State private var reactionTime=0.0
    @State private var reacting=false
    @State private var completedSignal=0
    private let foods=["🍓","🍌","🥕","🥦","🫐","🧀"]
    private var dish:FantasyDish {FantasyDish.make(recipe.ingredients)}
    private var dishColor:Color {Color(red:dish.red,green:dish.green,blue:dish.blue)}
    private var tastingFriend:FantasyFriend {
        var copy=friend
        guard reacting else {return copy}
        switch dish.feeling {
        case .berry:copy.eyes=10;copy.mouth=0
        case .creamy:copy.eyes=3;copy.mouth=0
        case .crunchy:copy.mouth=5
        case .fizzy:copy.mouth=3
        case .bouncy:copy.mouth=1
        case .rainbow:copy.eyes=4;copy.mouth=1
        }
        return copy
    }
    var body:some View {
        AdventureGameShell(kind:.kitchen) {active in
            GeometryReader {proxy in
                ZStack {
                    cook.frame(width:min(340,proxy.size.width*0.75),height:proxy.size.height*0.36)
                        .position(x:proxy.size.width/2,y:proxy.size.height*0.31)
                        .onDrop(of:[UTType.text.identifier],isTargeted:nil) {_ in
                            guard incoming == -1,mixed else {return false}
                            incoming=nil;taste();return true
                        }
                    Rectangle().fill(Color(red:0.88,green:0.57,blue:0.25))
                        .frame(height:proxy.size.height*0.35).position(x:proxy.size.width/2,y:proxy.size.height*0.84)
                        .allowsHitTesting(false)
                    bowl.frame(width:min(360,proxy.size.width*0.85),height:210)
                        .position(x:proxy.size.width/2,y:proxy.size.height*0.62)
                        .onDrop(of:[UTType.text.identifier],isTargeted:nil) {_ in
                            guard let ingredient=incoming,ingredient>=0 else {return false}
                            add(ingredient);incoming=nil;return true
                        }
                        .onDrag {
                            guard mixed else {return NSItemProvider()}
                            incoming = -1;return NSItemProvider(object:"fantasy-dish" as NSString)
                        }
                    PlayCelebration(revision:celebration)
                    VStack(spacing:10) {
                        Spacer()
                        Text(store.t(tasted ? dish.feeling.key : mixed ? "feedDishHint" : "recipeHint"))
                            .font(.system(.headline,design:.rounded).weight(.heavy)).multilineTextAlignment(.center)
                            .padding(12).background(Capsule().fill(.white.opacity(0.94))).padding(.horizontal,18)
                        HStack(spacing:12) {
                            RoundButton(icon:"arrow.counterclockwise",label:store.t("newRecipe"),action:clear)
                            CandyButton(title:store.t(mixed ? "taste" : "mix"),icon:mixed ? "heart.fill" : "arrow.triangle.2.circlepath") {
                                if mixed {taste()} else {mix()}
                            }.disabled(recipe.ingredients.isEmpty)
                        }.padding(.horizontal,16)
                        PlayDock(spacing:0) {
                            ForEach(0..<6) {index in
                                Button {add(index)} label:{
                                    Text(foods[index]).font(.system(size:30)).frame(maxWidth:.infinity,minHeight:52).contentShape(Rectangle())
                                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("ingredient_\(index)"))
                                    .onDrag {incoming=index;return NSItemProvider(object:"kitchen-food" as NSString)}
                            }
                        }
                    }
                }
            }
            .task(id:"\(signal)-\(active)") {
                guard active else {reacting=false;return}
                guard signal>completedSignal else {return}
                reacting=true;reactionTime=0
                SoundService.shared.react(voice:friend.voice?.rawValue ?? 0)
                do {
                    for step in 0..<36 {
                        reactionTime=Double(step)/15
                        try await Task.sleep(nanoseconds:66_666_666)
                    }
                    reacting=false;completedSignal=signal
                } catch {}
            }
        }
    }
    private var cook:some View {
        Button {if mixed {taste()} else {SoundService.shared.react(voice:friend.voice?.rawValue ?? 0)}} label:{
            ZStack {
                CharacterView(friend:tastingFriend)
                    .scaleEffect(x:reacting && dish.feeling == .fizzy ? 1.12 : 1,y:reacting && dish.feeling == .fizzy ? 0.96 : 1,anchor:.bottom)
                    .offset(y:reduced || !reacting || dish.feeling != .bouncy ? 0 : -abs(sin(reactionTime*7))*42)
                    .rotationEffect(.degrees(reduced || !reacting || dish.feeling != .rainbow ? 0 : sin(reactionTime*9)*9))
                if reacting {
                    DishReactionArt(feeling:dish.feeling,friend:friend,progress:reactionTime).offset(y:-80)
                    if dish.feeling == .crunchy {Text("✦").font(.system(size:36,weight:.heavy)).foregroundColor(dishColor).offset(y:30)}
                }
            }.contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(friend.name)
            .accessibilityHint(store.t("feedDishHint"))
    }
    private var bowl:some View {
        ZStack {
            Ellipse().fill(GameStyle.ink.opacity(0.14)).frame(width:280,height:40).offset(y:68)
            RoundedRectangle(cornerRadius:65).fill(StudioStyle.colors[5]).frame(width:270,height:120).offset(y:25)
            Ellipse().fill(dishColor).frame(width:270,height:65).overlay(Ellipse().stroke(GameStyle.ink,lineWidth:3))
            if mixed {
                ForEach(0..<9) {i in
                    Text(dish.feeling == .rainbow ? ["✦","•","♥"][i%3] : foods[dish.topping])
                        .font(.system(size:dish.feeling == .rainbow ? 16 : 20,weight:.heavy))
                        .foregroundColor(GameStyle.palette[(i*2+friend.accent)%16])
                        .offset(x:CGFloat((i*43)%180-90),y:CGFloat((i*17)%34-17))
                }
            } else {
                HStack(spacing:-4) {
                    ForEach(Array(recipe.ingredients.enumerated()),id:\.offset) {_,ingredient in Text(foods[ingredient]).font(.system(size:39))}
                }.rotationEffect(.degrees(reduced ? 0 : turns))
            }
            Text("🥄").font(.system(size:65)).rotationEffect(.degrees(reduced ? -20 : turns*0.1-20)).offset(x:70,y:-30)
        }.contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance:3).onChanged {value in
                guard !recipe.ingredients.isEmpty else {return}
                if let before=stirring {
                    let distance=hypot(value.location.x-before.x,value.location.y-before.y)
                    stirDistance+=distance
                    if !reduced {turns+=distance*0.8}
                    if stirDistance>240 && !mixed {mix()}
                }
                stirring=value.location
            }.onEnded {_ in stirring=nil})
            .accessibilityLabel(store.t("mix")).accessibilityAction {mix()}
    }
    private func add(_ ingredient:Int) {
        recipe.add(ingredient);mixed=false;tasted=false;reacting=false;stirDistance=0
        SoundService.shared.play(.click)
    }
    private func taste() {guard mixed else {return};tasted=true;signal+=1;celebration+=1}
    private func mix() {
        guard !recipe.ingredients.isEmpty else {return}
        mixed=true;tasted=false
        withAnimation(reduced ? nil : .easeInOut(duration:0.6)) {turns+=360}
        SoundService.shared.play(.reaction)
    }
    private func clear() {recipe.clear();mixed=false;tasted=false;reacting=false;turns=0;stirDistance=0}
}
