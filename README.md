# FantasiVen

Et originalt, lokalt iPhone-spil til børn på 3–8 år. Swift 6, SwiftUI og iOS 15+. Ingen tredjepartspakker, login, netværkskald eller køb.

## Tryk direkte på husene og leg uden robotoplæsning

Hvert hus på forsiden har ét samlet rektangulært trykområde omkring illustration og navn. Tegningerne er fortsat dekorative under dette trykområde. Fem korte navne står direkte i scenen med afrundet cartoon-skrift og hvid kontur. Store tekstpaneler, invitationsteksten og den ekstra maskotboks er fjernet fra forsiden. Landsbyen tilpasser huse og ven til den tilgængelige højde uden en intern rulleliste, også på liggende telefon. Dørovergangen bruger samme korte skrift.

AVSpeechSynthesizer, oplæsningsopgaver og alle oplæsningskald er fjernet fra appen. Gamle gemte taleindstillinger aktiverer derfor ikke oplæsning. Indstillingen vises ikke længere. Værkstedshjælp viser en håndbevægelse og en tekstinstruktion; minispilhjælp viser sin instruktion direkte. Afsløringen beholder sin glade lyd, og bogreolen giver en kort musikalsk reaktion. Musik, øvrige lyde og systemets tilgængelighedsmærkater bevares.

Ingen build eller tests kørt efter brugerens ønske.

## Samlet nuttet cartoon-grafik

De nitten tidligere malede illustrationer er udskiftet: landskab, fem huse, figurværksted, otte pizzaillustrationer samt seng, dyne, lampe og legetøjsskab. Et nyt græskarmiljø bruger turkis aftenhimmel, lilla tage og varme lys inspireret af brugerens reference. Forsiden på iPad har en ny nuttet maskotillustration. Alle 21 illustrationer er bundtet lokalt.

Store runde former, klare slikfarver og enkle overflader erstatter de realistiske teksturer. Figurernes native rendering har blødere skygger, lysere øjne og større pupiller. Fælles paneler, værktøjsbakker og værelsesfarver er lysere; vennen fylder mere på torvet. Døre, låger og ovnkammer er placeret efter de nye illustrationer. Gemte venner og tegninger bruger fortsat samme data, og pizzaens indhold og græskarudskæringer er stadig dynamiske.

Grafikken er lavet med det indbyggede image_gen-værktøj. Alle filplaceringer og prompts findes i [Documentation/Art/Cartoon-Art.md](Documentation/Art/Cartoon-Art.md). Ingen build, tests eller afprøvning af den kørende app er kørt i denne grafikændring efter brugerens ønske. De følgende afsnit beskriver tidligere udviklingstrin; Cartoon-Art.md beskriver det aktuelle billedsæt.

## Et levende værelse: Leg og Indret

Værelset åbner i **Leg**. **Indret** bruges til at flytte, dreje, farve og ændre størrelsen på møbler. Fortryd og gentag vises kun under indretning. Tryk i indretning vælger et møbel; i leg udløses dets handling.

Fire originale malede illustrationer giver seng, separat dyne, lampe og legetøjsskab samme varme materialer som figurværkstedet og pizzabageriet. Skabets illustrerede låger åbner med hængselanimation. Tryk på sengen lægger vennen til at sove; træk dynen op og ned med fingeren. Et nyt tryk på sengen eller kram/dans vækker vennen. Lampen kan tændes, og vinduets gardiner lukker med animation og dæmper rummet.

Åbn legetøjsskabet, og træk klodser, sæbebobler og lommelygter ud på gulvet. Klodser kan stables ved at slippe dem tæt på hinanden. Tryk på bobleflasken giver bobler og en reaktion; en flytbar lommelygte kaster lys og kan slukkes. Ryd op samler legetøjet og lukker skabene. Op til 24 løse legeting gemmes lokalt sammen med rummets indretning. Valgfrie Codable-felter bevarer gamle gemte rum. Vennens egne tegnestreger vises i billedrammen, og op til to gemte græskar står ved døren.

De fire billeder er lavet med det indbyggede image_gen-værktøj. Filplaceringer og endelige prompts: [Documentation/Art/Room-Art.md](Documentation/Art/Room-Art.md). Projektgeneratoren registrerer den nye Swift-fil. Ingen build, tests eller afprøvning på iPad er kørt.

