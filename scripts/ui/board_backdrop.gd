extends Control
## Original high-resolution vector frame: a single cached texture draw for 72
## wells and metallic edges. The grid remains at the same exact cell positions.
const FRAME = preload("res://assets/casual/board-frame.svg")
const OCEAN=preload("res://assets/casual/board-ocean.svg")
var world:=1
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_texture_rect(OCEAN if world==2 else FRAME,Rect2(-12,-12,500,560),false)
