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
    private let foods=["🍓","🍌","🥕","🥦","🫐","🧀"]
    var body:some View {
        AdventureGameShell(kind:.kitchen) {_ in
            GeometryReader {proxy in
                ZStack {
                    LivingFriend(friend:friend,action:recipe.flavor == 1 ? .tickle : .feed,signal:signal)
                        .frame(width:min(340,proxy.size.width*0.75),height:proxy.size.height*0.34)
                        .position(x:proxy.size.width/2,y:proxy.size.height*0.32)
                    RoundedRectangle(cornerRadius:0).fill(Color(red:0.88,green:0.57,blue:0.25))
                        .frame(height:proxy.size.height*0.35).position(x:proxy.size.width/2,y:proxy.size.height*0.84)
                        .allowsHitTesting(false)
                    bowl.frame(width:min(360,proxy.size.width*0.85),height:210)
                        .position(x:proxy.size.width/2,y:proxy.size.height*0.62)
                        .onDrop(of:[UTType.text.identifier],isTargeted:nil) {_ in
                            guard let ingredient=incoming else {return false}
                            add(ingredient);incoming=nil;return true
                        }
                    PlayCelebration(revision:celebration)
                    VStack(spacing:10) {
                        Spacer()
                        if tasted {
                            Text(store.t("flavor_\(recipe.flavor)")).font(.system(.title2,design:.rounded).weight(.heavy))
                                .padding(12).background(Capsule().fill(.white))
                        }
                        HStack(spacing:12) {
                            RoundButton(icon:"arrow.counterclockwise",label:store.t("newRecipe"),action:clear)
                            CandyButton(title:store.t(mixed ? "taste" : "mix"),icon:mixed ? "heart.fill" : "arrow.triangle.2.circlepath") {
                                if mixed {tasted=true;signal+=1;celebration+=1}
                                else {mix()}
                            }.disabled(recipe.ingredients.isEmpty)
                        }.padding(.horizontal,16)
                        PlayDock(spacing:0) {
                            ForEach(0..<6) {index in
                                Button {add(index)} label:{
                                    Text(foods[index]).font(.system(size:30))
                                        .frame(maxWidth:.infinity,minHeight:52).contentShape(Rectangle())
                                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("ingredient_\(index)"))
                                    .disabled(recipe.ingredients.count == 5)
                                    .onDrag {incoming=index;return NSItemProvider(object:"kitchen-food" as NSString)}
                            }
                        }
                    }
                }
            }
        }
    }
    private var bowl:some View {
        ZStack {
            Ellipse().fill(GameStyle.ink.opacity(0.14)).frame(width:280,height:40).offset(y:68)
            RoundedRectangle(cornerRadius:65).fill(StudioStyle.colors[5]).frame(width:270,height:120).offset(y:25)
            Ellipse().fill(mixed ? GameStyle.palette[recipe.flavor*3+1] : StudioStyle.colors[0])
                .frame(width:270,height:65).overlay(Ellipse().stroke(GameStyle.ink,lineWidth:3))
            HStack(spacing:-4) {
                ForEach(Array(recipe.ingredients.enumerated()),id:\.offset) {_,ingredient in
                    Text(foods[ingredient]).font(.system(size:mixed ? 28 : 39))
                }
            }.rotationEffect(.degrees(reduced ? 0 : turns))
            Text("🥄").font(.system(size:65)).rotationEffect(.degrees(reduced ? -20 : turns*0.1-20)).offset(x:70,y:-30)
        }.contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance:3).onChanged {value in
                guard !recipe.ingredients.isEmpty,!tasted else {return}
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
        recipe.add(ingredient);mixed=false;tasted=false;stirDistance=0
        SoundService.shared.play(.click)
    }
    private func mix() {
        guard !recipe.ingredients.isEmpty else {return}
        mixed=true;tasted=false
        withAnimation(reduced ? nil : .easeInOut(duration:0.6)) {turns+=360}
        SoundService.shared.play(.reaction)
    }
    private func clear() {recipe.clear();mixed=false;tasted=false;turns=0;stirDistance=0}
}
