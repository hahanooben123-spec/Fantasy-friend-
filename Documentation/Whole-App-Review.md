# Samlet gennemgang af FantasiVen

Gennemgang af kildekoden pr. 24. oktober 2026, udgangspunkt: `6be6891`.
Dette er en vurdering af kode, flows og layoutregler. Appen er ikke kørt på en
iPad, og grafikkens faktiske udtryk, animationernes jævnhed og børns forståelse
kan derfor ikke bekræftes her. Ingen spilfunktioner er ændret i gennemgangen.

## Vurdering

Vi bør bruge næste udviklingsrunde på sammenhæng og færre valg frem for flere
aktiviteter. Skaberen, pizzaen, græskarværkstedet, værelserne og æblespillet har
allerede gode dele. De skal beholde deres kreative frihed, men bruge samme
visuelle sprog og samme lette måde at komme videre på.

Æblespillets gemte rekord og gradvise tempoøgning er allerede implementeret.
Værelserne tillader fri flytning, og skaberen har valg af arme/ben med tre
størrelser. Det er ikke funktioner, der mangler og skal bygges igen.

## 1. Først: beskyt barnets ufærdige arbejde

**Bekræftet i koden:** `PlaySessions` har kun én figurkladde og én pizzakladde.
`HomeView.create()` åbner altid en ny figur. `FriendStore.saveEditorDraft()`
erstatter den tidligere kladde, og builderen gemmer automatisk efter en kort
pause. En ny figur kan dermed overskrive en anden ufærdig figur.

Pizzaens `restore()` henter kun kladden, hvis vennens ID passer. Den efterfølgende
autolagring erstatter den globale pizzakladde, også når barnet blot har åbnet
køkkenet med en anden ven. Allerede færdiggemte venner bliver ikke slettet af dette.

Desuden viser forsiden kun seneste aktivitet. Et besøg i et andet spil kan skjule
adgangen til en stadig eksisterende figurkladde.

**Anbefaling:** behold kladder pr. kreation/ven. Vis den ufærdige ven direkte ved
skaberhuset med et stort billede og en separat lille mulighed for en ny ven.
Undgå tekstbaserede bekræftelsesdialoger i det almindelige legeflow.

Kilder: `Models/PlaySessions.swift`, `Services/FriendStore.swift`,
`Views/HomeView.swift`, `Views/BuilderView.swift`, `Views/KitchenGameView.swift`.

## 2. Ét fælles layout, der giver plads til legen

**Bekræftet:** skaberen skifter til sidepanel fra 650 punkter i landskab,
pizzaen fra 900 i landskab og græskar fra 740 uanset orientering. Værelsets
bundpanel har fast højde på 245 eller 315 punkter; skaberens kan optage op til
425 punkter. Samme skærm kan derfor give meget forskellige arbejdsområder.

Det er en layoutmæssig risiko, ikke dokumentation for konkret afklipning på en
bestemt iPad. Split View og lav skærmhøjde bør håndteres efter den tilgængelige
plads, ikke kun bredden.

**Anbefaling:** fælles regler for minimumsplads til figuren/maden, store synlige
valg, værktøjer langs siden i brede vinduer og en lav bakke i smalle. Behold den
store klar-knap synlig uden at dække arbejdsområdet. Detaljevalg kan åbnes i
bakken, mens selve kreationen bliver på skærmen.

## 3. Boblespillet er næste oplagte spil at forbedre

**Bekræftet:** samme boble kan trykkes, holdes, trækkes og knibes. Der er også
sammenlægning, vækst og særskilte kontroller. Boblernes størrelse kan øges
betydeligt uden tilsvarende kontrol af, om hele boblen bliver inden for skærmen.

**Anbefaling:** start med én tydelig leg: tryk for at poppe. Lad et langt tryk
puste boblen op med en tydelig visuel reaktion. Gør sammenlægning til en valgfri
opdagelse senere. Fjern behovet for knibebevægelser og sørg for, at bobler kan
rammes uden at ligge bag betjeningen. Brug korte kædereaktioner og nuttede
reaktioner frem for flere paneler.

Kilde: `Views/MiniGameSessionView.swift`, især boblernes gestus og størrelse.

## 4. Enklere navigation fra hus til aktivitet

Husene er allerede trykbare; det skal bevares. Rejsen hen til huset og gennem
døren giver sammenhæng, men skal være kort og let at springe over.

Galleriet har både en genvej til den valgte vens hjem og kort, der åbner en
mellemside med flere menuknapper. Det gør vejen til andre venners værelser længere.

**Anbefaling:** lad hver ven have en genkendelig dør til sit værelse og et tydeligt
penselikon til redigering. Brug samme tilbageknap og samme betydning af ikoner
alle steder. Vis hvilken aktivitet »fortsæt« åbner med et billede af aktiviteten.

Kilder: `Views/HomeView.swift`, `Components/VillageSquare.swift`,
`Views/GalleryView.swift`.

## 5. Saml det grafiske sprog

Koden bruger flere sideløbende stildefinitioner: `GameStyle`, `StudioStyle`,
`StorybookStyle` og `WorkshopLook`. Menuer blander illustrerede elementer,
emojier, SF Symbols og forskellige paneltyper. Det gør en ensartet stil sværere
at vedligeholde; den endelige visuelle vurdering kræver skærmbilleder fra appen.

