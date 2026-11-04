"""Run with Blender 4: blender -b --python tools/build_dojo.py. Coordinates below use Godot axes."""
import bpy, math, os, random
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(28)
def xyz(p): return (p[0],-p[2],p[1])
def mat(name,color,rough=.6,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
wood=mat('Oiled cedar',(0.28,.16,.08),.65)
p=wood.node_tree.nodes.get('Principled BSDF');nodes=wood.node_tree.nodes;links=wood.node_tree.links
for file,socket in [('cedar_albedo.png','Base Color'),('cedar_roughness.png','Roughness')]:
 t=nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/'assets/dojo'/file));t.image.colorspace_settings.name='sRGB' if socket=='Base Color' else 'Non-Color';links.new(t.outputs['Color'],p.inputs[socket])
t=nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/'assets/dojo/cedar_normal.png'));t.image.colorspace_settings.name='Non-Color'
normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.45;links.new(t.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],p.inputs['Normal'])
woods=[wood]
for i in range(4):
 m=wood.copy();m.name='Cedar tone '+str(i)
 principled=m.node_tree.nodes.get('Principled BSDF');mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.85+i*.075,.86+i*.07,.88+i*.065,1)
 source=next(t for t in m.node_tree.nodes if t.type=='TEX_IMAGE' and t.image.name.startswith('cedar_albedo'))
 m.node_tree.links.new(source.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],principled.inputs['Base Color']);woods.append(m)
dark=mat('Smoked oak',(0.055,.035,.024),.5);brass=mat('Aged bronze',(.34,.25,.12),.33,.72)
stone=mat('Charcoal foundation',(.085,.10,.105),.85);plaster=mat('Lime plaster',(.49,.45,.36),.95)
paper=mat('Rice paper',(.60,.64,.59),.95);cream=mat('Scroll silk',(.66,.56,.36),.88)
indigo=mat('Indigo linen',(.028,.065,.09),.96);red=mat('Oxblood linen',(.20,.035,.025),.95)
cord=mat('Hemp cord',(.26,.20,.12),.98);green=mat('Bamboo leaves',(.06,.12,.048),.8)
water=mat('Basin water',(.035,.075,.07),.12,.25)
lamp=mat('Lantern silk',(.83,.61,.32),.8)
bs=lamp.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=(1,.55,.19,1);bs.inputs['Emission Strength'].default_value=.55
meshes=[]
def uv_project(o):
 mesh=o.data
 uv=mesh.uv_layers.active or mesh.uv_layers.new()
 for poly in mesh.polygons:
  axes=sorted(range(3),key=lambda i:abs(poly.normal[i]))[:2]
  axes.sort(key=lambda i:o.dimensions[i],reverse=True)
  for li in poly.loop_indices:
   co=mesh.vertices[mesh.loops[li].vertex_index].co
   uv.data[li].uv=(co[axes[0]]*.45,co[axes[1]]*2.4)
def finish(o,name,material,bevel=.0):
 o.name=name;o.data.materials.append(material)
 if bevel:
  mod=o.modifiers.new('Rounded joinery','BEVEL');mod.width=bevel;mod.segments=3
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
  mod=o.modifiers.new('Crafted normals','WEIGHTED_NORMAL');mod.keep_sharp=True
  bpy.ops.object.modifier_apply(modifier=mod.name)
 meshes.append(o);return o
def box(name,pos,size,m=wood,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(pos));o=bpy.context.object;o.dimensions=xyz((size[0],size[1],-size[2]))
 o.dimensions=(abs(size[0]),abs(size[2]),abs(size[1]));bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 uv_project(o);return finish(o,name,m,min(bevel,min(size)*.22))
def cyl(name,pos,r,h,m=wood,vertices=24):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=h,location=xyz(pos));o=bpy.context.object
 return finish(o,name,m,min(.012,h*.1))
def torus(name,pos,major,minor,m=brass):
 bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=xyz(pos),major_radius=major,minor_radius=minor)
 return finish(bpy.context.object,name,m)
def pole(name,a,b,r,m=wood):
 a,b=Vector(xyz(a)),Vector(xyz(b));mid=(a+b)*.5
 bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=(b-a).length,location=mid)
 o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return finish(o,name,m,.007)
def cloth(name,x,z,m):
 verts=[];faces=[];nx,ny=10,24
 for j in range(ny+1):
  for i in range(nx+1):
   xx=x+(i/nx-.5)*.85;yy=4.45-j/ny*2.6;zz=z+math.sin(i/nx*math.pi*5)*.045+math.sin(j/ny*4)*.04
   verts.append(xyz((xx,yy,zz)))
 for j in range(ny):
  for i in range(nx):
   a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
 solid=o.modifiers.new('Woven thickness','SOLIDIFY');solid.thickness=.008
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.modifier_apply(modifier=solid.name);o.select_set(False)
 return finish(o,name,m)
