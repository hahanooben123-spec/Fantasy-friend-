import SwiftUI

struct KitchenGameView: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend: FantasyFriend
    @State private var recipe = KitchenRecipe()
    @State private var mixed = false
    @State private var tasted = false
    @State private var turns = 0.0
    @State private var signal = 0
    private let foods = ["🍓", "🍌", "🥕", "🥦", "🫐", "🧀"]
    var body: some View {
        AdventureGameShell(kind: .kitchen) { _ in
            VStack(spacing: 20) {
                LivingFriend(friend: friend, action: recipe.flavor == 1 ? .tickle : .feed, signal: signal)
                    .frame(height: 210)
                ZStack {
                    Ellipse().fill(GameStyle.ink.opacity(0.12)).frame(width: 240, height: 35).offset(y: 56)
                    RoundedRectangle(cornerRadius: 65).fill(StudioStyle.colors[5]).frame(width: 230, height: 100).offset(y: 20)
                    Ellipse().fill(StudioStyle.colors[0]).frame(width: 230, height: 55)
                        .overlay(Ellipse().stroke(GameStyle.ink, lineWidth: 3))
                    HStack(spacing: -2) {
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            Text(foods[ingredient]).font(.system(size: mixed ? 26 : 35))
                        }
                    }.rotationEffect(.degrees(reduced ? 0 : turns))
                }.frame(height: 145)
                if tasted {
                    Text(store.t("flavor_\(recipe.flavor)")).font(.system(.title2, design: .rounded).weight(.heavy)).multilineTextAlignment(.center)
                } else { Text(store.t("recipeHint")).font(.system(.subheadline, design: .rounded).weight(.bold)) }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84))], spacing: 12) {
                    ForEach(0..<6) { index in
                        Button {
                            recipe.add(index); mixed = false; tasted = false
                            SoundService.shared.play(.click)
                        } label: {
                            VStack {
                                Text(foods[index]).font(.system(size: 43))
                                Text(store.t("ingredient_\(index)")).font(.system(.caption, design: .rounded).weight(.bold))
                            }.frame(maxWidth: .infinity, minHeight: 95).background(CandySurface(color: .white, cornerRadius: 25)).contentShape(Rectangle())
                        }.buttonStyle(SquishStyle()).disabled(recipe.ingredients.count == 5)
                    }
                }
                HStack {
                    CandyButton(title: store.t("mix"), icon: "arrow.triangle.2.circlepath") {
                        mixed = true; tasted = false
                        withAnimation(reduced ? nil : .easeInOut(duration: 0.6)) { turns += 360 }
                        SoundService.shared.play(.reaction)
                    }.disabled(recipe.ingredients.isEmpty)
                    CandyButton(title: store.t("taste"), icon: "heart.fill", color: GameStyle.purple) {
                        tasted = true; signal += 1
                    }.disabled(!mixed)
                }
                CandyButton(title: store.t("newRecipe"), icon: "plus", color: Color(red: 0.1, green: 0.49, blue: 0.37)) {
                    recipe.clear(); mixed = false; tasted = false; turns = 0
                }
            }
        }
    }
}
