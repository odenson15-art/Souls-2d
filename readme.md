# Ember Yard

Godot 4.6 2.5D knight training arena: fully 3D models, with gameplay constrained to a side-scrolling plane. Open `project.godot` in Godot 4.6 and press **F5**, or run `godot --path .`.

## Controls

| Control | Action |
| --- | --- |
| A/D or left/right arrows | Run |
| Z, repeated presses | Alternating Slash1 / Slash2 combo |
| C, held | Raise shield and guard |
| V + direction | Direction-locked forward roll |
| V without direction | Standing backward dodge |
| Space | Jump; tap clears the opponent, hold for a higher jump |
| S/down arrow, held | Crouch; release to stand |
| B | Heal 100 HP; three charges |
| Enter | Animation viewer |
| R | Restart duel |

Both knights have **250 HP**. Heavy attacks and stamina have been removed. Guard reduces frontal damage; back attacks bypass it. The opponent's red ring warns of an attack. You may cross the opponent. After victory, keep exploring; after defeat, your knight recovers after its death animation. R starts a fresh duel.

## Movement and animation timing

Running is 5.5 m/s (previously 3.5). The camera is closer and follows the player. The forward roll uses **Sprinting Forward Roll.fbx** over 0.68 seconds, with quicker playback during the opening dive and a smooth transition into its rolling phase. It carries running momentum in/out and covers about 3.9 metres with direction held, down from about five metres. A new dodge press is buffered for 0.4 seconds, so pressing V before recovery ends can chain directly into another roll. Roll direction is locked per roll. The backward dodge is faster (0.88 seconds) while keeping the same source-synchronized travel curve and roughly two-metre distance.

Slashes play at 2.1× their source speed. Press Z during a swing to queue the next attack. Queued swings transition before the source clip's return-to-idle section, blending into the next wind-up instead of replaying its neutral opening. A press within 0.25 seconds after an unqueued attack also continues the alternating chain.

Jumping keeps the uploaded Moving Jump and Sword And Shield Jump poses. Physical takeoff follows anticipation. The authored vertical flight offset is subtracted from the model so the animation no longer adds a second arc on top of physics. Gravity slows upward velocity naturally toward the apex. Tapped and held jumps reach approximately 1.97 and 2.37 metres at the character body, retaining clearance over the 1.8-metre opponent without the earlier excessive height.

Facing stays locked during flight. Air input accelerates gradually: opposite input first brakes forward momentum, then permits a small reverse drift capped at 28% of running speed. A stationary takeoff has limited air steering in either direction. Running resumes immediately on contact if a direction is held. The stationary clip stops before its wide landing stance until actual contact, so the knight stays tucked in the air.

Crouching takes 0.15 seconds, standing up 0.18 seconds. Hold S/down and C together: Crouch Block Begin plays once, then a corrected crouched guard idle loops while crouch and guard remain held. The supplied Shield Crouch Idle contains the lowered-arm pose, so the game retains its body idle motion while holding the shield arm at the raised endpoint of Crouch Block Begin. Releasing C plays Crouch Block Begin backward into the default crouch; pressing it again while lowering reverses back into raising. Original source clips remain unchanged for preview. Attack chaining is unchanged.

## Animation assignments

| Situation | Supplied filename |
| --- | --- |
| Front hit | Impact.fbx |
| Frontal hit while guarding | Shield Impact.fbx |
| Rear hit | Back Impact.fbx |
| Crouched hit | Crouch Impact.fbx |
| Crouched frontal guard hit | Crouch Shield Impact.fbx |
| Forward roll | Sprinting Forward Roll.fbx |
| No-input dodge | Standing Dodge Backward.fbx |
| Moving / stationary jump | Moving Jump.fbx / Sword And Shield Jump.fbx |
| Alternating slashes | Sword And Shield Slash1.fbx / Sword And Shield Slash2.fbx |
| Crouch / stand | Crouch.fbx / Crouch To Standing.fbx |
| Raise shield standing / crouched | Shield Block Begin.fbx / Crouch Block Begin.fbx |
| Crouched shield idle | Shield Crouch Idle.fbx |

## Animation viewer

Press Enter to pause combat and hide the opponent. Click a filename in the scrollable list to perform it on your knight. Search filters names. Replay, Stop, Loop, speed, Turn, and Copy name help inspect clips and share choices. Enter returns to the duel without consuming health or healing charges.

There are **69 clips**: 51 from the original Pro Sword and Shield Pack, 14 organized individual uploads, and four later roll/shield uploads. Original filenames are preserved in the viewer. Run Attack and the superseded roll remain available for preview. The earlier oversized Pack 2 archive was not imported in full; separately supplied files are included.

## Implementation and validation

`arena.gd` creates the arena, camera and HUD. `fighter.gd` handles movement, combat and animation timing. `animation_viewer.gd` provides previews. `assets/knight.glb` combines the supplied knight, textures and animation clips using their shared Mixamo skeleton. Horizontal root travel is removed at runtime. No plugins or external services are needed. Asset rights remain with their creators; the uploads did not include license documents.

Focused Godot 4.6.3 headless checks passed for reversed crouched shield release, faster backstep/source travel synchronization, shorter buffered roll chaining, lower variable jump heights and apex slowdown, airborne pose timing, gradual/limited reverse air steering with locked facing, and running on landing. Previous checks verified the sustained raised shield pose and attack seams. Interactive rendering and gameplay feel were not manually tested.

For a cloud shell with a read-only home, set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` to writable directories before launching Godot.
