extends ScrollContainer
## Native Android drags, independent of mouse emulation. Children keep tap input.
var pointer:=-1
var start:=Vector2.ZERO
var last:=Vector2.ZERO
var scrolling:=false
var speed:=0.0
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():pointer=-1;speed=0;return
	if event is InputEventScreenTouch:
		if event.pressed and pointer<0 and Rect2(Vector2.ZERO,size).has_point(get_global_transform_with_canvas().affine_inverse()*event.position):
			pointer=event.index;start=event.position;last=start;scrolling=false;speed=0
		elif not event.pressed and event.index==pointer:
			if scrolling:get_viewport().set_input_as_handled()
			pointer=-1
	elif event is InputEventScreenDrag and event.index==pointer:
		var factor:=get_global_transform_with_canvas().get_scale().y
		if not scrolling and event.position.distance_to(start)>12*factor:
			scrolling=true
			for child in get_children():
				for node in child.get_children():
					if node is Button:node.set_pressed_no_signal(false)
		if scrolling:
			var movement: float=(last.y-event.position.y)/factor
			scroll_vertical+=roundi(movement);speed=movement*30
			get_viewport().set_input_as_handled()
		last=event.position
func _process(delta: float) -> void:
	if pointer<0 and absf(speed)>5:
		scroll_vertical+=roundi(speed*delta)
		speed*=exp(-delta*9)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED:pointer=-1;scrolling=false;speed=0
