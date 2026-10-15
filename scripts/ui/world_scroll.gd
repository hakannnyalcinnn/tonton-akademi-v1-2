extends ScrollContainer
## One gesture owns either scrolling or a release tap, including mouse emulation.
var pointer:=-1
var start:=Vector2.ZERO
var last:=Vector2.ZERO
var scrolling:=false
var speed:=0.0
var blocked:=false
var cancelled:=false
var pressed_at:=0
var mouse_down:=false
func suspend(value: bool) -> void:
 blocked=value;pointer=-1;mouse_down=false;speed=0;scrolling=false;cancelled=true
 set_process_input(not value)
func may_select() -> bool:
 return not blocked and not cancelled and not scrolling and absf(speed)<5
func contains(point: Vector2) -> bool:
 return Rect2(Vector2.ZERO,size).has_point(get_global_transform_with_canvas().affine_inverse()*point)
func begin(point: Vector2) -> void:
 cancelled=absf(speed)>5;speed=0;start=point;last=point;scrolling=false;pressed_at=Time.get_ticks_msec()
func move_pointer(point: Vector2) -> void:
 var factor:=maxf(.01,get_global_transform_with_canvas().get_scale().y)
 # 16 screen-scaled logical pixels; independent of the board's cell geometry.
 var threshold:=16*factor
 if OS.get_name()=="Android":threshold=maxf(12*factor,16*clampf(float(DisplayServer.screen_get_dpi())/160.0,1.0,4.0))
 if point.distance_to(start)>threshold:scrolling=true;cancelled=true
 if scrolling:
  var movement: float=(last.y-point.y)/factor
  scroll_vertical+=roundi(movement);speed=movement*30
  get_viewport().set_input_as_handled()
 last=point
func end() -> void:
 if Time.get_ticks_msec()-pressed_at>650:cancelled=true
 if scrolling or cancelled:get_viewport().set_input_as_handled()
 pointer=-1;mouse_down=false;scrolling=false
func _input(event: InputEvent) -> void:
 if blocked or not is_visible_in_tree():return
 if event is InputEventScreenTouch:
  if event.pressed and pointer<0 and contains(event.position):pointer=event.index;begin(event.position)
  elif not event.pressed and event.index==pointer:end()
 elif event is InputEventScreenDrag and event.index==pointer:move_pointer(event.position)
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
  if event.pressed and contains(event.position):mouse_down=true;begin(event.position)
  elif not event.pressed and mouse_down:end()
 elif event is InputEventMouseMotion and mouse_down:move_pointer(event.position)
func _process(delta: float) -> void:
 if blocked:return
 if pointer<0 and not mouse_down and absf(speed)>5:
  var prior:=scroll_vertical;scroll_vertical+=roundi(speed*delta)
  speed=0 if prior==scroll_vertical else speed*exp(-delta*9)
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED:suspend(blocked)
