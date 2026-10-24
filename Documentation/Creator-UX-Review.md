# Gennemgang af skaberen - 24. oktober 2026

> Efterfølgende implementering: [Creator-Redesign.md](Creator-Redesign.md). Fundene nedenfor beskriver tilstanden før ombygningen.

## Afgrænsning

Gennemgang af den aktuelle SwiftUI-kode, layoutmål, valg, gestusser og forløbet frem til gemning.
Appen er ikke startet i simulator eller på iPad. Observationer om plads og skjulte valg
følger af layoutreglerne; det endelige udseende skal senere vurderes på en enhed.
Ingen implementering er ændret i denne gennemgang.

## Prioriterede problemer

### 1. Kategorierne skjules på selve iPad-layoutet - høj

BuilderView bruger en sidebakke fra 740 punkters skærmbredde, uanset orientering.
Bakken er min(310, bredde * 0.35). Inde i den ligger otte kategorier i en vandret
ScrollView uden indikator. De fylder tilsammen 591 punkter: 8 * 67 + 7 * 5 + 20.
Barnet ser derfor kun en del af værktøjskategorierne ad gangen i en 259-310 punkters bakke.
Kilde: BuilderView.body, categoryRail og categoryButtons.

Retning: seks synlige billedkategorier i et gitter. Krop, Farve, Ansigt, Arme, Ben og
Pynt. Øjne og mund samles under Ansigt; maling ligger under Farve. Bevar de eksisterende
valgmuligheder, men vis dem i store overskuelige grupper med tydelig bladren.

### 2. Samme værktøj er fordelt over flere steder - høj

Kategorier og delvalg ligger i bakken; arm- og benstørrelser ligger under figuren;
startfigurer, afprøvning og tilfældig figur ligger over den. En tekstlinje optager
66 punkter under figuren også når der ikke er størrelsesvalg. På smalle skærme er
værktøjsbakken fast 244 punkter, før scenens egne kontroller og hjælpelinje tælles med.
Kilde: BuilderView.scene, selectionTools og body.

Retning: hold variant, farve og størrelse i samme værktøjsområde. Giv figuren resten
af scenen. Saml sjældnere handlinger, og undgå flere rækker af knapper omkring den.

### 3. Krop er både et valg og et følsomt formningsværktøj - høj

CreatorStage bruger DragGesture med minimumDistance 0, og kropskategorien er valgt
fra start. Et tryk med lidt bevægelse over kroppen kan derfor ændre silhuetten.
Der er også to resize-håndtag og en tofinger-gestus. I de fleste andre kategorier
returnerer samme gestus straks, så berøring af figuren ikke giver en legereaktion.
Kilde: CreatorStage.gesture, bodyHandle og CreatorClay.pull/pinch.

Retning: adskil almindelig berøring fra en tydelig Form selv-tilstand. Tilbyd først
kropsformer og enkle størrelsesvalg. Lad almindelige tryk give en nuttet reaktion.

### 4. Kropspreview svarer ikke altid til resultatet - høj, konkret kodeproblem

sample(index) nulstiller bodySculpt, bodyWidth og bodyHeight for kropspreviews.
apply(.body) ændrer alene body. Tidligere formning bliver derfor på den nye krop,
selvom billedvalget viser en uformet figur. Ansigtspreviewet fjerner også gamle
facePlacements, mens valg af øjne/mund bevarer dem.
Kilde: BuilderView.sample og apply.

Retning: vælg en konsekvent regel for at bevare eller nulstille formning og placering,
og lad previewet bruge præcis samme regel som den endelige ændring.

### 5. Farver har ingen valgt-markering - høj, konkret kodeproblem

colorChoices tegner alle farver med samme kontur. Hverken kropsfarven eller den valgte
malefarve vises som valgt. Krop/ekstra farve skiftes desuden via en tekstknap.
Kilde: BuilderView.colorChoices og drawer.

Retning: tydeligt flueben og kant på aktiv farve. To billedbaserede farvezoner fremfor
at kræve forståelse af teksten Ekstra farve.

### 6. Maling mangler præcis rettelse og konkurrerer om plads - mellem/høj

Maling kombinerer farverulleliste, tre penselstørrelser og slet al maling inde i den
samme faste bakke. Der er ingen lokal viskelæderfunktion. Hele figurens revisionsreaktion
køres også efter afsluttede malestrøg og fortryd, fordi alle ændringer øger revision.
Kilde: BuilderView.brushTools/change/finishGesture og CreatorStage.task(id:revision).

Retning: stor farvepalette, én tydelig pensel og et viskelæder. Brug en lille lokal
reaktion ved maling; reserver større kropsbevægelser til relevante delvalg.

### 7. Tilbehør er en flad liste uden hjælp til kombinationer - mellem

Femten typer ligger samlet; samme tryk både tilføjer og fjerner. Flere typer kan optage
samme område på hovedet. Kombinationer er tilladt, men der er ikke et samlet billede
af det aktive tilbehør eller en særskilt, synlig fjern-handling.
Kilde: BuilderView.optionCount, chosen og apply(.extras).

Retning: store billedvalg i grupper såsom På hovedet, På kroppen og Bagpå. Gør aktivt
pynt tydeligt, og vis fjernelse med samme tryk som en let genkendelig til/fra-handling.
Bevar muligheden for at blande ting kreativt.

### 8. Færdig kræver en teksttung navngivningsskærm - mellem/høj

Færdig åbner et ark med tekstfelt, fire tekstnavne, en foreslå-knap og en gem-knap.
Automatisk navn findes først ved gemning af et tomt navn. En ny ven starter allerede
med et navn fra sin startfigur. Barnet skal dermed gennem en navneformular, selvom
det kun vil gøre vennen færdig.
Kilde: BuilderView.NamingView og finishFriend.

Retning: tilbyd et navn automatisk og én stor Min ven er klar-knap. Bevar navneskift
som et valgfrit enkelt trin. Lad barnet møde vennen først.

## Det, der skal bevares

- Delvalg opdaterer straks den samme store figur.
- Arme og ben er par med tre enkle størrelser.
- Original vektorfigur, fri maling og mulighed for at blande pynt.
- Lokal kladde, fortryd og sikker gemning med fejlvisning.
- Nuttede bevægelser og direkte overgang til vennens værelse efter gemning.

## Anbefalet rækkefølge

1. Ret kategori-layoutet, saml værktøjerne og frigør plads til figuren.
2. Ret preview/resultat og farvemarkering, før flere illustrationer tilføjes.
3. Adskil leg, formning og maling; gør rettelser nemme.
4. Forenkle navngivning og afslutning.
5. Vurder derefter det samlede forløb på både stående og liggende iPad.

Målet er en enkel hovedsløjfe: tryk på et stort billede, se ændringen på vennen,
og prøv videre. Ingen obligatorisk rækkefølge eller opgaver, som skal fuldføres.
