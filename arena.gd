extends Node3D
var player:CharacterBody3D
var enemy:CharacterBody3D
var camera:Camera3D
var hud:Label
var hint:Label
var health:ProgressBar
var energy:ProgressBar
var enemy_health:ProgressBar
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
 bind("left",[KEY_A,KEY_LEFT]);bind("right",[KEY_D,KEY_RIGHT]);bind("attack",[KEY_Z]);bind("heavy",[KEY_X]);bind("block",[KEY_C]);bind("dodge",[KEY_V]);bind("heal",[KEY_B]);bind("restart",[KEY_R])
 var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("101827");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9ab4cf");env.ambient_light_energy=0.65;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-35,0);sun.light_color=Color("ffdda5");sun.light_energy=1.5;sun.shadow_enabled=true;add_child(sun)
 box(Vector3(0,-0.35,0),Vector3(26,0.7,6),Color("3c4554"),true)
 for x in range(-12,13,2):
  box(Vector3(x,0.015,0),Vector3(0.025,0.03,5.8),Color("677080"))
 for x in [-12,-8,-4,0,4,8,12]:
  box(Vector3(x,1.7,-3.4),Vector3(0.65,3.4,0.7),Color("293544"))
  box(Vector3(x,3.5,-3.4),Vector3(1.0,0.3,1),Color("596275"))
 for x in [-10,10]:
  box(Vector3(x,0.45,-2),Vector3(1,0.9,1),Color("242a36"))
  var fire=OmniLight3D.new();fire.position=Vector3(x,1.4,-2);fire.light_color=Color("ff913a");fire.light_energy=3;fire.omni_range=5;add_child(fire)
  box(Vector3(x,1.05,-2),Vector3(0.6,0.25,0.6),Color("ffad52"))
 box(Vector3(0,4,-3.4),Vector3(25,0.6,0.8),Color("293544"))
 player=CharacterBody3D.new();player.set_script(load("res://fighter.gd"));player.position=Vector3(-3,0.1,0);player.arena=self;add_child(player)
 enemy=CharacterBody3D.new();enemy.set_script(load("res://fighter.gd"));enemy.enemy=true;enemy.position=Vector3(3,0.1,0);enemy.arena=self;add_child(enemy);player.foe=enemy;enemy.foe=player
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=14;camera.position=Vector3(0,4.3,12);add_child(camera);camera.look_at(Vector3(0,1,0))
 var ui=CanvasLayer.new();add_child(ui)
 var panel=ColorRect.new();panel.color=Color(0.025,0.035,0.055,0.9);panel.position=Vector2(24,24);panel.size=Vector2(380,145);ui.add_child(panel)
 hud=label(ui,Vector2(42,34),24,"EMBER YARD  /  TRAINING")
 health=bar(ui,Vector2(42,78),Color("e26663"));energy=bar(ui,Vector2(42,104),Color("7fc797"))
 label(ui,Vector2(42,132),16,"HEALTH   /   STAMINA")
 label(ui,Vector2(882,35),20,"THE ASHEN SPARRING KNIGHT")
 enemy_health=bar(ui,Vector2(882,72),Color("d78761"))
 hint=label(ui,Vector2(30,570),21,"")
 label(ui,Vector2(30,655),18,"A/D  MOVE     Z  COMBO     X  HEAVY     C  GUARD     V  QUICKSTEP     B  HEAL     R  RESET")
 label(ui,Vector2(30,685),14,"ENTER  ANIMATION VIEWER  •  Hold your ground. Spend stamina wisely.")
 var viewer=CanvasLayer.new();viewer.set_script(load("res://animation_viewer.gd"));viewer.arena=self;add_child(viewer)
func box(pos:Vector3,size:Vector3,color:Color,solid=false):
 var mesh=MeshInstance3D.new();var cube=BoxMesh.new();cube.size=size;mesh.mesh=cube;mesh.position=pos
 var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.85;mesh.material_override=mat;add_child(mesh)
 if solid:
  var body=StaticBody3D.new();var col=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;col.shape=shape;body.position=pos;body.add_child(col);add_child(body)
func label(ui:Node,pos:Vector2,size:int,text:String)->Label:
 var l=Label.new();l.position=pos;l.add_theme_font_size_override("font_size",size);l.text=text;ui.add_child(l);return l
func bar(ui:Node,pos:Vector2,color:Color)->ProgressBar:
 var b=ProgressBar.new();b.position=pos;b.size=Vector2(340,18);b.show_percentage=false
 var style=StyleBoxFlat.new();style.bg_color=color;b.add_theme_stylebox_override("fill",style);ui.add_child(b);return b
func finish(lost:bool):
 finished=true;notice="YOU FELL — Recovering… Explore freely, or R to retry" if lost else "TRIAL COMPLETE — Explore freely, or R to spar again"
func _process(dt):
 if previewing:return
 if Input.is_action_just_pressed("restart"):get_tree().reload_current_scene();return
 health.value=player.hp;energy.value=player.stamina;enemy_health.value=enemy.hp
 hint.text=notice+"\n"+str(player.potions)+" healing charges  •  Quickstep costs 22 stamina"
 shake=maxf(0,shake-dt)
 camera.position.x=lerpf(camera.position.x,(player.position.x+enemy.position.x)*0.35,dt*3)+randf_range(-shake,shake)
