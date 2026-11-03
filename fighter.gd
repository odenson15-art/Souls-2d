extends CharacterBody3D
var enemy=false
const MAX_HEALTH=250.0
const RUN_SPEED=5.5
const ATTACK_RATE=2.1
var hp=MAX_HEALTH
var attack_phase=0.0
var attack_previous_distance=0.0
var attack_motion={}
var combo_roll_opener=false
var roll_attack_window=0.0
var roll_attack_buffer=0.0
var roll_attack_input_axis=0.0
var roll_finishing=false
var roll_exit_clip=""
const ROLL_ATTACK_SOURCE="Sword And Shield Attack (1)"
const ROLL_ATTACK_CLIP="__roll_attack"
const ROLL_ATTACK_RECOVERY="__roll_attack_recover"
const ROLL_STOP_CLIP="__roll_stop"
const ROLL_ATTACK_END=1.55
const ROLL_FOLLOW_SOURCE="Sword And Shield Slash (1)"
const ROLL_FOLLOW_CLIP="__roll_followup"
const ROLL_FOLLOW_RECOVERY="__roll_followup_recover"
const ROLL_FOLLOW_START=0.2
const ROLL_FOLLOW_END=2.0
const ROLL_FOLLOW_HIT=1.2666667
const TURN_SOURCE="Sword And Shield 180 Turn (1)"
const TURN_CLIP="__running_turn"
const LAND_STOP_CLIP="__landing_stop"
var turn_yaw:Curve
var turn_start_yaw=0.0
var turn_from_facing=1.0
var jump_visual_base=0.0
var landing_contact_time=0.0
const ROLL_ATTACK_HIT=0.7333333
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
var combo_presses=0
const PLAYER_COMBO_RATE=1.8
const COMBO_SOURCE="One Hand Sword Combo"
const COMBO_STARTS=[0.1666667,1.4,2.4333333]
const COMBO_ENDS=[1.4,2.4333333,3.4]
const COMBO_STRIKES=[0.9666667,1.9333333,2.9666667]
const COMBO_CLIPS=["__combo_1","__combo_2","__combo_3"]
const COMBO_RECOVERIES=["__combo_recover_1","__combo_recover_2","__combo_recover_3"]
const ENEMY_ATTACK_CLIP="Sword And Shield Slash1"
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
 cache_attack_motion()
 cache_turn_yaw()
 make_animations_in_place()
 build_crouch_guard_hold()
 build_attack_stages()
 build_roll_clips()
 build_turn_clip()
 animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
 animator.mixer_applied.connect(correct_jump_contact)
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
func cache_attack_motion():
 var sk=visual.find_child("Skeleton3D",true,false) as Skeleton3D
 for clip in [COMBO_SOURCE,ROLL_ATTACK_SOURCE,ROLL_FOLLOW_SOURCE,TURN_SOURCE]:
  var source=animator.get_animation(clip)
  var curve=Curve.new();curve.min_value=-20;curve.max_value=20
  for track in source.get_track_count():
   if source.track_get_type(track)!=Animation.TYPE_POSITION_3D:continue
   if not str(source.track_get_path(track)).ends_with(":mixamorig_Hips"):continue
   var origin=(sk.global_basis*source.position_track_interpolate(track,0)).z
   for sample_index in range(301):
    var phase=sample_index/300.0
    var position_value=sk.global_basis*source.position_track_interpolate(track,source.length*phase)
    curve.add_point(Vector2(phase,position_value.z-origin),0,0,Curve.TANGENT_LINEAR,Curve.TANGENT_LINEAR)
  attack_motion[clip]=curve
func cache_turn_yaw():
 var sk=visual.find_child("Skeleton3D",true,false) as Skeleton3D
 var source=animator.get_animation(TURN_SOURCE)
 var axes=sk.global_basis.orthonormalized()
 turn_yaw=Curve.new();turn_yaw.min_value=-8;turn_yaw.max_value=8
 for track in source.get_track_count():
  if source.track_get_type(track)!=Animation.TYPE_ROTATION_3D or not str(source.track_get_path(track)).ends_with(":mixamorig_Hips"):continue
  var initial=source.rotation_track_interpolate(track,0)
  var previous=0.0
  for i in range(181):
   var phase=i/180.0
   var q=source.rotation_track_interpolate(track,source.length*phase)
   var delta=axes*Basis(q*initial.inverse())*axes.inverse()
   var angle=atan2(delta.z.x,delta.z.z)
   if i>0:angle=previous+wrapf(angle-previous,-PI,PI)
   turn_yaw.add_point(Vector2(phase,angle),0,0,Curve.TANGENT_LINEAR,Curve.TANGENT_LINEAR)
   previous=angle
