# End overlay

The reusable scene is `res://scenes/end_overlay.tscn`. Add it to a playable level's root node. It waits 1.5 seconds after a completion signal, then pauses the game. The stage menu stays above it and remains usable while paused.

The overlay includes a circular-arrow button to replay and a right-arrow button to open the next stage. These use text glyphs, so no icon files are required. The last stage has no next stage and its arrow button is disabled. The stage order is configured in `scripts/end_overlay.gd` in `STAGE_SCENES`.

For an end screen image, select `EndOverlay` in the Inspector and assign your imported image to `endgame_image`. The image fills the screen behind the functional replay and next-stage buttons. If no image is assigned, the overlay uses its default dark backdrop and heading.

The distance/displacement guide belongs to `tutorial1.tscn`, not the end screen. It instances `res://scenes/end_distance_displacement_diagram.tscn`, which uses the gameplay displacement vector and a dashed Z-shaped route sharing the same start and end points.

New displayed text goes in `res://localization/game_text.csv` using translation keys. Add one column per locale and call `tr("KEY")` in scripts. Godot loads that CSV from Project Settings.

## Standard level

Leave `tutorial_mode` off. When the player reaches `PortalTarget`, it emits `completed` and the overlay displays `COMPLETE`.

## A different completion condition

Disable `connect_completion_sources` on `EndOverlay` so the portal does not trigger it too. Then call `show_completion()` on the level's `EndOverlay` node from that level's own logic, when its condition is met:

```gdscript
$EndOverlay.show_completion()
```

For example, call it after checking a quiz answer or a required vector setup.