## Åbent figurværksted, formbar krop og prøvescene

Figurværkstedet har en ny original malet studiebaggrund og mere plads omkring vennen: smallere sidebakke på iPad, lavere kategori-/deleområde på stående skærme og ingen obligatorisk starterskærm. Startere er stadig tilgængelige fra scenen. Farverige kategorier, store previews og detaljer som trædepuder, sømme og snørebånd gør delene lettere at skelne.

I kropsværktøjet kan barnet trække i kroppens øvre, midterste eller nedre del for at forme silhuetten, trække i midten for at gøre den skæv og knibe med to fingre for at ændre størrelse. En gendanknap fjerner formningen. Formning og knib indgår i samme fortryd-/gentag-historik som andre ændringer. De nye formdata er et valgfrit Codable-felt og valideres ved indlæsning. Ældre venner kan stadig åbnes. Den samme silhuet bruges i renderingen og ved valg af kropsområdet. Standardarme og -ben følger kropsformningen; frit placerede dele beholder deres egne placeringer.

**Prøv** åbner en separat fuldskærmsscene med den aktuelle, endnu ikke nødvendigvis gemte figur. Tryk på jorden for at gå, eller vælg gang, hop og dans. Tilbage vender direkte til samme værkstedsfigur. Ingen ekstra gemmehandling kræves. Bevægelse følger sceneaktivitet og Reducer bevægelse.

Nye ben prøver en gangbevægelse, arme reagerer med et kram, og andre dele får en kort krops-/tilbehørsreaktion. Greb skjules kort under reaktionen og står stille, når barnet begynder at redigere. De eksisterende frie placeringer, kopiering, spejling, farvelægning og tegning bevares. Personlighed og gentag findes under Mere.

Ved navngivning får en ven uden eksisterende værelse et indrettet hjem med farver fra figuren. Eksisterende indretninger bevares. Afsløringen viser hjemmets illustration og en direkte indgang til værelset.

Illustrationen er genereret med det indbyggede image_gen-værktøj. Filplacering og endelig prompt findes i [Documentation/Art/Creator-Art.md](Documentation/Art/Creator-Art.md). Projektgeneratoren er kørt for den nye Swift-fil. Ingen build, tests eller afprøvning af den kørende app på iPad er kørt.

## Malet pizzabageri fra blanding til servering

Pizzaspillet bruger nu otte nye originale illustrationer: køkken, melpose, vandkande, olieflaske, keramikskål, træske, stenovn og tallerken. Ingredienserne bruger samme grafik i bakke, under træk og under hældning. Vandstanden tegnes separat i kanden. Skålen har levende indhold mellem den malede bagkant og forkant, og skeen følger omrøringen.

Ovnen har en illustreret sten-/teglskal med levende ild i kammeret og den faktiske pizza som separat lag. Ved servering ligger pizzaen på en malet tallerken med bevægelig damp. Fingerbid fjerner fortsat kun mad. Dejens brødmateriale har varme skygger og porer, og sovsen har mere dybde og glans; fyld, smeltet ost, krydderier og bidder er stadig dynamiske.

Illustrationerne er lavet med det indbyggede image_gen-værktøj og bundtet lokalt i asset-kataloget. Alle filplaceringer, endelige prompts og integrationsbeskrivelse findes i [Documentation/Art/Pizza-Art.md](Documentation/Art/Pizza-Art.md). Der er ingen nye API-kald eller netværkskrav i appen.

Projektgeneratoren er kørt for den nye Swift-fil. Ingen build, tests, skærmbilleder eller afprøvning af den kørende app på iPad er kørt.

## Malede miljøer og fem unikke bygninger

Torvets tidligere gentagne husform er erstattet af fem separate originale bygningsillustrationer: malerværksted med pensel og snoet tag, ovnformet pizzabageri, musikalsk spillehus, træhus og organisk græskarværksted. De har tydeligt forskellige silhuetter, malede træ-, sten-, tegl- og stofmaterialer og samme varme lysretning.

