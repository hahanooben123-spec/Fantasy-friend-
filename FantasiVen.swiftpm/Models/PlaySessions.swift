import Foundation

enum ActivityKind:String,Codable,Equatable {case creator,pizza,pumpkin,room,apples,bubbles,orchestra,playground}
struct ActivityBookmark:Codable,Equatable {
    var kind:ActivityKind
    var friendID:UUID?
}
struct EditorDraft:Codable,Equatable {
    var friend:FantasyFriend
    var existing:Bool
}
struct PizzaDraft:Codable,Equatable {
    var companion:FantasyFriend
    var recipe:PizzaRecipe
    var step:Int
    var spice:Int
    var topping:PizzaToppingKind
    var herbs:Bool
    var inserted:Bool
    var baked:Double
    var served:Bool
    var eaten:Int
    var workTool:Int?
    var isValid:Bool {
        companion.isValid && recipe.isValid && (0...3).contains(step) &&
        (0...2).contains(spice) && baked.isFinite && (0...1).contains(baked) &&
        (0...8).contains(eaten) && (!served || (inserted && baked>=1)) &&
        (!inserted || step == 3) && (workTool.map {(0...3).contains($0)} ?? true)
    }
}
struct PlaySessions:Codable,Equatable {
    var version=1
    var editor:EditorDraft?
    var pizza:PizzaDraft?
    var recent:ActivityBookmark?
    var companionID:UUID?
    var isValid:Bool {version == 1 && (editor?.friend.isValid ?? true) && (pizza?.isValid ?? true)}
}