**Anbefaling:** én fælles farvepalet, kontur, skygge, knapform og typografi.
Brug egne cartoonikoner til børnenes værktøjer. Bevar den varme, nuttede
illustrationsstil fra græskar og pizza. Prioritér overskuelige silhuetter og
kontrast over ekstra pynt. Arbejdsobjektet skal være tydeligere end baggrunden.

## 6. Skaberen: finpuds frem for endnu en total ombygning

Behold seks kategorier, store figurforhåndsvisninger og simple arm-/benstørrelser.
De resterende problemer er mange underniveauer og sider med valg samt en
»prøv«-funktion gemt under mere-menuen.

**Anbefaling:** vis de mest forskellige valg først, gør første brug uden læsning
mulig og giv hver ændring en kort lokal reaktion. Gør prøv-legen mere synlig,
uden at tilføje en ekstra permanent knaprække.

**Konkret fejl:** ved inaktiv app nulstiller `CreatorStage` en igangværende
malestreg (`draft=nil`) uden først at føje den til figuren. Gem den aktuelle
streg før oprydning, så baggrundsskift ikke mister den igangværende handling.

## 7. Pizza og græskar skal bruge samme princip for fremdrift

Pizzaen har nu en klar-knap, der tilbyder næste trin uden at stoppe legen.
Græskarværkstedet går stadig automatisk videre 400 ms efter færdig udhuling.

**Anbefaling:** brug samme store klar-knap i begge værksteder, og lad barnet
fortsætte sin handling indtil trykket. Vis næste handling med en illustration.
Behold fri mængde pizzafyld og fingerspisning. Forbedr først overblik og
placering af værktøjer frem for at tilføje flere trin.

Kilder: `Views/KitchenGameView.swift`, `Views/PumpkinWorkshopView.swift`.

## 8. Værelser: tydelig respons på valg og placering

Den frie indretning er implementeret, og automatisk placerede pizza-/græskarting
er fjernet fra værelserne. Behold denne løsning.

**Anbefaling:** tydelig glød om den valgte ting, en diskret skygge under flytning
og et lille landingshop, når barnet slipper. Gør møblernes indbyrdes størrelse,
perspektiv og kontakt med gulvet ensartet. Det sidste er et visuelt arbejde, som
skal vurderes på et faktisk skærmbillede. Undgå at genindføre rotation, lagpaneler
eller obligatoriske faste møbelpladser.

## 9. Musik og legeplads: færre kontroller i første visning

Orkestret kombinerer tre instrumenter, afspilning, optagelse, gendannelse og en
rytmeeditor. Legepladsen kombinerer ragdoll, seks handlinger, ven-/miljøvalg,
fælles legeplads og to andre legetøjsaktiviteter.

**Anbefaling:** lad barnet straks slå på instrumenter eller tage fat i vennen.
Læg optagelse/rytmeeditor og valg af ekstra legetøj bag en genkendelig legekasse.
Bevar avancerede muligheder, men gør dem sekundære.

Den globale sværhedsgrad ændrer blandt andet orkestrets tempo, mens æblespillet
nu øger tempo efter spilletid. Erstat den uklare fælles indstilling med konkrete
indstillinger dér, hvor de har betydning.

## 10. Lyd og belønning skal støtte handlingen

Systemet har allerede separate lyd-/musikniveauer, korte effekter og musikskift.
Der er ingen grund til at genindføre robotsnak.

**Anbefaling:** ét sammenhængende sæt bløde materialelyde, korte musikalske svar
og en særlig afsløringslyd. Lokal respons ved hver handling; større fejring ved
et færdigt værk. Undgå mange samtidige glædeslyde og fuldskærmseffekter under
præcise fingerhandlinger. Lydkvalitet skal bedømmes ved lytning, ikke ud fra kode.

## 11. Lagring og ydelse

**Bekræftet:** `FriendStore` skriver JSON synkront på main actor. En møbelændring
kan skrive hele vennesamlingen. Volumenslideren gemmer og konfigurerer lyden ved
hver ændring. Der er atomiske writes, men ingen lokal backup/gendannelsesvej ved
beskadiget arkiv; lagring blokeres i stedet for at overskrive det.

**Anbefaling:** en ordnet skrivekø uden for UI-tråden, samle tætte ændringer og
bevar en seneste gyldig backup. Håndtér fejl synligt uden at vise en falsk
»gemt«-status. Ryd også referencer og kladder ved sletning af en ven.

Flere scener har egne løbende animationsopdateringer. Det er et område til senere
måling på en ældre iPad, ikke bevis for lav ydelse eller memory leaks. Begræns
løbende opdateringer til synlige, aktive scener og områder med bevægelse.

## Foreslået rækkefølge

1. Beskyt kladder og den igangværende malestreg.
2. Saml layout, navigation og grafiske grundkomponenter.
3. Ombyg boblespillet omkring enkel direkte leg.
4. Finpuds pizza/græskar, værelser og creator med de fælles komponenter.
5. Forenkle orkester og legeplads; saml lyd og feedback.
6. Forbedr lagringskø og backup. Afslut med én samlet bygning og afprøvning på iPad.

## Afgrænsning og udført kontrol

`python tools/check_project.py` passerer: 80 Swift-kildereferencer,
projektobjekter, scheme, plists, ikon og 567 tosprogede tekstnøgler.
Det er en fil-/ressourcekontrol og finder ikke Swift-typefejl, forkert
skærmlayout, lydproblemer eller dårlig børnebetjening. Ingen Xcode-build,
simulator- eller enhedstest er udført i Windows-miljøet.
