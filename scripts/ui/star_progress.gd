extends Control
signal star_earned(index: int)
const Art=preload("res://scripts/ui/casual_skin.gd")
var thresholds: Array=[]
var score:=0.0
var target:=0.0
var quiet:=false
var star: AtlasTexture
var pulses: Array[float]=[0.0,0.0,0.0]
var track: StyleBoxFlat
var fill: StyleBoxFlat
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 star=Art.texture("ui",3,Art.UI)
 track=preload("res://scripts/ui/palette.gd").panel(Color("d4c4e8"),4)
 fill=preload("res://scripts/ui/palette.gd").panel(Color("ffb546"),4)
func _process(delta: float) -> void:
 var previous:=score
 var changed:=false
 if absf(score-target)>.1:
  score=target if quiet else lerpf(score,target,minf(1,delta*12));changed=true
 elif score!=target:score=target;changed=true
 for i in mini(3,thresholds.size()):
  if previous<float(thresholds[i]) and score>=float(thresholds[i]):
   pulses[i]=0 if quiet else .35
   if float(thresholds[i])>0:star_earned.emit(i)
  if pulses[i]>0:pulses[i]=maxf(0,pulses[i]-delta);changed=true
 if changed:queue_redraw()
func _draw() -> void:
 if thresholds.size()!=3 or track==null:return
 var progress:=clampf(score/maxf(1,thresholds[2]),0,1)
 var width:=maxf(1,size.x-28)
 draw_style_box(track,Rect2(14,17,width,6))
 if progress>0:draw_style_box(fill,Rect2(14,17,width*progress,6))
 for i in 3:
  var x:=14+clampf(float(thresholds[i])/thresholds[2],0,1)*width
  var magnitude:=24+4*sin(pulses[i]/.35*PI)
  if pulses[i]>0:
   draw_circle(Vector2(x,14),17,Color(1,.82,.27,pulses[i]*.6))
   for k in 4:
    var point:=Vector2(x,14)+Vector2.from_angle(k*TAU/4)*((1-pulses[i]/.35)*16+8)
    draw_circle(point,1.5,Color(1,.78,.23,pulses[i]*2))
  draw_texture_rect(star,Rect2(x-magnitude/2,14-magnitude/2,magnitude,magnitude),false,Color.WHITE if score>=thresholds[i] else Color(.65,.62,.78,.6))
