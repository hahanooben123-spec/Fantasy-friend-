# Simpler creator and shared game UI

## References

- [Toca Boca: Outfit Designer](https://tocaboca.helpshift.com/hc/en/3-toca-boca-world/faq/241-introducing-outfit-designer-your-new-tool-to-style-outfits/) describes browsing categories and mixing selected pieces, with illustrated choices rather than editing technical geometry.
- [Toca Boca World](https://www.tocaboca.com/toca-boca-world) presents character creation and home design as tools for self-expression.
- [Sago Mini / Piknik: Gabby's Dollhouse](https://help.sagomini.com/article/871-what-learning-activities-does-gabby-s-dollhouse-provide) describes open-ended exploration, interactive items and imaginative play.

The following design decisions are our interpretation of those references and the user's feedback, not claims that these changes have been tested with children.

## Implemented

- Arm and leg choices replace a matching pair. No new loose limbs are added by the main creator.
- Three large picture choices set small, medium or large limbs. Native attachment positions compensate for scaling at shoulders and hips.
- Opening an old creation in the editor converts loose arms/legs to a single pair in the editing copy, using the latest loose type where present. The saved collection is unchanged until the child saves. Other accessories and drawings are retained.
- Optional armSize and legSize fields preserve older archive decoding. Friends outside the editor retain old explicit placements until edited.
- Part dragging and rotation handles are removed from the main creator. Body sculpting and painting remain direct gestures.
- Extras toggle the standard accessory instead of adding unlimited duplicate accessories. Extra-eye, duplicate and mirror commands are removed from the main creator.
- One active category, large picture choices and a consistent checked selected state. The phone header has Back, Undo, More and Done; Try sits beside the stage. Redo is available in More.
- Shared round controls, lighter card surfaces, simpler shelves, outlined scene headings and consistent selected tools apply across the creator, games, gallery, settings and play screens.
- Game selection uses adaptive picture cards. Room play hides the editing instruction strip. Back navigation returns immediately without a separate goodbye bubble.

No build, automated tests or runtime UI checks were run, at the user's request.
