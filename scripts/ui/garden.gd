extends Control
const WorldArt=preload("res://scripts/ui/world_art_cache.gd")
var pending_art:=""
const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
const Palette = preload("res://scripts/ui/palette.gd")
## Calm, layered world; monochrome slowly restores with collected color energy.
var world:=1
var world_completed:=false
var shader_completed:=-1.0
var last_flow:=0.0
var quality := "balanced"
var refresh_age := 0.0
var backdrop: TextureRect
var vitality: float = 0.35
var clock: float = 0.0
var reduced_motion := false
var artwork: Texture2D
var displayed_vitality := 0.2
var color_energy: Array = [0, 0, 0, 0, 0]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color_material := ShaderMaterial.new()
	color_material.shader = load("res://assets/art/restore_color.gdshader")

	if ResourceLoader.exists("res://assets/casual/world-garden.png"):
		artwork = load("res://assets/casual/world-garden.png")
		backdrop = TextureRect.new()
		backdrop.texture = artwork
		backdrop.material = color_material
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.show_behind_parent = true
		add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)

func set_world(number: int) -> void:
	world=number
	world_completed=false
	shader_completed=-1.0
	if backdrop:
		pending_art=str(preload("res://scripts/core/world_catalog.gd").get_world(world).art)
		WorldArt.prefetch(world)
		backdrop.modulate.a=0
		backdrop.material.set_shader_parameter("lava_effect",1.0 if world==5 else 0.0)
	queue_redraw()

func _process(delta: float) -> void:
	if pending_art!="" and backdrop:
		var loaded:=WorldArt.ready(pending_art)
		if loaded!=null:artwork=loaded;backdrop.texture=loaded;pending_art=""
	if backdrop and pending_art=="":backdrop.modulate.a=1 if reduced_motion else minf(1,backdrop.modulate.a+delta*9)
	if not reduced_motion: clock += delta
	var previous_vitality := displayed_vitality
	displayed_vitality = vitality if reduced_motion else lerpf(displayed_vitality,vitality,minf(1,delta*2.5))
	if backdrop and absf(previous_vitality-displayed_vitality)>.0005:
		backdrop.material.set_shader_parameter("vitality",displayed_vitality)
	refresh_age += delta
	var interval := .05 if quality == "high" else .1
	if refresh_age >= interval and (not reduced_motion and quality != "performance"):
		refresh_age = 0
		if backdrop and world==5:
			last_flow=fmod(clock*.12,1.0);backdrop.material.set_shader_parameter("flow_phase",last_flow)
		queue_redraw()
	if backdrop:
		var complete:=1.0 if world_completed else 0.0
		if shader_completed!=complete:
			shader_completed=complete;backdrop.material.set_shader_parameter("lava_complete",complete)
		if (reduced_motion or quality=="performance") and last_flow!=0:
			last_flow=0;backdrop.material.set_shader_parameter("flow_phase",0.0)

func _draw() -> void:
	var extent := size
	if artwork:
		draw_rect(Rect2(Vector2.ZERO,extent),Color(.98,.98,1,.025))
	else:
		# Original vector fallback, usable offline while optional painted art imports.
		for layer in 3:
			for i in 8:
				var x := float(i) * extent.x / 7
				var y := extent.y * (0.25 + layer * 0.10)
				draw_circle(Vector2(x, y), 85 - layer * 13, Color(0.025, 0.12 + vitality * 0.07, 0.17, 0.7))
		for side in [0, 1]:
			var x: float = extent.x * side
			var trunk := PackedVector2Array([Vector2(x - 32, extent.y), Vector2(x + 23, extent.y), Vector2(x + 17, 180), Vector2(x - 18, 60)])
			draw_colored_polygon(trunk, Color("172e36"))
			for i in 6:
				var base := Vector2(x, 100 + i * 92)
				var tip := base + Vector2(70 if side == 0 else -70, -66)
				draw_line(base, tip, Color("25474b"), 9)
				draw_circle(tip, 27, Color("244d51"))
	if world in [3,4] and not reduced_motion and quality!="performance":
		for k in 3:
			var x:=fmod(clock*7+k*211,extent.x+100)-50
			draw_ellipse_cloud(Vector2(x,80+k*110))
	for i in (24 if quality == "high" else 12) if quality != "performance" else 0:
		var pos := Vector2(fmod(i * 93.3 + 18, extent.x), fmod(i * 137.7 + 34, extent.y))
		if world==2:
			pos.y=fmod(pos.y-clock*(6+i%4),extent.y)
			if pos.y<0:pos.y+=extent.y
		else:pos += Vector2(sin(clock * 0.45 + i) * 4, cos(clock * 0.35 + i) * 6)
		var opacity := (0.2 + 0.18 * sin(clock + i)) * (0.3 + vitality)
		if world==2:draw_arc(pos,3+i%3,0,TAU,10,Color(.65,.9,1,opacity*.5),.7,true)
		draw_circle(pos, 7, Color(1, 0.82, 0.4, opacity * 0.09))
		draw_circle(pos, 1.5, Color(1, 0.90, 0.62, opacity))
	# Original painted butterfly/fish accents: bounded count, no per-frame nodes.
	for i in 3 if quality!="performance" else 0:
		var index:=5 if world==2 else 3
		var source:=CasualSkin.region("decor",index)
		var x:=fmod(80+i*extent.x*.32+clock*(8 if world==2 else 3),extent.x+80)-40
		var pos:=Vector2(x,extent.y*(.12+i*.27)+sin(clock*.8+i)*8)
		draw_texture_rect_region(CasualSkin.DECOR,CasualSkin.fit(Rect2(pos,Vector2(38,30)),source),source,Color(1,1,1,.8))
	for color in 5:
		var amount:=minf(1,float(color_energy[color])/18.0)
		if amount<=0:continue
		var source:=CasualSkin.region("decor",4 if world==2 else 2)
		var pos:=Vector2(4 if color%2==0 else extent.x-44,extent.y*(.28+color*.1))
		draw_texture_rect_region(CasualSkin.DECOR,CasualSkin.fit(Rect2(pos,Vector2(40,40)),source),source,Color(1,1,1,.3+.7*amount))

func draw_ellipse_cloud(center: Vector2) -> void:
	for k in 4:draw_circle(center+Vector2(k*17,4 if k%2==0 else -2),14+k%2*5,Color(1,.98,1,.065))
