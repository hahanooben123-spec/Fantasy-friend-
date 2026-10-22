# FantasiVen

Et originalt, lokalt iPhone-spil til børn på 3–8 år. Swift 6, SwiftUI og iOS 15+. Ingen tredjepartspakker, login, netværkskald eller køb.

## Åbn og kør

1. Åbn **FantasiVen.xcodeproj** på en Mac med Xcode 16 eller nyere.
2. Vælg schemet **FantasiVen**, en iPhone-simulator, og tryk Run.
3. Til en fysisk iPhone: vælg dit eget Team i Signing & Capabilities. Skift bundle identifier, hvis nødvendigt.
4. Kør testene med Product → Test.

Alternativt: Åbn **FantasiVen.swiftpm** i en Swift Playgrounds-version, der understøtter Swift 6 og AppleProductTypes. Pakken og Xcode-projektet bruger samme kildefiler. Playgrounds-kompatibilitet skal verificeres på en Apple-enhed; almindelig `swift build` på Windows understøtter ikke AppleProductTypes eller SwiftUI.

## Fri placering i figurværkstedet

Arme, ben og pynt kan nu trækkes fra bakken op på figuren. Hold kort på en miniature i bakken for at starte træk. Ved arme/ben vælges venstre eller højre side efter, hvor delen slippes. Træk derefter direkte på delen for at flytte den igen. Tryk på en del eller vælg dens navneknap for at markere den. Bakken viser nu de enkelte løse dele frem for hele figuren.

Den valgte del kan flyttes med pile, drejes, ændres i størrelse, nulstilles eller fjernes (pynt). Venstre/højre arm og ben har hver sin placering; typen af arme/ben vælges fortsat for parret. Pynt som ører, horn og vinger flyttes som den viste gruppe. Et træk giver ét fortryd-trin. Placering, rotation og størrelse gemmes sammen med vennen og bruges også i galleri og leg. Ældre venner åbner med deres normale placeringer.

Figuren står stille under placering, så den ikke bevæger sig væk fra fingeren. Delene holdes inden for tegneområdet. Berøringsreaktioner og vejrtrækning bruges fortsat i menu, detaljer og legeplads.

Denne udvidelses berørings- og drop-adfærd skal afprøves på iPad i Playgrounds. Enhedens bekræftede prototypekørsel gælder versionen før udvidelsen.

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

**Koden i commit 2d73361 er bygget med Swift 6 på GitHubs macOS-runner, og alle 13 XCTest-tests er bestået på iPhone-simulator.** Den faktiske touchoplevelse og det visuelle resultat af de nye funktioner mangler fortsat manuel afprøvning på iPad/iPhone. Python-kontrollen verificerer filreferencer, projektobjekter, scheme-XML, plist-filer, ikon og tekstnøgler; den erstatter ikke kompilering eller XCTest.

```sh
python tools/check_project.py
xcodebuild -project FantasiVen.xcodeproj -scheme FantasiVen -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
# Vælg en installeret iPhone med xcodebuild -showdestinations -scheme FantasiVen
xcodebuild -project FantasiVen.xcodeproj -scheme FantasiVen -destination 'platform=iOS Simulator,name=DIN IPHONE' CODE_SIGNING_ALLOWED=NO test
```

Der er XCTest-dækning af Codable-rundtur, gem/rediger/genåbn/slet, defekt fil, mislykket skrivning og indstillinger. GitHub-workflowet bygger først og kører derefter testene på macOS, når projektet lægges i et GitHub-repository. Den bekræftede kørsel for figurværksted og ragdoll er [iOS validation #39817770698](https://github.com/hahanooben123-spec/Fantasy-friend-/actions/runs/39817770698): build og 13 tests bestået.

Gennemfør [TESTPLAN.md](TESTPLAN.md) før næste udviklingsfase. Prioritér først at få en grøn Xcode-kompilering og afprøve spilsløjfen på en lille og en stor iPhone. Dernæst visuel polering på enhed, diskrete miljøanimationer, finere lyd og flere udtryksfulde lemmer. Baggrundene er statiske i denne MVP. Muligheder vises som små figurforhåndsvisninger; øjne og mund kan senere få mere detaljerede nærbilleder. Appen er en første kildekodeversion, ikke en App Store-valideret udgivelse.

Til App Store mangler bl.a. valgt signing/team, endeligt bundle-ID, enheds-QA, VoiceOver/Dynamic Type-gennemgang, screenshots, alderskategori og udgivelsesmetadata. Privatlivsmanifestet skal gennemgås mod den endelige binærfil og den aktuelle SDK før indsendelse.

Projektet kan regenereres med `python tools/generate_project.py`. Appikonet er originalt og kan regenereres med `python tools/make_icon.py`. Generatorerne kræver kun Pythons standardbibliotek.

## Ragdoll i legepladsen

Legepladsen bruger nu SpriteKit-fysik med en krop, fire separate lemmer, pin-led, tyngdekraft og bløde kollisioner mod gulv og vægge. Træk i kroppen eller et lem for at løfte og flytte vennen; et fjederled følger fingeren. Slip for at lade den falde og dingle. Nulstillingsknappen sætter den tilbage.

Den eksisterende Canvas-renderer tegner vennen ud fra fysikkens positioner og vinkler, inklusive den gemte pynt og delplaceringer. Fysikpositioner er midlertidige og skrives aldrig til samlingen. Legeknapperne giver fortsat ansigtsreaktioner og nu også fysiske impulser. Fysikken pauses, når legepladsen forlades eller appen går i baggrunden. Ved Reducer bevægelse kan figuren flyttes direkte uden tyngdekraft eller dinglende lemmer.

Den samlede bevægelses- og berøringsoplevelse skal fortsat afprøves manuelt i Playgrounds på iPad eller Xcode Simulator. SpriteKit er et indbygget Apple-framework; der er ingen nye pakker eller tjenester.
