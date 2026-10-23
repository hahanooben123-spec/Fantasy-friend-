# FantasiVen

Et originalt, lokalt iPhone-spil til børn på 3–8 år. Swift 6, SwiftUI og iOS 15+. Ingen tredjepartspakker, login, netværkskald eller køb.

## Åbn og kør

1. Åbn **FantasiVen.xcodeproj** på en Mac med Xcode 16 eller nyere.
2. Vælg schemet **FantasiVen**, en iPhone-simulator, og tryk Run.
3. Til en fysisk iPhone: vælg dit eget Team i Signing & Capabilities. Skift bundle identifier, hvis nødvendigt.
4. Kør testene med Product → Test.

Alternativt: Åbn **FantasiVen.swiftpm** i en Swift Playgrounds-version, der understøtter Swift 6 og AppleProductTypes. Pakken og Xcode-projektet bruger samme kildefiler. Playgrounds-kompatibilitet skal verificeres på en Apple-enhed; almindelig `swift build` på Windows understøtter ikke AppleProductTypes eller SwiftUI.

## Figurværkstedet

Skaberen er ét samlet arbejdsområde. På iPad står den illustrerede delbakke ved siden af den store figur; på iPhone ligger den under. Kategorierne viser de faktiske kropsdele, og øjne og munde vises tæt på.

Tryk på en kropsform eller et ansigt for at prøve det. Tryk på arme, ben eller pynt for at tilføje en løs del, eller hold på en miniature og træk den hen til figuren. Delene kan flyttes direkte med én finger. De blå greb på en markeret del bruges til rotation og størrelse; kroppens greb ændrer bredde og højde. Kopiér, spejl, farv eller fjern den markerede del fra værktøjerne under figuren. Ansigtet kan også flyttes og ændres i størrelse. Penslen maler direkte på kroppen.

Fortryd og gendan fungerer for valg, dele og hele træk. Gemte venner beholder deres identitet og åbner i det nye værksted. Nye valgfrie datafelter til ansigt, skjulte dele og spejling bevarer kompatibilitet med ældre samlinger. Berøringsoplevelsen skal fortsat afprøves på fysisk iPad.

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

## Farverigt fantasi-værksted

Byggeren har et større, åbent arbejdsområde, en farverig materialebakke med flere dele synlige samtidig og illustrerede kategorier. På brede iPad-vinduer står figur og bakke ved siden af hinanden. På smalle vinduer ligger bakken under figuren. Øjne og munde vises i nærbillede.

Mal selv: Vælg pensel, farve og størrelse, og tegn direkte på kroppen. Malingen følger kropsformen, mens ansigtet forbliver tydeligt. Maling gemmes lokalt med figuren og vises også i galleri og leg. Vask-knappen fjerner malingen og kan fortrydes. En penselstreg er ét fortryd-trin; lange streger samples automatisk for at begrænse punktmængden.

Farvemagi skifter kun farverne og bevarer figurens dele og maling. Overrask mig skaber en ny kombination med samme navn og ID. Fortryd og gendan gør det muligt at eksperimentere. Placering, drejning og størrelse findes fortsat ved den valgte del.

## Samlet UI/UX-overhaling

Menuen er et illustreret univers med indgange til værksted, Vennebyen og Legestuen. Hovedfiguren er den senest gemte ven, når samlingen ikke er tom. Vennebyen har farvede figurhjem og en tydelig indgang til at skabe en ny nabo. Egne sidehoveder og store tilbageknapper erstatter systemets navigationsbjælker i børneområdet.

Legetøjsknapperne er originale Canvas-illustrationer. Valg af ven og miljø åbnes i egne vælgere, så hovedskærmen har mere plads til fysisk leg. Miljøer har stærkere illustrationer og diskret skybevægelse, som respekterer Reducer bevægelse og appens livscyklus. Miniaturemiljøer animeres ikke.

I værkstedet vises Mal selv tidligt. Den valgte dels præcise indstillinger samles under Tilpas med store knapper. Navngivning har trykbare navneforslag. iPad er tilføjet som understøttet enhed sammen med iPhone. Den samlede ændring valideres som én milepæl, og manuel touch-/layoutgennemgang på enhed er fortsat nødvendig.

## Creative play expansion

The world map leads to the workshop, village, playground and adventure tree.
The free studio supports tap-then-place and drag/drop, independent part colors,
extra eyes/limbs/accessories, duplication, mirroring, rotation, scale, body stretching,
optional placement assistance, starting shapes, personal voice and movement.
The village offers sibling copies and locally saved, draggable room furniture.

Eight activities: fruit catching with picnic endings, bubble growing/merging,
hide-and-seek with clues, editable ragdoll slide tracks, trampoline/cushion play,
a fantasy kitchen, a three-instrument eight-step orchestra, and a connecting-path puzzle.
Tracks, songs and rooms save with the friend. The shared physics playground supports
up to four friends and twelve toys; extra creative pieces are limited to 64 per friend
and furniture to 32 objects per room to bound rendering/physics work.

