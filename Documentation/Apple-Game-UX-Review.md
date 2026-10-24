# Gennemgang af Grib æbler

> Efterfølgende ombygning: [Apple-Game-Redesign.md](Apple-Game-Redesign.md). Fundene nedenfor gælder udgaven før ombygningen.

Kodegennemgang, ikke en afprøvning på iPad eller med børn. Ingen spilændringer i denne gennemgang.

## Det, der fungerer

Ingen liv, nedtælling eller game over. Frugt, som ikke gribes, bliver til blomster.
Pause og picnic stopper simulationen. Vennen er barnets egen figur, og hvert greb
giver lyd, en ansigtsreaktion og en lille effekt. Det er et godt udgangspunkt.

## Prioriterede problemer

1. For mange samtidige funktioner. HUD har tilbage, indstillinger og pause. Hertil
   kommer tæller, vejrvælger, genstart, to pile, picnic og et træ, der kan rystes.
   Direkte fingerstyring er allerede tilgængelig, så de to pile konkurrerer med den.
   Genstart nulstiller straks legen. Kilde: MiniGameSessionView.body og restart.

2. Start og tempo er ikke rolige nok som standard. Simulationen kører før første
   handling; frugt begynder at dukke op efter cirka 0,32 sekund på letteste niveau.
   AppleRain.weather skifter automatisk hver 14. sekund, medmindre vejret vælges
   manuelt. Sessionen bruger altid adventurous:true: vind kan flytte frugt, og
   regnbuevejr forkorter intervallet. På letteste niveau tager en ny frugt cirka
   3,3 sekunder fra fødsel til gribezonen, mens nye kan komme hver 1,08 sekund i
   regnbuevejr. Ryst træet tilføjer op til tre ekstra frugter. Kilde: AppleRain.step,
   shake og weather samt MiniGameSessionView.tick.

3. Kurven og kollisionsområdet bruger forskellige mål. BasketToy er fast 112 punkter
   bred, og frugten er 46 punkter bred. Griberadius beregnes derimod som
   max(0.09,min(0.22,62/skærmbredde)). På en 1366 punkter bred scene giver det
   cirka 123 punkter til hver side af kurvens centrum, selv om kurvens synlige halve
   bredde er cirka 54 punkter. Lodret gribes i 0.70...0.79 af scenens højde, mens
   kurven står ved 0.75. Resultatet kan derfor se ud som et greb uden synlig kontakt.
   Kilde: MiniGameSessionView.appleField, BasketToy og AppleRain.step.

4. Ingen visuel introduktion til styringen. Den første hjælp er tekst, og enhver
   berøring fjerner den. Der er ingen hånddemonstration i appleField. Omvendt
   registrerer movementButton ikke interacted, så hjælpen kan blive stående, selv
   om barnet faktisk spiller med pilene. Træets tryk og scenens samtidige gestus
   kan også reagere på samme berøring: både frugtrystning og flytning.

5. Gangretningen er en konkret kodefejl. orchardDirection sættes efter orchardGaze.x,
   altså frugtens placering, i stedet for forskellen mellem ny og gammel playerX.
   Vennen kan derfor gå med forkert retningsbevægelse i forhold til fingerstyringen.

6. Skalaen bruger ikke tabletpladsen. Frugt er altid 46 x 48, kurven 112 x 82, og
   vennen begrænses til 210 punkters bredde. Det store landskab giver derfor ikke
   tilsvarende større og tydeligere legegenstande. HUD og tæller ligger desuden over
   trækronens område, som starter 65 punkter fra toppen.

7. Picnicens mad hænger ikke tydeligt sammen med det delte. fruitBasket beholder
   de seneste 12 frugter. Delte frugter markeres kun i picnicShared, som nulstilles
   ved genåbning. De samme frugter kan dermed deles igen uden nogen visuel forklaring.
   Picnic er en god mulighed, men tæller, kurv og mad bør vise samme tilstand.

## Anbefalet ombygning

Først: ét tydeligt træk med fingeren, større ven/kurv/frugt og et gribeområde afledt
af den tegnede kurvs åbning. Vent på første handling og vis en kort hånddemonstration.
Start med langsom frugt uden automatisk vejromslag. Ret gangretningen.

Dernæst: lad frugten lande synligt i kurven, giv vennen en kort glad reaktion og
bevar blomster ved tabt frugt. Fjern pile og synlig genstart fra hovedlegen. Behold
tilbage/pause og en enkelt billedknap til picnic. Ekstra vejrleg kan være valgfri.

Til sidst: gør picnicturen til en tydelig frivillig fortsættelse med de faktisk
samlede frugter. Vurder derefter stående/liggende skærm og styring på en rigtig iPad.
