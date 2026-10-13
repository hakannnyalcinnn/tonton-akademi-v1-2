extends Control
const Art=preload("res://scripts/ui/casual_skin.gd")
var thresholds: Array=[]
var score:=0.0
var target:=0.0
var quiet:=false
var star: AtlasTexture
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	star=Art.texture("ui",3,Art.UI)
func _process(delta: float) -> void:
	if absf(score-target)<.1:
		if score!=target:score=target;queue_redraw()
		return
	score=target if quiet else lerpf(score,target,minf(1,delta*12))
	queue_redraw()
func _draw() -> void:
	if thresholds.size()!=3:return
	var progress:=clampf(score/maxf(1,thresholds[2]),0,1)
	draw_style_box(preload("res://scripts/ui/palette.gd").panel(Color("e7d8ef"),5),Rect2(0,9,size.x,8))
	if progress>0:draw_style_box(preload("res://scripts/ui/palette.gd").panel(Color("ffb546"),5),Rect2(0,9,size.x*progress,8))
	for i in 3:
		var x:=clampf(float(thresholds[i])/thresholds[2],.08,.96)*size.x
		draw_texture_rect(star,Rect2(x-12,0,24,24),false,Color.WHITE if score>=thresholds[i] else Color(.7,.75,.85,.55))