Speech, effects and music have independent controls. Synthesized original music changes
with the environment; speech uses the device's installed voices without recording or
requesting microphone access. Gesture demonstrations are brief and noninteractive.
Three flower levels change fruit speed, music tempo, physics pace and puzzle layouts.
Reduce Motion has a guided alternative to physics rides. No lives, countdowns, streaks,
currencies, unlock requirements or online services.

Native build/model tests are automated. Real iPad interaction, installed Danish voice
availability and sessions with children in the 3–4, 5–6 and 7–8 age groups still require
hands-on validation; automated tests do not establish that children enjoy the design.

## Fuldskærmsleg og direkte minispil

Legepladsen, fællesgården og alle otte minispil bruger nu hele vinduet som spilleverden. Små flydende værktøjer erstatter scrollsider og indrammede spillebokse. Ragdoll-verdenen tilpasses skærmens proportioner, og dens berøringskoordinater følger samme størrelse.

Frugtfangst har fangstserier, gyldne frugter og frivillig picnic. Bobler driver gennem verdenen og kan sprænges med et fingerstrøg. Gemmeleg viser forskellige venner. Rutsjebane og trampolin har stjerner at samle; trampolin fortsætter uden en tvungen slutning. Køkkenet understøtter træk af ingredienser til skålen og omrøring med fingeren. Musikscenen har store instrumenter, rytmeforslag, live optagelse og en særskilt nodeeditor. Stispillet giver feedback på hver korrekt del og lader vennen gå automatisk, når stien passer. Fællesgården kan få legetøj placeret med et tryk i verdenen.

Stjerner og fangstserier er midlertidige legeeffekter. Ingen indholdslåse, valuta, straf eller daglige krav er tilføjet. Pause og baggrundstilstand stopper simulering og lyd. En samlet native bygning og modeltests bruges til validering; screenshottrinnet har en fast tidsgrænse og må ikke skjule fejl i kompilering eller tests.

## Fire minispil og byggelegetøj på legepladsen

Minispilsmenuen viser nu Æbleregn, Bobler, Fantasikøkken og Venneorkester. Rutsjebane og trampolin åbnes direkte fra legepladsen. Gemmeleg og stispillet er taget ud af det almindelige spilvalg.

Køkkenets ingredienser blandes til synlige farver og seks forskellige opdagelser: bærkys, cremet mad, knas, boblemad, hoppemad og regnbuemad. Barnet kan fortsætte eksperimentet ved at tilføje nye ingredienser; skålen beholder de seneste fem. Den færdige mad kan trækkes hen til vennen eller smages med knappen. Figurens midlertidige smagsreaktioner ændrer aldrig den gemte kreation.

Æbleregn veksler mellem grupper i frugthaven, en blid brise og regnbueregn. Bobler flyver fra vennens boblepind og indeholder toner, sommerfugle, små udgaver af vennen eller farvesprøjt. Overraskelser har kort levetid og en fast grænse på otte samtidig.

Musik bruger originale lokalt syntetiserede tromme-, klokke- og stemmelyde. Både figuren og instrumentknappen kan anslå instrumentet. Stemmelyden følger vennens stemmetype. Fire forskellige rytmeforslag kan afprøves, og optagelse starter med en tom rytme. Eksisterende gemte sange og baner bevares.

## Græskargløden

Et selvstændigt, helårligt græskarværksted fra forsiden og minispilsmenuen. Vælg mellem seks former og farver, skrab kerner ud, brug seks stempler eller tegn lukkede udskæringer med fingeren. Flyt, drej, skalér, luk huller og fortryd. Syv lys, nat og lysstyrke giver en levende afsløring; et swipe puster lyset ud. Kladden og den redigerbare lanternehave gemmes separat fra vennerne. Haven viser seks flytbare lanterner per side uden en grænse på samlingens størrelse. Ingen figur kræves.

Udskrabningen fylder en illustreret skål med animerede kerner og små lyde. Tryllestaven i lanternehaven spiller to korte runder med lanternernes egne lys og toner. Legen kan stoppes med samme knap eller ved at røre en lanterne. Lysmelodien ændrer ikke de gemte lysvalg og stopper, når haven forlades eller appen går i baggrunden. Animationerne respekterer Reducer bevægelse, og lydene følger appens lydindstilling.

Græskargrafikken bruger lagdelte, skyggefulde ribber, diskret overfladetekstur og udskæringer med varme snitkanter, lyskerne og lysspild. Miljøerne har illustrerede bakker, små huse, lyskæder, havehegn, træårer og slyngplanter. Kun ildfluelaget animeres i baggrunden, ved 12 billeder per sekund i mørke; det pauses ved reduceret bevægelse og i baggrunden. Grafikrunden er ikke manuelt afprøvet på iPad.

