# Creator redesign following the usability review

## One workspace

The six primary picture categories are always visible: Body, Color, Face, Arms, Legs
and Extras. Face contains eyes and mouth. Color contains primary/accent paint zones,
a brush and an eraser. Portrait tablets put the tray below the friend; landscape
screens put it alongside. The scene has no separate row of text instructions, limb
size controls, starters or shuffle buttons around the friend.

Variants use a grid with explicit previous/next buttons and page dots. Tablets show
six at a time, phones three. All original body, eye, mouth and limb variants remain.
Colors have a selected outline and check, with all sixteen colors available in a
vertical grid. The main categories stay outside that scroll. Smaller screens may
scroll the option area vertically, with an indicator.

Limb sizes live beside their type choices in the same tray. Extras are grouped into
Head, Body and Behind, with counts of active accessories. Selecting an accessory
toggles it; its check indicates whether it is on the friend. Combinations remain free.

## Deliberate sculpting and ordinary touch

Body starts in Shapes mode. Shape it explicitly enables clay dragging, pinching and
body handles, with three size choices and a reset. Ordinary touch no longer deforms
the friend. It follows the finger, greets once and responds with a boop, wave, curious
lean, hug or delight. Arm and leg choices retain their authored wave/walk responses.
Painting and sculpting do not trigger the large whole-body revision animation.

## Consistent previews

Changing body type clears sculpt/width/height, matching the pictured shape. Other
paint and decoration stay. Body previews use the actual friend's remaining data.
Eye/mouth previews and application both clear the placement of the selected face
feature, so an old offset cannot silently alter the chosen option. Limb pair rules
remain unchanged. Random friends are normalized to those same rules.

## Painting and finishing

The brush has one broad child-friendly size. The native illustrated eraser removes
local portions of strokes by splitting them; it retains their colors and widths.
A visible ring follows the eraser. Erasing is recorded as one undo transaction per
gesture. Saved Codable data has not changed: the eraser modifies ordinary strokes.
Wash all paint off remains under More, alongside redo, starters, shuffle, personality
and the try room. Sheet navigation dismisses More before presenting its destination.

Done opens a simple friend preview with an already available name and one My friend
is ready action. Editing the name/keyboard is optional; shuffle can suggest another
name. Saving, local draft persistence, error display and the friend reveal remain.
A newly created room uses the fixed little-hands arrangement.

No build, simulator run or tests were performed. Device layout and child usability
are not claimed verified; this is the implementation of the review's changes.