En sjette illustration er en detaljeret eventyrlysning med skov, vand, fjerne huse og lanterner. Den bruges i landsbyen, velkomstscenerne, dørovergangene og skov-/engmiljøerne. Illustrationen tilpasses skærmen uden at strække proportionerne. Husene er separate PNG-filer med ægte transparens. Figurer, navne, navigation, skilte, gemte kreationer og belysning er fortsat separate lag. Dørene animerer med de malede pixels fra selve huset.

Grafikken er lavet med det indbyggede image_gen-værktøj og er gemt i appens asset-katalog. Filplaceringer, integration og alle endelige prompts findes i [Documentation/Art/Village-Art.md](Documentation/Art/Village-Art.md). Ingen eksterne tjenester bruges af den færdige app.

Hovedmenuens tekst står på et roligt cremefarvet panel. Stier, lys, aftenstemning og få lyspartikler binder lagene sammen. I den malede udgave bruger hjemmets lille dørmåtte den gemte værelsesfarve; selve træhuset omfarves ikke.

Projektgeneratoren er kørt for at registrere den nye Swift-fil. Ingen build, tests, skærmbilleder eller visuel afprøvning af appen på Apple-enheder er kørt.

## Eventyrtorv og sammenhæng mellem aktiviteterne

Forsiden er nu et originalt illustreret torv med fem store, trykbare bygninger: figurværksted, pizzabageri, spillehus, vennernes hjem og græskarhave. På liggende iPad ligger husene bredt omkring en fælles plads; på stående skærme følger man stier ned gennem landsbyen. Indstillinger og dag/aften er samlet i den lille topbjælke. Fortsæt åbner stadig den konkrete seneste aktivitet eller kladde.

Den valgte ledsager gemmes som et valgfrit UUID i den eksisterende lokale sessionsfil, så ældre filer stadig kan åbnes. Vennevælgeren, samlingen, nye gemte figurer og besøg i aktiviteter holder valget fælles. Spillehuset og legepladsen bruger dette valg som udgangspunkt. Genoptagelse af en bestemt pizza eller aktivitet bevarer dens egen tilknyttede ven.

Indgange bruger samme bygning på torvet og i en cirka 0,52 sekunders overgang. Dørene åbner, vennen går frem, og bygningen kommer tættere på. Et tryk springer direkte videre; Reducer bevægelse springer bevægelsen over. Der er ingen ekstra bekræftelsesknap. Aktiviteterne beholder deres fulde skærmareal.

Gemte græskar står ved haven. En serveret pizza står ved bageriet. Andre gemte venner kigger frem ved hjemmene, og en tegnet figur vises som et lille indrammet billede ved værkstedet. Ledsagerens hus bruger farven fra det gemte værelse. Samlingen har en direkte indgang til denne vens værelse. Blomsten på torvet reagerer på tryk, og barnet kan selv vælge dag eller aften.

De oprindelige musikarrangementer er samlet i samme toneart og genkendelige melodiske fraser. Værkstedet beholder landsbyens puls på 88 BPM, mens den rolige variation bruger 72 BPM. Værelset vælger rolig musik om aftenen. Musik er fortsat valgfri og lokal; eksisterende lydindstillinger bevares.

Projektgeneratoren er kørt for at registrere de nye Swift-filer. Musikfilerne er genereret lokalt fra projektets originale komposition. Ingen build, tests, lytning eller visuel afprøvning på iPad er kørt for denne ændring.

## Ledbaserede animationer og fysisk efterbevægelse

`Animations/CreatureRig.swift` definerer et fælles 2D-skelet med skuldre, hofter, ansigt og tilbehørsankre. Tidsstyrede klip omfatter gang, hop, grin, spisning, dans, kram og søvn. Gangen skifter mellem plantet fod og svingben med knæbøjning og modsatrettede arme. Hop har forberedelse, afsæt, svævefase, landing og efterbevægelse. Spisning har række-bevægelse, åben mund, bid, tygning og et tilfreds smil. Blink, øjenbryn, hovedhældning, kæbe og kinder indgår i renderingen.

Poser lægges oven på gemte placeringer ved tegning. Frie, duplikerede arme, ben og ekstra dele får også bevægelse; figurmodellen ændres ikke af animationerne. Redigeringsgreb og figurdele forbliver sammenfaldende, mens barnet placerer dele. Ører har individuelle hængselreaktioner.

