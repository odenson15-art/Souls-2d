extends Node3D
# Modeled and beveled room geometry; all illumination is evaluated in 3D.
var lamps:Array[Node3D]=[]
var lights:Array[SpotLight3D]=[]
var clock=0.0
const LAMP_POSITIONS=[Vector3(-9,4.45,-2.3),Vector3(-3,4.45,0.65),Vector3(3,4.45,-2.3),Vector3(9,4.45,0.65)]
func _ready():
 name="AshenHall"
 var room=load("res://assets/dojo/dojo.glb").instantiate();room.name="ModeledDojo";add_child(room)
 for mesh in room.find_children("*","MeshInstance3D",true,false):
  for surface in mesh.mesh.get_surface_count():
   var material=mesh.mesh.surface_get_material(surface)
   if material is BaseMaterial3D:material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 var floor_body=StaticBody3D.new();floor_body.name="DojoFloor";floor_body.position=Vector3(0,-0.2,-1.5)
 var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(26,0.4,13);collider.shape=shape
 floor_body.add_child(collider);add_child(floor_body)
 var world=WorldEnvironment.new();world.name="DojoAtmosphere"
 var env=Environment.new();env.background_mode=Environment.BG_SKY
 var sky=Sky.new();var sky_material=ProceduralSkyMaterial.new()
 sky_material.sky_top_color=Color("26374f");sky_material.sky_horizon_color=Color("6b7479")
 sky_material.ground_bottom_color=Color("24201c");sky_material.ground_horizon_color=Color("676058")
 sky_material.sky_energy_multiplier=0.45;sky.sky_material=sky_material;env.sky=sky
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9daec0");env.ambient_light_energy=0.26
 env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.fog_enabled=true;env.fog_density=0.007;env.fog_light_color=Color("26394a");env.fog_light_energy=0.35
 world.environment=env;add_child(world)
 var moon=DirectionalLight3D.new();moon.name="MoonFill";moon.rotation_degrees=Vector3(-45,-25,-8)
 moon.light_color=Color("afc7df");moon.light_energy=0.40;add_child(moon)
 var soft=SpotLight3D.new();soft.name="SoftFrontFill";soft.position=Vector3(0,4.5,4.5)
 soft.light_color=Color("d2d9dd");soft.light_energy=2.0;soft.spot_range=22;soft.spot_angle=75
 add_child(soft);soft.look_at(Vector3(0,1,0))
 for x in [-7,7]:
  var fill=OmniLight3D.new();fill.position=Vector3(x,3.2,-6.7);fill.light_color=Color("8db1d4")
  fill.light_energy=0.6;fill.omni_range=6;add_child(fill)
 for position_value in LAMP_POSITIONS:
  var pivot=Node3D.new();pivot.position=position_value;add_child(pivot);lamps.append(pivot)
  var light=SpotLight3D.new();light.name="LanternShadowLight";light.position=Vector3(0,-0.48,0)
  light.light_color=Color("ffcf95");light.light_energy=3.0;light.spot_range=10;light.spot_angle=58
  light.shadow_enabled=true;light.shadow_bias=0.025;light.shadow_normal_bias=0.35;light.shadow_blur=1.4
  pivot.add_child(light);light.look_at(Vector3(position_value.x,0,position_value.z-0.35));lights.append(light)
 add_scroll_text("ASHEN\nHALL",Vector3(0,3.55,-7.43),0.0058)
 add_scroll_text("S W O R D   P R A C T I C E",Vector3(0,2.55,-7.43),0.0014)
func add_scroll_text(text:String,pos:Vector3,pixel_size:float):
 var label=Label3D.new();label.text=text;label.position=pos;label.pixel_size=pixel_size;label.font_size=64
 label.modulate=Color("32291f");label.outline_size=0;add_child(label)
func _process(dt):
 clock+=dt
 for i in range(lamps.size()):
  lamps[i].rotation.z=sin(clock*0.7+i*1.4)*0.01
  lights[i].light_energy=3.0*(1.0+sin(clock*1.8+i*2.3)*0.025)
