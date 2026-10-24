# Cuddly characters and simpler activity tools

## Character rendering

CreatureLimbArtwork is the shared native vector source for eight arm styles and eight foot styles. Shapes include pebble hands, teddy paws, round mittens, flippers, knitted cuffs, soft feathers, leaf hands and balloon hands; feet include beans, paws, flippers, little toes, slippers, boots, striped socks and cloud slippers. No raster character assets are required.

Shoulder and hip roots are derived once from each of the eight body silhouettes. The renderer, thumbnail bounds, attachment transforms, rig pivots and SpriteKit pins use the same geometry. Arm reach leaves room at the edge of the canvas for all three creator sizes. Attachment offsets also account for body width, height and sculpting when the sculpt is otherwise the identity.

Happy expressions retain large open eyes. Small eyes are slightly larger, cheek blush uses a soft gradient, smiles have round corners and the tongue-out option has a visible rounded tongue. Eye, mouth and body selections keep their existing saved indices.

The creator plays a short wave for arm choices and a short walking preview for legs. Walking eases in/out; jump reactions have enough time to land. Reduce Motion uses a still happy expression instead of those movements.

## Pizza

Ingredient, dough, topping, herb, tool and progress choices share GameChoiceSurface. Tool tabs use actual artwork previews where possible. The tray uses the shared light shelf instead of nested decorative panels. Existing automatic progression, drag/drop, unlimited topping placement and finger eating remain active.

## Pumpkins

The header follows Back, Undo, More and Done. Redo, the garden and duplication are grouped in More. The separate next-step button is removed because the four illustrated stages already provide direct navigation. Scooping advances to carving after completion. Stamp choices are shown only when using the stamp tool. The tool row scrolls on narrow screens.

Lighting uses large checked colour choices, a day/night button and three brightness presets in place of two sliders. Light type and on/off remain independent.

## Room

Selecting furniture shows three direct picture size choices. Items can still be dragged, but floating resize/rotate handles and pinch resizing are removed from the scene. Rotation remains in More with copying, mirroring and layer choices. Tapping a furniture choice closes the tray; dragging from it can still place several objects. The selected size row keeps a stable height during dragging.

No build, tests or runtime UI checks were run, at the user's request. The project generator was run only to register the new Swift source file.