Legepladsens eksisterende SpriteKit-fysik har fået en gangfunktion: tryk på en tom del af gulvet, og vennen går mod punktet. Ledmotorer hjælper den med at rette sig op. Hale, ører og antenner kan også gribes og har fysiske led, når de findes på figuren. Hopimpulsen kommer efter forberedelsen. VoiceOver har en gå-handling. Rutsjebane, trampolin og fællesleg bruger ansigtsreaktioner og tilbehørsinerti fra samme rig.

Levende venner, orkester, frugtfangst, værelser og pizza bruger systemet. Gentagne fingerbid afbryder ikke konstant tygningen. Hældning har løft, vip, rystning, retning tilbage, synkende vandniveau og ringe ved nedslaget. Dejen får en kort dæmpet elastisk efterbevægelse ved slip; bordet og opskriften deformeres ikke af denne effekt. Afsløringens gardiner har animeret stofkant og sammentrækning.

Systemet bruger SwiftUI Canvas til tegning og den eksisterende SpriteKit-scene til fysik, uden nye pakker. Tidslinjer følger sceneaktivitet, og spilfigurer følger aktiviteternes pause. Reducer bevægelse giver rolige udtryk uden bevægelsesklip. Der er ikke kørt build, tests eller afprøvning på Apple-enheder for denne ændring.

## Fælles eventyrstil fra græskarværkstedet

Appen bruger nu et fælles visuelt lag i `Components/StorybookStyle.swift`: cremefarvet emalje med gyldne kanter, varmt træ, blommefarvede konturer og skygger, sidebelysning og originale lyskæder. Græskarværkstedet og de øvrige værksteder deler selve lampetegningen. De farverige verdener beholder deres egne farver; figurernes gemte farveindekser er uændrede.

Forsiden har små belyste huse, blade i forgrunden og et træpodium under vennen. Samlingens venner står på samme type podier i deres valgte miljø. Figurværksted og værelser har fælles værktøjsbakker og formede valgknapper. Spillets overskrifter, statusmærker, pausepaneler, indstillinger og navigationskort følger samme materialesprog. Køkkenet, koncertscenen, verdenerne og afsløringen har samme varme lys og dybde, med deres egne scenefarver.

Dekorationerne tegnes med Canvas under interaktive objekter og kontroller og modtager ingen berøringer. Det fælles lyslag er statisk og introducerer ingen nye animationstimere. Knapper deler en kort fjederreaktion og respekterer Reducer bevægelse. Legeplads og minispil forbliver i fuld skærm.

Projektgeneratoren registrerer den nye Swift-fil i Xcode-projektet. Ingen build, tests eller afprøvning på iPad er kørt for denne ændring.

## Pizza: friere leg og færre knapper

Bland ingredienserne, og rør kort med fingeren: dejen kommer automatisk på bordet. Form dejen frit med træk, fingertryk og knib, eller vælg rund, hjerte, stjerne, sky, oval og firkant. Dejen, skorpen, sovsen og fyldet følger samme form. Den første vejledning skifter til sovs og derefter fyld efter en kort pause, når barnet har prøvet handlingen; alle værktøjer er stadig frit tilgængelige.

Der er ingen videre-knapper. Barnet bestemmer selv, hvornår pizzaen er klar, med **Bag pizza**. Ovnen bager og serverer automatisk. Den kompakte fyldbakke giver mere plads til pizzaen. De tidligere mængdestop for fyld og urter er fjernet fra både input, model og kladdevalidering. Ostens forbindelser bruger et lokalt gitter i stedet for at sammenligne alle ostestykker parvist.

På den færdige pizza fjerner tryk og fingertræk små bidder præcis ved fingeren med ujævne bidekanter og krummer. En mundfuld af den aktuelle pizza bevæger sig hen til vennen. De gamle otte faste skiver bruges kun til at åbne ældre kladder korrekt. De nye dejformer, stræk, fingertryk, værktøjsvalg og bidder gemmes i kladden. VoiceOver har en handling til at tage næste bid.

Ingen build, tests eller visuel kontrol er kørt for denne ændring.

## Samlet forbedring af spiloplevelsen

