import Foundation

enum Words {
    static func text(_ key: String, _ language: Language) -> String {
        let pair = entries[key] ?? (key, key)
        return language == .da ? pair.0 : pair.1
    }
    static let entries: [String: (String, String)] = [
        "creativeStudio": ("Fantasi-værksted", "Imagination studio"),
        "studioHint": ("Her bestemmer din fantasi!", "Your imagination makes the rules!"),
        "paint": ("Mal selv", "Paint"),
        "paintHint": ("Mal farver og mønstre på kroppen", "Paint colors and patterns on the body"),
        "colorMagic": ("Farvemagi", "Color magic"), "surprise": ("Overrask mig", "Surprise me"),
        "done": ("Færdig", "Done"), "redo": ("Gendan", "Redo"),
        "brush": ("Pensel", "Brush"), "clearPaint": ("Vask malingen af", "Wash off paint"),
        "brushSize": ("Penselstørrelse", "Brush size"),
        "piecesHint": ("Vælg, træk og prøv dig frem", "Choose, drag and experiment"),
        "ragdollHint": ("Grib din ven, træk rundt og slip!", "Grab your friend, move and let go!"),
        "resetPlay": ("Sæt vennen på plads", "Put your friend back"),
        "workshop": ("Figurværksted", "Character workshop"),
        "dragHint": ("Træk en del fra bakken op på din ven. Flyt den med fingeren!", "Drag a part from the tray onto your friend. Move it with your finger!"),
        "leftArm": ("Venstre arm", "Left arm"), "rightArm": ("Højre arm", "Right arm"),
        "leftLeg": ("Venstre ben", "Left leg"), "rightLeg": ("Højre ben", "Right leg"),
        "moveLeft": ("Flyt til venstre", "Move left"), "moveRight": ("Flyt til højre", "Move right"),
        "moveUp": ("Flyt op", "Move up"), "moveDown": ("Flyt ned", "Move down"),
        "rotateLeft": ("Drej til venstre", "Rotate left"), "rotateRight": ("Drej til højre", "Rotate right"),
        "smaller": ("Gør mindre", "Make smaller"), "bigger": ("Gør større", "Make bigger"),
        "resetPart": ("Nulstil delen", "Reset part"), "removePart": ("Fjern pynten", "Remove accessory"),
        "eyebrow": ("EN LILLE VERDEN AF FANTASI", "A LITTLE WORLD OF IMAGINATION"),
        "tagline": ("Skab din helt egen fantasiven!", "Create your very own fantasy friend!"),
        "create": ("Skab en ven", "Create a friend"), "friends": ("Mine venner", "My friends"),
        "play": ("Leg med venner", "Play with friends"), "settings": ("Indstillinger", "Settings"),
        "body": ("Krop", "Body"), "color": ("Farve", "Color"), "accent": ("Ekstra farve", "Accent"),
        "eyes": ("Øjne", "Eyes"), "mouth": ("Mund", "Mouth"), "arms": ("Arme", "Arms"),
        "legs": ("Ben", "Legs"), "extras": ("Pynt", "Extras"), "save": ("Gem ven", "Save friend"),
        "name": ("Hvad hedder din ven?", "What's your friend's name?"),
        "suggest": ("Find på et navn", "Surprise me with a name"),
        "created": ("Du har skabt en ny fantasiven!", "You created a new fantasy friend!"),
        "updated": ("Din ven er gemt!", "Your friend is saved!"),
        "empty": ("Her skal dine venner bo", "Your friends will live here"),
        "emptyHint": ("Skab din første ven, og lad fantasien flyve.", "Create your first friend and let your imagination fly."),
        "edit": ("Rediger", "Edit"), "delete": ("Slet ven", "Delete friend"),
        "gate": ("Hjælp fra en voksen", "Ask a grown-up"),
        "gateHint": ("Skriv tallet syvogtredive for at fortsætte.", "Type the number thirty-seven to continue."),
        "confirmDelete": ("Slet denne ven permanent?", "Permanently delete this friend?"),
        "cancel": ("Annuller", "Cancel"), "continue": ("Fortsæt", "Continue"),
        "sound": ("Lyde", "Sounds"), "music": ("Rolig musik", "Calm music"),
        "language": ("Sprog", "Language"), "privacy": ("Kun på din iPhone. Ingen reklamer, køb eller internet.", "Only on your iPhone. No ads, purchases or internet."),
        "tickle": ("Kilde", "Tickle"), "feed": ("Mad", "Feed"), "jump": ("Hop", "Jump"),
        "dance": ("Dans", "Dance"), "sleep": ("Sove", "Sleep"), "hug": ("Kram", "Hug"),
        "forest": ("Magisk skov", "Magic forest"), "rainbow": ("Regnbueland", "Rainbow land"),
        "stars": ("Stjernehimmel", "Starry sky"), "clouds": ("Skyverden", "Cloud world"),
        "meadow": ("Blomstereng", "Flower meadow"), "castle": ("Eventyrslot", "Fairytale castle"),
        "back": ("Tilbage", "Back"), "undo": ("Fortryd", "Undo"), "random": ("Tilfældig ven", "Random friend"),
        "close": ("Luk", "Close"), "error": ("Kunne ikke gemme", "Couldn't save"),
        "retry": ("Prøv igen", "Try again"), "saved": ("Gemt", "Saved"),
        "discard": ("Forlad din ven?", "Leave your friend?"),
        "discardHint": ("Dine ændringer er ikke gemt endnu.", "Your changes haven't been saved yet."),
        "leave": ("Forlad", "Leave"), "tap": ("Tryk på mig!", "Tap me!"),
        "loadError": ("Samlingen kunne ikke læses. Originalfilen er bevaret. Prøv at åbne appen igen.", "The collection couldn't be read. The original file is preserved. Try reopening the app."),
        "round": ("Rund", "Round"), "oval": ("Oval", "Oval"), "pear": ("Pære", "Pear"),
        "cushion": ("Blød firkant", "Cushion"), "drop": ("Dråbe", "Drop"),
        "cloud": ("Sky", "Cloud"), "bean": ("Bønne", "Bean"), "chubby": ("Buttet", "Chubby"),
        "horns": ("Horn", "Horns"), "ears": ("Kaninører", "Bunny ears"),
        "antennae": ("Antenner", "Antennae"), "wings": ("Vinger", "Wings"),
        "tail": ("Hale", "Tail"), "hat": ("Hat", "Hat"), "bow": ("Sløjfe", "Bow"),
        "glasses": ("Briller", "Glasses"), "crown": ("Krone", "Crown"),
        "spots": ("Pletter", "Spots"), "stripes": ("Striber", "Stripes"),
        "spikes": ("Små pigge", "Little spikes"), "flower": ("Blomst", "Flower"),
        "scarf": ("Halstørklæde", "Scarf"), "freckles": ("Fregner", "Freckles")
    ]
    static let partKeys = ["body", "color", "accent", "eyes", "mouth", "arms", "legs", "extras", "paint"]
    static let bodyKeys = ["round", "oval", "pear", "cushion", "drop", "cloud", "bean", "chubby"]
    static let worldKeys = ["forest", "rainbow", "stars", "clouds", "meadow", "castle"]
    static let extraKeys = ["horns", "ears", "antennae", "wings", "tail", "hat", "bow", "glasses", "crown", "spots", "stripes", "spikes", "flower", "scarf", "freckles"]
    static let names = ["Bimse", "Pjuske", "Bobbi", "Nulle", "Fnuller", "Bobo", "Mimmi", "Zippi", "Lumi", "Pippo", "Tutti", "Momo"]
}