func build_turn_clip():
 var source=animator.get_animation(TURN_SOURCE).duplicate(true)
 var axes=skeleton.global_basis.orthonormalized()
 for track in source.get_track_count():
  if source.track_get_type(track)!=Animation.TYPE_ROTATION_3D or not str(source.track_get_path(track)).ends_with(":mixamorig_Hips"):continue
  for key in source.track_get_key_count(track):
   var phase=source.track_get_key_time(track,key)/source.length
   var parent_yaw=(axes.inverse()*Basis(Vector3.UP,turn_yaw.sample(phase))*axes).get_rotation_quaternion()
   var q=source.track_get_key_value(track,key)
   source.track_set_key_value(track,key,(parent_yaw.inverse()*q).normalized())
 animator.get_animation_library("").add_animation(TURN_CLIP,source)
func start_turn():
 turn_from_facing=facing
 turn_start_yaw=facing*PI/2
 visual.rotation.y=turn_start_yaw
 attack_previous_distance=0
 begin("turn",clip_duration(TURN_SOURCE)/1.35)
 play_anim(TURN_CLIP);animator.seek(0,true)
func correct_jump_contact():
 var active=state in ["jump_start","jump_air","jump_land"] or landing_contact_time>0
 if not active:return
 visual.position.y=jump_visual_base
 skeleton.force_update_all_bone_transforms()
 var left=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_LeftToeBase")).origin).y
 var right=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightToeBase")).origin).y
 var lowest=minf(left,right)
 if is_on_floor() or state=="jump_start":visual.position.y+=0.004-lowest
 elif lowest<0.004:visual.position.y+=0.004-lowest
func apply_attack_motion(source:String,start:float,end:float,elapsed:float,dt:float):
 var curve=attack_motion[source]
 var length=clip_duration(source)
 var distance=curve.sample(clampf((start+elapsed)/length,start/length,end/length))-curve.sample(start/length)
 velocity.x=facing*(distance-attack_previous_distance)/dt
 attack_previous_distance=distance
func active_attack_clip()->String:
 if enemy:return ENEMY_ATTACK_CLIP
 if combo_roll_opener and combo_index==0:return ROLL_ATTACK_CLIP
 if combo_roll_opener and combo_index==1:return ROLL_FOLLOW_CLIP
 return COMBO_CLIPS[combo_index]
func active_recovery_clip()->String:
 if combo_roll_opener and combo_index==0:return ROLL_ATTACK_RECOVERY
 if combo_roll_opener and combo_index==1:return ROLL_FOLLOW_RECOVERY
 return COMBO_RECOVERIES[combo_index]
func apply_jump_root_offset():
 # Keep the supplied poses, but do not add their authored flight arc to physics.
 var phase=animator.current_animation_position/clip_duration(jump_clip)
 jump_visual_base=-maxf(0,jump_vertical_motion[jump_clip].sample(clampf(phase,0,1)))
 visual.position.y=jump_visual_base
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
func sample_transform_track(animation:Animation,track:int,time:float):
 match animation.track_get_type(track):
  Animation.TYPE_POSITION_3D:return animation.position_track_interpolate(track,time)
  Animation.TYPE_ROTATION_3D:return animation.rotation_track_interpolate(track,time)
  Animation.TYPE_SCALE_3D:return animation.scale_track_interpolate(track,time)
 return null
func slice_animation(source:Animation,start:float,end:float)->Animation:
 var result=Animation.new();result.length=end-start
 for track in source.get_track_count():
  var type=source.track_get_type(track)
  if type not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:continue
  var copy=result.add_track(type)
  result.track_set_path(copy,source.track_get_path(track))
  result.track_set_interpolation_type(copy,source.track_get_interpolation_type(track))
  result.track_insert_key(copy,0,sample_transform_track(source,track,start))
  for key in source.track_get_key_count(track):
   var time=source.track_get_key_time(track,key)
   if time>start and time<end:result.track_insert_key(copy,time-start,source.track_get_key_value(track,key))
  result.track_insert_key(copy,result.length,sample_transform_track(source,track,end))
 return result
