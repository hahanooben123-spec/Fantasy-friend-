# Første gennemgang på iPhone

Status: **Swift 6-build og 13 automatiske tests bestået på iPhone-simulator for commit 2d73361. Manuel UI- og touchtest af den nye version afventer iPad/iPhone.** Markér først punkter som godkendt efter faktisk afprøvning.

## Fase 1: Projekt og navigation

- Byg Debug og Release med Swift 6. Kør alle XCTest-tests.
- Åbn hovedmenuen på iPhone SE og en stor iPhone. Kontrollér safe areas, scroll og minimum 44 pt touchområder.
- Åbn og luk bygger, galleri, legeplads og indstillinger. Åbn også en tom samling.
- Kontrollér valgfrit .swiftpm-projekt i en Swift 6-kompatibel Playgrounds-version.

## Fase 2: Figur og bygger

- Vælg alle otte kroppe. Arme, ben, ansigt og pynt skal holde sig inden for figurområdet.
- Gennemgå alle 16 farver, 12 øjne, 10 munde, 8 arme og 8 ben.
- Slå hver af de 15 tilbehørstyper til og fra. Prøv horn + ører + krone og vinger + hale.
- Swipe vandret i kategorier og muligheder. Den store figur skal altid være synlig.
- Tryk hurtigt, brug fortryd, og lav gentagne tilfældige figurer. Navn og ID bevares ved redigering.
- Luk en ændret figur: annullér eller bekræft at forlade uden at gemme.

## Fase 3: Gem og saml

- Skriv navn, prøv tomt navn, 30+ tegn, emoji og navneforslag.
- Gem, genstart appen helt, og kontrollér figur, navn, tilbehør og miljø.
- Redigér en gemt ven: der skal fortsat kun være én udgave i galleriet.
- Opret mindst 50 venner. Scroll galleriet og skift mellem venner på legepladsen.
- Sletning: forkert voksensvar må ikke åbne bekræftelsen. Annullér ved begge trin, og kontrollér at vennen bevares. Slet derefter og genstart.
- Kør de automatiske tests for ødelagt fil og skrivefejl. Ingen stille nulstilling af data.

## Fase 4: Leg, lyd og tilgængelighed

- Afprøv alle seks handlinger, tryk gentagne gange, skift ven og navigér væk midt i en animation.
- En sovende ven skal vågne ved en anden handling eller berøring.
- Afprøv alle miljøer og genstart: hver ven skal huske sit miljø.
- Slå lyd og musik til/fra, brug telefonens lydløs tilstand, og sæt appen i baggrunden.
- Skift dansk/engelsk, og genstart. Kontrollér tekster og systemnavigation.
- Test flytilstand. Alle spilfunktioner skal fortsat fungere.
- Aktivér Reducer bevægelse, VoiceOver og stor tekst. Kontrollér læselighed, fokus og knapnavne.
- Kør i både systemets lyse og mørke tilstand: spillets bevidst lyse tema skal være konsistent.
- Brug Instruments til hukommelse/CPU på fysisk iPhone, især ved gentagen åbning/lukning af bygger og leg.

## Fri placering: regression på iPad

- Hold på en arm-miniature og træk den op. Slip på venstre/højre side, og kontrollér at kun den tilsvarende arms placering ændres.
- Flyt hver arm og hvert ben separat direkte på figuren. De skal følge fingeren uden hop. Afprøv både let tryk og træk.
- Træk horn, hat, briller, hale og hver anden pyntetype op fra bakken. Flyt igen og kombinér flere dele.
- Annullér et træk uden for værkstedet: figuren skal være uændret. Start straks et nyt træk.
- Vælg overlappende dele via navneknapperne og flyt dem separat. Nulstil eller fjern en del, som ligger bag kroppen.
- Drej og ændr størrelse ved alle fire kanter. Delene må ikke forsvinde ud af tegneområdet.
- Flyt med pileknapperne og VoiceOver. Afprøv alle værktøjsknapper.
- Ét fuldført træk skal kræve præcis ét tryk på Fortryd. En annulleret eller uændret placering skal ikke optage et trin.
- Gem en ven med forskellige arm-/benplaceringer og drejet pynt. Genåbn appen og kontrollér galleri, redigering og leg.
- Åbn gamle venner uden placeringer. De skal ligne sig selv og kunne gemmes med nye placeringer.
- Gentag på to forskellige vinduesstørrelser i Playgrounds. Relativ placering og fingerposition skal passe.

## Ragdoll

- Grib kroppen, hver arm og hvert ben. Træk langsomt/hurtigt og slip over gulvet.
- Kontrollér at arme og ben forbliver hængslet til kroppen, og at pynt følger den.
- Test alle kropsformer og venner med flyttede/drejede/skalerede lemmer.
- Flyt fingeren uden for legefeltet, og slip; vennen skal blive i feltet.
- Tryk på alle seks legeknapper og nulstilling før/efter et træk.
- Skift ven og miljø under leg. Forlad legepladsen og sæt appen i baggrunden.
- Genåbn byggeren: ragdoll-leg må ikke have ændret de gemte placeringer.
- Slå Reducer bevægelse til: direkte flytning skal virke uden dinglen eller fald.

## Kreativt værksted

- Afprøv bredt iPad-vindue og smalt vindue: bakke ved siden af/under figuren, stor figur, tilgængelige Færdig/Fortryd/Gendan.
- Gennemgå alle illustrerede kategorier og grid med dele; øjne og munde skal være tydelige nærbilleder.
- Træk fra bakken og flyt direkte på figuren. Placering, størrelse og drejning skal fortsat virke.
- Mal prikker og streger i alle farver og tre størrelser. Langsom/hurtig maling, meget lang streg og annulleret berøring.
- Malingen skal ligge på kroppen og bevare synlige øjne og mund. Skift krop og kontrollér at malingen følger den.
- Vask malingen af. Fortryd og gendan både vask, penselstrøg, farvemagi, flytning og tilfældig figur.
- Farvemagi skal bevare placeringer og maling. Et nyt valg efter Fortryd skal tømme Gendan.
- Gem, genstart og se malingen i galleri og ragdoll-leg. Gamle venner skal åbne uden maling.
- Test stor tekst, Reducer bevægelse og VoiceOver på pensler, farver, dele og værktøjer.
