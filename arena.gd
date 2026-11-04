extends Node3D
var player:CharacterBody3D
var enemy:CharacterBody3D
var camera:Camera3D
var hud:Label
var hint:Label
var health:ProgressBar
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
 bind("jump",[KEY_SPACE]);bind("crouch",[KEY_S,KEY_DOWN])
 bind("left",[KEY_A,KEY_LEFT]);bind("right",[KEY_D,KEY_RIGHT]);bind("attack",[KEY_Z]);bind("block",[KEY_C]);bind("dodge",[KEY_V]);bind("heal",[KEY_B]);bind("restart",[KEY_R])
 var dojo=Node3D.new();dojo.set_script(load("res://dojo.gd"));add_child(dojo)
 player=CharacterBody3D.new();player.set_script(load("res://fighter.gd"));player.position=Vector3(-3,0.1,0);player.arena=self;add_child(player)
 enemy=CharacterBody3D.new();enemy.set_script(load("res://fighter.gd"));enemy.enemy=true;enemy.position=Vector3(3,0.1,0);enemy.arena=self;add_child(enemy);player.foe=enemy;enemy.foe=player
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=42;camera.near=0.1;camera.far=80;camera.position=Vector3(0,3.6,10.2);add_child(camera);camera.look_at(Vector3(0,1.2,0))
 var ui=CanvasLayer.new();add_child(ui)
 var panel=ColorRect.new();panel.color=Color(0.025,0.035,0.055,0.9);panel.position=Vector2(24,24);panel.size=Vector2(380,120);ui.add_child(panel)
 hud=label(ui,Vector2(42,34),24,"ASHEN HALL  /  DOJO")
 health=bar(ui,Vector2(42,78),Color("e26663"));health.max_value=player.MAX_HEALTH
 label(ui,Vector2(42,106),16,"HEALTH")
 label(ui,Vector2(882,35),20,"THE MIRROR KNIGHT")
 enemy_health=bar(ui,Vector2(882,72),Color("d78761"));enemy_health.max_value=enemy.MAX_HEALTH
 hint=label(ui,Vector2(30,570),21,"")
 label(ui,Vector2(30,655),18,"A/D  MOVE     Z  COMBO     C  GUARD     V  DODGE     B  HEAL     R  RESET")
 label(ui,Vector2(30,685),14,"SPACE  JUMP     S / ↓  CROUCH     ENTER  ANIMATION VIEWER")
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
 health.value=player.hp;enemy_health.value=enemy.hp
 hint.text=notice+"\n"+str(player.potions)+" healing charges  •  Hold SPACE for a higher jump"
 shake=maxf(0,shake-dt)
 camera.position.x=lerpf(camera.position.x,player.position.x*0.75,dt*3)+randf_range(-shake,shake)