## Fælles eventyrstil

Figurer, løse kropsdele og pynt deler nu et modelleret legetøjsmateriale med varm hovedbelysning, farvede skygger og blødere kanter. Figurerne har farvede iris og formede highlights. De eksisterende former, farveindeks og placeringer bruges fortsat.

De seks fælles miljøer har lagdelte landskaber, formgivne træer, snoede stier, detaljerede eventyrhuse, vindueslys, skyer og blomster. Figurværkstedet har træbord, farvekrukker og et stort vindue ind i samme univers. Menuer, værktøjer og spil deler mere taktile knapper; æbler, bobler og legetøjsillustrationer følger materialestilen.

Denne grafikrunde er implementeret uden en test- eller kontrolrunde efter brugerens ønske. Native kompilering og det faktiske udseende på iPad er ikke verificeret for denne ændring.

## Tre startvenner

Bimse er en blå, rund hoppeven med små horn, store poter og et åbent grin. Pjuske er en lyserød skyven med lange ører, rolige øjne og små sko. Lumi er en mintfarvet, dråbeformet svæveven med antenner og vinger. De har forskellige stemmer og gangarter og vises i en ny valgskærm, når en ny ven skabes. Startvenner-knappen åbner valget igen.

Valg af startven er ét fortryd-trin. Ved redigering bevares vennens ID, navn, miljø, værelse, sang og bane. Alle dele er fortsat frit redigerbare. Startvennerne bruger de eksisterende datafelter; gemte samlinger behøver ingen ny filversion.

Rund, sky og dråbe har gentegnede silhuetter. Poter, arme, horn, ører, antenner, vinger, hat og briller har nye illustrationer; øjne og mund har mere detaljeret belysning. Skaberen har rolig vejrtrækning og korte glade ansigtsreaktioner efter ændringer. Vejet bevægelse slås fra ved Reducer bevægelse og når appen er inaktiv.

Implementeret uden ny kompilering, tests eller visuel kontrol efter brugerens ønske.

## Værelsesværkstedet

Værelset fylder arbejdsområdet; på iPad står møbelbakken ved siden af, og på iPhone ligger den under. Indretning og leg har hver sin tilstand. Der er 18 originale møbler og dekorationer fordelt på tre kategorier. Tryk for at tilføje eller træk en miniature ind i rummet. Flyt med én finger; knapper ændrer størrelse, drejning, spejling, farve og lag. Kopiering, fjernelse og 50 trin fortryd/gendan er inkluderet. Størrelse kan også ændres med to fingre.

Seks tapeter, fire gulve, dag/aften og tre startindretninger kan vælges. En startindretning erstatter først rummet efter en tydelig bekræftelse og kan fortrydes. Eksisterende indretninger indlæses; kun en ven uden et tidligere rum får den første startindretning automatisk. Der er plads til 32 ting med en synlig besked ved grænsen.

Leg: seng → søvn, sofa/pude → kram, mad/bord → spisning, musikspiller → dans og toner, bold/skammel → hop, plante → kilden, bogreol → kort oplæst historie. Lamper og legetøjskister kan åbnes/tændes og lukkes/slukkes. Lamper giver varmt lys i aftenrummet. Korte møbelreaktioner følger Reducer bevægelse. Tale stoppes, når værelset forlades.

Alle møbler, farver, størrelser, vinkler, spejling, lag, lysvalg, tapet, gulv og vennens placering gemmes lokalt med vennen. Flytninger gemmes ved afsluttet træk; mislykket filskrivning ændrer ikke den gemte indretning. Nye egenskaber er valgfrie Codable-felter, så ældre venner stadig kan læses.

Denne udvidelse er ikke kompileret, testet eller visuelt kontrolleret efter brugerens ønske.

## Pizzaværkstedet

Pizzaværkstedet erstatter Fantasikøkkenet i minispilsmenuen. Forløbet består af fire trin: tilsæt mel, vand og olie, rør og form dejen; mal tomatsovs med fingeren; drys oregano, basilikum, salt og eventuelt ost; skub pizzaen ind i stenovnen. Hvert trin har en stor berøringsflade og en hjælpeknap til børn, som foretrækker tryk. Sovs og krydderier følger præcis den samme pizza gennem bagningen.

Original Canvas-grafik viser skål, dej, træbræt, ingredienser, krydderiglas og en varm stenovn. Skorpen bliver gylden under en kort bagning. Bagningen pauses sammen med spillet og i baggrunden; pizzaen brænder aldrig på. Efter bagning kan barnet tage pizzaen ud, dele op til otte stykker med vennen og begynde på en ny. Fortryd gemmer op til 30 ændringer under tilberedningen. Pizzaen er en legesession og gemmes ikke som en del af vennens samling.

Implementeret uden kompilering, tests eller visuel kontrol efter brugerens ønske.
