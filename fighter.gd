extends CharacterBody3D
var enemy=false
var hp=100.0
var stamina=100.0
var facing=1.0
var state="idle"
var timer=0.0
var struck=false
var cooldown=1.2
var potions=3
var combo_index=0
var combo_queued=false
var combo_window=0.0
const COMBO_CLIPS=["attack", "attack (2)", "attack (3)", "attack (4)"]
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
 visual=load("res://assets/knight.glb").instantiate();add_child(visual)
 animator=find_anim(visual)
 make_animations_in_place()
 flash=MeshInstance3D.new();var ring=TorusMesh.new();ring.inner_radius=0.38;ring.outer_radius=0.45;flash.mesh=ring;flash.position.y=0.04
 var mat=StandardMaterial3D.new();mat.albedo_color=Color(0.9,0.23,0.08) if enemy else Color(0.2,0.8,1);mat.emission_enabled=true;mat.emission=mat.albedo_color;flash.material_override=mat;add_child(flash)
func make_animations_in_place():
 # FBX hips axes differ from the scene: local Y is forward travel.
 # Remove world-horizontal translation while retaining vertical pose motion.
 var skeleton=visual.find_child("Skeleton3D",true,false) as Skeleton3D
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
func start_slash():
 stamina-=20
 combo_queued=false
 combo_window=0
 begin("attack",0.62)
func find_anim(n:Node)->AnimationPlayer:
 if n is AnimationPlayer:return n
 for c in n.get_children():
  var a=find_anim(c)
  if a:return a
 return null
func play_anim(key:String,loop=false):
 if last_anim==key:return
 last_anim=key
 if animator:
  for a in animator.get_animation_list():
   if a==key or a.ends_with("/"+key):
    animator.get_animation(a).loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
    animator.speed_scale=1.0
    if state in ["attack","heavy","heal","hurt"]:animator.speed_scale=animator.get_animation(a).length/maxf(timer,0.1)
    animator.play(a,0.12);return
func begin(s:String,t:float):
 state=s;timer=t;struck=false;last_anim=""
func _physics_process(dt):
 if not foe:return
 timer=maxf(0,timer-dt);cooldown-=dt
 combo_window=maxf(0,combo_window-dt)
 if hp<=0:
  play_anim("death");velocity=Vector3.ZERO;flash.visible=false
  if not enemy and timer<=0:
   hp=100;stamina=100;position=Vector3(-3,0.1,0);begin("idle",0)
  return
 if enemy and arena.finished:
  velocity=Vector3.ZERO;flash.visible=false;play_anim("idle",true);return
 var axis=0.0
 var block=false
 if enemy:
  facing=1.0 if foe.position.x>position.x else -1.0
  if state=="idle":
   if absf(foe.position.x-position.x)>1.85:axis=facing
   elif cooldown<=0:begin("windup",0.75)
 else:
  axis=Input.get_axis("left","right")
  block=Input.is_action_pressed("block") and stamina>1
  if state=="attack" and Input.is_action_just_pressed("attack"):
   combo_queued=true
  if state=="idle":
   if Input.is_action_just_pressed("dodge") and stamina>=22:
    stamina-=22;begin("dodge",0.32)
    if axis!=0:facing=signf(axis)
   elif Input.is_action_just_pressed("attack") and stamina>=20:
    combo_index=(combo_index+1)%4 if combo_window>0 else 0
    start_slash()
   elif Input.is_action_just_pressed("heavy") and stamina>=35:
    stamina-=35;begin("heavy",1.05)
   elif Input.is_action_just_pressed("heal") and potions>0:
    potions-=1;begin("heal",1.3)
  if axis!=0 and state=="idle" and not block:facing=signf(axis)
 visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*18)
 velocity.x=0
 match state:
  "idle":
   stamina=minf(100,stamina+dt*(10 if block else 25))
   velocity.x=axis*(1.2 if block else 3.5)
   play_anim("block idle" if block else ("run" if axis!=0 else "idle"),true)
  "windup":
   play_anim("block",false)
   flash.scale=Vector3.ONE*(1.2+sin(timer*22)*0.15)
   if timer<=0:begin("attack",0.8)
  "attack","heavy":
   play_anim(COMBO_CLIPS[combo_index] if state=="attack" else "slash (2)")
   var hit_time=0.43 if state=="attack" else 0.52
   if timer<hit_time and not struck:
    struck=true
    if absf(foe.position.x-position.x)<2.25 and (foe.position.x-position.x)*facing>0:
     foe.hurt(22 if state=="attack" else 38,self)
   if timer<=0:
    if state=="attack" and not enemy and combo_queued and stamina>=20 and combo_index<3:
     combo_index+=1;start_slash()
    else:
     combo_window=0.4 if state=="attack" else 0.0
     combo_queued=false;begin("idle",0);cooldown=1.5
  "dodge":
   play_anim("crouching",true);velocity.x=facing*7
   if timer<=0:begin("idle",0)
  "hurt":
   play_anim("impact");velocity.x=-facing*1.5
   if timer<=0:begin("idle",0)
  "heal":
   play_anim("power up")
   if timer<=0:hp=minf(100,hp+55);begin("idle",0);arena.notice="Restored 55 health"
 flash.visible=enemy and state=="windup"
 velocity.y-=20*dt
 move_and_slide();position.z=0;position.x=clampf(position.x,-11.5,11.5)
func hurt(damage:float,source:Node):
 if hp<=0 or state=="dodge" or arena.finished:return
 var guarding=not enemy and Input.is_action_pressed("block") and state=="idle" and stamina>=15 and (source.position.x-position.x)*facing>0
 if guarding:
  stamina=maxf(0,stamina-damage);hp-=damage*0.08;arena.notice="BLOCKED • stamina absorbed the blow"
 else:
  hp-=damage;begin("hurt",0.35);arena.notice="Heavy strike!" if damage>25 else "Steel meets steel"
 arena.shake=0.13
 if hp<=0:hp=0;begin("dead",2.6);arena.finish(not enemy)
