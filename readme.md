# Ember Yard

A compact Godot 4.6 2.5D sword-and-shield training arena. Fully 3D knights and scenery; movement and melee stay on the side-scrolling X/Y plane.

## Play

Open `project.godot` in Godot 4.6 and press **F6** on `arena.tscn`, or **F5** to run the project. From a terminal: `godot --path .`.

| Control | Action |
| --- | --- |
| A / D or arrows | Move |
| Z | Alternating Slash1 → Slash2 → Slash1 combo: press repeatedly (20 stamina per hit) |
| X | Heavy strike (35 stamina) |
| C, held | Guard facing forward |
| V + direction | Invulnerable forward roll, heading locked (22 stamina) |
| V without direction | Standing backward dodge (22 stamina) |
| Space | Jump; moving and stationary clips selected automatically |
| S / down arrow, held | Crouch; release to stand |
| B | Heal 55 HP; three charges; leaves you exposed |
| R | Restart the duel |

Defeat the sparring knight. A pulsing red ring signals its attack wind-up. Guard reduces incoming damage and consumes stamina; quickstep passes through strikes. Stamina regenerates fastest when your guard is down. Heavy attacks trade recovery time for damage. Restart replenishes both fighters and healing charges. You can pass through the opponent. After victory you may keep exploring; after defeat your knight recovers after the death animation so you can move again. Press R for another duel.

## Animation viewer

Press **Enter** during play to open the scrollable animation menu. The opponent disappears and combat pauses. Click an original FBX filename to perform it on the knight. Use the search field to filter names, Replay to restart, Stop to pause, Loop to repeat, the speed slider for slow motion, Turn to inspect another angle, and Copy name to share your choice. Press Enter again to return to the duel. Previewing does not consume health, stamina, or healing charges.

The viewer includes **65 clips**: the original 51 animations plus all 14 individually uploaded organized files. Organized filenames retain their original capitalization. `Run Attack.fbx` is included for preview; Z always uses the requested alternating slash combo. `X Bot.fbx` is the original pack's reference model rather than another animation. The earlier oversized Pack 2 archive was not imported in full; its separately supplied organized clips are now included.

## Requested animation rules

| Situation | Animation |
| --- | --- |
| Normal front hit | Impact.fbx |
| Front hit while guarding | Shield Impact.fbx |
| Rear hit (bypasses shield) | Back Impact.fbx |
| Crouched front hit | Crouch Impact.fbx |
| Crouched front hit while guarding | Crouch Shield Impact.fbx |
| V with directional input | Stand To Roll.fbx |
| V without directional input | Standing Dodge Backward.fbx |
| Jump with directional input | Moving Jump.fbx |
| Jump without directional input | Sword And Shield Jump.fbx |
| First/next alternating attack | Sword And Shield Slash1.fbx / Sword And Shield Slash2.fbx |
| Enter / exit crouch | Crouch.fbx / Crouch To Standing.fbx |

The combo buffers another press during the current slash and accepts a next press within 0.3 seconds after it finishes. Each queued hit costs stamina; if stamina is depleted, the chain stops. A roll's direction and facing are locked until it finishes. A no-input dodge retreats without turning the knight. Guarding requires stamina and a frontal attack; rear hits use Back Impact even if guard is held. Hold C while crouched to guard low. Release S/down to play the stand-up transition.

## Assets and implementation

`assets/knight.glb` combines the supplied Paladin WProp J Nordstrom knight with 51 original clips and 14 organized clips. Shared Mixamo bone names allow the clips to drive the knight skeleton. World-horizontal hips travel is removed from all clips at runtime for gameplay-controlled movement, retaining vertical pose motion. Movement, heavy strikes, healing, guard idle, crouch guard idle, and death retain the original pack's clips; the requested actions use the named organized clips above.

The arena, lights, HUD, and fighters are created by `arena.gd`; movement, animation and combat are in `fighter.gd`. No plugins or external services are required. Imported materials/textures are from the supplied model. Asset rights remain with their respective creators; the upload did not include license documents.

In a cloud shell with a read-only home directory, set writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` before running Godot. For example, create `/tmp/ember/{data,config,cache}` and set those variables to the corresponding directories.

Validation: Godot 4.6.3 asset import and a focused headless check passed for all 65 previews, the five hit reactions and shield damage rules, alternating buffered slashes, roll direction lock, backward dodge, moving/stationary jump selection, and crouch/stand transitions. Interactive rendering and gameplay feel were not manually tested.
