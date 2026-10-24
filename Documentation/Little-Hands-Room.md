# A room for little hands

FriendRoomView now opens directly into play, with one Decorate button and a day/night
switch. Decorating uses six picture categories: bed, rug, lamp, toy cabinet, picture
and walls. Each offers four large picture choices that apply immediately. Tapping
a furnishing in the scene selects its category. Done returns to play. Undo is visible
while decorating; there are no furniture inventory sheets, duplicate controls,
rotation, scale, layers, placement handles or drag-to-add steps in this view.

Furniture uses fixed anchors through RoomLayout.forLittleHands(). Existing objects,
IDs, colors, mirror settings and room design are retained, and missing basic furniture
is added where the existing 32-object limit allows. Saved furniture positions, angles
and sizes are simplified in the editing copy; an existing room is persisted on its
next change. No old objects are deleted. Sleeping bed references remain valid.

The RoomScene fixedLayout option blocks furniture movement and size adjustment.
A small finger drag over a fixed item still activates its tap action on release.
The old drag tutorial is suppressed for fixed rooms. The ball can still be rolled
in play, and the friend, quilt and actual toys remain directly interactive.

Play has three large actions: hug, dance and bubbles. Existing bubble toys and
flashlights are reused instead of accumulating duplicates. The bed, lamp, curtains,
cabinet, saved pizza and lanterns retain their direct interactions.

No build, tests or simulator checks were run, as requested.
