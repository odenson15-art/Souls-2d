extends CharacterBody3D
var enemy=false
const MAX_HEALTH=250.0
const RUN_SPEED=5.5
const ATTACK_RATE=2.1
var hp=MAX_HEALTH
var attack_phase=0.0
var dodge_previous_distance=0.0
var jump_hold_time=0.0
var jump_phase=0.0
var shield_raised=false
var guard_clip="Shield Block Begin"
var skeleton:Skeleton3D
var facing=1.0
var state="idle"
var timer=0.0
var struck=false
var cooldown=1.2
var potions=3
var combo_index=0
var combo_queued=false
var combo_window=0.0
const COMBO_CLIPS=["Sword And Shield Slash1", "Sword And Shield Slash2"]
var action_duration=0.0
var crouched=false
var dodge_direction=1.0
var dodge_clip="Sprinting Forward Roll"
var jump_clip="Sword And Shield Jump"
var reaction_clip="Impact"
var knockback_direction=0.0
var capsule:CapsuleShape3D
var body_shape:CollisionShape3D
var visual:Node3D
var animator:AnimationPlayer
var foe:CharacterBody3D
var arena:Node
var last_anim=""
var flash:MeshInstance3D
func _ready():
 # Fighters collide with the floor, but can cross one another.
 collision_layer=2
 collision_mask=1
 var shape=CollisionShape3D.new()
 var cap=CapsuleShape3D.new();cap.radius=0.3;cap.height=1.8
 shape.shape=cap;shape.position.y=0.9;add_child(shape)
 capsule=cap;body_shape=shape
 visual=load("res://assets/knight.glb").instantiate();add_child(visual)
 animator=find_anim(visual)
 make_animations_in_place()
 flash=MeshInstance3D.new();var ring=TorusMesh.new();ring.inner_radius=0.38;ring.outer_radius=0.45;flash.mesh=ring;flash.position.y=0.04
 var mat=StandardMaterial3D.new();mat.albedo_color=Color(0.9,0.23,0.08) if enemy else Color(0.2,0.8,1);mat.emission_enabled=true;mat.emission=mat.albedo_color;flash.material_override=mat;add_child(flash)
func make_animations_in_place():
 # FBX hips axes differ from the scene: local Y is forward travel.
 # Remove world-horizontal translation while retaining vertical pose motion.
 skeleton=visual.find_child("Skeleton3D",true,false) as Skeleton3D
 var basis=skeleton.global_transform.basis
 for library_name in animator.get_animation_library_list():
  var library=animator.get_animation_library(library_name).duplicate(true)
  animator.remove_animation_library(library_name)
  animator.add_animation_library(library_name,library)
  for name in library.get_animation_list():
   var animation=library.get_animation(name)
   for track in animation.get_track_count():
    if animation.track_get_type(track)!=Animation.TYPE_POSITION_3D:continue
    if not str(animation.track_get_path(track)).ends_with(":mixamorig_Hips"):continue
    var first=basis*animation.track_get_key_value(track,0)
    for key in animation.track_get_key_count(track):
     var value=basis*animation.track_get_key_value(track,key)
     value.x=0;value.z=0
     if name in ["Moving Jump","Sword And Shield Jump"]:value.y=first.y
     animation.track_set_key_value(track,key,basis.inverse()*value)
func clip_duration(key:String, fallback:float=0.5)->float:
 return maxf(animator.get_animation(key).length,0.1) if animator.has_animation(key) else fallback
func start_slash(chained=false):
 combo_queued=false
 combo_window=0
 attack_phase=([0.18,0.24][combo_index] if chained else 0.0)
 begin("attack",(1.0-attack_phase)*clip_duration(COMBO_CLIPS[combo_index])/ATTACK_RATE)
 play_anim(COMBO_CLIPS[combo_index])
 animator.seek(attack_phase*clip_duration(COMBO_CLIPS[combo_index]),true)
func set_crouched(value:bool):
 crouched=value
 capsule.height=1.1 if value else 1.8
 body_shape.position.y=capsule.height/2.0
func start_dodge(axis:float):
 set_crouched(false);shield_raised=false
 dodge_previous_distance=0
 if is_zero_approx(axis):
  dodge_direction=-facing;dodge_clip="Standing Dodge Backward"
 else:
  dodge_direction=signf(axis);facing=dodge_direction;dodge_clip="Sprinting Forward Roll"
 begin("dodge",0.55 if dodge_clip=="Sprinting Forward Roll" else 0.65)
func start_jump(axis:float):
 set_crouched(false);shield_raised=false
 jump_clip="Moving Jump" if not is_zero_approx(axis) else "Sword And Shield Jump"
 if not is_zero_approx(axis):facing=signf(axis)
 jump_hold_time=0
 velocity.y=0
 begin("jump_start",0.10 if jump_clip=="Moving Jump" else 0.14)
