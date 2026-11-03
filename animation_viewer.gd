extends CanvasLayer

var arena:Node3D
var active=false
var panel:PanelContainer
var list:VBoxContainer
var search:LineEdit
var title:Label
var loop_toggle:CheckBox
var speed: HSlider
var selected=""
var entries:Array[Dictionary]=[]
var saved_player:Transform3D
var saved_enemy:Transform3D
var saved_rotation:Vector3
var saved_camera:Transform3D
var saved_camera_size=14.0
var saved_player_physics=true
var saved_enemy_physics=true

func _ready():
 layer=5
 panel=PanelContainer.new();panel.position=Vector2(20,185);panel.size=Vector2(460,455);add_child(panel)
 var style=StyleBoxFlat.new();style.bg_color=Color(0.035,0.045,0.065,0.97)
 for edge in ["content_margin_left","content_margin_right","content_margin_top","content_margin_bottom"]:style.set(edge,12.0)
 panel.add_theme_stylebox_override("panel",style)
 var column=VBoxContainer.new();panel.add_child(column)
 var heading=Label.new();heading.text="ANIMATION VIEWER  •  Enter to close";column.add_child(heading)
 search=LineEdit.new();search.placeholder_text="Filter by original FBX filename…";search.text_changed.connect(rebuild_list);column.add_child(search)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(430,245);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
 list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 title=Label.new();title.text="Choose a filename to play it";title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(title)
 var row=HBoxContainer.new();column.add_child(row)
 button(row,"Replay",replay)
 button(row,"Stop",func():arena.player.animator.pause())
 loop_toggle=CheckBox.new();loop_toggle.text="Loop";loop_toggle.button_pressed=true;loop_toggle.focus_mode=Control.FOCUS_NONE;loop_toggle.toggled.connect(func(_v):replay());row.add_child(loop_toggle)
 button(row,"Turn",func():arena.player.visual.rotation.y+=PI/2)
 button(row,"Copy name",func():
  if selected!="":DisplayServer.clipboard_set(filename_for(selected)))
 var speed_row=HBoxContainer.new();column.add_child(speed_row)
 var caption=Label.new();caption.text="Speed";speed_row.add_child(caption)
 speed=HSlider.new();speed.min_value=0.25;speed.max_value=2;speed.step=0.25;speed.value=1;speed.size_flags_horizontal=Control.SIZE_EXPAND_FILL;speed_row.add_child(speed)
 var rate=Label.new();rate.text="1.00×";speed_row.add_child(rate)
 speed.value_changed.connect(func(value):arena.player.animator.speed_scale=value;rate.text="%.2f×"%value)
 for clip in arena.player.animator.get_animation_list():
  if clip=="RESET":continue
  var organized=clip[0]==clip[0].to_upper()
  var file=clip if organized or clip.begins_with("draw ") or clip.begins_with("sheath ") else "sword and shield "+clip
  entries.append({"clip":clip,"file":file+".fbx","pack":"Organized animations" if organized else "Pro Sword and Shield Pack"})
 entries.sort_custom(func(a,b):return a.file.naturalnocasecmp_to(b.file)<0)
 rebuild_list("");panel.hide()

func button(parent:Node,text:String,callback:Callable):
 var b=Button.new();b.text=text;b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(callback);parent.add_child(b)

func filename_for(clip:String)->String:
 for entry in entries:
  if entry.clip==clip:return entry.file
 return clip

func rebuild_list(filter_text:String):
 for child in list.get_children():
  list.remove_child(child);child.queue_free()
 for entry in entries:
  if not filter_text.is_empty() and not filter_text.to_lower() in entry.file.to_lower():continue
  var b=Button.new();b.text=entry.file;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.focus_mode=Control.FOCUS_NONE;b.tooltip_text=entry.pack
  b.pressed.connect(select_clip.bind(entry.clip));list.add_child(b)

func _input(event):
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ENTER:
  toggle();get_viewport().set_input_as_handled()

func toggle():
 active=not active
 arena.previewing=active
 panel.visible=active
 if active:
  saved_player=arena.player.transform;saved_enemy=arena.enemy.transform
  saved_rotation=arena.player.visual.rotation
  saved_camera=arena.camera.transform;saved_camera_size=arena.camera.size
  saved_player_physics=arena.player.is_physics_processing();saved_enemy_physics=arena.enemy.is_physics_processing()
  arena.player.set_physics_process(false);arena.enemy.set_physics_process(false)
  arena.enemy.hide();arena.player.flash.hide()
  arena.player.position=Vector3(2,0,0);arena.player.visual.rotation=Vector3(0,PI/4,0)
  arena.camera.position=Vector3(0,3.3,10);arena.camera.look_at(Vector3(0,1,0));arena.camera.size=9
  search.release_focus()
  if selected.is_empty():select_clip(entries[0].clip)
  else:replay()
 else:
  arena.player.animator.stop();arena.player.last_anim=""
  arena.player.transform=saved_player;arena.enemy.transform=saved_enemy
  arena.player.visual.rotation=saved_rotation
  arena.camera.transform=saved_camera;arena.camera.size=saved_camera_size
  arena.player.begin("dead" if arena.player.hp<=0 else "idle",2.6 if arena.player.hp<=0 else 0)
  arena.player.velocity=Vector3.ZERO
  arena.player.set_crouched(false)
  arena.enemy.show();arena.player.set_physics_process(saved_player_physics);arena.enemy.set_physics_process(saved_enemy_physics)

func select_clip(clip:String):
 selected=clip
 title.text=filename_for(clip)
 replay()

func replay():
 if selected.is_empty():return
 var animator=arena.player.animator
 var animation=animator.get_animation(selected)
 animation.loop_mode=Animation.LOOP_LINEAR if loop_toggle.button_pressed else Animation.LOOP_NONE
 animator.stop();animator.speed_scale=speed.value;animator.play(selected,0.0);animator.advance(0)
