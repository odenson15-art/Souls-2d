# Ember Yard

A compact Godot 4.6 2.5D sword-and-shield training arena. Fully 3D knights and scenery; movement and melee stay on the side-scrolling X/Y plane.

## Play

Open `project.godot` in Godot 4.6 and press **F6** on `arena.tscn`, or **F5** to run the project. From a terminal: `godot --path .`.

| Control | Action |
| --- | --- |
| A / D or arrows | Move |
| J | Slash (20 stamina) |
| K | Heavy strike (35 stamina) |
| L, held | Guard facing forward |
| Space | Invulnerable quickstep (22 stamina) |
| E | Heal 55 HP; three charges; leaves you exposed |
| R | Restart the duel |

Defeat the sparring knight. A pulsing red ring signals its attack wind-up. Guard reduces incoming damage and consumes stamina; quickstep passes through strikes. Stamina regenerates fastest when your guard is down. Heavy attacks trade recovery time for damage. Restart replenishes both fighters and healing charges.

## Assets and implementation

`assets/knight.glb` combines the supplied Paladin WProp J Nordstrom knight with all 51 clips from the supplied Pro Sword and Shield Pack. Shared Mixamo bone names allow the clips to drive the knight skeleton. Horizontal root travel is removed for gameplay-controlled movement. The prototype uses idle, run, slash, attack, block, block idle, crouching, impact, power up, and death. Quickstep uses the crouching clip rather than inventing an unavailable roll animation. Other supplied clips remain available in AnimationPlayer.

The arena, lights, HUD, and fighters are created by `arena.gd`; movement, animation and combat are in `fighter.gd`. No plugins or external services are required. Imported materials/textures are from the supplied model. Asset rights remain with their respective creators; the upload did not include license documents.

In a cloud shell with a read-only home directory, set writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` before running Godot. For example, create `/tmp/ember/{data,config,cache}` and set those variables to the corresponding directories.

Validation: imported with Godot 4.6.3 and ran a headless scene smoke check. Interactive rendering and gameplay feel were not manually tested.
