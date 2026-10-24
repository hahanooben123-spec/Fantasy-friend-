# Pizza: materials, creative edits and serving

The pizza workshop keeps its child-controlled next-step buttons. No preparation
stage changes just because the child has finished a gesture.

## Tactile feedback

- Dough follows the existing free deformation geometry and springs after release.
  A local soft indentation follows the finger; a short flour puff follows release.
- Sauce uses midpoint curves rather than sharp line segments. A little spoon and
  wet highlight follow the finger, without intercepting its gesture.
- Melted cheese connections have a wider creamy body and a thin gloss highlight.
  Eating a cheese-containing mouthful draws up to three short stretching strands.
  These stop after 0.36 seconds, and skip under Reduce Motion.

## Creative corrections

The toppings tray has an explicit Move picture button. In this mode, a finger picks
the topmost nearby topping, moves it within the dough, or removes it by dropping it
past the crust. A white ring marks the held piece. Choosing another ingredient
returns to placing. The same undo transaction records the whole move or removal.
VoiceOver's surface action removes the last topping while in Move mode.
Unlimited placement, free dough shapes, herb choices and existing saved drafts remain.

## Serving

Once baked, Let's taste opens a warm glass oven flap. After 0.45 seconds, the pizza
and plate slide forward; steam puffs, celebration and a short instrumental flourish
accompany the reveal. After another 0.85 seconds, finger eating becomes available.
Reduce Motion goes directly to serving. Reveal tasks cancel during pause and resume
when play becomes active again. A draft saved before the reveal finishes still
contains the completed pizza in the oven.

Gesture lessons also demonstrate stirring and sauce spreading after inactivity.
They disappear as soon as that activity begins. No speech or external services.

No build, tests or simulator checks were run, following the user's preference.


## Larger visible choices

Landscape tablets use a 350-440 point tool tray, proportional to screen width.
Portrait tablets keep the work surface above a full-width tray instead of placing
a narrow vertical shelf beside it. Ingredient pictures and tool labels are larger.
All six dough shapes and all seven topping types plus Move appear in grids; there
is no hidden horizontal choice strip. Tablet portrait uses one row of topping
choices, landscape uses three columns, and phones use four columns. Touch drags
can now start in any direction because no horizontal tray scroll competes with them.

The option area can scroll vertically on smaller screens, with an indicator. Undo
and the next-step button stay outside that scroll so navigation remains visible.
