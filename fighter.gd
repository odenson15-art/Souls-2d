extends CharacterBody3D
var enemy=false
const MAX_HEALTH=250.0
const RUN_SPEED=5.5
const ATTACK_RATE=2.1
var hp=MAX_HEALTH
var attack_phase=0.0
var dodge_previous_distance=0.0
var backstep_motion:Curve
const CROUCH_GUARD_HOLD="__crouch_guard_hold"
var dodge_buffer=0.0
var buffered_dodge_axis=0.0
var jump_air_velocity=0.0
var jump_facing=1.0
var jump_moving=false
var jump_vertical_motion={}
var jump_hold_time=0.0
var jump_flight_start_y=0.0
var dodge_entry_speed=0.0
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
 cache_backstep_motion()
 cache_jump_vertical_motion()
 make_animations_in_place()
 build_crouch_guard_hold()
 animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
 flash=MeshInstance3D.new();var ring=TorusMesh.new();ring.inner_radius=0.38;ring.outer_radius=0.45;flash.mesh=ring;flash.position.y=0.04
 var mat=StandardMaterial3D.new();mat.albedo_color=Color(0.9,0.23,0.08) if enemy else Color(0.2,0.8,1);mat.emission_enabled=true;mat.emission=mat.albedo_color;flash.material_override=mat;add_child(flash)
func cache_backstep_motion():
 var sk=visual.find_child("Skeleton3D",true,false) as Skeleton3D
 var source=animator.get_animation("Standing Dodge Backward")
 backstep_motion=Curve.new();backstep_motion.min_value=-1;backstep_motion.max_value=4
 for track in source.get_track_count():
  if source.track_get_type(track)!=Animation.TYPE_POSITION_3D:continue
  if not str(source.track_get_path(track)).ends_with(":mixamorig_Hips"):continue
  var origin=(sk.global_basis*source.position_track_interpolate(track,0)).z
  for sample_index in range(121):
   var phase=sample_index/120.0
   var position_value=sk.global_basis*source.position_track_interpolate(track,source.length*phase)
   backstep_motion.add_point(Vector2(phase,origin-position_value.z),0,0,Curve.TANGENT_LINEAR,Curve.TANGENT_LINEAR)
func cache_jump_vertical_motion():
 var sk=visual.find_child("Skeleton3D",true,false) as Skeleton3D
 for clip in ["Moving Jump","Sword And Shield Jump"]:
  var source=animator.get_animation(clip)
  var curve=Curve.new();curve.min_value=-4;curve.max_value=4
  for track in source.get_track_count():
   if source.track_get_type(track)!=Animation.TYPE_POSITION_3D:continue
   if not str(source.track_get_path(track)).ends_with(":mixamorig_Hips"):continue
   var origin=(sk.global_basis*source.position_track_interpolate(track,0)).y
   for sample_index in range(121):
    var phase=sample_index/120.0
    var position_value=sk.global_basis*source.position_track_interpolate(track,source.length*phase)
    curve.add_point(Vector2(phase,position_value.y-origin),0,0,Curve.TANGENT_LINEAR,Curve.TANGENT_LINEAR)
  jump_vertical_motion[clip]=curve
func apply_jump_root_offset():
 # Keep the supplied poses, but do not add their authored flight arc to physics.
 var phase=animator.current_animation_position/clip_duration(jump_clip)
 visual.position.y=-maxf(0,jump_vertical_motion[jump_clip].sample(clampf(phase,0,1)))
func update_air_steering(axis:float,dt:float):
 var target=jump_air_velocity
 var acceleration=2.0
 if not is_zero_approx(axis):
  if jump_moving:
   target=jump_facing*RUN_SPEED if axis*jump_facing>0 else -jump_facing*RUN_SPEED*0.28
   acceleration=6.0 if axis*jump_facing>0 else 10.0
  else:
   target=axis*RUN_SPEED*0.35
   acceleration=6.0
 else:target=0
 jump_air_velocity=move_toward(jump_air_velocity,target,acceleration*dt)
 velocity.x=jump_air_velocity
