extends Control

const Design=preload("res://scripts/ui/ui_theme.gd")
const IconButton=preload("res://scripts/ui/visual_icon_button.gd")
var map_scroll: ScrollContainer
var settings_origin:="map"
var transition_token:=0
var entering_level:=false
var last_move_badge:=-1
var move_tween: Tween
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

var production_mode:=OS.has_feature("prizma_production")
var boss_badge
var companion
var earned_treasure:=false
var selected_booster:=""
var fast_test:=false
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
var armed_helper:=""
var helper_buttons: Dictionary={}
var reading_goal:=false
var game_hud
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
	if save==null:save = Save.new("user://prizma-dev-save.json" if OS.has_feature("prizma_dev_tools") or OS.has_feature("editor") else "user://prizma-save.json")
	if OS.has_feature("prizma_dev_tools"):save.data.unlocked=Catalog.count()
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
	if not save.data.settings.reduced_motion:
		var splash:=Control.new();splash.size=stage.size;splash.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(splash)
		var emblem:=TextureRect.new();emblem.texture=Design.icon("gems",7);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.position=Vector2(211,stage.size.y*.42);emblem.size=Vector2(118,118);splash.add_child(emblem)
		label(splash,"PRİZMA",Rect2(155,stage.size.y*.42+125,230,50),40,Design.INK,HORIZONTAL_ALIGNMENT_CENTER)
		var intro:=splash.create_tween();intro.tween_property(splash,"modulate:a",0,.3);intro.tween_callback(splash.queue_free)

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
		page.position.y = 0 if screen in ["game","map","worlds"] else extra*.5
		if screen=="map" and is_instance_valid(map_scroll):
			map_scroll.size.y=maxf(200,stage.size.y-206)
			for node in footer_nodes:
				if is_instance_valid(node):node.position.y=float(node.get_meta("base_y"))+extra
	if screen == "game" and board_view:
		game_hud.position=Vector2(23,12+minf(24,extra*.1));game_hud.size.x=stage.size.x-46
		game_hud.update_height()
		var top: float=game_hud.position.y+game_hud.size.y+12
		var available_bottom: float=stage.size.y-190
		board_view.position.y = maxf(top,top+(available_bottom-top-board_view.size.y)*.5)
		for node in page.get_children():
			if node is Control and node.has_meta("hud_y") and node!=game_hud:node.position.y=float(node.get_meta("hud_y"))+extra*.5
		for node in footer_nodes:
			if is_instance_valid(node):
				var base: int=int(node.get_meta("base_y"))
				var offset: float={816:12,817:13,860:49,936:125,940:125,972:153,974:153}.get(base,base-736)
				if node.get_script()==preload("res://scripts/ui/companion.gd"):offset=92
				node.position.y=board_view.position.y+board_view.size.y+offset
				if node.get_script()==preload("res://scripts/ui/companion.gd"):node.base_y=node.position.y
	if screen=="game" and is_instance_valid(goal_tip):goal_tip.position.y=minf(board_view.position.y+board_view.size.y+125,stage.size.y-76)
	if overlay_root:
		overlay_root.size = stage.size
		overlay_root.get_child(0).size = stage.size
		overlay.position.y = extra*.5

func _process(delta: float) -> void:
	if screen=="worlds" and page!=null:
		var list:=page.get_node_or_null("WorldsScroll")
		if list!=null:
			for row in list.get_child(0).get_children():
				var image=row.get_child(0)
				if image is TextureRect and image.texture==null:image.texture=preload("res://scripts/ui/world_art_cache.gd").ready(str(image.get_meta("world_art")))
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
			game_hud.show_score(int(round(score_display)))
		elif score_display!=score_target:
			score_display = score_target
			game_hud.show_score(int(score_target))
	if board_view and is_instance_valid(board_view): garden.quality = board_view.quality

func _exit_tree() -> void:
	preload("res://scripts/ui/world_art_cache.gd").shutdown()
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
	if overlay != null:close_overlay()
	elif screen=="game":show_pause()
	elif screen=="map":
		open_overlay("Oyundan çıkılsın mı?","İlerlemen bu cihazda korunur.")
		button(overlay,"HARİTADA KAL",Rect2(80,461,380,58),close_overlay,true)
		button(overlay,"ÇIK",Rect2(80,536,380,48),func():persist_board();save.finish_writes();get_tree().quit(),false,17)
	elif screen=="worlds":show_map()
	else:show_home()

func persist_board() -> void:
	if test_mode: return
	if board != null and screen == "game":
		if board.outcome == "won": save.complete(board)
		elif board.outcome == "playing": save.save_active(board)
	elif settings_dirty: save.flush()
	settings_dirty = false

func begin_page(next_screen: String) -> void:
	transition_token+=1
	close_overlay()
	goal_tip=null
	reading_goal=false
	pending_goal_tutorials.clear()
	if page != null:
		page.hide()
		page.queue_free()
	page = Control.new()
	page.name = next_screen.capitalize()
	page.size = Vector2(540, 960)
	stage.add_child(page)
	screen = next_screen
	armed_helper=""
	helper_buttons.clear()
	if garden.backdrop:garden.backdrop.material.set_shader_parameter("game_focus",1.0 if next_screen in ["game","transition"] else 0.0)
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
	panel.add_theme_stylebox_override("panel",Design.surface())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false, font_size: int = 20) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal",Design.action(primary))
	btn.add_theme_stylebox_override("hover",Design.action(primary))
	btn.add_theme_stylebox_override("pressed",Design.action(primary,true))
	btn.add_theme_stylebox_override("disabled",Design.action(false,true))
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

func current_level() -> int:
	return int(save.data.active.get("level_id",save.data.unlocked))

func show_home() -> void:
	persist_board()
	show_map(int((current_level()-1)/10))

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
	card(page,Rect2(20,14,500,86))
	label(page,"DÜNYALAR",Rect2(39,29,360,38),29)
	button(page,"×",Rect2(456,33,44,40),go_back,false,23)
	var scroll:=ScrollContainer.new();scroll.name="WorldsScroll";scroll.position=Vector2(27,121);scroll.size=Vector2(486,704);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(scroll)
	var content:=Control.new();content.custom_minimum_size=Vector2(476,Worlds.playable_worlds().size()*116);scroll.add_child(content)
	var i:=0
	for metadata in Worlds.playable_worlds():
		var world: int=int(metadata.id)
		var row:=button(content,str(metadata.title).to_upper()+" · %d–%d"%[int(metadata.start),int(metadata.end)],Rect2(6,i*116+4,462,104),func():selected_world=world;show_map(int((int(metadata.start)-1)/10)),false,18)
		row.add_theme_stylebox_override("normal",Design.surface());row.add_theme_stylebox_override("disabled",Design.surface());row.add_theme_color_override("font_color",Color.TRANSPARENT);row.add_theme_color_override("font_disabled_color",Color.TRANSPARENT)
		row.set_meta("world_id",world)
		row.disabled=int(save.data.unlocked)<int(metadata.start)
		var image:=TextureRect.new();image.texture=preload("res://scripts/ui/world_art_cache.gd").ready(str(metadata.art));image.set_meta("world_art",str(metadata.art));image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.position=Vector2(9,9);image.size=Vector2(88,86);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(image)
		label(row,str(metadata.title),Rect2(111,14,326,33),21)
		var done: int=save.data.results.keys().filter(func(k):return Catalog.world_for(int(k))==world).size()
		label(row,"%d–%d · %d/%d tamamlandı"%[int(metadata.start),int(metadata.end),done,int(metadata.end)-int(metadata.start)+1],Rect2(111,50,326,27),14,Design.ACCENT)
		if row.disabled:label(row,"KİLİTLİ",Rect2(111,76,326,19),11,Palette.MUTED)
		i+=1
	label(page,"%d gerçek bölüm · %d dünya"%[Catalog.count(),Worlds.playable_worlds().size()],Rect2(35,871,470,37),16,Design.INK,HORIZONTAL_ALIGNMENT_CENTER)

