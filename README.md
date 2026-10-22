# FantasiVen

Et originalt, lokalt iPhone-spil til børn på 3–8 år. Swift 6, SwiftUI og iOS 15+. Ingen tredjepartspakker, login, netværkskald eller køb.

## Åbn og kør

1. Åbn **FantasiVen.xcodeproj** på en Mac med Xcode 16 eller nyere.
2. Vælg schemet **FantasiVen**, en iPhone-simulator, og tryk Run.
3. Til en fysisk iPhone: vælg dit eget Team i Signing & Capabilities. Skift bundle identifier, hvis nødvendigt.
4. Kør testene med Product → Test.

Alternativt: Åbn **FantasiVen.swiftpm** i en Swift Playgrounds-version, der understøtter Swift 6 og AppleProductTypes. Pakken og Xcode-projektet bruger samme kildefiler. Playgrounds-kompatibilitet skal verificeres på en Apple-enhed; almindelig `swift build` på Windows understøtter ikke AppleProductTypes eller SwiftUI.

## Første version

- Illustreret hovedmenu med en ven, der reagerer på berøring.
- Canvas-renderer med 8 kroppe, 16 krops- og sekundærfarver, 12 øjne, 10 munde, 8 arm- og benvariationer samt 15 tilbehørstyper, som kan kombineres.
- Visuelle valg, vandret swipe, fortryd op til 60 ændringer og tilfældig figur.
- Navngivning, navneforslag og velkomst til den nye ven.
- Lokalt galleri, detaljevisning, redigering og sletning bag voksenspørgsmål + særskilt bekræftelse.
- Legeplads med kilden, mad, hop, dans, søvn og kram. Ingen behov, point eller pres for at vende tilbage.
- Seks illustrerede miljøer. Valg gemmes per ven.
- Blinken, vejrtrækning, berøringsreaktioner og glædespartikler. Reduceret bevægelse respekteres for bevægelsesanimationer.
- Originale syntetiserede lydtoner og valgfri rolig tonemelodi. Lyd respekterer lydløs tilstand; musik og effekter pauses i baggrunden.
- Dansk/engelsk og kontrolleret lyst farvetema.

## Arkitektur

| Mappe | Ansvar |
| --- | --- |
| App | App-livscyklus og delt tilstand |
| Models | Codable-figur, validering og indstillinger uden UI-afhængighed |
| CharacterRenderer | Organiske Paths, tilhæftningspunkter og lagdelt Canvas-tegning |
| Components | Spilknapper, farvepalette og illustrerede miljøer |
| Animations | Afbrydelige reaktioner, blinken og vejrtrækning |
| Views | Menu, bygger, navngivning, galleri, detaljer, leg og indstillinger |
| Services | FileManager-lagring og AVAudioPlayer |
| Localization | Danske og engelske tekster |
| Resources | Appikon og privatlivsmanifest |

Figurdata indeholder kun stabile ID'er og indeks. Rendereren udleder tegningen af dataene. Tilbehør gemmes som et sæt, så valg kan kombineres. Lagringen er versionsmærket og atomisk i Application Support/FantasiVen. Ændringer offentliggøres først i hukommelsen, når filskrivningen lykkes. En korrupt eller ukendt samling bevares, og overskrivning blokeres med en synlig fejl. Ingen automatisk nulstilling, kvote eller beskæring af samlingen.

Tilføj eventuelt egne `click.wav`, `reaction.wav`, `complete.wav` og `music.wav` i Resources. Registrér nye ressourcer i projektgeneratoren for Xcode, og kør generatoren igen. SoundService benytter Bundle.main og falder tilbage til genererede toner, hvis filerne mangler eller ikke kan afspilles.

## Verifikation og næste fase

**Dette projekt er udviklet på Windows uden Swift/Xcode. Det er ikke kompileret eller visuelt afprøvet i en iOS-simulator endnu.** Python-kontrollen verificerer filreferencer, projektobjekter, scheme-XML, plist-filer, ikon og tekstnøgler; den erstatter ikke kompilering eller XCTest.

```sh
python tools/check_project.py
xcodebuild -project FantasiVen.xcodeproj -scheme FantasiVen -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
# Vælg en installeret iPhone med xcodebuild -showdestinations -scheme FantasiVen
xcodebuild -project FantasiVen.xcodeproj -scheme FantasiVen -destination 'platform=iOS Simulator,name=DIN IPHONE' CODE_SIGNING_ALLOWED=NO test
```

Der er XCTest-dækning af Codable-rundtur, gem/rediger/genåbn/slet, defekt fil, mislykket skrivning og indstillinger. GitHub-workflowet bygger først og kører derefter testene på macOS, når projektet lægges i et GitHub-repository. Det er ikke kørt fra denne mappe.

Gennemfør [TESTPLAN.md](TESTPLAN.md) før næste udviklingsfase. Prioritér først at få en grøn Xcode-kompilering og afprøve spilsløjfen på en lille og en stor iPhone. Dernæst visuel polering på enhed, diskrete miljøanimationer, finere lyd og flere udtryksfulde lemmer. Baggrundene er statiske i denne MVP. Muligheder vises som små figurforhåndsvisninger; øjne og mund kan senere få mere detaljerede nærbilleder. Appen er en første kildekodeversion, ikke en App Store-valideret udgivelse.

Til App Store mangler bl.a. valgt signing/team, endeligt bundle-ID, enheds-QA, VoiceOver/Dynamic Type-gennemgang, screenshots, alderskategori og udgivelsesmetadata. Privatlivsmanifestet skal gennemgås mod den endelige binærfil og den aktuelle SDK før indsendelse.

Projektet kan regenereres med `python tools/generate_project.py`. Appikonet er originalt og kan regenereres med `python tools/make_icon.py`. Generatorerne kræver kun Pythons standardbibliotek.