- En personlig **Fortsæt din leg**-indgang viser den aktuelle figur-, pizza- eller græskarkreation. Den fører også tilbage til værelset eller det seneste minispil.
- Figurværkstedet og pizzaen gemmer validerede kladder atomisk i sessions.json efter en kort pause i arbejdet, ved baggrundsskift og ved afslutning. Gemte venner ændres fortsat først ved Gem. Pizzaens opskrift, trin, ovnfremskridt og spiste stykker gendannes.
- Dele trækkes direkte fra figurens bakke uden systemets lange tryk. En miniature følger fingeren, scenen markeres, og små placeringsforslag hjælper tæt på ansigt og lemmer. Fri placering og trykvalg bevares. Kopiering/spejling er samlet under Mere, og grebene er større.
- Møbler reagerer også under indretning. Bolden kan trækkes og kastes med en kort fjederbevægelse. To korte hånddemonstrationer hjælper i værksteder og legeaktiviteter.
- Frugt, blomster, stjerner og instrumenter har originale illustrationer. Picnic lader barnet dele den fangede frugt med vennen. Bobler kan trækkes sammen og blander farve.
- Orkestret har direkte spilbare instrumenter, fem toner på xylofonen og en koncertscene. Optagede toner gemmes i melodien; rytmeeditor og melodiforslag ligger under Mere. Melodien gemmes automatisk.
- Ni originale lokale effekter giver hældning, omrøring, ovn, spisning, bobler, fangst og boldspil forskellige lyde. Ingen nye krediteringskrav.
- Pauseindstillinger vender tilbage til den tidligere pausetilstand. Playgrounds-pakken understøtter nu også landskab.
- Hovedmenuens minispil er fortsat frugtfangst, bobler, pizza og orkester. Rutsjebane/trampolin hører til legepladsen. Gemmeleg og stispil er ikke eksponeret i hovedmenuen.

Genoptagelse af frugtfangst, bobler og fysisk leg åbner aktiviteten igen; midlertidige fysikpositioner og tællere gemmes ikke. Kladder, samling, værelse, sang og græskar gemmes lokalt. Der er ingen backend.

Denne samlede ændring er ikke bygget, afprøvet visuelt eller lydmæssigt eller testet på Apple-enheder. Projektgeneratoren er kun kørt for at registrere nye Swift-kilder og ressourcer.

## Levende venner, velkomst og minispil

Forsiden er nu en lys, illustreret have med en interaktiv ven og to primære indgange: Skab en ven og Leg og spil. Samling/værelse og pizza/græskar ligger i mindre indgange. Layoutet bruger en delt opbygning på liggende iPad og en kompakt stak på stående skærme. Genoptagelse fylder mindre, og overflødig bundtekst er fjernet.

Vennen følger fingerens placering med øjnene, ser sig diskret omkring, blinker i varieret tempo og reagerer forskelligt med arme, kropsbevægelse, overraskelse, blink med ét øje og tygning. Udtrykkene ændrer ikke barnets gemte figur. Figurværkstedet reagerer på nye dele med et kort hop og blik mod det ændrede område.

Gemte venner præsenteres på en lille scene med gardiner, entré og navn. Barnet kan gå direkte til værelset eller leg. Tale og lyd følger indstillingerne; Reducer bevægelse viser præsentationen uden entréanimationen.

Minispillenes vælger viser fire billedkort. Bimse gør det muligt at prøve spillene og fri leg uden først at gemme en figur. Frugttræet kan rystes, vejret kan skiftes, og fanget frugt vises i kurven med et kort fangstglimt. Bobler kan vokse ved langt tryk eller knib; flere bobler kan blandes ind i den store boble, og en farveknap skifter paletten. Orkestrets instrumenter kan stryges med fingeren, toner får visuel feedback, og den tidligere melodi kan gendannes efter en ny optagelse.

Ingen build, tests, visuel afprøvning eller lydaflytning er udført for denne ændring.

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

Lydfiler ligger i Resources/Audio. Projektgeneratoren inkluderer WAV-filerne i Xcode, og SwiftPM behandler Resources automatisk. SoundService finder både pakkens og appens ressourcer og har syntetiske reservetoner. Kilder og reproduktion: Documentation/Audio/README.md.

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

