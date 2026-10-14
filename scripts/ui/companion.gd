extends TextureRect
const ATLAS=preload("res://assets/casual/piril.png")
var creature:=0
var quiet:=false
var base_y:=0.0
var clock:=0.0
var reaction_tween: Tween
static func sprite(index: int) -> AtlasTexture:
	var result:=AtlasTexture.new();result.atlas=ATLAS
	var tile:=ATLAS.get_size()/Vector2(3,2)
	result.region=Rect2(Vector2(index%3,int(index/3))*tile,tile)
	return result
func _ready() -> void:
	texture=sprite(creature);expand_mode=TextureRect.EXPAND_IGNORE_SIZE;stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter=Control.MOUSE_FILTER_IGNORE;base_y=position.y;pivot_offset=size/2
func react(kind: String) -> void:
	if quiet:return
	if reaction_tween and reaction_tween.is_running():reaction_tween.kill()
	reaction_tween=create_tween()
	modulate=Color("b9c6dc") if kind=="sad" else Color.WHITE
	reaction_tween.tween_property(self,"scale",Vector2(1.14,1.14) if kind!="sad" else Vector2(.94,.94),.12)
	reaction_tween.tween_property(self,"scale",Vector2.ONE,.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func _process(delta: float) -> void:
	if quiet:return
	clock+=delta;position.y=base_y+sin(clock*1.8)*2