# Floor is continuous geometry in depth, not a painted backdrop.
box('Stone foundation',(0,-.26,-1.5),(27,.42,13.5),stone,.045)
for row in range(36):
 z=-7.8+row*.35
 for col in range(10):
  left=-13+col*2.8+(1.4 if row%2 else 0);right=min(left+2.8,13)
  left=max(left,-13)
  if right>left:box('Beveled floorboard',((left+right)/2,-.035,z),(right-left-.006,.07,.344),random.choice(woods),.005)
 if row%2:box('Staggered board',(-12.3,-.035,z),(1.394,.07,.344),wood,.005)
for z in [-1.35,1.35]:box('Training lane inlay',(0,.002,z),(23,.004,.024),dark,.001)
for x in [-11.5,11.5]:box('Lane end',(x,.002,0),(.024,.004,2.7),dark,.001)
# Recessed architecture and colonnade, several metres behind combat.
box('Rear wall',(0,3.1,-8.0),(27,6.2,.3),plaster,.04)
box('Low wall wainscot',(0,.6,-7.78),(26,1.2,.14),wood)
for x in [-13,-9,-4.5,4.5,9,13]:
 box('Rear column',(x,3,-7.5),(.28,6,.38),dark,.035)
 box('Column stone shoe',(x,.16,-7.5),(.48,.32,.58),stone,.035)
for x in [-12.8,12.8]:
 box('Side wall',(x,3,-1.7),(.3,6.0,12.6),plaster,.03)
 for z in [-7.5,-3.0,3.9]:
  box('Side depth column',(x,3,z),(.34,6,.38),dark,.04)
  box('Side column shoe',(x,.16,z),(.58,.32,.65),stone,.035)
for x in [-6.7,6.7,-11.0,11.0]:
 width=3.6 if abs(x)<10 else 3.3
 box('Recessed shoji frame',(x,3.0,-7.65),(width+.2,3.7,.16),dark,.025)
 box('Inset rice paper',(x,3.0,-7.49),(width,3.5,.035),paper,.003)
 for k in range(11):box('Shoji upright',(x-width/2+k*width/10,3,-7.40),(.025,3.55,.045),dark,.003)
 for y in [1.25,1.9,2.55,3.2,3.85,4.5,4.75]:box('Shoji crosspiece',(x,y,-7.39),(width+.05,.032,.05),dark,.004)
 for dx in [-width/2,width/2]:cyl('Door pin',(x+dx,1.1,-7.34),.022,.15,brass)
for y in [1.1,4.95,5.9]:box('Wall molding',(0,y,-7.45),(26,.13,.24),dark,.018)
for x in [-9,-4.5,4.5,9]:
 box('Colonnade post',(x,2.55,-4.9),(.23,5.1,.23),dark,.035)
 box('Plinth',(x,.12,-4.9),(.44,.24,.44),stone,.025)
box('Colonnade header',(0,5.15,-4.9),(26,.32,.32),dark,.04)
for x in [-12,-8,-4,4,8,12]:
 box('Deep ceiling rafter',(x,5.9,-1.4),(.18,.3,13),dark,.025)
for z in [-7.4,-4.9,-1.5,2.5]:box('Ceiling crossbeam',(0,6.1,z),(26,.24,.25),wood,.03)
# Tokonoma alcove: two real steps, a back panel, scroll and incense table.
box('Alcove rear',(0,2.85,-7.7),(7.5,5.6,.23),dark,.03)
box('Alcove lower step',(0,.09,-6.95),(6.5,.18,1.8),wood,.02)
box('Alcove upper step',(0,.24,-7.15),(5.9,.16,1.35),wood,.02)
box('Scroll hanging cloth',(0,3.25,-7.49),(1.8,2.85,.025),cream,.002)
for y in [1.8,4.7]:pole('Scroll roller',(-1,y,-7.42),(1,y,-7.42),.038,brass)
box('Small ceremonial table',(0,.9,-7.0),(2.0,.13,.65),dark,.03)
for x in [-.8,.8]:box('Table leg',(x,.59,-7.0),(.11,.65,.45),dark,.02)
cyl('Incense vessel',(0,1.05,-6.98),.15,.15,brass)
for x in [-.045,0,.045]:pole('Incense stick',(x,1.1,-6.98),(x,1.4,-6.98),.004,dark)
for x in [-2.5,2.5]:
 cloth('Hanging practice banner',x,-7.3,indigo if x<0 else red)
 crest=torus('Banner bronze crest',(x,3.2,-7.15),.19,.012,brass);crest.rotation_euler.x=math.pi/2
 for dx in [-.085,0,.085]:
  mark=box('Banner embroidered crest',(x+dx,3.2,-7.13),(.023,.34,.012),brass,.003);mark.rotation_euler.y=-.22