func build_crouch_guard_hold():
 # The supplied idle repeats the lowered pose. Preserve its breathing, offset
 # around the raised-shield pose at the end of the supplied transition.
 var source=animator.get_animation("Shield Crouch Idle")
 var transition=animator.get_animation("Crouch Block Begin")
 var hold=source.duplicate(true)
 for track in hold.get_track_count():
  var reference=transition.find_track(hold.track_get_path(track),hold.track_get_type(track))
  if reference<0:continue
  if hold.track_get_type(track)==Animation.TYPE_ROTATION_3D:
   var initial=hold.rotation_track_interpolate(track,0)
   var raised=transition.rotation_track_interpolate(reference,transition.length)
   for key in hold.track_get_key_count(track):
    var original=hold.track_get_key_value(track,key)
    var path=str(hold.track_get_path(track))
    var shield_arm="mixamorig_LeftShoulder" in path or "mixamorig_LeftArm" in path or "mixamorig_LeftForeArm" in path or "mixamorig_LeftHand" in path or "mixamorig_Shield_joint" in path
    hold.track_set_key_value(track,key,raised if shield_arm else (raised*initial.inverse()*original).normalized())
  elif hold.track_get_type(track)==Animation.TYPE_POSITION_3D:
   var offset=transition.position_track_interpolate(reference,transition.length)-hold.position_track_interpolate(track,0)
   for key in hold.track_get_key_count(track):
    hold.track_set_key_value(track,key,hold.track_get_key_value(track,key)+offset)
 hold.loop_mode=Animation.LOOP_LINEAR
 animator.get_animation_library("").add_animation(CROUCH_GUARD_HOLD,hold)
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
    for key in animation.track_get_key_count(track):
     var value=basis*animation.track_get_key_value(track,key)
     value.x=0;value.z=0
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
 dodge_buffer=0
 set_crouched(false);shield_raised=false
 dodge_previous_distance=0
 dodge_entry_speed=absf(velocity.x) if signf(velocity.x)==signf(axis) else 0.0
 if is_zero_approx(axis):
  dodge_direction=-facing;dodge_clip="Standing Dodge Backward"
 else:
  dodge_direction=signf(axis);facing=dodge_direction;dodge_clip="Sprinting Forward Roll"
 begin("dodge",0.68 if dodge_clip=="Sprinting Forward Roll" else 0.88)
 play_anim(dodge_clip);animator.seek(0,true)
func start_jump(axis:float):
 set_crouched(false);shield_raised=false
 jump_clip="Moving Jump" if not is_zero_approx(axis) else "Sword And Shield Jump"
 if not is_zero_approx(axis):facing=signf(axis)
 jump_hold_time=0
 jump_facing=facing
 jump_moving=not is_zero_approx(axis)
 jump_air_velocity=axis*RUN_SPEED
 velocity.y=0
 begin("jump_start",0.12*clip_duration(jump_clip) if jump_clip=="Moving Jump" else 0.23*clip_duration(jump_clip))
 play_anim(jump_clip)
 animator.speed_scale=1.0
func jump_air_state():
 # Preserve chronological source playback across takeoff, flight and landing.
 state="jump_air";timer=0;action_duration=0
 velocity.y=11.5
 jump_flight_start_y=position.y
func jump_land_state():
 # Running resumes on contact, rather than waiting for a stationary recovery.
 if dodge_buffer>0:
  start_dodge(buffered_dodge_axis)
  return
 var axis=Input.get_axis("left","right") if not enemy else 0.0
 if not is_zero_approx(axis):
  facing=signf(axis);velocity.x=axis*RUN_SPEED
  begin("idle",0);play_anim("run",true)
  return
 state="jump_land"
 animator.play();animator.speed_scale=1.4
 timer=maxf(0.06,(clip_duration(jump_clip)-animator.current_animation_position)/1.4)
 action_duration=timer
func update_jump_air(dt:float):
 # Stop before the stationary clip opens into its wide landing/idle stance.
 var landing_phase=0.80 if jump_clip=="Moving Jump" else 0.70
 var landing_time=landing_phase*clip_duration(jump_clip)
 if animator.current_animation_position>=landing_time:
  animator.pause();apply_jump_root_offset()
  return
 var height=maxf(0,position.y-jump_flight_start_y)
 var remaining=(velocity.y+sqrt(velocity.y*velocity.y+2.0*32.0*height))/32.0
 var desired=(landing_time-animator.current_animation_position)/maxf(remaining,0.05)
 animator.speed_scale=lerpf(animator.speed_scale,clampf(desired,0.25,1.2),minf(dt*8,1.0))
 apply_jump_root_offset()
func start_guard_release():
 var source_length=clip_duration("Crouch Block Begin")
 var phase=animator.current_animation_position/source_length if state=="guard_enter" else 1.0
 phase=clampf(phase,0,1)
 shield_raised=false
 begin("guard_exit",maxf(0.04,0.22*phase))
 last_anim="Crouch Block Begin"
 animator.speed_scale=source_length/0.22
 animator.play("Crouch Block Begin",0.04,-1.0,true)
 animator.seek(source_length*phase,true)
func start_guard():
 var resume_position=animator.current_animation_position if state=="guard_exit" else 0.0
 guard_clip="Crouch Block Begin" if crouched else "Shield Block Begin"
 shield_raised=true
 begin("guard_enter",maxf(0.04,0.22*(1.0-resume_position/clip_duration(guard_clip))))
 play_anim(guard_clip)
 animator.speed_scale=clip_duration(guard_clip)/0.22
 animator.seek(resume_position,true)
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
 var blend=0.10 if state=="attack" else 0.06
 if state=="dodge":blend=0.10 if dodge_clip=="Sprinting Forward Roll" else 0.04
 elif animator.current_animation=="Sprinting Forward Roll":blend=0.12
 animator.play(key,blend)