func pose_jump(phase:float,grounded=false):
 if last_anim!=jump_clip:
  play_anim(jump_clip)
 animator.pause()
 animator.seek(clampf(phase,0,1)*clip_duration(jump_clip),true)
 visual.position.y=0
 if grounded:
  skeleton.force_update_all_bone_transforms()
  var left=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_LeftToeBase")).origin).y
  var right=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightToeBase")).origin).y
  visual.position.y=position.y-minf(left,right)
func start_guard():
 guard_clip="Crouch Block Begin" if crouched else "Shield Block Begin"
 shield_raised=true
 begin("guard_enter",minf(0.22,clip_duration(guard_clip)))
func find_anim(n:Node)->AnimationPlayer:
 if n is AnimationPlayer:return n
 for c in n.get_children():
  var a=find_anim(c)
  if a:return a
 return null
func play_anim(key:String,loop=false):
 if last_anim==key:return
 last_anim=key
 if not animator.has_animation(key):return
 var animation=animator.get_animation(key)
 animation.loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
 animator.speed_scale=1.0
 if state in ["heal","hurt","dodge","crouch_enter","crouch_exit","guard_enter"]:
  animator.speed_scale=animation.length/maxf(action_duration,0.1)
 if state=="attack":animator.speed_scale=ATTACK_RATE
 elif key=="run":animator.speed_scale=1.35
 animator.play(key,0.10 if state=="attack" else 0.06)
func begin(s:String,t:float):
 state=s;timer=t;action_duration=t;struck=false;last_anim=""
 if s in ["attack","dodge","jump_start","heal","crouch_exit"]:shield_raised=false
 visual.position.y=0