func show_map(group: int=-1) -> void:
	persist_board();test_mode=false
	if group>=0:map_group=clampi(group,0,int((Catalog.count()-1)/10))
	else:map_group=int((int(Worlds.get_world(selected_world).start)-1)/10)
	begin_page("map")
	apply_world_progress(Catalog.world_for(map_group*10+1))
	var metadata:=Worlds.get_world(selected_world)
	preload("res://scripts/core/adventure_progress.gd").ensure(save.data)
	card(page,Rect2(20,10,500,64))
	var portrait:=preload("res://scripts/ui/companion.gd").new();portrait.position=Vector2(25,17);portrait.size=Vector2(52,52);portrait.quiet=save.data.settings.get("companion_quiet",false) or save.data.settings.reduced_motion;page.add_child(portrait)
	label(page,"PRİZMA",Rect2(88,17,230,25),20)
	label(page,"%d kristal"%int(save.data.adventure_progress.coins),Rect2(110,49,200,20),12,Design.ACCENT)
	var coin:=TextureRect.new();coin.texture=Design.icon("gems",3);coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;coin.position=Vector2(88,49);coin.size=Vector2(18,18);coin.mouse_filter=Control.MOUSE_FILTER_IGNORE;page.add_child(coin)
	button(page,"AYARLAR",Rect2(376,27,129,43),show_settings,false,13)
	label(page,str(metadata.title),Rect2(29,76,292,27),20,Design.INK)
	button(page,"DÜNYALAR",Rect2(350,76,156,29),show_worlds,false,12)
	map_buttons.clear()
	map_scroll=preload("res://scripts/ui/world_scroll.gd").new()
	map_scroll.position=Vector2(32,110);map_scroll.size=Vector2(476,734)
	map_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;map_scroll.follow_focus=false;page.add_child(map_scroll)
	var path:=MapPath.new()
	var first:=int(metadata.start);var last:=mini(Catalog.count(),int(metadata.end))
	path.count=last-first+1;path.ocean=selected_world==2;path.canyon=selected_world==3;path.world_theme=str(metadata.map_style);path.accent=Color(metadata.accent)
	path.quiet=save.data.settings.reduced_motion;path.completed_count=save.data.results.keys().filter(func(k):return Catalog.world_for(int(k))==selected_world).size()
	path.custom_minimum_size=Vector2(456,path.count*128+188);map_scroll.add_child(path)
	for n in range(first,last+1):
		var center: Vector2=path.node_position(n-first)
		var node:=preload("res://scripts/ui/level_node.gd").new()
		node.number=n;node.text=str(n);node.stars=int(save.data.results.get(str(n),{}).get("stars",0));node.active=n==current_level();node.finale=n==last
		node.size=Vector2(88,88) if node.finale or node.active else Vector2(76,76);node.position=center-node.size/2;node.disabled=n>save.data.unlocked
		var special: Dictionary=Design.marker_for(n)
		if not special.get("treasure",{}).is_empty():node.marker=preload("res://assets/casual/treasure-lid.svg")
		elif special.has("kind"):node.marker=preload("res://scripts/ui/goal_registry.gd").icon("rescues" if special.kind=="rescue" else "bosses")
		node.pressed.connect(request_level.bind(n));path.add_child(node);map_buttons[n]=node
		if node.active and not save.data.settings.reduced_motion:
			node.pivot_offset=node.size/2;var pulse:=node.create_tween().set_loops();pulse.tween_property(node,"scale",Vector2(1.05,1.05),.6);pulse.tween_property(node,"scale",Vector2.ONE,.6)
	var focus:=current_level() if current_level()>=first and current_level()<=last else first
	map_scroll.set_deferred("scroll_vertical",maxi(0,int(path.node_position(focus-first).y-map_scroll.size.y*.7)))
	button(page,"GÜNCEL BÖLÜM",Rect2(316,812,188,41),show_home,false,12).set_meta("base_y",812)
	var bar:=card(page,Rect2(17,878,506,70));bar.set_meta("base_y",878);footer_nodes.append(bar)
	var names: Array=["Harita","Günlük","Dostlar","Ödüller","Ayarlar"]
	var images: Array=[preload("res://assets/casual/navigation-map.svg"),preload("res://assets/casual/navigation-tasks.svg"),preload("res://scripts/ui/companion.gd").sprite(1),preload("res://assets/casual/treasure-lid.svg"),preload("res://assets/casual/navigation-settings.svg")]
	var actions: Array=[show_home,show_adventure_menu.bind(0),show_adventure_menu.bind(1),show_adventure_menu.bind(2),show_settings]
	for i in 5:
		var nav:=IconButton.new();nav.position=Vector2(25+i*99,879);nav.size=Vector2(94,66);nav.caption=names[i];nav.image=images[i];nav.chosen=i==0;nav.set_meta("navigation_index",i);nav.pressed.connect(actions[i]);page.add_child(nav);nav.set_meta("base_y",879);footer_nodes.append(nav)
	for node in page.get_children():
		if node is Button and node.has_meta("base_y"):footer_nodes.append(node)
	layout_stage()

