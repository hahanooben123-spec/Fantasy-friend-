# Simple free room arrangement

This replaces the fixed-place decorating interaction documented in Little-Hands-Room.md.

- Children add furniture by tapping a large pictured item in the catalog.
- A selected furnishing is outlined and can be moved directly with one finger.
- The toolbar has three actions: Add, Color (or Walls when nothing is selected),
  and Put away. Undo and Done stay in the header. No rotation, size or layer menus.
- The decorating tray keeps a stable height while its contents change, so a furniture
  drag does not change room geometry mid-gesture.
- Wall items stay above the floor; floor items stay below the wall. Drag previews and
  placement use the same RoomPlacement rule, with margins to keep objects onscreen.
- Furniture and a sleeping companion share a base size bounded by room height as well
  as width. The standing companion is also bounded by scene height.
- Existing saved arrangements load as saved: forLittleHands no longer runs on entry,
  and missing furniture is not automatically added back after a child puts it away.
- Automatically displayed pumpkin lanterns and saved pizza are removed from RoomScene.
  The original creations remain in their own games and are not deleted.
- Direct interactions with the bed, lamp, curtains, cabinet, toys and friend remain.

No build, tests or simulator run performed.