func _physics_process(dt):
 if not foe:return
 timer=maxf(0,timer-dt);cooldown-=dt
 combo_window=maxf(0,combo_window-dt)
 if hp<=0:
  play_anim("death");velocity=Vector3.ZERO;flash.visible=false
  if not enemy and timer<=0:
   hp=MAX_HEALTH;position=Vector3(-3,0.1,0);set_crouched(false);begin("idle",0)
  return
 if enemy and arena.finished:
  velocity=Vector3.ZERO;flash.visible=false;play_anim("idle",true);return
 var axis=0.0
 var block=false
 var want_crouch=false
 if enemy:
  if state=="idle":
   facing=1.0 if foe.position.x>position.x else -1.0
   if absf(foe.position.x-position.x)>1.85:axis=facing
   elif cooldown<=0:begin("windup",0.75)
 else:
  axis=Input.get_axis("left","right")
  block=Input.is_action_pressed("block")
  if not block:shield_raised=false
  want_crouch=Input.is_action_pressed("crouch")
  if state=="attack" and Input.is_action_just_pressed("attack"):
   combo_queued=true
  if state in ["idle","crouched"]:
   if Input.is_action_just_pressed("dodge") and is_on_floor():
    start_dodge(axis)
   elif Input.is_action_just_pressed("jump") and is_on_floor():
    start_jump(axis)
   elif state=="idle" and Input.is_action_just_pressed("attack"):
    if not is_zero_approx(axis):facing=signf(axis)
    var chained=combo_window>0
    combo_index=1-combo_index if chained else 0
    start_slash(chained)
   elif state=="idle" and Input.is_action_just_pressed("heal") and potions>0:
    potions-=1;begin("heal",1.3)
   elif state=="idle" and want_crouch and is_on_floor():
    set_crouched(true);begin("crouch_enter",clip_duration("Crouch"))
   elif state=="crouched" and not want_crouch:
    begin("crouch_exit",clip_duration("Crouch To Standing"))
  if state in ["idle","crouched"] and block and not shield_raised:start_guard()
  if axis!=0 and state in ["idle","crouched","jump_air"] and not block:facing=signf(axis)
 visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*18)
 velocity.x=0
 match state:
  "idle":
   velocity.x=axis*(1.8 if block else RUN_SPEED)
   play_anim("block idle" if block else ("run" if axis!=0 else "idle"),true)
  "crouch_enter":
   play_anim("Crouch")
   if timer<=0:state="crouched"
  "crouched":
   # Keep the final crouch pose; a standing guard must not replace it.
   if block:
    play_anim("Shield Crouch Idle",true)
   elif last_anim!="Crouch":
    play_anim("Crouch")
    animator.seek(animator.get_animation("Crouch").length,true);animator.pause()
  "crouch_exit":
   play_anim("Crouch To Standing")
   if timer<=0:set_crouched(false);begin("idle",0)
  "guard_enter":
   play_anim(guard_clip)
   velocity.x=0 if crouched else axis*1.8
   if not block or timer<=0:begin("crouched" if crouched else "idle",0)
  "jump_start":
   velocity.x=axis*RUN_SPEED
   var takeoff=0.12 if jump_clip=="Moving Jump" else 0.23
   pose_jump((1.0-timer/action_duration)*takeoff,true)
   if timer<=0:
    begin("jump_air",0);velocity.y=9.5
    jump_phase=takeoff
  "jump_air":
   velocity.x=axis*RUN_SPEED
   jump_hold_time+=dt
   if not Input.is_action_pressed("jump") and velocity.y>4.0:velocity.y=4.0
   var takeoff=0.12 if jump_clip=="Moving Jump" else 0.23
   var landing=0.89 if jump_clip=="Moving Jump" else 0.80
   # Follow physical ascent/descent, never return to idle while airborne.
   if velocity.y>0:
    jump_phase=maxf(jump_phase,lerpf(takeoff,0.5,1.0-clampf(velocity.y/9.5,0,1)))
   else:
    jump_phase=lerpf(0.5,landing,1.0-clampf(position.y/1.5,0,1))
   pose_jump(jump_phase)
  "jump_land":
   var landing=0.89 if jump_clip=="Moving Jump" else 0.80
   pose_jump(lerpf(landing,1.0,1.0-timer/action_duration),true)
   if timer<=0:begin("idle",0)
  "windup":
   play_anim("block",false)
   flash.scale=Vector3.ONE*(1.2+sin(timer*22)*0.15)
   if timer<=0:combo_index=0;start_slash()
  "attack":
   play_anim(COMBO_CLIPS[combo_index])
   attack_phase+=dt*ATTACK_RATE/clip_duration(COMBO_CLIPS[combo_index])
   if attack_phase>=0.42 and not struck:
    struck=true
    if absf(foe.position.x-position.x)<2.25 and absf(foe.position.y-position.y)<1.2 and (foe.position.x-position.x)*facing>0:
     foe.hurt(22,self)
   # Chain out before the authored return-to-idle, into the next wind-up.
   var chain_cut=[0.66,0.76][combo_index]
   if not enemy and combo_queued and attack_phase>=chain_cut:
    combo_index=1-combo_index;start_slash(true)
   elif timer<=0:
    combo_window=0.25;combo_queued=false;begin("idle",0);cooldown=1.2
  "dodge":
   play_anim(dodge_clip)
   var progress=1.0-timer/action_duration
   var backstep=dodge_clip=="Standing Dodge Backward"
   var start=0.18 if backstep else 0.05
   var end=0.50 if backstep else 0.80
   var u=clampf((progress-start)/(end-start),0,1)
   var distance=(1.35 if backstep else 3.16875)*smoothstep(0,1,u)
   velocity.x=dodge_direction*(distance-dodge_previous_distance)/dt
   dodge_previous_distance=distance
   if timer<=0:begin("idle",0)
  "hurt":
   play_anim(reaction_clip);velocity.x=knockback_direction*(0.3 if "Shield" in reaction_clip else 1.5)
   if timer<=0:
    begin("crouched" if crouched else "idle",0)
  "heal":
   play_anim("power up")
   if timer<=0:hp=minf(MAX_HEALTH,hp+100);begin("idle",0);arena.notice="Restored 100 health"
 flash.visible=enemy and state=="windup"
 var gravity=12.0 if state=="jump_air" and velocity.y>0 and Input.is_action_pressed("jump") and jump_hold_time<0.22 else 26.0
 velocity.y-=gravity*dt
 move_and_slide();position.z=0;position.x=clampf(position.x,-11.5,11.5)
 if state=="jump_air" and is_on_floor() and velocity.y<=0:begin("jump_land",0.14)
func hurt(damage:float,source:Node):
 if hp<=0 or state=="dodge" or arena.finished:return
 var behind=(source.position.x-position.x)*facing<0
 var guard_state=state in ["idle","crouched","crouch_enter","hurt","guard_enter"]
 var guarding=not enemy and Input.is_action_pressed("block") and guard_state and not behind
 if guarding:
  hp-=damage*0.08
  reaction_clip="Crouch Shield Impact" if crouched else "Shield Impact"
  arena.notice="BLOCKED • shield absorbed the blow"
 else:
  hp-=damage
  reaction_clip="Back Impact" if behind else ("Crouch Impact" if crouched else "Impact")
  arena.notice="Heavy strike!" if damage>25 else "Steel meets steel"
 knockback_direction=signf(position.x-source.position.x)
 combo_queued=false;combo_window=0
 begin("hurt",clip_duration(reaction_clip))
 arena.shake=0.13
 if hp<=0:hp=0;set_crouched(false);begin("dead",2.6);arena.finish(not enemy)