func make_pose_recovery(source:Animation,end:float,duration:float)->Animation:
 var idle=animator.get_animation("idle")
 var recovery=Animation.new();recovery.length=duration
 for track in source.get_track_count():
  var type=source.track_get_type(track)
  if type not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:continue
  var path=source.track_get_path(track)
  var idle_track=idle.find_track(path,type)
  var from_pose=sample_transform_track(source,track,end)
  var to_pose=sample_transform_track(idle,idle_track,0) if idle_track>=0 else from_pose
  var copy=recovery.add_track(type);recovery.track_set_path(copy,path)
  for step in range(9):
   var phase=step/8.0
   var weight=smoothstep(0,1,phase)
   var pose=from_pose.slerp(to_pose,weight) if type==Animation.TYPE_ROTATION_3D else from_pose.lerp(to_pose,weight)
   recovery.track_insert_key(copy,phase*duration,pose)
 return recovery
func build_attack_stages():
 var source=animator.get_animation(COMBO_SOURCE)
 var library=animator.get_animation_library("")
 for stage in range(3):
  library.add_animation(COMBO_CLIPS[stage],slice_animation(source,COMBO_STARTS[stage],COMBO_ENDS[stage]))
  var recovery:Animation
  if stage<2:recovery=make_pose_recovery(source,COMBO_ENDS[stage],0.28 if stage==0 else 0.32)
  else:recovery=slice_animation(source,COMBO_ENDS[stage],minf(4.1666667,source.length))
  library.add_animation(COMBO_RECOVERIES[stage],recovery)
func build_roll_clips():
 var source=animator.get_animation(ROLL_ATTACK_SOURCE)
 var library=animator.get_animation_library("")
 library.add_animation(ROLL_ATTACK_CLIP,slice_animation(source,0,ROLL_ATTACK_END))
 library.add_animation(ROLL_ATTACK_RECOVERY,slice_animation(source,ROLL_ATTACK_END,minf(1.7333333,source.length)))
 var follow=animator.get_animation(ROLL_FOLLOW_SOURCE)
 library.add_animation(ROLL_FOLLOW_CLIP,slice_animation(follow,ROLL_FOLLOW_START,ROLL_FOLLOW_END))
 library.add_animation(ROLL_FOLLOW_RECOVERY,slice_animation(follow,ROLL_FOLLOW_END,minf(2.4333333,follow.length)))
 var roll=animator.get_animation("Sprinting Forward Roll")
 library.add_animation(ROLL_STOP_CLIP,make_pose_recovery(roll,roll.length*0.80,0.14))
func start_roll_attack():
 var axis=roll_attack_input_axis if roll_attack_buffer>0 else Input.get_axis("left","right")
 if not is_zero_approx(axis):facing=signf(axis)
 visual.rotation.y=facing*PI/2
 combo_index=0;combo_presses=0;combo_roll_opener=true
 roll_attack_window=0;roll_attack_buffer=0;dodge_buffer=0
 start_slash()
func start_slash():
 attack_phase=0;attack_previous_distance=0
 var clip=active_attack_clip()
 var rate=ATTACK_RATE if enemy else PLAYER_COMBO_RATE
 begin("attack",clip_duration(clip)/rate)
 play_anim(clip)
 animator.seek(0,true)
func start_attack_recovery():
 attack_phase=0;attack_previous_distance=0
 var clip=active_recovery_clip()
 var rate=PLAYER_COMBO_RATE if combo_index==2 or combo_roll_opener else 1.0
 begin("attack_recover",clip_duration(clip)/rate)
 play_anim(clip)
func set_crouched(value:bool):
 crouched=value
 capsule.height=1.1 if value else 1.8
 body_shape.position.y=capsule.height/2.0
func start_dodge(axis:float):
 dodge_buffer=0
 roll_attack_window=0;roll_attack_buffer=0;roll_finishing=false;roll_exit_clip=""
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
 landing_contact_time=0.20
 if dodge_buffer>0:
  start_dodge(buffered_dodge_axis)
  return
 var axis=Input.get_axis("left","right") if not enemy else 0.0
 if axis*facing<0:
  start_turn()
 elif not is_zero_approx(axis):
  velocity.x=axis*RUN_SPEED;begin("idle",0);play_anim("run",true)
 else:
  # Replace the moving clip's running tail with a landing-to-idle recovery.
  var from_pose=animator.get_animation(jump_clip)
  var recovery=make_pose_recovery(from_pose,animator.current_animation_position,0.14)
  var library=animator.get_animation_library("")
  if library.has_animation(LAND_STOP_CLIP):library.remove_animation(LAND_STOP_CLIP)
  library.add_animation(LAND_STOP_CLIP,recovery)
  begin("jump_land",0.14);play_anim(LAND_STOP_CLIP)
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
 if state in ["heal","hurt","crouch_enter","crouch_exit","guard_enter","attack_recover","jump_land","turn"] or (state=="dodge" and key==dodge_clip):
  animator.speed_scale=animation.length/maxf(action_duration,0.1)
 if state=="attack":animator.speed_scale=ATTACK_RATE if enemy else PLAYER_COMBO_RATE
 elif key=="run":animator.speed_scale=1.35
 var blend=0.03 if state=="attack" else 0.06
 if state=="attack_recover":blend=0.02
 if key==ROLL_FOLLOW_CLIP and animator.current_animation==ROLL_ATTACK_CLIP:blend=0.12
 if key==COMBO_CLIPS[2] and animator.current_animation==ROLL_FOLLOW_CLIP:blend=0.12
 if state=="turn":blend=0.08
 if key==LAND_STOP_CLIP:blend=0.025
 if state=="dodge":blend=0.10 if key==dodge_clip and dodge_clip=="Sprinting Forward Roll" else 0.04
 if state=="dodge" and key in ["idle","run"]:blend=0.10
 if key==ROLL_STOP_CLIP:blend=0.02
 elif animator.current_animation=="Sprinting Forward Roll":blend=0.12
 animator.play(key,blend)