func request_level(number: int) -> void:
	selected_booster=""
	if number<1 or number>mini(Catalog.count(),int(save.data.unlocked)):return
	persist_board()
	var resume_requested: bool=not save.data.active.is_empty() and int(save.data.active.get("level_id",0))==number
	var definition: Dictionary=save.data.active.get("level_definition",Catalog.get_level(number)) if resume_requested else Catalog.get_level(number)
	apply_world_progress(Catalog.world_for(number))
	open_overlay("","")
	audio.play("preview_open")
	for child in overlay.get_children():child.queue_free()
	overlay.set_meta("preview_level",number)
	card(overlay,Rect2(54,155,432,650))
	var kind: String="DÜNYA FİNALİ" if number==int(Worlds.get_world(Catalog.world_for(number)).end) else "KURTARMA" if definition.get("adventure",{}).get("kind","")=="rescue" else "BEKÇİ MÜCADELESİ" if definition.get("adventure",{}).get("kind","")=="boss" else "HAZİNE" if definition.has("treasure") else "KRİSTAL MACERASI"
	label(overlay,kind,Rect2(78,172,348,24),12,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
	label(overlay,"BÖLÜM %d"%number,Rect2(78,201,348,39),30,Design.INK,HORIZONTAL_ALIGNMENT_CENTER)
	button(overlay,"×",Rect2(426,169,48,48),close_overlay,false,22)
	var preview:=preload("res://scripts/ui/goals_panel.gd").new();preview.position=Vector2(72,264);preview.size=Vector2(396,112);preview.compact=true;preview.preview_mode=true;preview.quiet=true;overlay.add_child(preview)
	preview.configure(definition.targets,save.data.active.get("collected",{}) if resume_requested else {})
	var explanation_panel:=PanelContainer.new();explanation_panel.name="PreviewExplanation";explanation_panel.position=Vector2(78,418);explanation_panel.size=Vector2(384,100);var explanation_style:=Design.surface();
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:explanation_style.set_content_margin(side,12)
	explanation_panel.add_theme_stylebox_override("panel",explanation_style);overlay.add_child(explanation_panel)
	var description_scroll:=ScrollContainer.new();description_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;explanation_panel.add_child(description_scroll)
	var explanation:=Label.new();explanation.name="ExplanationText";explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;explanation.size_flags_horizontal=Control.SIZE_EXPAND_FILL;explanation.add_theme_font_size_override("font_size",14);explanation.add_theme_color_override("font_color",Design.INK);description_scroll.add_child(explanation)
	explanation.text="Hedeflerin nasıl tamamlandığını görmek için bir simgeye dokun."
	preview.goal_pressed.connect(func(key):explanation.text=preload("res://scripts/ui/goal_registry.gd").description(key,int(definition.targets[key])))
	label(overlay,"%d hamle%s"%[int(save.data.active.get("moves",definition.moves)) if resume_requested else int(definition.moves)," · kayıtlı oyun" if resume_requested else ""],Rect2(94,383,352,28),16,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
	label(overlay,"GÜÇLENDİRİCİLER",Rect2(78,531,384,23),14,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
	preload("res://scripts/core/adventure_progress.gd").ensure(save.data)
	for i in 2:
		var key: String=["rocket","prism"][i];var stock:=int(save.data.adventure_progress.inventory.get(key,0))
		var choose:=IconButton.new();choose.position=Vector2(153+i*138,566);choose.size=Vector2(96,92);choose.caption="Roket" if key=="rocket" else "Prizma";choose.icon_radius=38;choose.image=Design.icon("gems",5 if i==0 else 7);choose.amount=stock;choose.tooltip_text="Roket" if i==0 else "Gökkuşağı Yıldızı"
		choose.locked=not preload("res://scripts/core/booster_catalog.gd").unlocked(save.data,key);choose.disabled=resume_requested;choose.unavailable=choose.locked or stock<=0;choose.set_meta("booster",key);overlay.add_child(choose)
		choose.pressed.connect(func():
			var rules=preload("res://scripts/core/booster_catalog.gd")
			if not rules.available(save.data,key):
				explanation.text="Bu güç %d. bölümde açılır."%int(rules.ITEMS[key].unlock) if not rules.unlocked(save.data,key) else "Stok yok. Bölüm ve hazine ödülleriyle kazanabilirsin."
				audio.play("locked");return
			explanation.text=rules.ITEMS[key].help
			audio.play("booster_select")
			selected_booster=key if selected_booster!=key else ""
			for item in overlay.get_children():
				if item is IconButton:item.chosen=str(item.get_meta("booster",""))==selected_booster;item.queue_redraw())
	var booster_rules=preload("res://scripts/core/booster_catalog.gd")
	for key in booster_rules.ITEMS:
		var marker: String="booster_intro_"+key
		if booster_rules.unlocked(save.data,key) and marker not in save.data.tutorials:
			save.data.tutorials.append(marker);save.flush()
			explanation.text="Yeni güç açıldı! "+str(booster_rules.ITEMS[key].name)+" · "+str(booster_rules.ITEMS[key].help)
			var acknowledgement:=button(overlay,"ANLADIM",Rect2(306,668,150,30),func():
				explanation.text="Hedef simgelerine dokunarak açıklamaları görebilirsin."
				var node=overlay.get_node_or_null("BoosterAcknowledgement")
				if node:node.hide(),false,13)
			acknowledgement.name="BoosterAcknowledgement"
			break
	button(overlay,"OYNA!",Rect2(83,711,374,63),func():
		close_overlay();begin_page("transition")
		var trail:=preload("res://scripts/ui/level_transition.gd").new();trail.quiet=save.data.settings.reduced_effects or save.data.settings.reduced_motion;page.add_child(trail)
		var guide:=preload("res://scripts/ui/companion.gd").new();guide.position=Vector2(198,299);guide.size=Vector2(144,144);guide.quiet=save.data.settings.get("companion_quiet",false) or save.data.settings.reduced_motion;page.add_child(guide);guide.react("excited")
		label(page,"KRİSTALLER UYANIYOR",Rect2(38,456,464,60),24,Design.INK,HORIZONTAL_ALIGNMENT_CENTER)
		var launch_token:=transition_token
		await get_tree().create_timer(.05 if fast_test or save.data.settings.reduced_motion else .55).timeout
		if screen=="transition" and launch_token==transition_token:start_level(number,resume_requested,{},true),true,25)
	if not save.data.settings.reduced_motion:
		overlay.pivot_offset=Vector2(270,488);overlay.scale=Vector2(.88,.88);var intro:=overlay.create_tween();intro.tween_property(overlay,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func start_level(number: int, resume: bool = false, test_definition: Dictionary = {}, animate_entry: bool=false) -> void:
	entering_level=false
	if test_definition.is_empty() and (number < 1 or number > mini(Catalog.count(),int(save.data.unlocked))): return
	earned_treasure=false
	test_mode = not test_definition.is_empty()
	var definition: Dictionary=Catalog.get_level(number) if not test_mode else test_definition
	if resume and not save.data.active.is_empty():definition=save.data.active.get("level_definition",definition)
	board = Board.new(definition)
	if resume and not save.data.active.is_empty(): board.restore(save.data.active)
	elif selected_booster!="" and not test_mode and preload("res://scripts/core/booster_catalog.gd").available(save.data,selected_booster):
		var slot:=-1
		var hint: Array=board.level.get("tutorial_swap",[])
		var preserve_hint: bool=hint.size()==2 and Match.can_swap(board.cells,int(hint[0]),int(hint[1]),8,9)
		var kind: String="rocket_h" if selected_booster=="rocket" else "prism"
		for i in range(board.cells.size()-1,-1,-1):
			if board.cells[i]==null or board.cells[i].get("fixed",false) or board.cells[i].p!="" or (preserve_hint and i in hint):continue
			board.cells[i].p=kind
			var valid: bool=not preserve_hint or Match.can_swap(board.cells,int(hint[0]),int(hint[1]),8,9)
			board.cells[i].p=""
			if valid:slot=i;break
		if slot>=0 and preload("res://scripts/core/adventure_progress.gd").consume(save.data,selected_booster):board.cells[slot].p="rocket_h" if selected_booster=="rocket" else "prism"
	selected_booster=""
	begin_page("game")
	apply_world_progress(Catalog.world_for(number))
	game_hud=preload("res://scripts/ui/game_hud.gd").new()
	game_hud.position=Vector2(23,12);game_hud.size=Vector2(494,176);page.add_child(game_hud)
	game_hud.configure(board.level,"GELİŞTİRİCİ TESTİ" if test_mode else world_name(selected_world),board.collected,save.data.settings.reduced_motion)
	game_hud.pause_requested.connect(show_pause)
	level_label=game_hud.title;score_label=game_hud.score;moves_label=game_hud.moves;star_progress=game_hud.stars;goals_panel=game_hud.goals
	star_progress.star_earned.connect(func(_index):audio.play("star_award"))
	goals_panel.configure(board.active_targets(),board.collected);game_hud.update_height()
	goals_panel.goal_pressed.connect(show_goal_description)
	goals_panel.goal_completed.connect(func(_key):audio.play("resonance"))
	companion=preload("res://scripts/ui/companion.gd").new();companion.position=Vector2(458,936);companion.size=Vector2(48,48);companion.quiet=save.data.settings.get("companion_quiet",false) or save.data.settings.reduced_motion;page.add_child(companion)
	board_view = BoardView.new()
	board_view.position = Vector2(32, Design.BOARD_Y)
	board_view.size = Vector2(476, 536)
	board_view.reduced_motion = save.data.settings.reduced_motion or fast_test
	board_view.colorblind = save.data.settings.colorblind
	board_view.settings = save.data.settings
	page.add_child(board_view)
	board_view.set_board(board)
	board_view.swap_requested.connect(on_swap)
	board_view.special_pressed.connect(on_special)
	board_view.cell_pressed.connect(on_helper_cell)
	board_view.device_pressed.connect(show_seal_description)
	board_view.feedback.connect(func(key):audio.play(key))
	board_view.wave_started.connect(on_wave)
	board_view.environment_started.connect(on_environment)
	board_view.animation_finished.connect(on_animation_finished)
	board_view.rocket_impact.connect(func():audio.play("rocket_impact"))
	card(page,Rect2(76,816,388,33),Color("fff8e9"))
	storm_gauge=preload("res://scripts/ui/storm_gauge.gd").new();storm_gauge.position=Vector2(82,817);storm_gauge.size=Vector2(376,30);storm_gauge.quiet=save.data.settings.reduced_motion;page.add_child(storm_gauge)
	resonance_label=label(page,"",Rect2(38,936,414,22),12,Color("fff9e8"),HORIZONTAL_ALIGNMENT_CENTER)
	resonance_label.add_theme_color_override("font_outline_color",Color(.13,.08,.2,.9));resonance_label.add_theme_constant_override("outline_size",3)
	boss_badge=null
	if board.adventure.has("boss"):
		boss_badge=preload("res://scripts/ui/boss_badge.gd").new();boss_badge.position=Vector2(38,940);boss_badge.size=Vector2(370,40);page.add_child(boss_badge);boss_badge.update_state(board.adventure.boss)
		resonance_label.hide()
	build_helper_bar()
	gravity_buttons.clear()
	hint_label=label(page,"",Rect2(28,972,350 if developer_tools_available() else 400,30),12,Palette.MUTED,HORIZONTAL_ALIGNMENT_CENTER);hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_color_override("font_color",Color("fff9e8"))
	hint_label.add_theme_color_override("font_outline_color",Color(.13,.08,.2,.85))
	hint_label.add_theme_constant_override("outline_size",3)
	if developer_tools_available():button(page,"Test araçları",Rect2(390,974,114,28),show_developer_menu,false,11)
	for node in page.get_children():
		if node is Control and node.position.y<Design.BOARD_Y:node.set_meta("hud_y",node.position.y)
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
	if animate_entry and not fast_test and not save.data.settings.reduced_motion:
		entering_level=true
		var view=board_view;view.mouse_filter=Control.MOUSE_FILTER_IGNORE;view.modulate.a=0
		var entrance: Tween=view.create_tween();entrance.tween_property(view,"modulate:a",1,.15)
		entrance.tween_callback(func():
			if is_instance_valid(view):view.mouse_filter=Control.MOUSE_FILTER_STOP
			entering_level=false)

func update_hud(update_goals: bool=true) -> void:
	if update_goals and board.level.has("objective_stages"):level_label.text="BÖLÜM %d · %s · %d/%d"%[int(board.level.id),board.level.name,board.objective_stage+1,board.level.objective_stages.size()]
	star_progress.target=board.score
	score_target = board.score
	score_display = board.score
	game_hud.show_score(board.score)
	moves_label.text = str(board.moves)
	if board.moves!=last_move_badge and not save.data.settings.reduced_motion:
		if move_tween and move_tween.is_valid():move_tween.kill()
		moves_label.pivot_offset=moves_label.size*.5;move_tween=moves_label.create_tween();move_tween.tween_property(moves_label,"scale",Vector2(1.06,1.06),.12);move_tween.tween_property(moves_label,"scale",Vector2.ONE,.2)
	last_move_badge=board.moves
	moves_label.add_theme_color_override("font_color",Color("d63e69") if board.moves<=3 else Color("ce8129") if board.moves<=5 else Design.INK)
	if update_goals:
		if goals_panel.targets!=board.active_targets():goals_panel.configure(board.active_targets(),board.collected)
		goals_panel.update_progress(board.collected,false)
		game_hud.update_height()
		layout_stage()
	resonance_label.text = "YANKI  ·  %s %d/3" % [Strings.COLORS[board.resonance.color] if board.resonance.color >= 0 else "", board.resonance.count] if board.level.resonance else ""
	if board.adventure.has("boss"):
		if is_instance_valid(boss_badge):boss_badge.update_state(board.adventure.boss)
		var boss: Dictionary=board.adventure.boss
		resonance_label.text="BEKÇİ YENİLDİ!" if boss.defeated else "%s · %d/%d · %d enerji"%[boss.name,int(boss.phase)+1,boss.phases.size(),boss.remaining]
		if not boss.defeated:
			var phase: Dictionary=boss.phases[int(boss.phase)]
			set_hint("Sıradaki kalkan: özel güç kullan." if phase.get("special",false) else "Sıradaki kalkan: %s eşleştir."%", ".join(phase.colors.map(func(c):return Strings.COLORS[int(c)])))
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
	if armed_helper!="":set_hint("Gücü uygulamak için bir kristale dokun; iptal için güce tekrar bas.");return
	if reading_goal:close_goal_tip();return
	if screen != "game" or paused or entering_level or board_view.busy or not board.available(): return
	var started := Time.get_ticks_usec()
	var event: Dictionary = board.swap(a,b)
	Metrics.elapsed("swap_and_cascades",started)
	process_event(event)

func on_special(index: int) -> void:
	if armed_helper!="":on_helper_cell(index);return
	if reading_goal:close_goal_tip();return
	if entering_level:return
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
	audio.play("swap_accept")
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
	game_hud.show_score(int(score_display))
	# Persist only the completely settled logical result, before cosmetic playback.
	if not test_mode:
		earned_treasure=board.outcome=="won" and not board.level.get("treasure",{}).is_empty() and "level-%d"%int(board.level.id) not in save.data.adventure_progress.claimed
		preload("res://scripts/core/adventure_progress.gd").action(save.data,event)
		if board.outcome == "won": save.complete(board)
		else: save.save_active(board)
	board_view.animate(event)

func on_environment(data: Dictionary) -> void:
	if data.kind in ["storm","crystal_wave"] and not test_mode:
		var marker: String="gameplay2_"+str(data.kind)
		if marker not in save.data.tutorials:
			save.data.tutorials.append(marker);save.flush()
			set_hint("12 enerji: Fırtına en yakın üç normal kristali temizler." if data.kind=="storm" else "Üç eşleşme zinciri: Dalga en fazla iki normal kristali boyar.")
	if data.kind=="storm":storm_gauge.pulse=.48
	if data.kind=="shuffle":set_hint("Kristaller karıştırılıyor!")
	storm_gauge.set_value(int(data.get("energy_before",data.get("storm_energy",board.storm_charge()))))
	audio.play({"portal":"portal","vine":"vine","paint":"resonance","bubble":"pop","conveyor":"gravity","seal":"color","trait":"resonance","storm":"storm","crystal_wave":"crystal_wave","shuffle":"shuffle","magnet":"magnet"}.get(data.kind,"pop"))
	if data.has("collected"):goals_panel.update_progress(data.collected)

func on_wave(data: Dictionary) -> void:
	if data.get("adventure",{}).has("boss"):
		var boss: Dictionary=data.adventure.boss
		if is_instance_valid(boss_badge):boss_badge.update_state(boss)
		resonance_label.text="BEKÇİ YENİLDİ!" if boss.defeated else "%s · %d/%d · %d enerji"%[boss.name,int(boss.phase)+1,boss.phases.size(),boss.remaining]
	for e in data.get("adventure_events",[]):
		if e.kind=="rescue" and e.hp==0:audio.play("rescue")
		elif e.kind=="boss":audio.play("boss_win" if data.get("adventure",{}).get("boss",{}).get("defeated",false) else "boss_hit")
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
	if board_view.bomb_origin>=0:
		audio.play("color")
	elif data.get("combo_kind","")!="":
		audio.play("double_color" if data.combo_kind=="color_color" else "combo_power");audio.vibrate(true)
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
		button(overlay,"HARİTA",Rect2(68,661,404,45),show_home,false,16)
		return
	if board.outcome != "playing": show_result()


func on_gravity(_direction: String) -> void:
	# Old callbacks are inert; no player/manual direction selection exists.
	return

func show_seal_description(index: int) -> void:
	if screen!="game" or board_view.busy:return
	var m: Dictionary=board.cells[index].get("obstacle",{})
	if m.get("kind","")!="seal":return
	close_goal_tip();goal_tip=Control.new();goal_tip.position=Vector2(30,minf(board_view.position.y+board_view.size.y+125,stage.size.y-76));goal_tip.size=Vector2(480,76);page.add_child(goal_tip)
	card(goal_tip,Rect2(0,0,480,76),Color("fffaf0"))
	label(goal_tip,"ŞİFRELİ MÜHÜR · RENK SIRASI",Rect2(18,4,400,20),12,Palette.GOLD)
	for k in m.sequence.size():
		var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=preload("res://scripts/ui/goal_registry.gd").icon(str(m.sequence[k]));icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.position=Vector2(25+k*61,26);icon.size=Vector2(26,26);goal_tip.add_child(icon)
		label(goal_tip,"✓" if k<int(m.step) else ("SIRADAKİ" if k==int(m.step) else ""),Rect2(12+k*61,53,56,17),10,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	button(goal_tip,"×",Rect2(423,8,48,48),close_goal_tip,false,20)
func show_goal_description(key: String,tutorial: bool=false) -> void:
	if screen!="game" or goals_panel==null or not goals_panel.targets.has(key) or (board_view.busy and not tutorial):return
	close_goal_tip()
	board_view.highlight_goal(key)
	if is_instance_valid(companion):companion.hide()
	goal_tip=Control.new();goal_tip.position=Vector2(30,minf(board_view.position.y+board_view.size.y+125,stage.size.y-76));goal_tip.size=Vector2(480,60)
	reading_goal=not tutorial
	page.add_child(goal_tip)
	card(goal_tip,Rect2(0,0,480,60),Color("fffaf0"))
	var registry=preload("res://scripts/ui/goal_registry.gd")
	var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=registry.icon(key);icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.position=Vector2(10,7);icon.size=Vector2(44,44);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;goal_tip.add_child(icon)
	label(goal_tip,"YENİ HEDEF · "+registry.entry(key)[2] if tutorial else registry.entry(key)[2],Rect2(64,3,345,18),11,Palette.GOLD)
	var text:=label(goal_tip,registry.description(key,int(goals_panel.targets[key])),Rect2(64,22,349,34),12)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(goal_tip,"×",Rect2(423,5,48,48),advance_goal_tutorial if tutorial else close_goal_tip,false,20)
	if tutorial:
		var timeout:=Timer.new();timeout.wait_time=2.6;timeout.one_shot=true;goal_tip.add_child(timeout);timeout.timeout.connect(advance_goal_tutorial);timeout.start()
	
func close_goal_tip() -> void:
	reading_goal=false
	if screen=="game" and is_instance_valid(companion):companion.show()
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
func flowing_text(parent: Node, text: String, rect: Rect2, font_size: int=17) -> Label:
	var scroll:=ScrollContainer.new();scroll.name="TextScroll";scroll.position=rect.position;scroll.size=rect.size;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll)
	var body:=Label.new();body.name="FlowText";body.text=text;body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_font_size_override("font_size",font_size);body.add_theme_color_override("font_color",Palette.INK);scroll.add_child(body)
	return body

func help_flow(text: String, actions: Array, font_size: int=17) -> void:
	var column:=VBoxContainer.new();column.name="DialogFlow";column.position=Vector2(62,315);column.size=Vector2(416,405);column.add_theme_constant_override("separation",10);overlay.add_child(column)
	var scroll:=ScrollContainer.new();scroll.name="TextScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	var body:=Label.new();body.name="FlowText";body.text=text;body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_font_size_override("font_size",font_size);body.add_theme_color_override("font_color",Palette.INK);scroll.add_child(body)
	var controls:=VBoxContainer.new();controls.name="DialogActions";controls.add_theme_constant_override("separation",8);column.add_child(controls)
	for action in actions:
		var btn:=button(controls,action[0],Rect2(0,0,416,42),action[1],bool(action[2]),14);btn.custom_minimum_size.y=42

func show_help() -> void:
	open_overlay("Nasıl oynanır?")
	help_flow(Strings.text("help_body"),[["HEDEFLER / ÖĞRETİCİLER",show_goal_gallery,false],["ENGELLER VE HEDEFLER",show_mechanic_help,false],["DEVAM ET",close_overlay,true]])

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
	var explanation:=flowing_text(overlay,registry.description(key,1),Rect2(70,500,400,112),18);explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"DİĞER HEDEFLER",Rect2(68,653,404,43),show_goal_gallery.bind(group),true,15)

func show_migration_notice() -> void:
	if not save.data.get("migration_notice", false): return
	open_overlay("Match-3'e hoş geldin")
	var body := flowing_text(overlay, "Artık blokları kaydırarak üçlü eşleştiriyoruz.\n\nAçılan bölümler, yıldızlar ve ayarlar korundu. Eski aktif tahta arşivlendi; aynı bölüm yeni kurallarla, tam hamleyle yeniden başlıyor.", Rect2(62, 313, 416, 268), 18)
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

func select_navigation(index: int) -> void:
	if screen!="map" or page==null:return
	for child in page.get_children():
		if child is IconButton and child.has_meta("navigation_index"):child.chosen=int(child.get_meta("navigation_index"))==index;child.queue_redraw()

func close_overlay() -> void:
	audio.play("panel_close")
	select_navigation(0)
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
	if board==null or board.outcome=="playing":return
	close_goal_tip();pending_goal_tutorials.clear()
	if test_mode:
		open_overlay("Test tamamlandı","Laboratuvar sonuçları gerçek oyuncu profiline yazılmaz.")
		button(overlay,"YENİ TEST",Rect2(80,456,380,58),start_mechanic_test,true)
		button(overlay,"HARİTA",Rect2(80,533,380,48),show_home);return
	var won: bool=board.outcome=="won"
	if won:save.complete(board)
	else:save.data.active={};save.flush()
	var final: bool=won and int(board.level.id)==int(Worlds.get_world(Catalog.world_for(int(board.level.id))).end)
	if final:show_world_result()
	else:show_result_popup(won,false)

func show_result_popup(won: bool,finale: bool=false) -> void:
	var metadata: Dictionary=Worlds.get_world(Catalog.world_for(int(board.level.id)))
	audio.play("world_unlock" if finale else "success2" if won else "lose")
	open_overlay("","")
	for child in overlay.get_children():child.queue_free()
	card(overlay,Rect2(54,239,432,482) if won else Rect2(54,280,432,400))
	label(overlay,str(metadata.success_text) if won else "Bir kez daha deneyelim",Rect2(72,249 if won else 292,396,48),25,Design.INK,HORIZONTAL_ALIGNMENT_CENTER)
	var host:=Control.new();host.position=Vector2(222,298 if won else 340);overlay.add_child(host)
	var face:=preload("res://scripts/ui/companion.gd").new();face.size=Vector2(96,84);face.quiet=save.data.settings.get("companion_quiet",false) or save.data.settings.reduced_motion;host.add_child(face);face.react("happy" if won else "sad")
	if won:
		var count:=Score.stars(board.score,board.level.stars)
		for i in 3:
			var star:=TextureRect.new();star.texture=Design.icon("ui",3);star.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;star.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;star.position=Vector2(175+i*67,377);star.size=Vector2(56,56);star.pivot_offset=Vector2(28,28);star.modulate=Color.WHITE if i<count else Color(.55,.59,.65,.4);star.set_meta("result_star",true);overlay.add_child(star)
			if not save.data.settings.reduced_motion:
				star.scale=Vector2(.2,.2);var t:=star.create_tween();t.tween_property(star,"scale",Vector2.ONE,.22).set_delay(i*.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if i<count:t.tween_callback(func():audio.play("star_award"))
		label(overlay,"%d PUAN"%board.score,Rect2(74,436,392,36),28,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
		var goals:=preload("res://scripts/ui/goals_panel.gd").new();goals.position=Vector2(83,479);goals.size=Vector2(480,112);goals.scale=Vector2(.78,.78);goals.quiet=true;overlay.add_child(goals);goals.configure(board.level.targets,board.collected)
		if earned_treasure:
			var chest:=preload("res://scripts/ui/treasure_visual.gd").new();chest.position=Vector2(392,315);chest.size=Vector2(61,57);chest.quiet=save.data.settings.reduced_motion;overlay.add_child(chest);audio.play("chest")
			label(overlay,"HAZİNE +%d kristal"%int(board.level.treasure.coins),Rect2(80,568,380,24),13,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
		elif finale:label(overlay,str(metadata.reward)+" kaydedildi",Rect2(80,568,380,24),13,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
		if not save.data.settings.reduced_motion and not save.data.settings.reduced_effects:
			var confetti:=Celebration.new();confetti.world_finale=finale;confetti.world_theme=str(metadata.theme);confetti.ocean=int(metadata.id)==2;confetti.canyon=int(metadata.id)==3;overlay.add_child(confetti)
		if int(board.level.id)<Catalog.count():button(overlay,"SONRAKİ BÖLÜM",Rect2(83,604,374,57),request_level.bind(int(board.level.id)+1),true,22)
		else:button(overlay,"HARİTAYI KEŞFET",Rect2(83,604,374,57),show_home,true,21)
		button(overlay,"YENİDEN OYNA",Rect2(83,674,182,36),request_level.bind(int(board.level.id)),false,12)
		button(overlay,"HARİTA",Rect2(275,674,182,36),show_map,false,12)
	else:
		label(overlay,"Kalan hedefleri farklı bir hamleyle tamamlayabilirsin.",Rect2(80,426,380,31),13,Design.ACCENT,HORIZONTAL_ALIGNMENT_CENTER)
		var unfinished: Dictionary={}
		for key in board.active_targets():
			if Objectives.value(board.collected,key)<int(board.active_targets()[key]):unfinished[key]=board.active_targets()[key]
		var goals:=preload("res://scripts/ui/goals_panel.gd").new();goals.position=Vector2(83,464);goals.size=Vector2(480,112);goals.scale=Vector2(.78,.78);goals.quiet=true;goals.remaining_mode=true;overlay.add_child(goals)
		if not unfinished.is_empty():goals.configure(unfinished,board.collected)
		button(overlay,"YENİDEN OYNA",Rect2(83,567,374,57),request_level.bind(int(board.level.id)),true,22)
		button(overlay,"HARİTA",Rect2(83,636,374,35),show_map,false,14)
	# Additional-move providers can extend the presentation later; no unavailable offers.
	overlay.set_meta("result_extensions",[])

func show_settings() -> void:
	if screen!="settings":settings_origin=screen
	persist_board();begin_page("settings")
	title_header(Strings.text("settings"),"KRİSTALLERİ KENDİ RİTMİNDE UYANDIR")
	var scroll:=ScrollContainer.new();scroll.name="SettingsScroll";scroll.add_theme_stylebox_override("panel",Design.surface());scroll.position=Vector2(32,185);scroll.size=Vector2(476,625);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);scroll.add_child(column)
	var heading:=label(column,"GÖRSEL KALİTE",Rect2(0,0,400,26),14);heading.custom_minimum_size.y=26
	var quality_row:=HBoxContainer.new();column.add_child(quality_row);quality_buttons.clear()
	var modes: Array=["auto","high","balanced","performance"];var titles: Array=["Otomatik","Yüksek","Dengeli","Performans"]
	for i in 4:
		var mode: String=modes[i];var option:=button(quality_row,titles[i],Rect2(0,0,100,44),set_quality.bind(mode),save.data.settings.get("quality","auto")==mode,12);option.custom_minimum_size.y=44;option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;quality_buttons[mode]=option
	for spec in [["companion_quiet","Pırıl için sakin mod"],["shake","Hafif ekran sarsıntısı"],["reduced_effects","Azaltılmış efektler"],["reduced_motion","Daha az hareket"],["haptics","Dokunma titreşimi"],["colorblind","Şekille renk erişimi"],["music","Müzik"],["sfx","Efekt sesi"]]:
		var key: String=spec[0];var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);column.add_child(row)
		var caption:=label(row,spec[1],Rect2(0,0,300,44),17);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;caption.custom_minimum_size.y=44
		var toggle:=button(row,"AÇIK" if save.data.settings[key] else "KAPALI",Rect2(0,0,105,44),toggle_setting.bind(key),save.data.settings[key],12);toggle.custom_minimum_size=Vector2(105,44);toggle.name=key
		if key in ["music","sfx"]:
			var slider:=HSlider.new();slider.custom_minimum_size.y=32;slider.max_value=1;slider.step=.05;slider.value=save.data.settings.get(key+"_volume",.7);column.add_child(slider)
			slider.value_changed.connect(func(value):save.data.settings[key+"_volume"]=value;settings_dirty=true;audio.apply_settings(save.data.settings))
			slider.drag_ended.connect(func(_changed):save.flush();settings_dirty=false)
	for action in [["YARDIM / ÖĞRETİCİLER",show_help],["Performans raporu",show_diagnostics]]:
		var btn:=button(column,action[0],Rect2(0,0,400,44),action[1],false,14);btn.custom_minimum_size.y=44
	if developer_tools_available():
		var dev:=button(column,"Geliştirici: mekanik laboratuvarı",Rect2(0,0,400,44),show_developer_menu,false,13);dev.custom_minimum_size.y=44
	button(page,Strings.text("resume") if settings_origin=="game" and not save.data.active.is_empty() else Strings.text("map"),Rect2(42,835,456,56),play_latest if settings_origin=="game" and not save.data.active.is_empty() else show_home,true)
	label(page,"PRİZMA 0.12.4 · RENKLERİN MACERASI",Rect2(32,920,476,28),12,Palette.GOLD,HORIZONTAL_ALIGNMENT_CENTER)

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
	var toggle := page.find_child(key,true,false) as Button
	if toggle:
		toggle.text = "AÇIK" if save.data.settings[key] else "KAPALI"
		update_option_style(toggle,save.data.settings[key])
	garden.reduced_motion = save.data.settings.reduced_motion or save.data.settings.get("reduced_effects",false)

func update_option_style(btn: Button, active: bool) -> void:
	for state in ["normal","hover","pressed"]:
		btn.add_theme_stylebox_override(state,Design.action(active,state=="pressed"))
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
	var body := flowing_text(overlay,lines,Rect2(59,386,425,220),14)
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
	return not production_mode and (OS.has_feature("editor") or OS.has_feature("prizma_dev_tools"))

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
	var body:=flowing_text(overlay,"Tohum: yanında eşleştir, 2 darbeyle çiçek açar.\n\nBuz: kristali sabit tutar; yanında patlama veya doğrudan güçle 2 katmanı kır.\n\nTaş: 3 dayanıklılık. Doğrudan prizma 2 hasar verir; roket 1.\n\nRenk kilidi: istenen renkte normal kristalleri topla. Zincirler de sayılır.\n\nÇapraz komşuluk hasar vermez. Aynı dalga aynı engeli tekrar vurmaz.",Rect2(61,315,418,315),16)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"YENİ KRİSTALLER",Rect2(68,650,404,35),show_crystal_help,false,14)
	button(overlay,"ANLADIM",Rect2(68,699,404,35),close_overlay,true,15)

func show_world_result() -> void:
	garden.vitality=1.0;garden.world_completed=true;garden.color_energy=[18,18,18,18,18]
	show_result_popup(true,true)

func show_crystal_help() -> void:
	open_overlay("İki rengin uyanışı")
	var body:=flowing_text(overlay,"Çift renkli kristal yalnızca gösterdiği iki renkle eşleşir. Bir dalgada tek renk olarak sayılır.\n\nBukalemun iki başarılı takasın zincirleri bittikten sonra sıradaki rengine geçer. Parlayan çerçeve dönüşümün yaklaştığını gösterir. Geçersiz takas, zincirler ve yön değişimi sayacı ilerletmez.\n\nPrizma Köprüsü her renge uyum sağlar; en az bir renkli kristalle üçlü çizgi oluşturmalıdır. 51. bölümde tanıtılır.\n\nYer Çekimi Çivisi kristali sabit tutar; iki ayrı darbeyle açılır. 56. bölümde tanıtılır.",Rect2(61,315,418,315),17)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(overlay,"ANLADIM",Rect2(68,658,404,48),close_overlay,true,16)

func show_adventure_menu(kind: int) -> void:
	var progress_rule=preload("res://scripts/core/adventure_progress.gd")
	progress_rule.ensure(save.data)
	var progress: Dictionary=save.data.adventure_progress
	open_overlay(["Günlük görevler","Kurtardığın dostlar","Kazanılan ödüller"][kind],"Çevrimdışı maceran bu cihazda saklanır.")
	select_navigation(kind+1)
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

func show_developer_menu() -> void:
	if not developer_tools_available():return
	open_overlay("Geliştirici testi","Ayrı test APK ve kayıt profili · 1–250")
	var number:=SpinBox.new();number.min_value=1;number.max_value=Catalog.count();number.value=int(board.level.id) if board!=null else 1;number.position=Vector2(70,369);number.size=Vector2(210,40);overlay.add_child(number)
	button(overlay,"BÖLÜME GİT",Rect2(293,369,178,40),func():dev_command("jump",int(number.value)),true,14)
	var commands: Array=[["Kazan","win"],["Kaybet","lose"],["Önceki","previous"],["Sonraki","next"],["+10 hamle","moves"],["İki bomba","double"],["Roket ekle","rocket"],["Yıldız ekle","prism"],["Boss aç","boss"],["Kurtarma aç","rescue"],["Seed ile başlat","seed"],["Hızlı / normal","speed"],["Mekanik laboratuvarı","lab"],["Dünyaları aç","worlds"],["Mekanik araçları","layers"],["Yeniden başlat","seed"],["Önizleme","preview"],["Harita testi","map"],["Testi sıfırla","reset"],["Roket + roket","rr"],["Bomba + roket","cr"],["Fırtına","storm"],["Dev kırılması","giant"]]
	for i in commands.size():
		button(overlay,commands[i][0],Rect2(68+(i%4)*103,428+int(i/4)*43,96,36),dev_command.bind(commands[i][1],int(number.value)),false,12)
	button(overlay,"KAPAT",Rect2(68,753,404,38),close_overlay,false,14)

func dev_command(command: String,number: int=1) -> void:
	if not developer_tools_available():return
	# Only the isolated developer build can bypass campaign unlocks.
	if not OS.has_feature("prizma_dev_tools") and not OS.has_feature("editor"):return
	if command=="preview":save.data.unlocked=Catalog.count();request_level(number);return
	if command=="map":show_home();return
	if command=="reset":save.data=Save.defaults();save.data.unlocked=Catalog.count();board=null;save.flush();show_home();return
	if command=="layers":
		if test_mode:show_mechanic_test_tools()
		return
	if command=="lab":start_mechanic_test();return
	if command=="worlds":save.data.unlocked=Catalog.count();show_worlds();return
	if command=="speed":
		fast_test=not fast_test;close_overlay()
		if is_instance_valid(board_view):board_view.reduced_motion=fast_test or save.data.settings.reduced_motion
		return
	if command in ["jump","boss","rescue","next","previous","seed"]:
		if command=="boss":number=35
		if command=="rescue":number=12
		if command=="next" and board!=null:number=int(board.level.id)+1
		if command=="previous" and board!=null:number=int(board.level.id)-1
		if command=="seed" and board!=null:number=int(board.level.id)
		if number<1 or number>Catalog.count():return
		save.data.unlocked=Catalog.count();start_level(number);return
	if board==null or screen!="game" or board_view.busy:return
	close_overlay()
	if command=="win":
		for key in board.level.targets:board.collected[key]=int(board.level.targets[key])
		board.outcome="won";show_result();return
	if command=="lose":board.moves=0;board.outcome="lost";show_result();return
	if command=="moves":board.moves+=10;board.initial_moves+=10;board.level.moves=board.initial_moves;update_hud();return
	if command=="storm":
		board.energy=1;board.energy_blocks=0
		board.level.gravity=true;board.level.automatic_storm=true;close_goal_tip()
		var moves: Array=Match.legal_swaps(board.cells,8,9)
		if not moves.is_empty():on_swap(int(moves[0][0]),int(moves[0][1]))
		return
	if command=="giant":
		start_level(247);close_goal_tip();board.canyon.giants["44"]=1;command="double"
	if command in ["double","rr","cr","rocket","prism"]:
		for i in 71:
			if board.cells[i]==null or board.cells[i].get("fixed",false):continue
			if command in ["double","rr","cr"]:
				if i%8==7 or board.cells[i+1]==null or board.cells[i+1].get("fixed",false):continue
				board.cells[i].p="rocket_h" if command=="rr" else "color";board.cells[i+1].p="rocket_v" if command=="rr" else "rocket_h" if command=="cr" else "color"
			else:board.cells[i].p="rocket_h" if command=="rocket" else "prism"
			break
		board_view.set_board(board)

func build_helper_bar() -> void:
	if not test_mode:preload("res://scripts/core/adventure_progress.gd").ensure(save.data)
	var rules=preload("res://scripts/core/booster_catalog.gd")
	for i in 2:
		var key: String=["rocket","prism"][i]
		var item:=IconButton.new();item.position=Vector2(115+i*133,860);item.size=Vector2(96,72);item.image=Design.icon("gems",int(rules.ITEMS[key].image));item.amount=int(save.data.get("adventure_progress",{}).get("inventory",{}).get(key,0));item.disabled=test_mode;item.locked=not rules.unlocked(save.data,key);item.unavailable=test_mode or not rules.available(save.data,key);item.tooltip_text=rules.ITEMS[key].name;page.add_child(item);helper_buttons[key]=item
		item.pressed.connect(func():
			if test_mode:return
			if board_view.busy or not board.available():return
			close_goal_tip()
			if not rules.available(save.data,key):set_hint("%d. bölümde açılır."%int(rules.ITEMS[key].unlock) if not rules.unlocked(save.data,key) else "Bu güçten stok kalmadı.");audio.play("locked");return
			armed_helper="" if armed_helper==key else key
			for other in helper_buttons:helper_buttons[other].chosen=other==armed_helper;helper_buttons[other].queue_redraw()
			set_hint("İptal için güce tekrar dokun." if armed_helper!="" else "Güç seçimi iptal edildi.");audio.play("booster_select"))
func on_helper_cell(index: int) -> void:
	if test_mode or armed_helper=="" or board_view.busy or not board.available():return
	var rules=preload("res://scripts/core/booster_catalog.gd")
	if not rules.available(save.data,armed_helper):return
	var event: Dictionary=board.deploy_power(index,str(rules.ITEMS[armed_helper].power))
	if not event.accepted:audio.play("invalid");set_hint("Korunmamış normal bir kristal seç.");return
	preload("res://scripts/core/adventure_progress.gd").consume(save.data,armed_helper)
	armed_helper=""
	for key in helper_buttons:
		helper_buttons[key].amount=int(save.data.adventure_progress.inventory.get(key,0));helper_buttons[key].chosen=false;helper_buttons[key].unavailable=not rules.available(save.data,key);helper_buttons[key].queue_redraw()
	save.save_active(board);board_view.animate(event);board_view.spawn_stars(board_view.cell_position(index)+Vector2(28,28),4);audio.play("power");set_hint("Güç yerleştirildi; normal hamle harcanmadı.")
