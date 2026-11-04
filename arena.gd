extends Node3D
var player:CharacterBody3D
var enemy:CharacterBody3D
var camera:Camera3D
var notice="Close the distance. Watch for the red wind-up."
var finished=false
var previewing=false
var shake=0.0
func bind(action:String,keys:Array):
 if InputMap.has_action(action):return
 InputMap.add_action(action)
 for k in keys:
  var e=InputEventKey.new();e.physical_keycode=k;InputMap.action_add_event(action,e)
func _ready():
 bind("jump",[KEY_SPACE]);bind("crouch",[KEY_DOWN])
 bind("left",[KEY_LEFT]);bind("right",[KEY_RIGHT]);bind("attack",[KEY_S]);bind("strong_attack",[KEY_W]);bind("block",[KEY_D]);bind("dodge",[KEY_A]);bind("heal",[KEY_SHIFT]);bind("restart",[KEY_R])
 var dojo=Node3D.new();dojo.set_script(load("res://dojo.gd"));add_child(dojo)
 player=CharacterBody3D.new();player.set_script(load("res://fighter.gd"));player.position=Vector3(-3,0.1,0);player.arena=self;add_child(player)
 enemy=CharacterBody3D.new();enemy.set_script(load("res://fighter.gd"));enemy.enemy=true;enemy.position=Vector3(3,0.1,0);enemy.arena=self;add_child(enemy);player.foe=enemy;enemy.foe=player
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=42;camera.near=0.1;camera.far=80;camera.position=Vector3(0,2.8,10.2);add_child(camera);camera.look_at(Vector3(0,1.2,0))
 var ui=CanvasLayer.new();ui.name="HUD";add_child(ui)
 var display=Control.new();display.set_script(load("res://hud.gd"));display.arena=self;ui.add_child(display)
 var viewer=CanvasLayer.new();viewer.set_script(load("res://animation_viewer.gd"));viewer.arena=self;add_child(viewer)
func finish(lost:bool):
 finished=true;notice="YOU FELL — Recovering… Explore freely, or R to retry" if lost else "TRIAL COMPLETE — Explore freely, or R to spar again"
func _process(dt):
 if previewing:return
 if Input.is_action_just_pressed("restart"):get_tree().reload_current_scene();return
 shake=maxf(0,shake-dt)
 camera.position.x=lerpf(camera.position.x,player.position.x*0.75,dt*3)+randf_range(-shake,shake)
