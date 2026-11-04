extends Control
# Quiet combat HUD: health, remaining flasks, and a brief duel result.
var arena:Node
var player_trail=1.0
var enemy_trail=1.0
var result_time=0.0
var was_finished=false
const GOLD=Color("a48e60")
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(dt):
 visible=not arena.previewing
 var player_ratio=clampf(arena.player.hp/arena.player.MAX_HEALTH,0,1)
 var enemy_ratio=clampf(arena.enemy.hp/arena.enemy.MAX_HEALTH,0,1)
 player_trail=move_toward(maxf(player_trail,player_ratio),player_ratio,dt*0.24)
 enemy_trail=move_toward(maxf(enemy_trail,enemy_ratio),enemy_ratio,dt*0.24)
 if arena.finished and not was_finished:result_time=3.2
 was_finished=arena.finished
 result_time=maxf(0,result_time-dt)
 queue_redraw()
func meter(rect:Rect2,ratio:float,trail:float):
 draw_rect(rect.grow(3),Color(0.025,0.02,0.018,0.8))
 draw_rect(rect.grow(3),GOLD.darkened(0.3),false,1)
 draw_rect(rect,Color("251c1b"))
 if trail>0:draw_rect(Rect2(rect.position,Vector2(rect.size.x*trail,rect.size.y)),Color("a48a56"))
 if ratio>0:
  draw_rect(Rect2(rect.position,Vector2(rect.size.x*ratio,rect.size.y)),Color("8d2928"))
  draw_line(rect.position+Vector2(0,2),rect.position+Vector2(rect.size.x*ratio,2),Color("bd5550"),1)
func _draw():
 if not is_instance_valid(arena):return
 # Fixed design coordinates match the 1280x720 stretched viewport.
 meter(Rect2(70,40,300,13),arena.player.hp/arena.player.MAX_HEALTH,player_trail)
 draw_circle(Vector2(45,46),15,Color("1e1b18"))
 draw_arc(Vector2(45,46),15,0,TAU,48,GOLD,1.5,true)
 draw_colored_polygon(PackedVector2Array([Vector2(45,36),Vector2(50,46),Vector2(45,56),Vector2(40,46)]),Color("823b30"))
 # A small flask silhouette and charge pips replace explanatory text.
 var gold=GOLD if arena.player.potions>0 else GOLD.darkened(0.65)
 draw_style_box(flask_frame(),Rect2(28,619,52,65))
 draw_colored_polygon(PackedVector2Array([Vector2(48,631),Vector2(60,631),Vector2(60,643),Vector2(66,650),Vector2(65,668),Vector2(43,668),Vector2(42,650),Vector2(48,643)]),gold)
 draw_line(Vector2(46,631),Vector2(62,631),Color("e0c795"),3,true)
 for i in range(3):draw_circle(Vector2(39+i*15,695),2.3,GOLD if i<arena.player.potions else Color("352f27"))
 if arena.enemy.hp>0:
  meter(Rect2(350,660,580,9),arena.enemy.hp/arena.enemy.MAX_HEALTH,enemy_trail)
 if result_time>0:
  var alpha=minf(1,result_time)*minf(1,(3.2-result_time)*3)
  draw_rect(Rect2(0,293,1280,105),Color(0.015,0.012,0.008,alpha*0.65))
  var text="YOU DIED" if arena.enemy.hp>0 else "TRIAL COMPLETE"
  var font=ThemeDB.fallback_font
  var text_width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,34).x
  draw_string(font,Vector2((1280-text_width)/2,358),text,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color(0.68,0.54,0.32,alpha))
func flask_frame()->StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=Color(0.025,0.02,0.015,0.55)
 style.set_border_width_all(1);style.border_color=GOLD.darkened(0.4)
 return style
