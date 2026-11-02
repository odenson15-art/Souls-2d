# Ember Yard

A compact Godot 4.6 2.5D sword-and-shield training arena. Fully 3D knights and scenery; movement and melee stay on the side-scrolling X/Y plane.

## Play

Open `project.godot` in Godot 4.6 and press **F6** on `arena.tscn`, or **F5** to run the project. From a terminal: `godot --path .`.

| Control | Action |
| --- | --- |
| A / D or arrows | Move |
| Z | Four-hit combo: press repeatedly (20 stamina per hit) |
| X | Heavy strike (35 stamina) |
| C, held | Guard facing forward |
| V | Invulnerable quickstep (22 stamina) |
| B | Heal 55 HP; three charges; leaves you exposed |
| R | Restart the duel |

Defeat the sparring knight. A pulsing red ring signals its attack wind-up. Guard reduces incoming damage and consumes stamina; quickstep passes through strikes. Stamina regenerates fastest when your guard is down. Heavy attacks trade recovery time for damage. Restart replenishes both fighters and healing charges. You can pass through the opponent. After victory you may keep exploring; after defeat your knight recovers after the death animation so you can move again. Press R for another duel.

## Assets and implementation

`assets/knight.glb` combines the supplied Paladin WProp J Nordstrom knight with all 51 clips from the supplied Pro Sword and Shield Pack. Shared Mixamo bone names allow the clips to drive the knight skeleton. World-horizontal hips travel is removed from all clips at runtime for gameplay-controlled movement, retaining vertical pose motion. The prototype uses idle, run, attack 1–4 for the combo, slash (2) for heavy strikes, block, block idle, crouching, impact, power up, and death. Quickstep uses the crouching clip rather than inventing an unavailable roll animation. Other supplied clips remain available in AnimationPlayer.

The arena, lights, HUD, and fighters are created by `arena.gd`; movement, animation and combat are in `fighter.gd`. No plugins or external services are required. Imported materials/textures are from the supplied model. Asset rights remain with their respective creators; the upload did not include license documents.

In a cloud shell with a read-only home directory, set writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` before running Godot. For example, create `/tmp/ember/{data,config,cache}` and set those variables to the corresponding directories.

Validation: Godot 4.6.3 headless startup and targeted checks passed for zero horizontal root travel across all 51 clips, four buffered combo stages, passing the opponent, movement after victory, death/recovery after defeat, and Z/X/C/V/B input bindings. Interactive rendering and gameplay feel were not manually tested.
