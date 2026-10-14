extends Control
## Separate CanvasItem keeps the terrain shader off the road's vertex colors.
var path: Control
var world_offset:=0.0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 if is_instance_valid(path) and not path.road.is_empty():
  draw_set_transform(Vector2(0,130-world_offset))
  path.paint_road(self)
  draw_set_transform(Vector2.ZERO)
