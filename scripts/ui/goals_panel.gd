extends Control
signal goal_pressed(key: String)
signal goal_completed(key: String)
const Registry=preload("res://scripts/ui/goal_registry.gd")
const Objectives=preload("res://scripts/mechanics/objective_manager.gd")
var targets: Dictionary={}
var amounts: Dictionary={}
var displayed: Dictionary={}
var pulses: Dictionary={}
var rects: Dictionary={}
var remaining_mode:=false
var quiet:=false
var offset:=0.0
var pressed_key:=""
var finger_y:=0.0
var dragged:=false
var content_height:=112.0
var font: Font
var styles: Array[StyleBoxFlat]=[]
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 clip_contents=true
 font=ThemeDB.fallback_font
 for done in [false,true]:
  var box:=StyleBoxFlat.new();box.bg_color=Color("f0fff6") if done else Color("fff9ec");box.border_color=Color("6cce8b") if done else Color("e6c78a");box.set_border_width_all(2);box.set_corner_radius_all(12);styles.append(box)
func configure(definition: Dictionary,progress: Dictionary) -> void:
 targets=definition.duplicate();amounts.clear();displayed.clear();pulses.clear();rects.clear();offset=0
 var columns:=mini(3,targets.size())
 var rows:=ceili(float(targets.size())/columns)
 var stride:=50.0 if rows>2 else 56.0
 content_height=maxf(112,rows*stride+(12 if rows>2 else 0))
 var height:=112.0 if rows==1 else stride
 var width:=minf(156,480.0/columns)
 var left:=(480-width*columns)/2
 var i:=0
 for key in targets:
  amounts[key]=mini(int(targets[key]),Objectives.value(progress,key));displayed[key]=float(amounts[key]);pulses[key]=0.0
  rects[key]=Rect2(left+(i%columns)*width+3,(i/columns)*height+2,width-6,height-4)
  Registry.icon(key);i+=1
 queue_redraw()
func update_progress(progress: Dictionary,animate: bool=true) -> void:
 for key in targets:
  var value:=mini(int(targets[key]),Objectives.value(progress,key))
  if value>int(amounts[key]):
   pulses[key]=.38 if animate and not quiet else 0.0
   if value>=int(targets[key]):goal_completed.emit(key)
  amounts[key]=value
  if not animate or quiet:displayed[key]=float(value)
 queue_redraw()
func _process(delta: float) -> void:
 var changed:=false
 for key in targets:
  if absf(float(displayed[key])-float(amounts[key]))>.01:
   displayed[key]=move_toward(float(displayed[key]),float(amounts[key]),delta*maxf(16,absf(float(displayed[key])-float(amounts[key]))*12));changed=true
  elif displayed[key]!=float(amounts[key]):displayed[key]=float(amounts[key]);changed=true
  if pulses[key]>0:pulses[key]=maxf(0,pulses[key]-delta);changed=true
 if changed:queue_redraw()
func key_at(point: Vector2) -> String:
 for key in rects:
  if rects[key].has_point(point+Vector2(0,offset)):return key
 return ""
func _gui_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch or event is InputEventMouseButton:
  if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   offset=clampf(offset+(32 if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else -32),0,content_height-112);queue_redraw();accept_event();return
  if event is InputEventMouseButton and event.button_index!=MOUSE_BUTTON_LEFT:return
  if event.pressed:pressed_key=key_at(event.position);finger_y=event.position.y;dragged=false
  else:
   if not dragged and pressed_key!="" and key_at(event.position)==pressed_key:goal_pressed.emit(pressed_key)
   pressed_key=""
  accept_event()
 elif event is InputEventScreenDrag:
  if absf(event.position.y-finger_y)>6:dragged=true
  offset=clampf(offset-event.relative.y,0,content_height-112);queue_redraw();accept_event()
func _draw() -> void:
 if font==null:return
 for key in rects:
  var r: Rect2=rects[key];r.position.y-=offset
  var done:=int(amounts[key])>=int(targets[key])
  draw_style_box(styles[1 if done else 0],r)
  var icon_size:=64.0 if r.size.y>80 else (30.0 if content_height>112 else 34.0)
  var icon_rect:=Rect2(r.get_center().x-icon_size/2,r.position.y+4,icon_size,icon_size)
  if pulses[key]>0:draw_circle(icon_rect.get_center(),icon_size*.55,Color(1,.85,.35,float(pulses[key])*.5))
  if key=="total":
   for i in 3:draw_texture_rect(Registry.icon(str(i)),Rect2(icon_rect.position+Vector2(i*icon_size*.22,0),Vector2(icon_size*.62,icon_size*.85)),false)
  else:draw_texture_rect(Registry.icon(key),preload("res://scripts/ui/casual_skin.gd").fit(icon_rect,Rect2(Vector2.ZERO,Registry.icon(key).get_size())),false)
  if key.begins_with("shield"):
   var color:=int(key.trim_prefix("shield"))
   draw_texture_rect(Registry.icon(str(color)),Rect2(icon_rect.get_center()-Vector2(9,9),Vector2(18,18)),false)
  var text:="Kalan %d"%maxi(0,int(targets[key])-int(amounts[key])) if remaining_mode else "%d/%d"%[roundi(float(displayed[key])),int(targets[key])]
  draw_string(font,Vector2(r.get_center().x-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,r.end.y-5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("425877"))
  if done:
   var art=preload("res://scripts/ui/casual_skin.gd");draw_texture_rect_region(art.ADVANCED,Rect2(r.end.x-25,r.position.y+3,22,22),art.region("advanced",7))
 if content_height>112:
  draw_rect(Rect2(474,offset/content_height*112,4,112*112/content_height),Color("62b9b0"))
  draw_rect(Rect2(0,100,470,12),Color("fff9ec"))
  draw_string(font,Vector2(6,110),"%d hedef · kaydır"%targets.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("426176"))
