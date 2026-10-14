extends Control

const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
const MapPath=preload("res://scripts/ui/map_path.gd")
var map_buttons: Dictionary={}

const Objectives = preload("res://scripts/mechanics/objective_manager.gd")
const Mechanics = preload("res://scripts/mechanics/mechanic_manager.gd")
const Generator = preload("res://scripts/core/board_generator.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
const Board = preload("res://scripts/core/board.gd")
const Worlds=preload("res://scripts/core/world_catalog.gd")
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

var companion
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
var star_progress
var score_display := 0.0
var score_target := 0.0
var board_view
var screen := "home"
var paused := false
var score_label: Label
var moves_label: Label
var level_label: Label
var goals_panel
var goal_tip: Control
var pending_goal_tutorials: Array=[]
var hint_label: Label
var resonance_label: Label
var energy_label: Label
var storm_gauge
var hint_age:=0.0
var gravity_buttons: Dictionary = {}
var toast_label: Label

func _ready() -> void:
	if save==null:save = Save.new()
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
		for node in page.get_children():
			if node is Control and node.has_meta("hud_y"):node.position.y=float(node.get_meta("hud_y"))+extra*.5
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
	if screen=="game" and is_instance_valid(hint_label):
		hint_age+=delta;hint_label.modulate.a=clampf((5.0-hint_age)/.6,0,1)
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
	goal_tip=null
	pending_goal_tutorials.clear()
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

func card(parent: Node, rect: Rect2, tint: Color = Color("fff7ee")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel",Palette.panel(tint,18,Color("edc69a")))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false, font_size: int = 20) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal",CasualSkin.panel_style(0 if primary else 1))
	btn.add_theme_stylebox_override("hover",CasualSkin.panel_style(0 if primary else 1,Color(1.05,1.05,1.05)))
	btn.add_theme_stylebox_override("pressed",CasualSkin.panel_style(0 if primary else 1,Color(.92,.92,.92)))
	btn.add_theme_stylebox_override("disabled",CasualSkin.panel_style(1,Color(.72,.76,.8)))
	btn.add_theme_stylebox_override("focus",Palette.panel(Color.TRANSPARENT,18,Palette.GOLD))
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
	card(page,Rect2(22,18,496,152),Color(1,.98,.94,.9))
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
	logo.texture=CasualSkin.texture("gems",7,CasualSkin.GEMS)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.position = Vector2(210, 119)
	logo.size = Vector2(120, 120)
	page.add_child(logo)
	label(page, "PRİZMA", Rect2(20, 251, 500, 78), 62, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label(page, Strings.text("tagline"), Rect2(20, 333, 500, 32), 17, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	label(page, "Renkleri eşleştir, dünyayı uyandır.", Rect2(20, 402, 500, 34), 21, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
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
		request_level(int(save.data.unlocked))

func world_name(number: int) -> String:
	return str(Worlds.get_world(number).get("title","PRİZMA")).to_upper()

func apply_world_progress(number: int) -> void:
	selected_world=number
	garden.set_world(number)
	garden.world_completed=number in save.data.get("world_rewards",[])
	var completed:=0
	for key in save.data.results:
		if Catalog.world_for(int(key))==number:completed+=1
	garden.vitality=1.0 if number in save.data.get("world_rewards",[]) else .18+.82*minf(1,float(completed)/maxi(1,int(Worlds.get_world(number).end)-int(Worlds.get_world(number).start)+1))
	garden.color_energy=[]
	for color in 5:garden.color_energy.append(mini(18,completed*(1+color%2)))

func show_worlds() -> void:
	persist_board();test_mode=false;begin_page("worlds")
	title_header("Dünyaların uyanışı","RENKLERİNİ GERİ GETİR")
	var scroll:=preload("res://scripts/ui/world_scroll.gd").new()
	scroll.name="WorldsScroll"
	scroll.position=Vector2(32,205);scroll.size=Vector2(476,730)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var content:=Control.new();content.custom_minimum_size=Vector2(476,Worlds.playable_worlds().size()*235)
	scroll.add_child(content)
	var index:=0
	for metadata in Worlds.playable_worlds():
		var world:=int(metadata.id);var y:=index*235;index+=1
		card(content,Rect2(0,y,476,225))
		var picture:=TextureRect.new()
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		var source: Texture2D=load(metadata.art)
		var thumbnail:=AtlasTexture.new();thumbnail.atlas=source
		thumbnail.region=Rect2(0,source.get_height()*(.63 if world==2 else .48),source.get_width(),source.get_height()*.32)
		picture.texture=thumbnail
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.position=Vector2(14,y+14);picture.size=Vector2(448,110)
		picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;picture.clip_contents=true;content.add_child(picture)
		label(content,world_name(world),Rect2(24,y+125,390,30),23,Color(metadata.accent))
		var unlocked: bool=int(save.data.unlocked)>=int(metadata.start)
		var node:=button(content,("%d–%d · KEŞFET"%[int(metadata.start),int(metadata.end)]) if unlocked else ("%d. BÖLÜMÜ TAMAMLA"%[int(metadata.start)-1]),Rect2(16,y+174,444,37),show_map.bind(int((int(metadata.start)-1)/10)),unlocked,15)
		node.disabled=not unlocked


func show_map(group: int = -1) -> void:
	persist_board();test_mode=false
	if group>=0:map_group=clampi(group,0,int((Catalog.count()-1)/10))
	else:map_group=int((int(Worlds.get_world(selected_world).start)-1)/10)
	begin_page("map")
	apply_world_progress(Catalog.world_for(map_group*10+1))
	var metadata:=Worlds.get_world(selected_world)
	title_header(world_name(selected_world),"%d–%d · %d / %d TAMAMLANDI"%[int(metadata.start),int(metadata.end),save.data.results.keys().filter(func(k):return Catalog.world_for(int(k))==selected_world).size(),int(metadata.end)-int(metadata.start)+1])
	button(page,"DÜNYALAR",Rect2(350,179,158,35),show_worlds,false,13)
	label(page,"Her bölüm yeni bir renk.",Rect2(32,179,305,30),17,Palette.GOLD)
	map_buttons.clear()
	var scroll:=preload("res://scripts/ui/world_scroll.gd").new()
	scroll.position=Vector2(32,226);scroll.size=Vector2(476,620)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=false
	page.add_child(scroll)
	var path:=MapPath.new()
	var first:=int(metadata.start)
	var last:=mini(Catalog.count(),int(metadata.end))
	path.count=last-first+1;path.ocean=selected_world==2;path.canyon=selected_world==3;path.world_theme=str(metadata.map_style);path.accent=Color(metadata.accent)
	path.quiet=save.data.settings.reduced_motion;path.completed_count=save.data.results.keys().filter(func(k):return Catalog.world_for(int(k))==selected_world).size()
	path.custom_minimum_size=Vector2(456,path.count*100+100)
	scroll.add_child(path)
	for n in range(first,last+1):
		var local_index:=n-first
		var center: Vector2=path.node_position(local_index)
		var unlocked: bool=n<=save.data.unlocked
		var result: Dictionary=save.data.results.get(str(n),{})
		if unlocked and n==save.data.unlocked:
			var glow:=TextureRect.new();glow.texture=load("res://assets/crystals/glow.svg")
			glow.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glow.position=center-Vector2(49,49);glow.size=Vector2(98,98);glow.mouse_filter=Control.MOUSE_FILTER_IGNORE;glow.modulate=Color(1,.9,.4,.8);path.add_child(glow)
			if not save.data.settings.reduced_motion:
				var pulse:=glow.create_tween().set_loops();pulse.tween_property(glow,"modulate:a",.35,.65);pulse.tween_property(glow,"modulate:a",.8,.65)
		var node:=button(path,str(n),Rect2(center-Vector2(36,36),Vector2(72,72)),request_level.bind(n),unlocked and n==save.data.unlocked,25)
		node.disabled=not unlocked;map_buttons[n]=node
		if not unlocked:
			var lock:=TextureRect.new();lock.texture=CasualSkin.texture("ui",4,CasualSkin.UI)
			lock.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;lock.position=center+Vector2(22,-37);lock.size=Vector2(22,22);lock.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;lock.mouse_filter=Control.MOUSE_FILTER_IGNORE;path.add_child(lock)
		for star_index in int(result.get("stars",0)):
			var star:=TextureRect.new();star.texture=CasualSkin.texture("ui",3,CasualSkin.UI)
			star.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;star.position=center+Vector2(-29+star_index*20,35);star.size=Vector2(19,19);star.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;star.mouse_filter=Control.MOUSE_FILTER_IGNORE;path.add_child(star)

	scroll.set_deferred("scroll_vertical",maxi(0,(map_group*10+1-first)*100-70))

	var start_group:=int((first-1)/10)
	var groups:=int(ceil(float(last-first+1)/10))
	for i in groups:
		var group_index:=start_group+i
		button(page,"%d–%d"%[group_index*10+1,mini(Catalog.count(),group_index*10+10)],Rect2(33+i*96,864,89,45),show_map.bind(group_index),group_index==map_group,14)
	for i in 3:
		button(page,["GÜNLÜK","KOLEKSİYON","ÖDÜLLER"][i],Rect2(33+i*164,918,154,33),show_adventure_menu.bind(i),false,12)

func request_level(number: int) -> void:
	if number<1 or number>mini(Catalog.count(),int(save.data.unlocked)):return
	persist_board()
	var definition: Dictionary=Catalog.get_level(number)
	apply_world_progress(Catalog.world_for(number))
	open_overlay("BÖLÜM %d"%number, "%s · %s"%[world_name(Catalog.world_for(number)),definition.name])
	var preview:=preload("res://scripts/ui/goals_panel.gd").new()
	preview.position=Vector2(48,367);preview.size=Vector2(480,112);preview.quiet=true
	overlay.add_child(preview);preview.configure(definition.targets,{})
	preview.goal_pressed.connect(func(key):label(overlay,preload("res://scripts/ui/goal_registry.gd").description(key,int(definition.targets[key])),Rect2(68,525,404,48),13,Palette.INK,HORIZONTAL_ALIGNMENT_CENTER))
	label(overlay,"%d HAMLE"%int(definition.moves),Rect2(68,488,404,32),20,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	button(overlay,"OYNA!",Rect2(68,583,404,58),func():
		close_overlay()
		begin_page("transition")
		label(page,"KRİSTALLER UYANIYOR",Rect2(38,425,464,60),25,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
		var destination:=number
		await get_tree().create_timer(.6 if not save.data.settings.reduced_motion else .05).timeout
		if screen=="transition":start_level(destination),true,22)
	button(overlay,"VAZGEÇ",Rect2(68,663,404,45),close_overlay,false,16)

func start_level(number: int, resume: bool = false, test_definition: Dictionary = {}) -> void:
	if test_definition.is_empty() and (number < 1 or number > mini(Catalog.count(),int(save.data.unlocked))): return
	test_mode = not test_definition.is_empty()
	var definition: Dictionary=Catalog.get_level(number) if not test_mode else test_definition
	if resume and not save.data.active.is_empty():definition=save.data.active.get("level_definition",definition)
	board = Board.new(definition)
	if resume and not save.data.active.is_empty(): board.restore(save.data.active)
	begin_page("game")
	apply_world_progress(Catalog.world_for(number))
	card(page,Rect2(23,12,494,59),Color(1,.98,.94,.9))
	label(page,"GELİŞTİRİCİ TESTİ" if test_mode else world_name(selected_world),Rect2(32,15,350,19),11,Palette.GOLD)
	level_label=label(page,"%02d  /  %s"%[number,board.level.name],Rect2(32,35,415,31),20)
	button(page,"Ⅱ",Rect2(456,23,52,40),show_pause,false,23)
	card(page,Rect2(30,79,480,57))
	label(page,Strings.text("score"),Rect2(49,85,150,17),11,Palette.MUTED)
	score_label=label(page,"0",Rect2(49,104,140,27),23)
	label(page,Strings.text("moves"),Rect2(351,85,139,17),11,Palette.MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	moves_label=label(page,"",Rect2(354,104,136,27),23,Palette.GOLD,HORIZONTAL_ALIGNMENT_RIGHT)
	star_progress=preload("res://scripts/ui/star_progress.gd").new()
	star_progress.position=Vector2(195,102);star_progress.size=Vector2(142,24)
	star_progress.thresholds=board.level.stars;star_progress.quiet=save.data.settings.reduced_motion
	page.add_child(star_progress)
	goals_panel=preload("res://scripts/ui/goals_panel.gd").new()
	goals_panel.position=Vector2(30,145);goals_panel.size=Vector2(480,112)
	goals_panel.quiet=save.data.settings.reduced_motion
	page.add_child(goals_panel)
	goals_panel.configure(board.active_targets(),board.collected)
	goals_panel.goal_pressed.connect(show_goal_description)
	goals_panel.goal_completed.connect(func(_key):audio.play("resonance"))
	companion=preload("res://scripts/ui/companion.gd").new();companion.position=Vector2(458,873);companion.size=Vector2(48,48);companion.quiet=save.data.settings.get("companion_quiet",false) or save.data.settings.reduced_motion;page.add_child(companion)
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
	board_view.device_pressed.connect(show_seal_description)
	board_view.wave_started.connect(on_wave)
	board_view.environment_started.connect(on_environment)
	board_view.animation_finished.connect(on_animation_finished)
	card(page,Rect2(30,816,480,47),Color("fff8e9"))
	storm_gauge=preload("res://scripts/ui/storm_gauge.gd").new();storm_gauge.position=Vector2(36,817);storm_gauge.size=Vector2(468,44);page.add_child(storm_gauge)
	resonance_label=label(page,"",Rect2(38,869,464,22),12,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	gravity_buttons.clear()
	hint_label=label(page,"",Rect2(28,898,484,38),12,Palette.MUTED,HORIZONTAL_ALIGNMENT_CENTER);hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_color_override("font_color",Color("fff9e8"))
	hint_label.add_theme_color_override("font_outline_color",Color(.13,.08,.2,.85))
	hint_label.add_theme_constant_override("outline_size",3)
	if test_mode:button(page,"Test araçları",Rect2(330,937,172,23),show_mechanic_test_tools,false,11)
	for node in page.get_children():
		if node is Control and node.position.y<270:node.set_meta("hud_y",node.position.y)
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
	queue_goal_tutorials()

func update_hud(update_goals: bool=true) -> void:
	if update_goals and board.level.has("objective_stages"):level_label.text="%d / %s · %d/%d"%[int(board.level.id),board.level.name,board.objective_stage+1,board.level.objective_stages.size()]
	star_progress.target=board.score
	score_target = board.score
	score_display = board.score
	score_label.text = str(board.score)
	moves_label.text = str(board.moves)
	if update_goals:
		if goals_panel.targets!=board.active_targets():goals_panel.configure(board.active_targets(),board.collected)
		goals_panel.update_progress(board.collected,false)
	resonance_label.text = "YANKI  ·  %s %d/3" % [Strings.COLORS[board.resonance.color] if board.resonance.color >= 0 else "", board.resonance.count] if board.level.resonance else ""
	if update_goals:storm_gauge.set_value(board.storm_charge())
	var progress := 0.0
	for color in 5: garden.color_energy[color] = board.collected[str(color)]
	for key in board.level.targets:
		progress += minf(1, float(Objectives.value(board.collected,key)) / float(board.level.targets[key]))
	garden.vitality=maxf(garden.vitality,.15+.65*progress/board.level.targets.size())

func set_hint(text: String) -> void:
	hint_age=0.0
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
	update_hud(false)
	score_display = board.score - int(event.points)
	score_target = score_display
	star_progress.target=score_display
	score_label.text = str(int(score_display))
	# Persist only the completely settled logical result, before cosmetic playback.
	if not test_mode:
		preload("res://scripts/core/adventure_progress.gd").action(save.data,event)
		if board.outcome == "won": save.complete(board)
		else: save.save_active(board)
	board_view.animate(event)

func on_environment(data: Dictionary) -> void:
	if data.kind in ["storm","crystal_wave"] and not test_mode:
		var marker: String="gameplay2_"+str(data.kind)
		if marker not in save.data.tutorials:
			save.data.tutorials.append(marker);save.flush()
			set_hint("12 kristal enerjisi: Fırtına yönü kendisi seçer." if data.kind=="storm" else "Üç eşleşme zinciri: Dalga en fazla iki normal kristali boyar.")
	if data.kind=="shuffle":set_hint("Kristaller karıştırılıyor!")
	storm_gauge.set_value(int(data.get("storm_energy",board.storm_charge())))
	audio.play({"portal":"portal","vine":"vine","paint":"resonance","bubble":"pop","conveyor":"gravity","seal":"color","trait":"resonance","storm":"storm","crystal_wave":"crystal_wave","shuffle":"shuffle","magnet":"magnet"}.get(data.kind,"pop"))
	if data.has("collected"):goals_panel.update_progress(data.collected)

func on_wave(data: Dictionary) -> void:
	if is_instance_valid(companion):companion.react("excited" if int(data.combo)>2 or data.get("combo_kind","")!="" else "happy")
	storm_gauge.set_value(int(data.get("storm_energy",board.storm_charge())))
	goals_panel.update_progress(data.get("collected",board.collected))
	if not data.get("beams",[]).is_empty():audio.play("mirror")
	for effect in data.get("mechanics",[]):
		if effect.kind in ["vine","crate"]:audio.play(effect.kind);break
	for e in data.get("canyon_events",[]):
		audio.play("core_break" if e.kind=="core" and e.get("opened",false) else "giant_break" if e.kind=="giant" and e.get("hp",1)==0 else "floor_crack")
	star_progress.target=data.score
	score_target = data.score
	if data.get("combo_kind","")!="":
		audio.play("combo_power");audio.vibrate(true)
	elif data.resonated:
		audio.play("resonance")
		audio.vibrate(true)
	elif data.get("special", false):
		var power_key := "prism"
		for index in data.get("triggered",[]):
			if data.before[index].p == "color": power_key = "color"; break
			if data.before[index].p.begins_with("rocket"): power_key = "rocket"
		audio.play(power_key)
		audio.vibrate(true)
	elif not data.get("creations",[]).is_empty():
		var key := "rocket"
		for creation in data.creations:
			if creation.kind=="color": key="color"; break
			if creation.kind=="prism": key="prism"
		audio.play("match4" if key=="rocket" else "match5")
		audio.play(key)
		audio.vibrate(true)
	else:
		audio.play("match5" if data.removed.size()>=5 else "match4" if data.removed.size()==4 else "match3")
		audio.vibrate()
	var mechanic_sound := ""
	for effect in data.get("mechanics",[]):
		if not effect.opened: continue
		if effect.kind=="lock": mechanic_sound="color"; break
		elif effect.kind=="stone" or effect.kind=="ice": mechanic_sound="large"
		elif mechanic_sound=="": mechanic_sound="resonance"
	if mechanic_sound!="": audio.play(mechanic_sound)
	if data.combo > 1:
		audio.play("combo_big" if int(data.combo)>=4 else "cascade",mini(4,int(data.combo)-1))
		var names := ["KOMBO!", "SÜPER!", "MUHTEŞEM!", "EFSANEVİ!"]
		set_hint("%s  ·  x%d  ·  +%d puan" % [names[mini(3, int(data.combo) - 2)], data.multiplier, data.points])

func on_animation_finished() -> void:
	if board == null or screen != "game": return
	update_hud()
	if board.recovery_failed:
		open_overlay("Tahta kurtarılamadı","Durum tanılama kaydına alındı. Hamle, puan ve hedefler korunuyor.")
		button(overlay,"BÖLÜMÜ YENİDEN DENE",Rect2(68,605,404,45),request_level.bind(int(board.level.id)),true,16)
		button(overlay,"ANA MENÜ",Rect2(68,661,404,45),show_home,false,16)
		return
	if board.outcome != "playing": show_result()


func on_gravity(_direction: String) -> void:
	# Old callbacks are inert; no player/manual direction selection exists.
	return

func show_seal_description(index: int) -> void:
	if screen!="game" or board_view.busy:return
	var m: Dictionary=board.cells[index].get("obstacle",{})
	if m.get("kind","")!="seal":return
	close_goal_tip();goal_tip=Control.new();goal_tip.position=Vector2(30,12+(stage.size.y-960)*.5);goal_tip.size=Vector2(480,125);page.add_child(goal_tip)
	card(goal_tip,Rect2(0,0,480,125),Color("fffaf0"))
	label(goal_tip,"ŞİFRELİ MÜHÜR · RENK SIRASI",Rect2(18,8,400,25),16,Palette.GOLD)
	for k in m.sequence.size():
		var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=preload("res://scripts/ui/goal_registry.gd").icon(str(m.sequence[k]));icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.position=Vector2(25+k*70,42);icon.size=Vector2(42,42);goal_tip.add_child(icon)
		label(goal_tip,"✓" if k<int(m.step) else ("SIRADAKİ" if k==int(m.step) else ""),Rect2(15+k*70,91,62,18),10,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	button(goal_tip,"×",Rect2(429,9,42,38),close_goal_tip,false,20)
func show_goal_description(key: String,tutorial: bool=false) -> void:
	if screen!="game" or not board.level.targets.has(key):return
	close_goal_tip()
	board_view.highlight_goal(key)
	goal_tip=Control.new();goal_tip.position=Vector2(30,12+(stage.size.y-960)*.5);goal_tip.size=Vector2(480,125)
	page.add_child(goal_tip)
	card(goal_tip,Rect2(0,0,480,125),Color("fffaf0"))
	var registry=preload("res://scripts/ui/goal_registry.gd")
	var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=registry.icon(key);icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.position=Vector2(12,24);icon.size=Vector2(65,65);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;goal_tip.add_child(icon)
	label(goal_tip,"YENİ HEDEF · "+registry.entry(key)[2] if tutorial else registry.entry(key)[2],Rect2(88,10,325,23),16,Palette.GOLD)
	var text:=label(goal_tip,registry.description(key,int(board.level.targets[key])),Rect2(88,35,330,70),15)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(goal_tip,"×",Rect2(429,9,42,38),advance_goal_tutorial if tutorial else close_goal_tip,false,20)
	if tutorial:button(goal_tip,"GEÇ",Rect2(374,92,95,26),advance_goal_tutorial,false,11)
func close_goal_tip() -> void:
	if is_instance_valid(goal_tip):goal_tip.hide();goal_tip.queue_free()
	goal_tip=null
func queue_goal_tutorials() -> void:
	if test_mode:return
	for key in board.level.targets:
		var marker: String="goal_"+key
		if marker not in save.data.tutorials:pending_goal_tutorials.append(key)
	if not pending_goal_tutorials.is_empty():
		var key: String=pending_goal_tutorials.pop_front()
		if "goal_"+key not in save.data.tutorials:save.data.tutorials.append("goal_"+key)
		save.flush();show_goal_description(key,true)
func advance_goal_tutorial() -> void:
	close_goal_tip()
	if not pending_goal_tutorials.is_empty():
		var key: String=pending_goal_tutorials.pop_front()
		if "goal_"+key not in save.data.tutorials:save.data.tutorials.append("goal_"+key)
		save.flush();show_goal_description(key,true)
func replay_goal_tutorials() -> void:
	close_overlay()
	pending_goal_tutorials=board.level.targets.keys().duplicate()
	advance_goal_tutorial()
func show_help() -> void:
	open_overlay("Nasıl oynanır?")
	var body := label(overlay, Strings.text("help_body"), Rect2(62, 311, 416, 308), 17, Palette.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"HEDEFLER / ÖĞRETİCİLER",Rect2(68,595,404,32),show_goal_gallery,false,13)
	button(overlay, "ENGELLER VE HEDEFLER", Rect2(68, 637, 404, 36), show_mechanic_help, false, 13)
	button(overlay, "DEVAM ET", Rect2(68, 685, 404, 36), close_overlay, true, 15)

func show_goal_gallery(group: int=0) -> void:
	var registry=preload("res://scripts/ui/goal_registry.gd")
	var keys: Array=["0","1","2","3","4"]+registry.ENTRIES.keys()
	open_overlay("Hedefleri tanı","İkona dokun; kısa öğreticiyi gör.")
	for k in 6:
		var index:=group*6+k
		if index>=keys.size():break
		var key: String=keys[index];var x: int=65+(k%2)*210;var y: int=384+(k/2)*84
		button(overlay,registry.entry(key)[2],Rect2(x,y,200,74),show_goal_reference.bind(key,group),false,12)
		var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=registry.icon(key);icon.position=Vector2(x+7,y+13);icon.size=Vector2(35,35);icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(icon)
	if (group+1)*6<keys.size():button(overlay,"SONRAKİ",Rect2(280,654,193,32),show_goal_gallery.bind(group+1),false,13)
	if group>0:button(overlay,"ÖNCEKİ",Rect2(67,654,193,32),show_goal_gallery.bind(group-1),false,13)
	button(overlay,"GERİ",Rect2(67,695,406,29),show_help,false,13)
func show_goal_reference(key: String,group: int) -> void:
	var registry=preload("res://scripts/ui/goal_registry.gd")
	open_overlay(registry.entry(key)[2])
	var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=registry.icon(key);icon.position=Vector2(220,376);icon.size=Vector2(100,100);icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;overlay.add_child(icon)
	var explanation:=label(overlay,registry.description(key,1),Rect2(70,500,400,112),18);explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"DİĞER HEDEFLER",Rect2(68,653,404,43),show_goal_gallery.bind(group),true,15)

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
	dim.color = Color(.27,.31,.58,.38)
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
	button(overlay, Strings.text("replay"), Rect2(68, 421, 404, 59), request_level.bind(int(board.level.id)), true)
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
	if won and int(board.level.id)==int(Worlds.get_world(Catalog.world_for(int(board.level.id))).end):
		save.complete(board)
		show_world_result()
		return
	if won: save.complete(board)
	else:
		save.data.active = {}
		save.flush()
	audio.play("success2" if won else "lose")
	open_overlay("Okyanus meydan okuması!" if won and int(board.level.id)==75 else (str(Worlds.get_world(Catalog.world_for(int(board.level.id))).get("success_text","Dünya renkleniyor!")) if won else Strings.text("lost")), "Her renk bir iz bırakır." if won else "Farklı bir renk sırası veya özel güç birleşimi dene.")
	if won:
		if not save.data.settings.reduced_motion and not save.data.settings.get("reduced_effects",false) and save.data.settings.get("quality","auto")!="performance":
			var confetti := Celebration.new()
			confetti.world_finale=int(board.level.id)==75
			confetti.challenge=int(board.level.id)==75
			overlay.add_child(confetti)
		var stars: int = Score.stars(board.score, board.level.stars)
		for i in 3:
			var star:=TextureRect.new();star.texture=CasualSkin.texture("ui",3,CasualSkin.UI)
			star.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			star.position=Vector2(165+i*72,371);star.size=Vector2(66,66)
			star.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star.modulate=Color.WHITE if i<stars else Color(.6,.65,.7,.45)
			star.pivot_offset=Vector2(33,33);overlay.add_child(star)
			if not save.data.settings.reduced_motion:
				star.scale=Vector2(.1,.1)
				var tween:=star.create_tween();tween.tween_property(star,"scale",Vector2.ONE,.24).set_delay(i*.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		label(overlay, "%d PUAN" % board.score, Rect2(66, 436, 408, 37), 26, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		label(overlay, "2★: %d   ·   3★: %d" % [board.level.stars[1], board.level.stars[2]], Rect2(66, 475, 408, 28), 13, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		if int(board.level.id) < Catalog.count():
			button(overlay, Strings.text("next"), Rect2(68, 529, 404, 58), request_level.bind(int(board.level.id) + 1), true)
		else:
			label(overlay, "%d bölüm tamamlandı!"%Catalog.count(), Rect2(66, 516, 408, 38), 22, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			button(overlay, "OKYANUSU KEŞFET" if int(board.level.id)>=51 else Strings.text("map"), Rect2(68, 567, 404, 53), show_map, true)
		button(overlay, Strings.text("replay"), Rect2(68, 637, 404, 53), request_level.bind(int(board.level.id)))
	else:
		var remaining:=preload("res://scripts/ui/goals_panel.gd").new()
		remaining.position=Vector2(30,357);remaining.size=Vector2(480,112);remaining.quiet=true
		overlay.add_child(remaining);remaining.configure(board.active_targets(),board.collected)
		button(overlay, Strings.text("replay"), Rect2(68, 467, 404, 59), request_level.bind(int(board.level.id)), true)
		button(overlay, Strings.text("map"), Rect2(68, 552, 404, 55), show_map)

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
	var definitions := [["companion_quiet","Pırıl için sakin mod"],["shake","Hafif ekran sarsıntısı"],["reduced_effects","Azaltılmış efektler"],["reduced_motion","Daha az hareket"],["haptics","Dokunma titreşimi"],["colorblind","Şekille renk erişimi"]]
	for k in definitions.size():
		var key: String = definitions[k][0]
		var y := 275+k*53
		card(page,Rect2(32,y,476,54))
		label(page,definitions[k][1],Rect2(48,y+7,314,40),18)
		var toggle := button(page,"AÇIK" if save.data.settings[key] else "KAPALI",Rect2(371,y+8,119,38),func(): toggle_setting(key),save.data.settings[key],13)
		toggle.name = key
	volume_slider("music","Müzik",620)
	volume_slider("sfx","Efekt sesi",693)
	button(page,"YARDIM / ÖĞRETİCİLER",Rect2(42,768,222,44),show_help,false,13)
	button(page,"Performans raporu",Rect2(274,768,224,44),show_diagnostics,false,13)
	button(page,Strings.text("resume") if not save.data.active.is_empty() else Strings.text("home"),Rect2(42,835,456,56),play_latest if not save.data.active.is_empty() else show_home,true)
	label(page,"PRİZMA 0.12 · RENKLERİN MACERASI",Rect2(32,920,476,28),12,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)

	if developer_tools_available():
		button(page,"Geliştirici: mekanik laboratuvarı",Rect2(42,896,456,27),start_mechanic_test,false,12)

func volume_slider(key: String, title: String, y: float) -> void:
	card(page,Rect2(32,y-4,476,69),Color(1,.98,.94,.93))
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
	for state in ["normal","hover","pressed"]:
		btn.add_theme_stylebox_override(state,CasualSkin.panel_style(0 if active else 1))
	for key in ["font_color","font_hover_color","font_pressed_color"]:
		btn.add_theme_color_override(key,Palette.INK)

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
	var kinds: Array=["seed","ice","stone","lock","dual","chameleon","bridge","pin","portal","vine","crate","mirror","fountain","bubble","conveyor","seal"]
	var names: Array=["Tohum","Buz","Taş","Renk kilidi","Çift renk","Bukalemun","Prizma Köprüsü","Yer Çekimi Çivisi","Portal sahnesi","Sarmaşık sahnesi","Sandık sahnesi","Ayna sahnesi","Boyama Çeşmesi","Yüzen Baloncuk","Konveyör","Şifreli Mühür"]
	for i in 16:
		button(overlay,names[i],Rect2(68+(i%2)*208,386+int(i/2)*33,196,29),add_test_mechanic.bind(kinds[i]),false,14)
	button(overlay,"SEED İLE TAHTAYI SIFIRLA",Rect2(68,653,404,42),start_mechanic_test,true,15)
	button(overlay,"GERİ DÖN",Rect2(68,706,404,38),close_overlay,false,15)

func add_test_mechanic(kind: String) -> void:
	if not developer_tools_available() or not test_mode or board_view.busy: return
	close_overlay()
	if not board.available(): return
	if kind in ["portal","vine","crate","mirror","fountain","bubble","conveyor","seal"]:
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
	audio.play("success2")
	garden.vitality=1.0
	garden.world_completed=true
	garden.color_energy=[18,18,18,18,18]
	var metadata:=Worlds.get_world(selected_world)
	var finale_text: String={"cloud":"Bulutların arasında gökkuşağı dalgası yayıldı!","lava":"Lav nehirleri kristal enerjisine dönüştü!"}.get(str(metadata.theme),"Renkler uyandı!")
	open_overlay(str(metadata.title)+" uyandı!",finale_text+" "+str(metadata.reward)+" kaydedildi.")
	var medal:=TextureRect.new()
	medal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	medal.texture=load(metadata.reward_icon) if metadata.has("reward_icon") else (CasualSkin.texture("decor",7,CasualSkin.DECOR) if selected_world==2 else CasualSkin.texture("traits",18,CasualSkin.TRAITS))
	medal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.position=Vector2(202,376)
	medal.size=Vector2(136,136)
	medal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(medal)
	label(overlay,str(metadata.reward).to_upper(),Rect2(55,514,430,31),17,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	label(overlay,"★".repeat(Score.stars(board.score,board.level.stars))+"  ·  %d PUAN"%board.score,Rect2(55,553,430,30),19,Palette.INK,HORIZONTAL_ALIGNMENT_CENTER)
	if not save.data.settings.reduced_motion and not save.data.settings.get("reduced_effects",false) and save.data.settings.get("quality","auto")!="performance":
		var celebration:=Celebration.new()
		celebration.world_finale=true
		celebration.ocean=selected_world==2
		celebration.canyon=selected_world==3
		celebration.world_theme=str(metadata.theme)
		celebration.accent=Color(metadata.accent)
		overlay.add_child(celebration)
	if int(board.level.id)<Catalog.count():
		button(overlay,"SONRAKİ DÜNYA",Rect2(68,604,404,45),request_level.bind(int(board.level.id)+1),true,17)
	else:
		label(overlay,"%d dünya · %d bölüm tamamlandı!"%[Worlds.playable_worlds().size(),Catalog.count()],Rect2(55,599,430,32),17,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	button(overlay,"DÜNYAYI KEŞFET",Rect2(68,653,404,45),show_map.bind(int((int(Worlds.get_world(selected_world).end)-1)/10)),true,17)

func show_crystal_help() -> void:
	open_overlay("İki rengin uyanışı")
	var body:=label(overlay,"Çift renkli kristal yalnızca gösterdiği iki renkle eşleşir. Bir dalgada tek renk olarak sayılır.\n\nBukalemun iki başarılı takasın zincirleri bittikten sonra sıradaki rengine geçer. Parlayan çerçeve dönüşümün yaklaştığını gösterir. Geçersiz takas, zincirler ve yön değişimi sayacı ilerletmez.\n\nPrizma Köprüsü her renge uyum sağlar; en az bir renkli kristalle üçlü çizgi oluşturmalıdır. 51. bölümde tanıtılır.\n\nYer Çekimi Çivisi kristali sabit tutar; iki ayrı darbeyle açılır. 56. bölümde tanıtılır.",Rect2(61,315,418,315),17)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"ANLADIM",Rect2(68,658,404,48),close_overlay,true,16)

func show_adventure_menu(kind: int) -> void:
	var progress_rule=preload("res://scripts/core/adventure_progress.gd")
	progress_rule.ensure(save.data)
	var progress: Dictionary=save.data.adventure_progress
	open_overlay(["Günlük görevler","Kurtardığın dostlar","Kazanılan ödüller"][kind],"Çevrimdışı maceran bu cihazda saklanır.")
	if kind==0:
		var d: Dictionary=progress_rule.daily(save.data)
		var keys: Array=["blue","wins","combos"]
		var names: Array=["Mavi kristal", "Yeni bölüm tamamla", "Büyük kombo"]
		var amounts: Array=[30,3,2]
		for i in 3:
			label(overlay,"%s · %d/%d"%[names[i],mini(int(d[keys[i]]),amounts[i]),amounts[i]],Rect2(65,374+i*72,282,44),17)
			var claim:=button(overlay,"ALINDI" if keys[i] in d.claimed else "+15",Rect2(360,374+i*72,112,44),func():
				if progress_rule.claim_daily(save.data,keys[i]):save.flush();show_adventure_menu(0),false,15)
			claim.disabled=keys[i] in d.claimed or int(d[keys[i]])<amounts[i]
	elif kind==1:
		for i in 5:
			var c:=preload("res://scripts/ui/companion.gd").new();c.creature=i+1;c.position=Vector2(69+(i%3)*136,365+int(i/3)*125);c.size=Vector2(108,108);c.quiet=save.data.settings.reduced_motion
			c.modulate=Color.WHITE if "creature-%d"%(i+1) in progress.creatures else Color(.4,.45,.5,.45);overlay.add_child(c)
		label(overlay,"%d / 5 dost kurtarıldı"%progress.creatures.size(),Rect2(68,623,404,34),19,Palette.INK,HORIZONTAL_ALIGNMENT_CENTER)
	else:
		label(overlay,"%d KRİSTAL PARA\n\nRoket: %d · Gökkuşağı Yıldızı: %d\n\n%d hazine sandığı açıldı"%[progress.coins,progress.inventory.get("rocket",0),progress.inventory.get("prism",0),progress.claimed.size()],Rect2(68,375,404,230),20,Palette.INK,HORIZONTAL_ALIGNMENT_CENTER)
	button(overlay,"KAPAT",Rect2(68,690,404,45),close_overlay,false,16)