func begin(s:String,t:float):
 state=s;timer=t;action_duration=t;struck=false;last_anim=""
 if s in ["attack","dodge","jump_start","heal","crouch_exit"]:shield_raised=false
 jump_visual_base=0;visual.position.y=0
func _physics_process(dt):
 if not foe:return
 timer=maxf(0,timer-dt);cooldown-=dt
 dodge_buffer=maxf(0,dodge_buffer-dt)
 roll_attack_window=maxf(0,roll_attack_window-dt)
 roll_attack_buffer=maxf(0,roll_attack_buffer-dt)
 landing_contact_time=maxf(0,landing_contact_time-dt)
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
  if Input.is_action_just_pressed("attack"):
   if state=="dodge" and (roll_finishing or timer<action_duration*0.4):
    roll_attack_input_axis=axis
    roll_attack_buffer=maxf(0.25,timer+0.05)
   elif state=="attack":combo_presses=mini(combo_presses+1,2-combo_index)
   elif state=="attack_recover" and combo_index<2:
    combo_index+=1;start_slash()
  if state in ["idle","crouched"]:
   if dodge_buffer>0 and is_on_floor():
    start_dodge(buffered_dodge_axis)
   elif Input.is_action_just_pressed("jump") and is_on_floor():
    start_jump(axis)
   elif state=="idle" and Input.is_action_just_pressed("attack"):
    if not is_zero_approx(axis):facing=signf(axis)
    if roll_attack_window>0:start_roll_attack()
    else:
     combo_index=0;combo_presses=0;combo_roll_opener=false
     start_slash()
   elif state=="idle" and Input.is_action_just_pressed("heal") and potions>0:
    potions-=1;begin("heal",1.3)
   elif state=="idle" and want_crouch and is_on_floor():
    set_crouched(true);begin("crouch_enter",0.15)
   elif state=="crouched" and not want_crouch:
    begin("crouch_exit",0.18)
   elif state=="idle" and axis*facing<0 and absf(velocity.x)>RUN_SPEED*0.3 and not block and is_on_floor():
    start_turn()
  if state in ["idle","crouched"] and block and not shield_raised:start_guard()
  if axis!=0 and state in ["idle","crouched"] and not block:facing=signf(axis)
 if state!="turn":visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*18)
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
   velocity.x=jump_air_velocity if jump_moving else 0.0
   if timer<=0:jump_air_state()
  "jump_air":
   update_air_steering(axis,dt)
   jump_hold_time+=dt
   update_jump_air(dt)
  "jump_land":
   if dodge_buffer>0:start_dodge(buffered_dodge_axis)
   elif not is_zero_approx(axis):
    if axis*facing<0:start_turn()
    else:velocity.x=axis*RUN_SPEED;begin("idle",0);play_anim("run",true)
   elif timer<=0:begin("idle",0)
  "turn":
   play_anim(TURN_CLIP)
   var phase=clampf(1.0-timer/action_duration,0,1)
   visual.rotation.y=turn_start_yaw+turn_yaw.sample(phase)
   apply_attack_motion(TURN_SOURCE,0,clip_duration(TURN_SOURCE),phase*clip_duration(TURN_SOURCE),dt)
   if timer<=0:
    facing=-turn_from_facing
    begin("idle",0)
    play_anim("run" if not is_zero_approx(axis) else "idle",true)
  "windup":
   play_anim("block",false)
   flash.scale=Vector3.ONE*(1.2+sin(timer*22)*0.15)
   if timer<=0:combo_index=0;start_slash()
  "attack":
   var clip=active_attack_clip()
   var rate=ATTACK_RATE if enemy else PLAYER_COMBO_RATE
   play_anim(clip)
   attack_phase+=dt*rate
   var hit_time=clip_duration(clip)*0.42 if enemy else (ROLL_ATTACK_HIT if combo_roll_opener and combo_index==0 else (ROLL_FOLLOW_HIT-ROLL_FOLLOW_START if combo_roll_opener and combo_index==1 else COMBO_STRIKES[combo_index]-COMBO_STARTS[combo_index]))
   if not enemy:
    if combo_roll_opener and combo_index==0:apply_attack_motion(ROLL_ATTACK_SOURCE,0,ROLL_ATTACK_END,attack_phase,dt)
    elif combo_roll_opener and combo_index==1:apply_attack_motion(ROLL_FOLLOW_SOURCE,ROLL_FOLLOW_START,ROLL_FOLLOW_END,attack_phase,dt)
    else:apply_attack_motion(COMBO_SOURCE,COMBO_STARTS[combo_index],COMBO_ENDS[combo_index],attack_phase,dt)
   if attack_phase>=hit_time and not struck:
    struck=true
    if absf(foe.position.x-position.x)<2.25 and absf(foe.position.y-position.y)<1.2 and (foe.position.x-position.x)*facing>0:
     foe.hurt(22,self)
   if timer<=0:
    if enemy:begin("idle",0);cooldown=1.2
    elif combo_presses>0 and combo_index<2:
     combo_presses-=1;combo_index+=1;start_slash()
    else:start_attack_recovery()
  "attack_recover":
   play_anim(active_recovery_clip())
   if combo_roll_opener and combo_index==0:
    attack_phase+=dt*PLAYER_COMBO_RATE
    apply_attack_motion(ROLL_ATTACK_SOURCE,ROLL_ATTACK_END,minf(1.7333333,clip_duration(ROLL_ATTACK_SOURCE)),attack_phase,dt)
   elif combo_roll_opener and combo_index==1:
    attack_phase+=dt*PLAYER_COMBO_RATE
    apply_attack_motion(ROLL_FOLLOW_SOURCE,ROLL_FOLLOW_END,minf(2.4333333,clip_duration(ROLL_FOLLOW_SOURCE)),attack_phase,dt)
   elif combo_index==2:
    attack_phase+=dt*PLAYER_COMBO_RATE
    apply_attack_motion(COMBO_SOURCE,COMBO_ENDS[2],4.1666667,attack_phase,dt)
   if timer<=0:
    combo_presses=0;combo_index=0;begin("idle",0)
  "dodge":
   if not roll_finishing:play_anim(dodge_clip)
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
    if not roll_finishing:
     animator.speed_scale=lerpf(2.1,1.68,smoothstep(0,0.4,progress))
     if animator.current_animation_position/clip_duration(dodge_clip)>=0.80:
      roll_finishing=true
      roll_exit_clip=ROLL_STOP_CLIP if is_zero_approx(axis) else "run"
      play_anim(roll_exit_clip,roll_exit_clip=="run")
      if roll_exit_clip==ROLL_STOP_CLIP:animator.speed_scale=clip_duration(ROLL_STOP_CLIP)/maxf(timer,0.04)
    elif not is_zero_approx(axis) and roll_exit_clip==ROLL_STOP_CLIP:
     roll_exit_clip="run";play_anim("run",true)
    elif is_zero_approx(axis) and roll_exit_clip=="run":
     roll_exit_clip="idle";play_anim("idle",true)
    if progress<0.08:
     speed=lerpf(dodge_entry_speed,speed,smoothstep(0,0.08,progress))
    elif progress>0.85:
     var exit_speed=RUN_SPEED if axis*dodge_direction>0 else 0.0
     speed=lerpf(speed,exit_speed,smoothstep(0.85,1.0,progress))
    velocity.x=dodge_direction*speed
   if (roll_finishing or (backstep and timer<=0)) and roll_attack_buffer>0:
    start_roll_attack()
   elif timer<=0:
    if dodge_buffer>0:start_dodge(buffered_dodge_axis)
    else:
     roll_attack_window=0.22
     begin("idle",0)
     play_anim("idle" if is_zero_approx(axis) else "run",true)
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
 combo_presses=0;roll_attack_window=0;roll_attack_buffer=0
 begin("hurt",clip_duration(reaction_clip))
 arena.shake=0.13
 if hp<=0:hp=0;set_crouched(false);begin("dead",2.6);arena.finish(not enemy)
