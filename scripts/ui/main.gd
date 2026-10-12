extends Control

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

var save
var board
var audio
var garden
var stage: Control
var page: Control
var overlay: Control
var board_view
var screen := "home"
var paused := false
var combine_mode := false
var combine_first := -1
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

func layout_stage() -> void:
	if stage == null: return
	var factor := minf(size.x / 540.0, size.y / 960.0)
	stage.size = Vector2(540, 960)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - stage.size * factor) * 0.5
	garden.size = size

func _notification(what: int) -> void:
	if save == null: return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist_board()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		persist_board()
		if screen == "game" and board.outcome == "playing": show_pause()

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
		get_tree().quit()

func persist_board() -> void:
	if board != null and screen == "game":
		if board.outcome == "won": save.complete(board)
		elif board.outcome == "playing": save.save_active(board)

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
	combine_mode = false
	combine_first = -1
	garden.reduced_motion = save.data.settings.reduced_motion

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
	begin_page("home")
	garden.vitality = 0.30 + float(save.data.results.size()) * 0.06
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
	label(page, "Patlat. Yönü değiştir. Bahçeyi canlandır.", Rect2(20, 438, 500, 28), 15, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	card(page, Rect2(44, 518, 452, 102))
	label(page, Strings.text("world"), Rect2(65, 532, 350, 32), 24)
	var stars := 0
	for result in save.data.results.values(): stars += int(result.stars)
	label(page, "%d / 10 bölüm  ·  %d / 30 yıldız" % [save.data.results.size(), stars], Rect2(65, 572, 395, 28), 16, Palette.GOLD)
	var active: bool = not save.data.active.is_empty()
	button(page, Strings.text("resume") if active else Strings.text("play"), Rect2(44, 648, 452, 70), play_latest, true, 25)
	button(page, Strings.text("map"), Rect2(44, 733, 452, 57), show_map)
	button(page, Strings.text("settings"), Rect2(162, 818, 216, 48), show_settings, false, 17)
	label(page, Strings.text("saved"), Rect2(25, 898, 490, 28), 12, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func play_latest() -> void:
	if not save.data.active.is_empty():
		start_level(int(save.data.active.level_id), true)
	else:
		start_level(int(save.data.unlocked))

func show_map() -> void:
	persist_board()
	begin_page("map")
	title_header(Strings.text("world"), Strings.text("chapter"))
	label(page, "Her bölüm, bahçeye yeni bir renk.", Rect2(32, 179, 476, 30), 18, Palette.GOLD)
	for n in range(1, 11):
		var row := int((n - 1) / 2)
		var x := 64 if n % 2 == 1 else 292
		var y := 236 + row * 118
		var unlocked: bool = n <= save.data.unlocked
		var result: Dictionary = save.data.results.get(str(n), {})
		var node := button(page, str(n) if unlocked else "·", Rect2(x, y, 184, 69), start_level.bind(n), unlocked and n == save.data.unlocked, 28)
		node.disabled = not unlocked
		label(page, "★".repeat(int(result.get("stars", 0))) if not result.is_empty() else ("Seni bekliyor" if unlocked else "Kilitli"), Rect2(x, y + 71, 184, 25), 15, Palette.GOLD if unlocked else Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	label(page, "İLK AŞAMA · BAHÇENİN İLK ON ADIMI", Rect2(30, 881, 480, 32), 12, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func start_level(number: int, resume: bool = false) -> void:
	if number < 1 or number > save.data.unlocked: return
	board = Board.new(Catalog.get_level(number))
	if resume and not save.data.active.is_empty(): board.restore(save.data.active)
	begin_page("game")
	garden.vitality = 0.2
	label(page, "BÜYÜLÜ BAHÇE", Rect2(32, 22, 330, 28), 13, Palette.GOLD)
	label(page, "%02d  /  %s" % [number, board.level.name], Rect2(32, 55, 415, 39), 23)
	button(page, "Ⅱ", Rect2(456, 38, 52, 50), show_pause, false, 23)
	card(page, Rect2(30, 110, 480, 65))
	label(page, Strings.text("score"), Rect2(49, 119, 150, 17), 11, Palette.MUTED)
	score_label = label(page, "0", Rect2(49, 137, 225, 29), 24)
	label(page, Strings.text("moves"), Rect2(351, 119, 139, 17), 11, Palette.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	moves_label = label(page, "", Rect2(354, 137, 136, 29), 24, Palette.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	card(page, Rect2(30, 190, 480, 54))
	goals_label = label(page, "", Rect2(47, 196, 446, 40), 17)
	board_view = BoardView.new()
	board_view.position = Vector2(32, 270)
	board_view.size = Vector2(476, 536)
	board_view.reduced_motion = save.data.settings.reduced_motion
	board_view.colorblind = save.data.settings.colorblind
	page.add_child(board_view)
	board_view.set_board(board)
	board_view.cell_pressed.connect(on_cell)
	board_view.animation_finished.connect(on_animation_finished)
	resonance_label = label(page, "", Rect2(33, 816, 292, 28), 13, Palette.GOLD)
	energy_label = label(page, "", Rect2(326, 816, 182, 28), 13, Palette.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	gravity_buttons.clear()
	var directions := ["left", "up", "down", "right"]
	var arrows := ["←", "↑", "↓", "→"]
	for k in 4:
		var direction: String = directions[k]
		gravity_buttons[direction] = button(page, arrows[k], Rect2(31 + k * 56, 854, 48, 42), on_gravity.bind(direction), false, 24)
	button(page, "Güçleri birleştir", Rect2(274, 854, 235, 42), toggle_combine, false, 15)
	hint_label = label(page, "", Rect2(26, 903, 488, 46), 13, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	update_hud()
	if board.outcome != "playing":
		show_result()
		return
	if number == 1 and "tap" not in save.data.tutorials:
		set_hint(Strings.text("tap_hint"))
		board_view.hint_index = 0
	elif number == 4 and "gravity" not in save.data.tutorials:
		set_hint(Strings.text("gravity_hint"))
	elif number == 6 and "resonance" not in save.data.tutorials:
		set_hint(Strings.text("resonance_hint"))
	else:
		set_hint(Strings.text("power_hint"))
	save.save_active(board)

func update_hud() -> void:
	score_label.text = str(board.score)
	moves_label.text = str(board.moves)
	var descriptions: Array = []
	for key in board.level.targets:
		var target: int = int(board.level.targets[key])
		var amount: int = mini(target, int(board.collected[key]))
		var name: String = "Blok" if key == "total" else Strings.COLORS[int(key)]
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
		progress += minf(1, float(board.collected[key]) / float(board.level.targets[key]))
	garden.vitality = 0.15 + 0.85 * progress / board.level.targets.size()

func set_hint(text: String) -> void:
	if hint_label: hint_label.text = text

func on_cell(index: int) -> void:
	if screen != "game" or paused or board_view.busy or board.outcome != "playing": return
	var partner := -1
	if combine_mode:
		if board.cells[index].p == "":
			set_hint("Önce bir özel güç seç.")
			return
		if combine_first < 0:
			combine_first = index
			board_view.selected = index
			set_hint(Strings.text("combo_hint"))
			return
		partner = combine_first
		if partner == index or index not in Match.neighbors(partner, 8, 9):
			set_hint(Strings.text("combo_hint"))
			return
	if board.cells[index].p == "color" or (partner >= 0 and board.cells[partner].p == "color"):
		show_color_picker(index, partner)
	else:
		perform_tap(index, -1, partner)

func perform_tap(index: int, selected_color: int = -1, partner: int = -1) -> void:
	if board_view.busy or board.outcome != "playing": return
	var event: Dictionary = board.tap(index, selected_color, partner)
	if not event.accepted: return
	combine_mode = false
	combine_first = -1
	board_view.selected = -1
	save.mark_tutorial("tap")
	if event.get("resonated", false): save.mark_tutorial("resonance")
	if event.get("invalid", false):
		audio.play("invalid")
		set_hint(Strings.text("invalid"))
	elif event.get("resonated", false):
		audio.play("resonance")
		audio.vibrate(true)
		set_hint("REZONANS  ·  +%d puan" % event.points)
	elif event.get("special", false):
		audio.play("power")
		audio.vibrate(true)
		set_hint("Işık dalgası  ·  +%d puan" % event.points)
	else:
		audio.play("large" if event.removed.size() >= 5 else "pop")
		audio.vibrate()
		set_hint("+%d puan  ·  %s" % [event.points, "Özel güç oluştu!" if event.created != "" else "Bahçe renkleniyor."])
	if event.get("shuffled", false): set_hint(Strings.text("shuffle"))
	if board.energy > 0 and "gravity" not in save.data.tutorials:
		set_hint("Enerjin hazır! Bir yön düğmesine dokun; hamlen azalmaz.")
	update_hud()
	# Persist the final logical state before starting cosmetic animation.
	if board.outcome == "won": save.complete(board)
	else: save.save_active(board)
	board_view.animate(event)

func on_animation_finished() -> void:
	if board != null and board.outcome != "playing" and screen == "game": show_result()

func on_gravity(direction: String) -> void:
	if board_view.busy or paused: return
	var event: Dictionary = board.change_gravity(direction)
	if not event.accepted: return
	audio.play("gravity")
	save.mark_tutorial("gravity")
	save.save_active(board)
	update_hud()
	set_hint(Strings.text("gravity_hint"))
	board_view.animate(event)

func toggle_combine() -> void:
	if paused or board_view.busy or board.outcome != "playing": return
	combine_mode = not combine_mode
	combine_first = -1
	board_view.selected = -1
	set_hint("Bir özel güç seç, sonra komşusuna dokun." if combine_mode else Strings.text("power_hint"))

func open_overlay(title: String, subtitle: String = "") -> Control:
	close_overlay()
	paused = true
	overlay = Control.new()
	overlay.size = Vector2(540, 960)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.07, 0.83)
	dim.size = Vector2(540, 960)
	overlay.add_child(dim)
	card(overlay, Rect2(32, 225, 476, 512))
	label(overlay, title, Rect2(48, 247, 444, 56), 29, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var sub := label(overlay, subtitle, Rect2(57, 311, 426, 65), 16, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return overlay

func close_overlay() -> void:
	if overlay != null:
		overlay.hide()
		overlay.queue_free()
		overlay = null
	paused = false

func show_pause() -> void:
	if screen != "game": return
	if board.outcome != "playing":
		show_result()
		return
	persist_board()
	open_overlay(Strings.text("pause"), "Bahçe seni bekler. İlerlemen kaydedildi.")
	button(overlay, Strings.text("resume"), Rect2(68, 401, 404, 59), close_overlay, true)
	button(overlay, Strings.text("settings"), Rect2(68, 480, 404, 55), show_settings)
	button(overlay, Strings.text("replay"), Rect2(68, 553, 404, 55), func(): confirm_restart())
	button(overlay, Strings.text("map"), Rect2(68, 627, 404, 55), show_map)

func confirm_restart() -> void:
	open_overlay("Baştan başlayalım mı?", "Bu bölümün mevcut hamleleri sıfırlanır. Kazandığın yıldızlar korunur.")
	button(overlay, Strings.text("replay"), Rect2(68, 421, 404, 59), start_level.bind(int(board.level.id)), true)
	button(overlay, "VAZGEÇ", Rect2(68, 508, 404, 55), show_pause)

func show_color_picker(index: int, partner: int) -> void:
	open_overlay("Rengini seç", Strings.text("color_pick"))
	for color in 5:
		var selected_color: int = color
		var btn := button(overlay, Strings.COLORS[color], Rect2(70, 383 + color * 57, 400, 47), func():
			close_overlay()
			perform_tap(index, selected_color, partner), false, 17)
		btn.add_theme_color_override("font_color", Palette.COLORS[color])
	button(overlay, "VAZGEÇ", Rect2(171, 681, 198, 38), close_overlay, false, 13)

func show_result() -> void:
	if board.outcome == "playing": return
	var won: bool = board.outcome == "won"
	if won: save.complete(board)
	else:
		save.data.active = {}
		save.flush()
	audio.play("win" if won else "lose")
	open_overlay(Strings.text("won") if won else Strings.text("lost"), "Her renk bir iz bırakır." if won else "Farklı bir renk sırası veya düşüş yönü dene.")
	if won:
		if not save.data.settings.reduced_motion:
			var confetti := Celebration.new()
			overlay.add_child(confetti)
		var stars: int = Score.stars(board.score, board.level.stars)
		label(overlay, "★".repeat(stars) + "☆".repeat(3 - stars), Rect2(66, 368, 408, 64), 48, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		label(overlay, "%d PUAN" % board.score, Rect2(66, 436, 408, 37), 26, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		label(overlay, "2★: %d   ·   3★: %d" % [board.level.stars[1], board.level.stars[2]], Rect2(66, 475, 408, 28), 13, Palette.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		if int(board.level.id) < 10:
			button(overlay, Strings.text("next"), Rect2(68, 529, 404, 58), start_level.bind(int(board.level.id) + 1), true)
		else:
			label(overlay, "İlk on adım tamamlandı!", Rect2(66, 516, 408, 38), 22, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			button(overlay, Strings.text("map"), Rect2(68, 567, 404, 53), show_map, true)
		button(overlay, Strings.text("replay"), Rect2(68, 637, 404, 53), start_level.bind(int(board.level.id)))
	else:
		label(overlay, "%d PUAN" % board.score, Rect2(66, 388, 408, 50), 30, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		button(overlay, Strings.text("replay"), Rect2(68, 467, 404, 59), start_level.bind(int(board.level.id)), true)
		button(overlay, Strings.text("map"), Rect2(68, 552, 404, 55), show_map)
		button(overlay, Strings.text("home"), Rect2(68, 630, 404, 53), show_home)

func show_settings() -> void:
	persist_board()
	begin_page("settings")
	title_header(Strings.text("settings"), "OYUNU KENDİ RİTMİNDE OYNA")
	var definitions := [["music", "Bahçenin müziği"], ["sfx", "Patlama sesleri"], ["haptics", "Dokunma titreşimi"], ["reduced_motion", "Daha az hareket"], ["colorblind", "Renk erişilebilirliği"]]
	for k in definitions.size():
		var key: String = definitions[k][0]
		card(page, Rect2(32, 222 + k * 91, 476, 74))
		label(page, definitions[k][1], Rect2(51, 231 + k * 91, 325, 56), 20)
		var toggle := button(page, "AÇIK" if save.data.settings[key] else "KAPALI", Rect2(368, 240 + k * 91, 119, 39), func(): toggle_setting(key), save.data.settings[key], 14)
		toggle.name = key
	label(page, "Her blok kendi sembolünü taşır.\nTitreşim yalnızca destekleyen Android cihazlarda çalışır.", Rect2(42, 700, 456, 76), 14, Palette.MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(page, Strings.text("resume") if not save.data.active.is_empty() else Strings.text("home"), Rect2(42, 812, 456, 62), play_latest if not save.data.active.is_empty() else show_home, true)
	label(page, "PRİZMA 0.1 · İLK AŞAMA", Rect2(32, 895, 476, 28), 13, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)

func toggle_setting(key: String) -> void:
	save.data.settings[key] = not save.data.settings[key]
	save.flush()
	audio.apply_settings(save.data.settings)
	show_settings()
