extends RefCounted
## Original generated art; source rectangles are indexed, never loaded during drag.
const GEMS=preload("res://assets/casual/gems.png")
const MECHANICS=preload("res://assets/casual/mechanics.png")
const TRAITS=preload("res://assets/casual/traits.png")
const DEVICES=preload("res://assets/casual/devices.png")
const DECOR=preload("res://assets/casual/decor.png")
const UI=preload("res://assets/casual/ui.png")
static var metadata: Dictionary={}
static func region(group: String,index: int) -> Rect2:
	if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/casual/regions.json"))
	var r: Array=metadata[group].regions[index]
	return Rect2(r[0],r[1],r[2],r[3])
static func texture(group: String,index: int,source: Texture2D) -> AtlasTexture:
	var result:=AtlasTexture.new();result.atlas=source;result.region=region(group,index)
	return result
static func fit(rect: Rect2,source: Rect2) -> Rect2:
	var extent:=source.size*minf(rect.size.x/source.size.x,rect.size.y/source.size.y)
	return Rect2(rect.get_center()-extent/2,extent)

static func panel_style(index: int, tint: Color=Color.WHITE) -> StyleBoxTexture:
	var box:=StyleBoxTexture.new()
	box.texture=texture("ui",index,UI)
	var edge:=0.0
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		box.set_texture_margin(side,edge)
		box.set_content_margin(side,10)
	box.modulate_color=tint
	return box