Trin 3 er nu Pynt din pizza: en illustreret toppingbakke med ost, pepperoni, skinke, champignon, peberfrugt, oliven og ananas. Tryk placerer et stykke, og træk lægger flere stykker langs fingerens spor. Krydderier har en separat fane med oregano, basilikum og salt. Toppings er frit valgfrie, følger med gennem ovn og servering, og handlingerne kan fortrydes. Ost og øvrigt fyld får en varmere, bagt finish i ovnen. Ingen ny kompilering eller kontrolrunde kørt.

Pizzaværkstedets bakke har nu direkte træk-og-slip uden langt tryk: ingredienser og krydderiglas følger fingeren, og toppings trækkes fra syv synlige porcelænsskåle over på pizzaen. Modtageren får en lysende kant, når placeringen er gyldig. Slip udenfor ændrer ikke pizzaen. Hver gyldig placering er ét fortryd-trin. Toppings lander med en kort fjederbevægelse og et lille lysglimt; Reducer bevægelse respekteres. Trykvalg og hjælpeknappen findes fortsat.

Den visuelle opdatering giver skålene porcelænsglans, brættet kantprofil og træstruktur, pizzaen kontaktsskygge og tydeligere skorpe, og køkkenet varme lys og mere samlet belysning. Ingen kompilering, tests eller visuel kontrol kørt for denne ændring.

## Ny forside og iPad-menu

Forsiden har en samlet velkomstscene med den gemte ven, to startvenner, modelleret grøn platform og varmt lys. Fire hovedindgange ligger i et fast gitter med to kolonner: Skab en ven, Mine venner, Legeplads og Minispil. Menuillustrationerne er gentegnet med detaljerede huse, rutsjebane og spilobjekter. Pizza og Græskargløden ligger i en separat værkstedsrække, og en gemt vens værelse har en direkte indgang.

På brede iPad-landskabsvinduer står velkomstscene og menu ved siden af hinanden. På iPad i portræt og smalle vinduer ligger scenen over menuen. Menukort har fælles højde og faste afstande; adaptive kolonneantal og den tidligere særskilte store græskarbjælke er fjernet fra forsiden. Indholdet kan rulles på små skærme og i delte vinduer.

Ingen kompilering, tests eller visuel kontrol kørt efter brugerens ønske.

Værelsesbyggeren er forenklet til et børneforløb: rummet åbner uden møbelbakke og med to store valg, Tilføj ting og Rummets farver. Indret og Leg vises som to navngivne knapper. Bakken har billedkategorier og store miniaturer i et gitter; ting kan vælges med tryk eller trækkes direkte ind uden langt tryk. En Færdig-knap lukker bakken.

En markeret ting har store greb til størrelse og drejning. Hovedværktøjerne er Farve, Læg væk, Flere og Tilføj. Kopi, spejling, præcis størrelse og lag findes under Flere. Valg af farve lukker paletten igen. Fortryd er altid øverst, og Gendan vises, når der er noget at gendanne. Legetilstanden viser kun legehandlinger. Gemning og eksisterende indretninger bevares. Ingen kompilering, tests eller visuel kontrol kørt.

## Musik og legelyde

Tre originale musiktemaer og varierede Kenney CC0-effekter ligger nu i appen. Musik skifter med miljøet, toner blødt ind og dæmpes under tale. Musik og legelyde har separat lydstyrke under Indstillinger. Musik slås til med den eksisterende musikkontakt. Alt virker offline. Kilder og licenser: [Documentation/Audio](Documentation/Audio/README.md).

## Pizza: hæld, bag og smag

Melposen, vandkanden og olieflasken kan trækkes over skålen og slippes for at hælde i. Større ingrediensfelter gør dem lettere at gribe. Hældningen viser melstøv, vandstråle eller gylden olie, og skålens indhold afspejler det, der er tilsat. Et tryk giver samme hældning som alternativ til træk.

Under bagningen bliver barnets ost til smeltede felter med gyldne bobler; nærliggende ost flyder sammen. Ovnen har varm glød, små gløder og en færdig-fejring. Ved spisning flyver en skive fra den aktuelle pizza hen til vennen; jordbærikonet er fjernet i dette spil. Reduceret bevægelse respekteres. Ingen tests eller visuel kontrol kørt for denne ændring.