# Proper round lanterns, with ribs, end caps and chains.
lamps=[(-9,4.45,-2.3),(-3,4.45,.65),(3,4.45,-2.3),(9,4.45,.65)]
for x,y,z in lamps:
 cyl('Lantern silk chamber',(x,y,z),.30,.72,lamp,24)
 for yy in [y-.4,y+.4]:
  cyl('Lantern cap',(x,yy,z),.34,.075,dark,24);torus('Cap bronze edging',(x,yy,z),.32,.016,brass)
 for i in range(12):
  angle=i*math.tau/12;dx=math.cos(angle)*.306;dz=math.sin(angle)*.306
  pole('Lantern vertical rib',(x+dx,y-.38,z+dz),(x+dx,y+.38,z+dz),.008,brass)
 for yy in [y-.19,y+.19]:torus('Paper support ring',(x,yy,z),.305,.009,dark)
 pole('Suspension chain',(x,y+.45,z),(x,6.05,z),.012,brass)
# Bokken racks, rounded handles and lacquered guards.
for x in [-7.0,7.0]:
 z=-6.65
 for dx in [-1.0,1.0]:
  box('Rack foot',(x+dx,.12,z),(.35,.24,.7),dark,.025);box('Rack upright',(x+dx,1.2,z),(.10,2.1,.12),wood,.015)
 for yy in [.55,1.25,1.95]:box('Rack shelf',(x,yy,z),(2.2,.08,.27),dark,.012)
 for i in range(6):
  xx=x-.78+i*.3
  pole('Bokken blade',(xx,.42,z+.14),(xx+.08,1.60,z+.14),.028,wood)
  pole('Wrapped handle',(xx+.08,1.62,z+.14),(xx+.1,1.96,z+.14),.033,dark)
  for j in range(7):torus('Handle wrapping',(xx+.08,1.65+j*.04,z+.14),.034,.006,cord)
  cyl('Bokken guard',(xx+.08,1.61,z+.14),.095,.035,brass,16)
# Practice dummies and bound straw targets in the deeper aisles.
for x in [-10.4,10.4]:
 z=-5.65
 cyl('Dummy support',(x,.8,z),.08,1.6,dark)
 for dx,dz in [(-.5,.32),(.5,.32),(0,-.5)]:pole('Tripod base',(x,.25,z),(x+dx,.04,z+dz),.045,wood)
 cyl('Straw target',(x,1.5,z),.23,.9,cord)
 for yy in [1.11,1.25,1.4,1.55,1.7,1.88]:torus('Target binding',(x,yy,z),.232,.016,dark)
 pole('Dummy arms',(x-.65,1.63,z),(x+.65,1.63,z),.055,wood)
# Back-side benches, rolled mats and a stone water basin.
for x in [-5.4,5.4]:
 box('Gallery bench',(x,.55,-5.8),(2,.12,.62),wood,.035)
 for dx in [-.75,.75]:box('Bench support',(x+dx,.28,-5.8),(.12,.5,.55),dark,.018)
 for dx in [-.4,0,.4]:cyl('Rolled straw mat',(x+dx,1.0,-6.0),.14,.75,cord)
cyl('Stone basin pedestal',(-11.4,.42,-6.7),.36,.84,stone,32)
torus('Stone basin rim',(-11.4,.86,-6.7),.42,.09,stone)
cyl('Water surface',(-11.4,.84,-6.7),.35,.015,water,32)
for i in range(3):
 xx=-11.7+i*.18
 pole('Bamboo stem',(xx,.1,-7.1),(xx+.12,2.45+i*.2,-7.1),.035,wood)
 for h in [1.1,1.5,1.9,2.3]:
  pole('Bamboo node',(xx-.045,h,-7.1),(xx+.08,h,-7.1),.038,dark)
  for side in [-1,1]:
   o=box('Bamboo leaf',(xx+side*.18,h+.1,-7.05),(.32,.025,.08),green,.01);o.rotation_euler.y=side*.4
# Join by material for manageable draw counts; all shapes remain genuine 3D.
bpy.ops.object.select_all(action='DESELECT')
for material in list(bpy.data.materials):
 group=[o for o in list(bpy.data.objects) if o.type=='MESH' and material in list(o.data.materials)]
 if not group:continue
 for o in group:o.select_set(True)
 bpy.context.view_layer.objects.active=group[0]
 if len(group)>1:bpy.ops.object.join()
 group[0].name='Dojo '+material.name
 bpy.ops.object.select_all(action='DESELECT')
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/dojo/dojo.glb'),export_format='GLB',export_animations=False)
print('DOJO MODEL COMPLETE')
