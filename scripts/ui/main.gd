extends Control

const Objectives = preload("res://scripts/mechanics/objective_manager.gd")
const Mechanics = preload("res://scripts/mechanics/mechanic_manager.gd")
const Generator = preload("res://scripts/core/board_generator.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
const Board = preload("res://scripts/core/board.gd")
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Save = preload("res://scripts/core/save_manager.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const Score = preload("res://scripts/core/score.gd")
const Palette = preload("res://scripts/ui/palette.gd")
const Strings = preload("res://scripts/ui/strings.gd")
const Garden = preload("res://scripts/ui/garden.gd")
const BoardView = preload("res://scripts/ui/board_view.gd")
const Audio = preload("res://scripts/ui/audio_manager.gd")
const Celebration = preload("res://scripts/ui/celebration.gd")

var selected_world:=1
var map_group := 0
var test_mode := false
var test_seed := 104169
var test_index := 27
var save
var board
var audio
var garden
var stage: Control
var page: Control
var overlay: Control
var overlay_root: Control
var footer_nodes: Array[Control] = []
var safe_rect_override := Rect2()
var quality_buttons: Dictionary = {}
var settings_dirty := false
var reported_save_error := ""
var score_display := 0.0
var score_target := 0.0
var board_view
var screen := "home"
var paused := false
var score_label: Label
var moves_label: Label
var goals_label: Label
var hint_label: Label
var resonance_label: Label
var energy_label: Label
var gravity_buttons: Dictionary = {}
var toast_label: Label

func _ready() -> void:
	save = Save.new()
	save.background_writes = true
	Engine.max_fps = 60
	audio = Audio.new()
	add_child(audio)
	audio.apply_settings(save.data.settings)
	garden = Garden.new()
	add_child(garden)
	stage = Control.new()
	stage.name = "Stage"
	add_child(stage)
	resized.connect(layout_stage)
	get_tree().auto_accept_quit = false
	show_home()
	layout_stage()

func safe_rect() -> Rect2:
	if safe_rect_override.has_area(): return safe_rect_override
	if OS.get_name() != "Android": return Rect2(Vector2.ZERO,size)
	var physical := DisplayServer.get_display_safe_area()
	var window_size := Vector2(DisplayServer.window_get_size())
	if not physical.has_area() or window_size.x<=0 or window_size.y<=0: return Rect2(Vector2.ZERO,size)
	var scale_to_canvas := size/window_size
	return Rect2(Vector2(physical.position)*scale_to_canvas,Vector2(physical.size)*scale_to_canvas).intersection(Rect2(Vector2.ZERO,size))

func layout_stage() -> void:
	if stage == null: return
	var area := safe_rect()
	var factor := minf(area.size.x/540.0,area.size.y/960.0)
	if factor<=0: return
	stage.size = Vector2(540,area.size.y/factor)
	stage.scale = Vector2.ONE*factor
	stage.position = area.position+Vector2((area.size.x-540*factor)*.5,0)
	garden.size = size
	var extra := stage.size.y-960
	if page:
		page.position.y = 0 if screen == "game" else extra*.5
	if screen == "game" and board_view:
		board_view.position.y = 270+extra*.5
		for node in footer_nodes:
			if is_instance_valid(node): node.position.y = float(node.get_meta("base_y"))+extra
	if overlay_root:
		overlay_root.size = stage.size
		overlay_root.get_child(0).size = stage.size
		overlay.position.y = extra*.5

func _process(delta: float) -> void:
	if save:
		save.poll_flush()
		if save.last_error!="" and save.last_error!=reported_save_error:
			reported_save_error=save.last_error
			Metrics.incident("Save operation failed",{"error":save.last_error})
			if screen=="game": set_hint(save.last_error)
		elif save.last_error=="": reported_save_error=""
	if score_label and is_instance_valid(score_label) and screen == "game":
		if absf(score_display-score_target)>1:
			score_display = lerpf(score_display,score_target,minf(1,delta*14))
			score_label.text = str(int(round(score_display)))
		elif score_display!=score_target:
			score_display = score_target
			score_label.text = str(int(score_target))
	if board_view and is_instance_valid(board_view): garden.quality = board_view.quality

func _exit_tree() -> void:
	if save:
		if settings_dirty: save.flush()
		save.finish_writes()

func _notification(what: int) -> void:
	if save == null: return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist_board()
		save.finish_writes()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		persist_board()
		save.finish_writes()
		if screen == "game" and (board.outcome == "playing" or (board_view != null and board_view.busy)): show_pause(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()

func go_back() -> void:
	if overlay != null:
		close_overlay()
	elif screen == "game":
		show_pause()
	elif screen != "home":
		show_home()
	else:
		persist_board()
		save.finish_writes()
		get_tree().quit()

func persist_board() -> void:
	if test_mode: return
	if board != null and screen == "game":
		if board.outcome == "won": save.complete(board)
		elif board.outcome == "playing": save.save_active(board)
	elif settings_dirty: save.flush()
	settings_dirty = false

func begin_page(next_screen: String) -> void:
	close_overlay()
	if page != null:
		page.hide()
		page.queue_free()
	page = Control.new()
	page.name = next_screen.capitalize()
	page.size = Vector2(540, 960)
	stage.add_child(page)
	screen = next_screen
	board_view = null
	footer_nodes.clear()
	garden.reduced_motion = save.data.settings.reduced_motion or save.data.settings.get("reduced_effects",false)
	garden.quality = save.data.settings.get("quality","balanced")
	layout_stage()

func label(parent: Node, text: String, rect: Rect2, font_size: int = 20, color: Color = Palette.INK, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = text
	result.position = rect.position
	result.size = rect.size
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = alignment
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func card(parent: Node, rect: Rect2, tint: Color = Color(0.045, 0.08, 0.16, 0.93)) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", Palette.panel(tint, 22, Color(0.66, 0.85, 0.84, 0.18)))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false, font_size: int = 20) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.add_theme_font_size_override("font_size", font_size)
	var base := Color("8ce1c5") if primary else Color("17283f")
	btn.add_theme_stylebox_override("normal", Palette.panel(base, 18, Color(0.75, 0.88, 0.9, 0.18)))
	btn.add_theme_stylebox_override("hover", Palette.panel(base.lightened(0.08), 18, Palette.GOLD))
	btn.add_theme_stylebox_override("pressed", Palette.panel(base.darkened(0.15), 18))
	btn.add_theme_stylebox_override("disabled", Palette.panel(Color("17202e"), 18, Color("384457")))
	btn.add_theme_stylebox_override("focus", Palette.panel(Color(0, 0, 0, 0), 18, Palette.GOLD))
	btn.add_theme_color_override("font_color", Color("102d32") if primary else Palette.INK)
	btn.add_theme_color_override("font_hover_color", Color("102d32") if primary else Palette.INK)
	btn.add_theme_color_override("font_pressed_color", Color("102d32") if primary else Palette.INK)
	btn.add_theme_color_override("font_disabled_color", Color("707f93"))
	btn.pressed.connect(func():
		audio.play("click")
		callback.call())
	parent.add_child(btn)
	return btn

func title_header(title: String, subtitle: String) -> void:
	label(page, "PRİZMA", Rect2(32, 28, 220, 36), 24, Palette.GOLD)
	button(page, "‹", Rect2(456, 28, 52, 44), go_back, false, 30)
	label(page, title, Rect2(32, 88, 476, 45), 33)
	label(page, subtitle, Rect2(32, 136, 476, 28), 14, Palette.MUTED)

func show_home() -> void:
	selected_world=Catalog.world_for(int(save.data.unlocked))
	apply_world_progress(selected_world)
	test_mode = false
	begin_page("home")
	apply_world_progress(selected_world)
	if selected_world==1 and 1 in save.data.get("world_rewards",[]):
		label(page,"BÜYÜLÜ BAHÇE MADALYASI",Rect2(20,373,500,25),14,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
		garden.color_energy=[18,18,18,18,18]
	label(page, "ÇEVRİMDIŞI · SANA AİT BİR DÜNYA", Rect2(30, 44, 480, 28), 13, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/art/icon.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.position = Vector2(210, 119)
	logo.size = Vector2(120, 120)
	page.add_child(logo)
	label(page, "PRİZMA", Rect2(20, 251, 500, 78), 62, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label(page, Strings.text("tagline"), Rect2(20, 333, 500, 32), 17, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	label(page, "Bir dokunuşla renkleri uyandır.", Rect2(20, 402, 500, 34), 21, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label(page, "Kaydır. Eşleştir. Dünyayı canlandır.", Rect2(20, 438, 500, 28), 15, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	card(page, Rect2(44, 518, 452, 102))
	label(page, world_name(selected_world), Rect2(65, 532, 350, 32), 24)
	var stars := 0
	for result in save.data.results.values(): stars += int(result.stars)
	label(page, "%d / %d bölüm  ·  %d / %d yıldız" % [save.data.results.size(), Catalog.count(), stars, Catalog.count()*3], Rect2(65, 572, 395, 28), 16, Palette.GOLD)
	var active: bool = not save.data.active.is_empty()
	button(page, Strings.text("resume") if active else Strings.text("play"), Rect2(44, 648, 452, 70), play_latest, true, 25)
	button(page, Strings.text("map"), Rect2(44, 733, 452, 57), show_worlds)
	button(page, Strings.text("settings"), Rect2(162, 818, 216, 48), show_settings, false, 17)
	label(page, Strings.text("saved"), Rect2(25, 898, 490, 28), 12, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	if save.data.get("migration_notice", false): call_deferred("show_migration_notice")

func play_latest() -> void:
	if not save.data.active.is_empty():
		start_level(int(save.data.active.level_id), true)
	else:
		start_level(int(save.data.unlocked))

func world_name(number: int) -> String:
	return "KRİSTAL OKYANUS" if number==2 else "BÜYÜLÜ BAHÇE"

func apply_world_progress(number: int) -> void:
	selected_world=number
	garden.set_world(number)
	var completed:=0
	for key in save.data.results:
		if Catalog.world_for(int(key))==number:completed+=1
	garden.vitality=1.0 if number in save.data.get("world_rewards",[]) else .18+.82*minf(1,completed/50.0)
	garden.color_energy=[]
	for color in 5:garden.color_energy.append(mini(18,completed*(1+color%2)))

func show_worlds() -> void:
	persist_board();test_mode=false;begin_page("worlds")
	title_header("Dünyaların uyanışı","RENKLERİNİ GERİ GETİR")
	for world in [1,2]:
		var y: int=220+(int(world)-1)*285
		card(page,Rect2(32,y,476,255))
		var picture:=TextureRect.new()
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		var source: Texture2D=load("res://assets/art/ocean.png" if world==2 else "res://assets/art/garden.png")
		var thumbnail:=AtlasTexture.new();thumbnail.atlas=source
		thumbnail.region=Rect2(0,source.get_height()*(.63 if world==2 else .02),source.get_width(),source.get_height()*.32)
		picture.texture=thumbnail
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.position=Vector2(46,y+14);picture.size=Vector2(448,139)
		picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;picture.clip_contents=true;page.add_child(picture)
		label(page,world_name(world),Rect2(56,y+159,390,30),23,Palette.GOLD)
		var unlocked: bool=world==1 or int(save.data.unlocked)>=51
		var node:=button(page,"1–50 · BAHÇEYİ KEŞFET" if world==1 else ("51–75 · OKYANUSA DAL" if unlocked else "50. BÖLÜMÜ TAMAMLA"),Rect2(48,y+201,444,41),show_map.bind(0 if world==1 else 5),unlocked,15)
		node.disabled=not unlocked
	if ProjectSettings.get_setting("prizma/show_future_levels",true):label(page,"76–100 hazırlanıyor · henüz oynanabilir değil",Rect2(28,823,484,34),15,Palette.MUTED,HORIZONTAL_ALIGNMENT_CENTER)

func show_map(group: int = -1) -> void:
	persist_board();test_mode=false
	if group>=0:map_group=clampi(group,0,int((Catalog.count()-1)/10))
	else:map_group=0 if selected_world==1 else 5
	begin_page("map")
	apply_world_progress(1 if map_group<5 else 2)
	title_header(world_name(selected_world),"1–50 · BÜYÜLÜ BAHÇE" if selected_world==1 else ("51–75 OYNANABİLİR · 76–100 HAZIRLANIYOR" if ProjectSettings.get_setting("prizma/show_future_levels",true) else "51–75 · KRİSTAL OKYANUS"))
	button(page,"DÜNYALAR",Rect2(350,179,158,35),show_worlds,false,13)
	label(page,"Her bölüm yeni bir renk.",Rect2(32,179,305,30),17,Palette.GOLD)
	for n in range(1+map_group*10,mini(Catalog.count()+1,11+map_group*10)):
		var row:=int(((n-1)%10)/2);var x:=64 if n%2==1 else 292;var y:=236+row*118
		var unlocked: bool=n<=save.data.unlocked
		var result: Dictionary=save.data.results.get(str(n),{})
		var node:=button(page,str(n) if unlocked else "·",Rect2(x,y,184,69),start_level.bind(n),unlocked and n==save.data.unlocked,28)
		node.disabled=not unlocked
		label(page,"★".repeat(int(result.get("stars",0))) if not result.is_empty() else ("Seni bekliyor" if unlocked else "Kilitli"),Rect2(x,y+71,184,25),15,Palette.GOLD if unlocked else Palette.MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var start_group:=0 if selected_world==1 else 5
	var groups:=5 if selected_world==1 else 3
	for i in groups:
		var group_index:=start_group+i
		button(page,"%d–%d"%[group_index*10+1,mini(Catalog.count(),group_index*10+10)],Rect2(33+i*96,864,89,45),show_map.bind(group_index),group_index==map_group,14)
	label(page,world_name(selected_world),Rect2(30,918,480,26),12,Palette.MUTED,HORIZONTAL_ALIGNMENT_CENTER)

func start_level(number: int, resume: bool = false, test_definition: Dictionary = {}) -> void:
	if test_definition.is_empty() and (number < 1 or number > mini(Catalog.count(),int(save.data.unlocked))): return
	test_mode = not test_definition.is_empty()
	board = Board.new(Catalog.get_level(number) if not test_mode else test_definition)
	if resume and not save.data.active.is_empty(): board.restore(save.data.active)
	begin_page("game")
	apply_world_progress(Catalog.world_for(number))
	label(page, "GELİŞTİRİCİ · KAYIT DIŞI TEST" if test_mode else world_name(selected_world), Rect2(32, 22, 330, 28), 13, Palette.GOLD)
	label(page, "%02d  /  %s" % [number, board.level.name], Rect2(32, 55, 415, 39), 23)
	button(page, "Ⅱ", Rect2(456, 38, 52, 50), show_pause, false, 23)
	card(page, Rect2(30, 110, 480, 65))
	label(page, Strings.text("score"), Rect2(49, 119, 150, 17), 11, Palette.MUTED)
	score_label = label(page, "0", Rect2(49, 137, 225, 29), 24)
	label(page, Strings.text("moves"), Rect2(351, 119, 139, 17), 11, Palette.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	moves_label = label(page, "", Rect2(354, 137, 136, 29), 24, Palette.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	card(page, Rect2(30, 190, 480, 54))
	goals_label = label(page, "", Rect2(47, 193, 446, 46), 14)
	goals_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	board_view = BoardView.new()
	board_view.position = Vector2(32, 270)
	board_view.size = Vector2(476, 536)
	board_view.reduced_motion = save.data.settings.reduced_motion
	board_view.colorblind = save.data.settings.colorblind
	board_view.settings = save.data.settings
	page.add_child(board_view)
	board_view.set_board(board)
	board_view.swap_requested.connect(on_swap)
	board_view.special_pressed.connect(on_special)
	board_view.wave_started.connect(on_wave)
	board_view.environment_started.connect(on_environment)
	board_view.animation_finished.connect(on_animation_finished)
	resonance_label = label(page, "", Rect2(33, 816, 292, 28), 13, Palette.GOLD)
	energy_label = label(page, "", Rect2(326, 816, 182, 28), 13, Palette.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	gravity_buttons.clear()
	var directions := ["left", "up", "down", "right"]
	var arrows := ["←", "↑", "↓", "→"]
	for k in 4:
		var direction: String = directions[k]
		gravity_buttons[direction] = button(page, arrows[k], Rect2(31 + k * 56, 854, 48, 42), on_gravity.bind(direction), false, 24)
	button(page, "Test araçları" if test_mode else "Nasıl oynanır?", Rect2(274, 854, 235, 42), show_mechanic_test_tools if test_mode else show_help, false, 15)
	hint_label = label(page, "", Rect2(26, 903, 488, 46), 13, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for node in page.get_children():
		if node is Control and node.position.y>=816:
			node.set_meta("base_y",node.position.y)
			footer_nodes.append(node)
	layout_stage()
	update_hud()
	if board.outcome != "playing":
		show_result()
		return
	var tutorial_key := "m3_level_%d" % number
	set_hint(board.level.get("tutorial", Strings.text("power_hint")))
	if tutorial_key not in save.data.tutorials and board.level.has("tutorial_swap"):
		board_view.hint_index = int(board.level.tutorial_swap[0])
		board_view.hint_target = int(board.level.tutorial_swap[1])
	if not test_mode: save.save_active(board)

func update_hud() -> void:
	score_target = board.score
	score_display = board.score
	score_label.text = str(board.score)
	moves_label.text = str(board.moves)
	var descriptions: Array = []
	for key in board.level.targets:
		var target: int = int(board.level.targets[key])
		var amount: int = mini(target, Objectives.value(board.collected,key))
		var name: String = Objectives.NAMES[key] if Objectives.NAMES.has(key) else Strings.COLORS[int(key)]
		descriptions.append("%s  %d/%d" % [name, amount, target])
	goals_label.text = "   ·   ".join(descriptions)
	resonance_label.text = "YANKI  ·  %s %d/3" % [Strings.COLORS[board.resonance.color] if board.resonance.color >= 0 else "", board.resonance.count] if board.level.resonance else "YANKI  ·  6. bölümde açılır"
	energy_label.text = "YÖN  ·  %d/2  (%d/12)" % [board.energy, board.energy_blocks] if board.level.gravity else "YÖN  ·  4. bölümde"
	for direction in gravity_buttons:
		var btn: Button = gravity_buttons[direction]
		btn.disabled = not board.level.gravity or board.energy < 1 or direction == board.direction or board.outcome != "playing"
		btn.modulate = Palette.GOLD if direction == board.direction else Color.WHITE
	var progress := 0.0
	for color in 5: garden.color_energy[color] = board.collected[str(color)]
	for key in board.level.targets:
		progress += minf(1, float(Objectives.value(board.collected,key)) / float(board.level.targets[key]))
	garden.vitality=maxf(garden.vitality,.15+.65*progress/board.level.targets.size())

func set_hint(text: String) -> void:
	if hint_label: hint_label.text = text

func on_swap(a: int, b: int) -> void:
	if screen != "game" or paused or board_view.busy or not board.available(): return
	var started := Time.get_ticks_usec()
	var event: Dictionary = board.swap(a,b)
	Metrics.elapsed("swap_and_cascades",started)
	process_event(event)

func on_special(index: int) -> void:
	if screen != "game" or paused or board_view.busy or not board.available() or board.cells[index].p == "": return
	if board.cells[index].p == "color": show_color_picker(index)
	else: perform_special(index)

func perform_special(index: int, selected_color: int = -1) -> void:
	if paused or board_view.busy or not board.available(): return
	process_event(board.activate(index, selected_color))

func process_event(event: Dictionary) -> void:
	if not event.get("attempted", false): return
	if not event.accepted:
		audio.play("invalid")
		set_hint(Strings.text("invalid"))
		board_view.animate(event)
		return
	var tutorial := "m3_level_%d" % int(board.level.id)
	if not test_mode and tutorial not in save.data.tutorials: save.data.tutorials.append(tutorial)
	if not test_mode and event.get("resonated", false) and "m3_resonance" not in save.data.tutorials: save.data.tutorials.append("m3_resonance")
	if not test_mode and event.get("gravity", false) and "m3_gravity" not in save.data.tutorials: save.data.tutorials.append("m3_gravity")
	set_hint("+%d puan  ·  %s" % [event.points, "Özel güç oluştu!" if event.created_count > 0 else "Dünya renkleniyor."])
	if event.get("shuffled", false): set_hint(Strings.text("shuffle"))
	update_hud()
	score_display = board.score - int(event.points)
	score_target = score_display
	score_label.text = str(int(score_display))
	# Persist only the completely settled logical result, before cosmetic playback.
	if not test_mode:
		if board.outcome == "won": save.complete(board)
		else: save.save_active(board)
	board_view.animate(event)

func on_environment(data: Dictionary) -> void:
	audio.play("portal" if data.kind=="portal" else "vine")

func on_wave(data: Dictionary) -> void:
	if not data.get("beams",[]).is_empty():audio.play("mirror")
	for effect in data.get("mechanics",[]):
		if effect.kind in ["vine","crate"]:audio.play(effect.kind);break
	score_target = data.score
	if data.resonated:
		audio.play("resonance")
		audio.vibrate(true)
	elif data.get("special", false):
		var power_key := "power"
		for index in data.get("triggered",[]):
			if data.before[index].p == "color": power_key = "color"; break
			if data.before[index].p.begins_with("rocket"): power_key = "rocket"
		audio.play(power_key)
		audio.vibrate(true)
	elif not data.get("creations",[]).is_empty():
		var key := "rocket"
		for creation in data.creations:
			if creation.kind=="color": key="color"; break
			if creation.kind=="prism": key="power"
		audio.play(key)
		audio.vibrate(true)
	else:
		audio.play("large" if data.removed.size() >= 4 else "pop")
		audio.vibrate()
	var mechanic_sound := ""
	for effect in data.get("mechanics",[]):
		if not effect.opened: continue
		if effect.kind=="lock": mechanic_sound="color"; break
		elif effect.kind=="stone" or effect.kind=="ice": mechanic_sound="large"
		elif mechanic_sound=="": mechanic_sound="resonance"
	if mechanic_sound!="": audio.play(mechanic_sound)
	if data.combo > 1:
		audio.play("cascade",mini(4,int(data.combo)-1))
		var names := ["Kombo!", "Süper Kombo!", "Muhteşem!", "Efsanevi Zincir!"]
		set_hint("%s  ·  x%d  ·  +%d puan" % [names[mini(3, int(data.combo) - 2)], data.multiplier, data.points])

func on_animation_finished() -> void:
	if board == null or screen != "game": return
	update_hud()
	if board.outcome != "playing": show_result()
	elif board.energy > 0 and "m3_gravity" not in save.data.tutorials:
		set_hint("Enerjin hazır! Bir yön seç; hamlen azalmaz.")

func on_gravity(direction: String) -> void:
	if board_view.busy or paused or not board.available(): return
	var event: Dictionary = board.change_gravity(direction)
	if not event.accepted: return
	audio.play("gravity")
	process_event(event)
	set_hint(Strings.text("gravity_hint"))

func show_help() -> void:
	open_overlay("Nasıl oynanır?")
	var body := label(overlay, Strings.text("help_body"), Rect2(62, 311, 416, 308), 17, Palette.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(overlay, "ENGELLER VE HEDEFLER", Rect2(68, 637, 404, 36), show_mechanic_help, false, 13)
	button(overlay, "DEVAM ET", Rect2(68, 685, 404, 36), close_overlay, true, 15)

func show_migration_notice() -> void:
	if not save.data.get("migration_notice", false): return
	open_overlay("Match-3'e hoş geldin")
	var body := label(overlay, "Artık blokları kaydırarak üçlü eşleştiriyoruz.\n\nAçılan bölümler, yıldızlar ve ayarlar korundu. Eski aktif tahta arşivlendi; aynı bölüm yeni kurallarla, tam hamleyle yeniden başlıyor.", Rect2(62, 313, 416, 268), 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(overlay, "ANLADIM", Rect2(68, 627, 404, 58), func():
		save.data.migration_notice = false
		save.flush()
		close_overlay(), true)

func open_overlay(title: String, subtitle: String = "") -> Control:
	close_overlay()
	paused = true
	if screen == "game" and board != null and (board.outcome == "playing" or (board_view != null and board_view.busy)):
		board.pause()
		if board_view != null: board_view.cancel_drag()
	overlay_root = Control.new()
	overlay_root.size = stage.size
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(overlay_root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.07, 0.83)
	dim.size = stage.size
	overlay_root.add_child(dim)
	overlay = Control.new()
	overlay.size = Vector2(540,960)
	overlay.position.y = (stage.size.y-960)*.5
	overlay_root.add_child(overlay)
	card(overlay, Rect2(32, 225, 476, 512))
	label(overlay, title, Rect2(48, 247, 444, 56), 29, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var sub := label(overlay, subtitle, Rect2(57, 311, 426, 65), 16, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return overlay

func close_overlay() -> void:
	if overlay != null:
		overlay_root.hide()
		overlay_root.queue_free()
		overlay = null
		overlay_root = null
	paused = false
	if board != null: board.resume()

func show_pause(already_saved: bool = false) -> void:
	if screen != "game": return
	if board.outcome != "playing" and (board_view == null or not board_view.busy):
		show_result()
		return
	if not already_saved: persist_board()
	save.finish_writes()
	open_overlay(Strings.text("pause"), "Bahçe seni bekler. İlerlemen kaydedildi." if save.last_error=="" else save.last_error)
	button(overlay, Strings.text("resume"), Rect2(68, 401, 404, 59), close_overlay, true)
	button(overlay, Strings.text("settings"), Rect2(68, 480, 404, 55), show_settings)
	button(overlay, Strings.text("replay"), Rect2(68, 553, 404, 55), func(): confirm_restart())
	button(overlay, Strings.text("map"), Rect2(68, 627, 404, 55), show_map)

func confirm_restart() -> void:
	open_overlay("Baştan başlayalım mı?", "Bu bölümün mevcut hamleleri sıfırlanır. Kazandığın yıldızlar korunur.")
	button(overlay, Strings.text("replay"), Rect2(68, 421, 404, 59), start_level.bind(int(board.level.id)), true)
	button(overlay, "VAZGEÇ", Rect2(68, 508, 404, 55), show_pause)

func show_color_picker(index: int) -> void:
	open_overlay("Rengini seç", Strings.text("color_pick"))
	for color in 5:
		var selected_color: int = color
		var btn := button(overlay, Strings.COLORS[color], Rect2(70, 383 + color * 57, 400, 47), func():
			close_overlay()
			perform_special(index, selected_color), false, 17)
		btn.add_theme_color_override("font_color", Palette.COLORS[color])
	button(overlay, "VAZGEÇ", Rect2(171, 681, 198, 38), close_overlay, false, 13)

func show_result() -> void:
	if test_mode:
		open_overlay("Test tamamlandı","Laboratuvar sonuçları ilerlemene kaydedilmez.")
		button(overlay,"TAHTAYI SIFIRLA",Rect2(68,421,404,59),start_mechanic_test,true)
		button(overlay,"ANA MENÜ",Rect2(68,508,404,55),show_home)
		return
	if board.outcome == "playing": return
	var won: bool = board.outcome == "won"
	if won and int(board.level.id)%50==0:
		save.complete(board)
		show_world_result()
		return
	if won: save.complete(board)
	else:
		save.data.active = {}
		save.flush()
	audio.play("win" if won else "lose")
	open_overlay("Okyanus meydan okuması!" if won and int(board.level.id)==75 else (Strings.text("won") if won else Strings.text("lost")), "Her renk bir iz bırakır." if won else "Farklı bir renk sırası veya düşüş yönü dene.")
	if won:
		if not save.data.settings.reduced_motion and not save.data.settings.get("reduced_effects",false) and save.data.settings.get("quality","auto")!="performance":
			var confetti := Celebration.new()
			confetti.world_finale=int(board.level.id)==75
			confetti.challenge=int(board.level.id)==75
			overlay.add_child(confetti)
		var stars: int = Score.stars(board.score, board.level.stars)
		label(overlay, "★".repeat(stars) + "☆".repeat(3 - stars), Rect2(66, 368, 408, 64), 48, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		label(overlay, "%d PUAN" % board.score, Rect2(66, 436, 408, 37), 26, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		label(overlay, "2★: %d   ·   3★: %d" % [board.level.stars[1], board.level.stars[2]], Rect2(66, 475, 408, 28), 13, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		if int(board.level.id) < Catalog.count():
			button(overlay, Strings.text("next"), Rect2(68, 529, 404, 58), start_level.bind(int(board.level.id) + 1), true)
		else:
			label(overlay, "75 tamamlandı · 76–100 hazırlanıyor", Rect2(66, 516, 408, 38), 22, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			button(overlay, "OKYANUSU KEŞFET" if int(board.level.id)>=51 else Strings.text("map"), Rect2(68, 567, 404, 53), show_map, true)
		button(overlay, Strings.text("replay"), Rect2(68, 637, 404, 53), start_level.bind(int(board.level.id)))
	else:
		label(overlay, "%d PUAN" % board.score, Rect2(66, 388, 408, 50), 30, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		button(overlay, Strings.text("replay"), Rect2(68, 467, 404, 59), start_level.bind(int(board.level.id)), true)
		button(overlay, Strings.text("map"), Rect2(68, 552, 404, 55), show_map)
		button(overlay, Strings.text("home"), Rect2(68, 630, 404, 53), show_home)

func show_settings() -> void:
	persist_board()
	begin_page("settings")
	title_header(Strings.text("settings"), "KRİSTALLERİ KENDİ RİTMİNDE UYANDIR")
	label(page,"GÖRSEL KALİTE",Rect2(43,190,350,27),14,Palette.GOLD)
	var modes := ["auto","high","balanced","performance"]
	var names := ["Otomatik","Yüksek","Dengeli","Performans"]
	quality_buttons.clear()
	for i in 4:
		var mode: String = modes[i]
		quality_buttons[mode] = button(page,names[i],Rect2(32+i*122,225,113,43),set_quality.bind(mode),save.data.settings.get("quality","auto")==mode,13)
	var definitions := [["shake","Hafif ekran sarsıntısı"],["reduced_effects","Azaltılmış efektler"],["reduced_motion","Daha az hareket"],["haptics","Dokunma titreşimi"],["colorblind","Şekille renk erişimi"]]
	for k in definitions.size():
		var key: String = definitions[k][0]
		var y := 287+k*62
		card(page,Rect2(32,y,476,54))
		label(page,definitions[k][1],Rect2(48,y+7,314,40),18)
		var toggle := button(page,"AÇIK" if save.data.settings[key] else "KAPALI",Rect2(371,y+8,119,38),func(): toggle_setting(key),save.data.settings[key],13)
		toggle.name = key
	volume_slider("music","Müzik",620)
	volume_slider("sfx","Efekt sesi",693)
	button(page,"Performans ölçümü / rapor",Rect2(42,771,456,44),show_diagnostics,false,15)
	button(page,Strings.text("resume") if not save.data.active.is_empty() else Strings.text("home"),Rect2(42,835,456,56),play_latest if not save.data.active.is_empty() else show_home,true)
	label(page,"PRİZMA 0.6 · KRİSTAL OKYANUS",Rect2(32,920,476,28),12,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)

	if developer_tools_available():
		button(page,"Geliştirici: mekanik laboratuvarı",Rect2(42,896,456,27),start_mechanic_test,false,12)

func volume_slider(key: String, title: String, y: float) -> void:
	label(page,title,Rect2(44,y,175,29),17)
	var toggle := button(page,"AÇIK" if save.data.settings[key] else "KAPALI",Rect2(371,y-2,119,33),func(): toggle_setting(key),save.data.settings[key],12)
	toggle.name = key
	var slider := HSlider.new()
	slider.position = Vector2(44,y+34)
	slider.size = Vector2(446,25)
	slider.max_value = 1
	slider.step = .05
	slider.value = save.data.settings.get(key+"_volume",.7)
	page.add_child(slider)
	slider.value_changed.connect(func(value: float):
		save.data.settings[key+"_volume"] = value
		settings_dirty = true
		audio.apply_settings(save.data.settings))
	slider.drag_ended.connect(func(_changed: bool):
		save.flush()
		settings_dirty=false)

func toggle_setting(key: String) -> void:
	save.data.settings[key] = not save.data.settings[key]
	save.flush()
	audio.apply_settings(save.data.settings)
	var toggle := page.get_node_or_null(NodePath(key)) as Button
	if toggle:
		toggle.text = "AÇIK" if save.data.settings[key] else "KAPALI"
		update_option_style(toggle,save.data.settings[key])
	garden.reduced_motion = save.data.settings.reduced_motion or save.data.settings.get("reduced_effects",false)

func update_option_style(btn: Button, active: bool) -> void:
	var base := Color("8ce1c5") if active else Color("17283f")
	(btn.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = base
	(btn.get_theme_stylebox("hover") as StyleBoxFlat).bg_color = base.lightened(.08)
	(btn.get_theme_stylebox("pressed") as StyleBoxFlat).bg_color = base.darkened(.15)
	for key in ["font_color","font_hover_color","font_pressed_color"]:
		btn.add_theme_color_override(key,Color("102d32") if active else Palette.INK)

func set_quality(mode: String) -> void:
	save.data.settings.quality = mode
	save.flush()
	for key in quality_buttons:
		if is_instance_valid(quality_buttons[key]): update_option_style(quality_buttons[key],key==mode)
	garden.quality = "balanced" if mode=="auto" else mode

func show_diagnostics() -> void:
	var report: Dictionary = Metrics.report(save.data.settings)
	open_overlay("Cihaz performansı", "Son 2048 örnek · 60 FPS hedefi: 16,7 ms")
	var frame_metric: Dictionary = report.metrics.get("frame_interval",{})
	var fps := 1000.0/maxf(.001,frame_metric.get("mean_ms",0.0)) if not frame_metric.is_empty() else 0.0
	var lines := "Oynanış ort.: %.1f FPS · %s\n\n" % [fps,OS.get_model_name()]
	for key in ["frame_interval","touch_to_visual_submit","swap_and_cascades","match_scan","portal_logic","vine_logic","effect_queue_logic","beam_logic","board_draw_cpu"]:
		if report.metrics.has(key): lines += "%s: %.2f ms (p95)\n" % [key,report.metrics[key].p95_ms]
	var body := label(overlay,lines,Rect2(59,375,425,240),14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"RAPORU KOPYALA",Rect2(68,620,404,44),func():
		var content := JSON.stringify(Metrics.report(save.data.settings),"  ")
		DisplayServer.clipboard_set(content)
		var file := FileAccess.open("user://prizma-performance.json",FileAccess.WRITE)
		if file: file.store_string(content)
		print("PRIZMA_PERF "+content)
		body.text = "Rapor panoya ve cihazdaki oyun verisine kaydedildi.\n\nBu raporu cihaz testinden sonra paylaşabilirsin.",true,15)
	button(overlay,"KAPAT",Rect2(68,677,404,38),close_overlay,false,14)

func developer_tools_available() -> bool:
	return OS.has_feature("editor") or OS.has_feature("prizma_dev_tools")

func start_mechanic_test() -> void:
	if not developer_tools_available(): return
	persist_board()
	var definition:=Catalog.get_level(1)
	definition.seed=test_seed
	definition.name="Mekanik laboratuvarı"
	definition.moves=100
	definition.targets={"total":10000}
	definition.layout=[]
	definition.layout.resize(72)
	definition.layout.fill(-1)
	definition.gravity=true
	definition.resonance=true
	definition.opening_refill=[]
	definition.erase("tutorial_swap")
	definition.tutorial="Test araçlarıyla engel ekle. Gerçek ilerlemen değişmez."
	start_level(1,false,definition)
	board.energy=2
	update_hud()

func show_mechanic_test_tools() -> void:
	if not developer_tools_available() or not test_mode: return
	open_overlay("Mekanik laboratuvarı","Bu tahta ilerlemene ve ödüllerine kaydedilmez.")
	for child in overlay.get_children():
		if child is Panel:child.position.y=145;child.size.y=620
		elif child is Label:child.position.y-=82
	label(overlay,"Seed",Rect2(67,307,90,34),16)
	var seed_input:=SpinBox.new()
	seed_input.position=Vector2(167,307)
	seed_input.size=Vector2(300,36)
	seed_input.min_value=1
	seed_input.max_value=2147483647
	seed_input.value=test_seed
	overlay.add_child(seed_input)
	seed_input.value_changed.connect(func(value): test_seed=int(value))
	label(overlay,"Hücre (0–71)",Rect2(67,350,200,34),16)
	var index_input:=SpinBox.new()
	index_input.position=Vector2(280,350)
	index_input.size=Vector2(187,36)
	index_input.max_value=71
	index_input.value=test_index
	overlay.add_child(index_input)
	index_input.value_changed.connect(func(value): test_index=int(value))
	var kinds: Array=["seed","ice","stone","lock","dual","chameleon","bridge","pin","portal","vine","crate","mirror"]
	var names: Array=["Tohum","Buz","Taş","Renk kilidi","Çift renk","Bukalemun","Prizma Köprüsü","Yer Çekimi Çivisi","Portal sahnesi","Sarmaşık sahnesi","Sandık sahnesi","Ayna sahnesi"]
	for i in 12:
		button(overlay,names[i],Rect2(68+(i%2)*208,391+int(i/2)*42,196,36),add_test_mechanic.bind(kinds[i]),false,14)
	button(overlay,"SEED İLE TAHTAYI SIFIRLA",Rect2(68,653,404,42),start_mechanic_test,true,15)
	button(overlay,"GERİ DÖN",Rect2(68,706,404,38),close_overlay,false,15)

func add_test_mechanic(kind: String) -> void:
	if not developer_tools_available() or not test_mode or board_view.busy: return
	close_overlay()
	if not board.available(): return
	if kind in ["portal","vine","crate","mirror"]:
		var definition:=preload("res://scripts/mechanics/developer_scenarios.gd").make(kind,test_seed)
		start_level(1,false,definition);board.energy=2;update_hud()
		return
	if kind in ["dual","bridge"]:
		var count:=0
		for i in 72:
			if i!=test_index and Traits.flexible(board.cells[i]):count+=1
		if count>=Traits.MAX_FLEXIBLE:
			set_hint("Bu test tahtasında en fazla 8 çift renk/joker bulunabilir.")
			return
	# Replace a sandbox cell only; installed layers use the production manager.
	board.cells[test_index]=board.make_cell()
	var spec: Dictionary={"kind":kind,"index":test_index}
	if kind=="lock": spec.merge({"color":0,"required":15})
	if kind=="dual":spec.colors=[0,1]
	if kind=="chameleon":spec.merge({"sequence":[2,1,0,4],"period":2,"phase":0})
	Mechanics.install(board.cells,[spec])
	Generator.repair_start(board.cells,board.rng,8,9)
	board_view.set_board(board)
	set_hint("%s eklendi · hücre %d · seed %d"%[kind,test_index,test_seed])
	update_hud()

func show_mechanic_help() -> void:
	open_overlay("Bahçenin sırları")
	var body:=label(overlay,"Tohum: yanında eşleştir, 2 darbeyle çiçek açar.\n\nBuz: kristali sabit tutar; yanında patlama veya doğrudan güçle 2 katmanı kır.\n\nTaş: 3 dayanıklılık. Doğrudan prizma 2 hasar verir; roket 1.\n\nRenk kilidi: istenen renkte normal kristalleri topla. Zincirler de sayılır.\n\nÇapraz komşuluk hasar vermez. Aynı dalga aynı engeli tekrar vurmaz.",Rect2(61,315,418,315),16)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"YENİ KRİSTALLER",Rect2(68,650,404,35),show_crystal_help,false,14)
	button(overlay,"ANLADIM",Rect2(68,699,404,35),close_overlay,true,15)

func show_world_result() -> void:
	audio.play("win")
	garden.vitality=1.0
	garden.color_energy=[18,18,18,18,18]
	open_overlay("Büyülü Bahçe tamamlandı!","Renkler uyandı. Dünya madalyan kaydedildi.")
	var medal:=TextureRect.new()
	medal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	medal.texture=load("res://assets/mechanics2/garden-medal.svg")
	medal.position=Vector2(202,376)
	medal.size=Vector2(136,136)
	medal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(medal)
	label(overlay,"BÜYÜLÜ BAHÇE MADALYASI",Rect2(55,514,430,31),17,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	label(overlay,"★".repeat(Score.stars(board.score,board.level.stars))+"  ·  %d PUAN"%board.score,Rect2(55,553,430,30),19,Palette.INK,HORIZONTAL_ALIGNMENT_CENTER)
	if not save.data.settings.reduced_motion and not save.data.settings.get("reduced_effects",false) and save.data.settings.get("quality","auto")!="performance":
		var celebration:=Celebration.new()
		celebration.world_finale=true
		overlay.add_child(celebration)
	if int(board.level.id)<Catalog.count():
		button(overlay,"SONRAKİ DÜNYA",Rect2(68,604,404,45),start_level.bind(int(board.level.id)+1),true,17)
	else:
		label(overlay,"Yeni dünya hazırlanıyor",Rect2(55,599,430,32),19,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	button(overlay,"BAHÇEYİ KEŞFET",Rect2(68,653,404,45),show_map.bind(4),true,17)

func show_crystal_help() -> void:
	open_overlay("İki rengin uyanışı")
	var body:=label(overlay,"Çift renkli kristal yalnızca gösterdiği iki renkle eşleşir. Bir dalgada tek renk olarak sayılır.\n\nBukalemun iki başarılı takasın zincirleri bittikten sonra sıradaki rengine geçer. Parlayan çerçeve dönüşümün yaklaştığını gösterir. Geçersiz takas, zincirler ve yön değişimi sayacı ilerletmez.\n\nPrizma Köprüsü her renge uyum sağlar; en az bir renkli kristalle üçlü çizgi oluşturmalıdır. 51. bölümde tanıtılır.\n\nYer Çekimi Çivisi kristali sabit tutar; iki ayrı darbeyle açılır. 56. bölümde tanıtılır.",Rect2(61,315,418,315),17)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"ANLADIM",Rect2(68,658,404,48),close_overlay,true,16)
