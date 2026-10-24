# A calm, rewarding cartoon orchard

Implements the Apple-Game-UX-Review direction using native vector illustrations and
the shared ToyFinish materials, with no new network services or generated assets.

## Simple play

The apple session has its own HUD: back, pause and one large pictured picnic button.
Movement arrows, automatic weather changes, visible restart and tree-shaking controls
are removed from the play surface. Restart and an optional gentle breeze live under
pause. The default orchard stays calm.

Falling fruit waits for the first direct gesture or VoiceOver adjustment. A hand
demonstrates sideways movement; Reduce Motion uses a static direction cue. Default
fruit starts at the canopy, falls at 0.12 scene-heights per second, arrives at least
2.8 seconds apart and has at most two active falling pieces. New fruit appears near
the companion, without penalizing a miss. Movement direction uses the actual change
in player position.

## Shared visual measurements

OrchardMetrics controls basket, fruit, companion and the basket opening. The catch
window derives from those same pixel sizes instead of a screen-width minimum. A
small allowance accounts for the falling fruit's radius. Fruit is 52-82 points wide;
the basket is 122-190, and the companion also fits scene height.

The new original basket has a rounded handle, softly shaded wicker, a real opening
and visible fruit behind the front lip. Each caught piece makes a short landing
arc into the moving basket before becoming basket contents. The basket squashes
slightly, the friend claps and smiles, and catch sound pitch varies through the
existing audio service. Local star accents remain; apple play no longer triggers
periodic full-screen milestone celebrations. Fruit has soft swing and highlights;
the apple leaf now shares the same shaded material.

Missed fruit grows into a flower. Stable flower IDs preserve the existing garden
when a new flower arrives. Only selected flowers host fluttering butterflies; their
timelines pause during picnic, app inactivity and Reduce Motion.

## Picnic

The child tips the pictured basket, watches fruit spread onto the blanket, then taps
the actual collected pieces to share. Sharing removes that piece from the basket.
Reopening picnic does not restore eaten fruit or replay an old delivery animation.
The calm session retains all unshared collected fruit instead of silently dropping
old pieces at twelve. The legacy AppleRain defaults retain their prior basket limit
for callers that do not request relaxed play. State is still session-local.

Pause, backgrounding and picnic stop the falling simulation without a catch-up jump.
There are still no lives, countdowns, loss screens or return pressure. Existing bubble
and hide-and-seek interfaces remain on their shared HUD.

No build, tests or simulator run was performed. Visual layout is not claimed verified
on a real iPad.
