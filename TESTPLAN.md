# Første gennemgang på iPhone

Status: **Afventer Xcode og enhed/simulator.** Markér først punkter som godkendt efter faktisk afprøvning.

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