func begin(s:String,t:float):
 state=s;timer=t;action_duration=t;struck=false;last_anim=""
 if s in ["attack","dodge","jump_start","heal","crouch_exit"]:shield_raised=false
 visual.position.y=0
func _physics_process(dt):
 if not foe:return
 timer=maxf(0,timer-dt);cooldown-=dt
 combo_window=maxf(0,combo_window-dt)
 dodge_buffer=maxf(0,dodge_buffer-dt)
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
  if not block and shield_raised and crouched and state in ["crouched","guard_enter"]:
   start_guard_release()
  elif not block:shield_raised=false
  if Input.is_action_just_pressed("dodge"):
   dodge_buffer=0.4;buffered_dodge_axis=axis
  want_crouch=Input.is_action_pressed("crouch")
  if state=="attack" and Input.is_action_just_pressed("attack"):
   combo_queued=true
  if state in ["idle","crouched"]:
   if dodge_buffer>0 and is_on_floor():
    start_dodge(buffered_dodge_axis)
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
    set_crouched(true);begin("crouch_enter",0.15)
   elif state=="crouched" and not want_crouch:
    begin("crouch_exit",0.18)
  if state in ["idle","crouched"] and block and not shield_raised:start_guard()
  if axis!=0 and state in ["idle","crouched"] and not block:facing=signf(axis)
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
    play_anim(CROUCH_GUARD_HOLD,true)
   elif last_anim!="Crouch":
    play_anim("Crouch")
    animator.seek(animator.get_animation("Crouch").length,true);animator.pause()
  "crouch_exit":
   play_anim("Crouch To Standing")
   if timer<=0:set_crouched(false);begin("idle",0)
  "guard_enter":
   play_anim(guard_clip)
   velocity.x=0 if crouched else axis*1.8
   if not block or timer<=0:
    begin("crouched" if crouched else "idle",0)
    if block:play_anim(CROUCH_GUARD_HOLD if crouched else "block idle",true)
  "guard_exit":
   if block:start_guard()
   elif timer<=0:
    begin("crouched",0)
    play_anim("Crouch");animator.seek(clip_duration("Crouch"),true);animator.pause()
  "jump_start":
   velocity.x=axis*RUN_SPEED
   if timer<=0:jump_air_state()
  "jump_air":
   update_air_steering(axis,dt)
   jump_hold_time+=dt
   update_jump_air(dt)
  "jump_land":
   if dodge_buffer>0:start_dodge(buffered_dodge_axis)
   elif not is_zero_approx(axis):
    facing=signf(axis);velocity.x=axis*RUN_SPEED;begin("idle",0);play_anim("run",true)
   else:
    apply_jump_root_offset()
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
   if backstep:
    # Use the source root travel, with the same clock as the animation.
    var distance=backstep_motion.sample(clampf(progress,0,1))
    velocity.x=dodge_direction*(distance-dodge_previous_distance)/dt
    dodge_previous_distance=distance
   else:
    # Match running pace; preserve entry momentum and blend back into a run.
    var speed=RUN_SPEED*1.05
    animator.speed_scale=lerpf(2.1,1.68,smoothstep(0,0.4,progress))
    if progress<0.08:
     speed=lerpf(dodge_entry_speed,speed,smoothstep(0,0.08,progress))
    elif progress>0.85:
     var exit_speed=RUN_SPEED if axis*dodge_direction>0 else 0.0
     speed=lerpf(speed,exit_speed,smoothstep(0.85,1.0,progress))
    velocity.x=dodge_direction*speed
   if timer<=0:
    if dodge_buffer>0:start_dodge(buffered_dodge_axis)
    else:begin("idle",0)
  "hurt":
   play_anim(reaction_clip);velocity.x=knockback_direction*(0.3 if "Shield" in reaction_clip else 1.5)
   if timer<=0:
    begin("crouched" if crouched else "idle",0)
  "heal":
   play_anim("power up")
   if timer<=0:hp=minf(MAX_HEALTH,hp+100);begin("idle",0);arena.notice="Restored 100 health"
 flash.visible=enemy and state=="windup"
 var gravity=24.0 if state=="jump_air" and velocity.y>0 and Input.is_action_pressed("jump") and jump_hold_time<0.16 else 32.0
 velocity.y-=gravity*dt
 move_and_slide();position.z=0;position.x=clampf(position.x,-11.5,11.5)
 if state=="jump_air" and is_on_floor() and velocity.y<=0:jump_land_state()
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
