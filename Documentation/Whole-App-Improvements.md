# Samlet forbedringsrunde

Implementeret efter Whole-App-Review.md, 24. oktober 2026.

## Kladder og lagring

- Flere figurkladder og en pizzakladde pr. ven. Tidligere arkiver læses fortsat;
  de oprindelige valgfrie felter bevares som senest anvendte kladde.
- Skaberhuset åbner en billedhylde med ufærdige venner og et valg om en ny ven.
- Malestreger afsluttes før oprydning ved baggrundsskift. Kun gyldige streger
  føjes til modellen. Afslutning gemmer også, når appen allerede er inaktiv.
- Sletning af en ven rydder tilhørende kladder, ledsagervalg og aktivitetsreference.
- En fælles seriel filkø samler ændringer inden for 180 ms og koder/skriver
  snapshots uden for UI-tråden. Det gælder venner, sessioner, indstillinger og
  græskar. UI-modellen opdateres straks; en accepteret ændring er en kølagt
  lagring, ikke en garanti for et gennemført diskskriv.
- Køen bevarer sidste fil som .bak og prøver backup ved ugyldigt hovedarkiv.
  Ved skrivefejl bevares nyeste snapshot til gentagelse fra den synlige fejlknap.
  Hurtige afsluttede writes viser ikke konstant en gemmeindikator.
- Ved baggrundsskift tømmes den ventende kø med en kort iOS-baggrundsopgave.
  Der er ingen netværk eller nye runtimeafhængigheder.

## Sammenhængende betjening og grafik

- Samme vinduesbaserede regler for sidepanel i skaber, pizza, græskar og værelse.
  Bundbakker begrænses til cirka halvdelen af arbejdsområdets højde; store
  valglister kan rulles. Pizzaens fremdriftsknap forbliver uden for valglisterne.
- Fælles farvetokens, afrundede native cartoonikoner i centrale knapper og
  samme klar-knap i pizza og græskar. Eksisterende illustrationer bevares;
  dette er en samling af stil og betjening, ikke en udskiftning af alle bitmapfiler.
- Græskarets udhuling går ikke automatisk videre. Klar-knappen tilbyder næste
  trin uden at stoppe udhuling eller anden kreativ leg.
- Skaberens prøv-leg er direkte tilgængelig i toppen.
- Vennekort åbner værelser direkte, med pensel til redigering og flere
  muligheder bag en sekundær knap. Fortsæt-kort viser aktivitetens grafik.

## Spil og værelser

- Bobler: tryk for at poppe, hold for at vokse. Knibning er fjernet. Flytning og
  sammenblanding vælges i legekassen. Størrelser, kantbegrænsning og kollisioner
  bruger samme geometri. Store bobler tilpasses også skærmhøjden.
- Boblespillet pauser bag legekassen, og overraskelser starter ved boblens
  synlige placering. Lokale overraskelser erstatter fuldskærmskonfetti.
- Værelser: fri placering bevares. Valgt møbel får en varm markeringsramme;
  flytning giver løft/skygge, og slip giver et lille landingshop.
- Legeplads: tre direkte handlinger plus legekasse. Alle seks handlinger,
  miljø-/vennevalg og ekstra aktiviteter er fortsat tilgængelige i legekassen.
- Orkester: instrumenter og afspilning er først; optagelse, gendannelse,
  tempo og rytmeeditor ligger i musikkassen. Tempo vælges lokalt i dette spil.
- Den uklare globale sværhedsgradsvælger er fjernet fra indstillinger og generel
  spilhjælp. Gamle arkivfelter bevares af kompatibilitetshensyn.
- Æblespillets rekord, gradvise tempo, picnic og direkte styring bevares.

## Lyd og animation

- Reaktionslyde får en kort pause omkring afsløringer og afslutningstoner.
  Gentagne figurlyde begrænses, og færre effekter spiller samtidig.
- Lydsystemet håndterer iOS-lydafbrydelser og stopper effekter ved afbrydelse.
- Forsidens baggrund og fælles konfettianimation stopper ved inaktiv app.
  Eksisterende pause- og Reduce Motion-håndtering bevares.
- Ingen talesyntese er tilføjet, og ingen nye lydlicenser er nødvendige.

## Udført validering og begrænsninger

Xcode-projektet er regenereret med de nye kilder. Den portable projektkontrol
og en Swift-syntaksparser er anvendt samlet efter ændringerne. De erstatter ikke
Swift-typekontrol, en Xcode-build eller en afprøvning af layout/lyd på iPad.

Næste enhedsgennemgang bør dække lille iPhone, iPad stående/liggende og Split
View, gendannelse af gamle kladder, baggrundsskift midt i maling, lagerfejl og
backup, samt faktisk berøring og lytning. Der er ikke udført enhedstest eller
målt billedhastighed her. Perspektiv, samlet grafisk kvalitet og forståelighed
for en treårig er derfor forbedringsmål, ikke verificerede resultater.
