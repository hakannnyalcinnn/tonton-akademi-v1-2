extends RefCounted
## Shared PRIZMA surfaces, typography and hit targets for every world.
const Art=preload("res://scripts/ui/casual_skin.gd")
const INK=Color("243754")
const ACCENT=Color("6244a5")
const GOLD=Color("ffc76b")
const BOARD_Y=238.0
const MAP_TOP=126.0
const MAP_BOTTOM=858.0
const MODAL=Rect2(54,266,432,444)
static func surface(light: bool=true) -> StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=Color("faf1e7") if light else Color(.16,.16,.30,.94)
 s.border_color=Color("dfb977") if light else Color("9294db");s.set_border_width_all(2);s.set_corner_radius_all(24)
 s.shadow_color=Color(.07,.08,.16,.28);s.shadow_size=8;s.shadow_offset=Vector2(0,5)
 return s
static func action(primary: bool=false,pressed: bool=false) -> StyleBoxTexture:
 var s:=StyleBoxTexture.new();s.texture=preload("res://assets/casual/action-primary.svg") if primary else preload("res://assets/casual/action-secondary.svg")
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:s.set_texture_margin(side,18);s.set_content_margin(side,8)
 s.modulate_color=Color(.92,.92,.92) if pressed else Color.WHITE
 return s
static func icon(group: String,index: int) -> Texture2D:
 return Art.texture(group,index,{"gems":Art.GEMS,"ui":Art.UI,"devices":Art.DEVICES}[group])
