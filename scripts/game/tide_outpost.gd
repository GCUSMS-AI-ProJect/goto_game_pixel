extends "res://scripts/visuals/chart_art.gd"

const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const BattleLayout = preload("res://scripts/ui/battle_layout.gd")
const SAVE = "user://dock.cfg"
const PILOT_AREA = Rect2(40, 447, 400, 254)
const LAUNCH = Rect2(36, 739, 408, 67)
const PAUSE_BUTTONS = [Rect2(47, 362, 386, 62), Rect2(47, 437, 386, 62), Rect2(47, 512, 386, 62)]
const MOTION_OPTION = Rect2(49, 492, 382, 54)
const RESULT_DONE = Rect2(47, 545, 386, 59)
const RESULT_REVEAL_START := 0.19
const RESULT_REVEAL_END := 0.62
const HOME_SETTINGS = Rect2(390, 57, 54, 51)
const HOME_RECENTER := Rect2(390, 117, 54, 46)
const HOME_PORT = Rect2(36, 654, 171, 65)
const HOME_SHIP = Rect2(219, 654, 225, 65)
const UPGRADE_CONFIRM := Rect2(232, 634, 208, 51)
const UPGRADE_CLOSE := Rect2(40, 634, 178, 51)
const AUDIO_DONE = Rect2(49, 561, 382, 56)
const DRAG_THRESHOLD := 12.0
const NO_POINTER := -2
const ANDROID_GESTURE_MARGIN := 36.0
const CHAIN_WINDOW = 1.45
const SURGE_HITS = 8
const SEARCH_INTRO := 2.8
const COMBAT_TAIL := 2.0
const DOCK_EXIT := Rect2(36, 758, 408, 55)
const BATCH_SIZE := 3
const BATCH_INTERVAL := 2.2
const ELITE_ARRIVAL := 73.0
const BOSS_ARRIVAL := 149.0
const BOSS_HEALTH := 1100
const ENTRY_SPEED := 128.0
const WAVES = [
	[SEARCH_INTRO, "oo..oo..", "..o...o."],
	[12.0, "o..oo..o", ".o.rr.o."],
	[26.0, "..s..s..", "or....ro", ".oo..oo."],
	[43.0, "o.roor.o", ".s....s.", "..o..o.."],
	[60.0, "rr..oos.", "oo.r..sr", "..oo..oo"],
	[80.0, "s.oooo.s", ".ro..or.", "r..ss..r"],
	[102.0, "os..o..s", "rr.oo.rr", "..s..s.."],
	[126.0, "sro..ors", "or.s..ro", "r..oo..r"],
]
const CHOICES = [
	["灼浪", "命中引发小范围爆炸", PEACH],
	["霜流", "命中使敌人减速", MINT],
	["雷鸣", "命中时电击附近目标", LILAC],
	["锚石", "穿过首批敌人，继续向前", SKY],
	["蒸汽潮", "灼浪与霜流融合，爆炸并冻结", GOLD],
	["风暴眼", "霜流与雷鸣融合，减速并连锁", SKY],
	["熔雷", "灼浪与雷鸣融合，连锁并爆炸", CORAL],
	["珊瑚礁", "灼浪与锚石融合，穿透并爆炸", PEACH],
	["冰棱", "霜流与锚石融合，穿透并冻结", MINT],
	["磁暴锚", "雷鸣与锚石融合，穿透并连锁", LILAC],
	["速射", "缩短射击间隔", MINT],
	["折射", "弹球延长反弹时间", LILAC],
	["维修", "恢复船体耐久", PEACH],
	["扩容", "增加一颗可同时出击的主球", SKY],
]
const BASE_BALLS = 4
const BALL_SLOTS = 3
const RECIPES = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
const BUILDINGS = [
	["船坞", "耐久 +15/级", MINT],
	["合金炉", "伤害 +2/级", PEACH],
	["推进站", "闪避 +1/级", LILAC],
	["潮网", "晶盐 +1/级", SKY],
]

var rng := RandomNumberGenerator.new()
var mode := "home"
var settings_return := "home"
var audio_drag := -1
var audio_pointer := -2
var chart_notice_time := 0.0
var chart_dragging := false
var chart_last_point := Vector2.ZERO
var ship_drawer := false
var ship_slide := 0.0
var dock_port := 0
var pilot := Vector2(240, 655)
var movement := Vector2.ZERO
var touch_vector := Vector2.ZERO
var touch_origin := Vector2.ZERO
var arena_pointer := NO_POINTER
var arena_down := Vector2.ZERO
var arena_dragged := false
var control_presses := {}
var control_feedback := [0.0, 0.0, 0.0]
var menu_pointer := NO_POINTER
var menu_press_point := Vector2.INF
var menu_press_page := ""
var menu_feedback := 0.0
var combo_emphasis := 0.0
var seen_combo := 0
var battle_layout: BattleLayout
var layout_canvas := Rect2()
var layout_safe := Rect2()
var safe_area_poll := 0.0
var pilot_type := 0
var sector := 0
var hp := 100
var max_hp := 100
var xp := 0
var level := 1
var kills := 0
var earned := 0
var metal := 0
var wins := 0
var buildings: Array[int] = [0, 0, 0, 0]
var lots: Array[int] = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
var salvage: Array[int] = [2, 0, 1, 0, 0, 4, 0, 2, 3, 0, 3, 0]
var salt := 0
var sorties := 0
var sweeps := 2
var selected_building := 0
var dock_note := "点打捞收货，点设施建造或升级"
var modules: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var options: Array[int] = []
var elapsed := 0.0
var clock := 0.0
var wave := 0
var wave_banner := 0.0
var wave_batches: Array[Array] = []
var next_batch := 0
var batch_arrival := 0.0
var reinforcement_time := 0.0
var reinforcement_side := false
var elite_spawned := false
var shot_clock := 0.0
var boss_clock := 0.0
var boss_spawned := false
var encounter_time := 0.0
var armor_time := 0.0
var dash_time := 0.0
var dash_direction := Vector2.UP
var charges := 2
var max_charges := 2
var recharge := 0.0
var haste := 0
var bounces := 0
var core_capacity := 3
var recall_time := 0.0
var aim_point := Vector2.ZERO
var combo_hits := 0
var combo_time := 0.0
var best_combo := 0
var surge_ready := false
var shot_heading := Vector2.UP
var next_id := 0
var last_reward := 0
var last_salt_reward := 0
var upgrade_points := 0
var selected_upgrade := -1
var result_time := 0.0
var enemies: Array[Dictionary] = []
var balls: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var sound := AudioDirector.new()

func _ready() -> void:
	setup_art()
	rng.randomize()
	load_dock()
	add_child(sound)
	refresh_layout()
	get_viewport().size_changed.connect(refresh_layout)

func refresh_layout() -> void:
	var canvas := get_viewport_rect()
	var safe_area := canvas
	var android := OS.get_name() == "Android"
	if android:
		var window_rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
		var usable := window_rect.intersection(DisplayServer.get_display_safe_area())
		if usable.has_area() and window_rect.has_area():
			var scale := canvas.size / Vector2(window_rect.size)
			safe_area = Rect2(Vector2(usable.position - window_rect.position) * scale,
				Vector2(usable.size) * scale)
	if canvas == layout_canvas and safe_area == layout_safe:
		return
	layout_canvas = canvas
	layout_safe = safe_area
	battle_layout = BattleLayout.new(canvas, safe_area, ARENA, ANDROID_GESTURE_MARGIN if android else 0.0)
	clear_drag()

func menu_origin() -> Vector2:
	return (layout_canvas.get_center() - BattleLayout.DESIGN_SIZE * 0.5).floor()

func settings_origin() -> Vector2:
	return menu_origin() if settings_return == "home" else battle_layout.dialog_origin

func load_dock() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE) != OK:
		return
	metal = maxi(0, int(config.get_value("dock", "metal", 0)))
	wins = maxi(0, int(config.get_value("dock", "wins", 0)))
	for i in range(buildings.size()):
		buildings[i] = clampi(int(config.get_value("dock", str(i), 0)), 0, 3)
		if buildings[i] > 0:
			lots[i] = i
			salvage[i] = 0
	var stored_lots: Array = config.get_value("harbor", "lots", [])
	var stored_salvage: Array = config.get_value("harbor", "salvage", [])
	if stored_lots.size() == lots.size() and stored_salvage.size() == salvage.size():
		lots.assign(stored_lots)
		salvage.assign(stored_salvage)
	salt = maxi(0, int(config.get_value("harbor", "salt", 0)))
	sorties = maxi(0, int(config.get_value("harbor", "sorties", 0)))
	sweeps = clampi(int(config.get_value("harbor", "sweeps", 2)), 0, 2)
	reduced_fx = config.get_value("presentation", "reduced_fx", false)
	sound.music_level = clampf(float(config.get_value("audio", "music", 0.7)), 0, 1)
	sound.effects_level = clampf(float(config.get_value("audio", "effects", 0.8)), 0, 1)
	sector = clampi(int(config.get_value("navigation", "sea", 0)), 0, int(wins > 0))
	dock_port = clampi(int(config.get_value("navigation", "port", 0)), 0, PORTS.size() - 1)
	pilot_type = clampi(int(config.get_value("navigation", "ship", 0)), 0, int(buildings[2] > 0))

func save_dock() -> void:
	var config := ConfigFile.new()
	config.set_value("dock", "metal", metal)
	config.set_value("dock", "wins", wins)
	for i in range(buildings.size()):
		config.set_value("dock", str(i), buildings[i])
	config.set_value("harbor", "lots", lots)
	config.set_value("harbor", "salvage", salvage)
	config.set_value("harbor", "salt", salt)
	config.set_value("harbor", "sorties", sorties)
	config.set_value("harbor", "sweeps", sweeps)
	config.set_value("presentation", "reduced_fx", reduced_fx)
	config.set_value("audio", "music", sound.music_level)
	config.set_value("audio", "effects", sound.effects_level)
	config.set_value("navigation", "sea", sector)
	config.set_value("navigation", "port", dock_port)
	config.set_value("navigation", "ship", pilot_type)
	var result := config.save(SAVE)
	if result != OK:
		push_warning("Cannot save dock: %s" % error_string(result))

func price(index: int) -> int:
	return 5 + buildings[index] * 7 + index * 2

func work_lot(cell: int) -> void:
	var kind := lots[cell]
	if kind < 0:
		if salvage[cell] != 0:
			dock_note = "先用边上的箭头打捞这一格"
			return
		kind = selected_building
		if buildings[kind] > 0:
			dock_note = "这座设施已建成，点它所在的地块升级"
			return
	if buildings[kind] >= 3:
		dock_note = "设施已满级"
		return
	var salt_cost := 1 if kind == 3 or buildings[kind] == 2 else 0
	if metal < price(kind) or salt < salt_cost:
		dock_note = "需要铁料 %d · 晶盐 %d" % [price(kind), salt_cost]
		return
	metal -= price(kind)
	salt -= salt_cost
	lots[cell] = kind
	buildings[kind] += 1
	dock_note = "%s升到 %d 级" % [BUILDINGS[kind][0], buildings[kind]]
	save_dock()
	play_sound(2)

func sweep_line(index: int, column: bool) -> void:
	if sweeps == 0:
		dock_note = "打捞用完，下次出航回来再补充"
		return
	var iron := 0
	var crystal := 0
	for i in range(3 if column else 4):
		var cell := i * 4 + index if column else index * 4 + i
		iron += salvage[cell] % 4
		crystal += floori(salvage[cell] / 4.0)
		salvage[cell] = 0
	if iron + crystal == 0:
		dock_note = "这条线上没有可打捞的货物"
		return
	metal += iron
	salt += crystal
	sweeps -= 1
	dock_note = "打捞获得铁料 %d · 晶盐 %d" % [iron, crystal]
	save_dock()
	play_sound(1)

func best_harvest(resource: int) -> Vector4i:
	var best := Vector4i(-1, 0, 0, 0)
	for line in range(7):
		var column := line >= 3
		var index := line - 3 if column else line
		var iron := 0
		var crystals := 0
		for step in range(3 if column else 4):
			var cargo := salvage[step * 4 + index if column else index * 4 + step]
			iron += cargo % 4
			crystals += cargo / 4
		var desired := iron if resource == 0 else crystals
		var secondary := crystals if resource == 0 else iron
		var current := best.z if resource == 0 else best.w
		var current_secondary := best.w if resource == 0 else best.z
		if desired > current or (desired > 0 and desired == current and secondary > current_secondary):
			best = Vector4i(index, int(column), iron, crystals)
	return best

func harvest(resource: int) -> void:
	var cargo := best_harvest(resource)
	if cargo.x >= 0:
		sweep_line(cargo.x, bool(cargo.y))
	else:
		dock_note = "暂时没有可打捞的货物"

func improve_facility(kind: int) -> void:
	selected_building = kind
	var cell := lots.find(kind)
	if cell < 0:
		for index in range(lots.size()):
			if lots[index] < 0 and salvage[index] == 0:
				cell = index
				break
	if cell >= 0:
		work_lot(cell)
	else:
		dock_note = "先打捞货物腾出空地"

func start_run() -> void:
	ship_drawer = false
	ship_slide = 0
	pilot = Vector2(240, 650)
	max_hp = 100 + 15 * buildings[0] - 15 * pilot_type
	hp = max_hp
	xp = 0
	level = 1
	upgrade_points = 0
	selected_upgrade = -1
	options.clear()
	kills = 0
	earned = 0
	haste = 0
	bounces = 0
	core_capacity = 3
	recall_time = 0
	aim_point = Vector2.ZERO
	combo_hits = 0
	combo_time = 0
	best_combo = 0
	surge_ready = false
	seen_combo = 0
	combo_emphasis = 0.0
	control_feedback.fill(0.0)
	modules.fill(0)
	elapsed = 0
	shot_clock = 0.25
	wave = 0
	wave_banner = 0.0
	wave_batches.clear()
	next_batch = 0
	batch_arrival = 0.0
	reinforcement_time = 0.0
	reinforcement_side = false
	elite_spawned = false
	boss_clock = 0
	boss_spawned = false
	encounter_time = 0.0
	armor_time = 0
	dash_time = 0
	recharge = 0
	max_charges = 2 + buildings[2]
	charges = max_charges
	next_id = 0
	enemies.clear()
	balls.clear()
	hazards.clear()
	pickups.clear()
	reset_fx()
	clear_drag()
	mode = "fight"
	sound.play_cue("departure")

func clear_drag() -> void:
	arena_pointer = NO_POINTER
	arena_dragged = false
	control_presses.clear()
	menu_pointer = NO_POINTER
	chart_dragging = false
	menu_feedback = 0.0
	touch_vector = Vector2.ZERO
	movement = Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode == "fight":
			mode = "pause"
		clear_drag()

func _input(event: InputEvent) -> void:
	if mode == "settings" and handle_audio_pointer(event):
		return
	if mode == "fight" and handle_battle_pointer(event):
		return
	if handle_menu_pointer(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if mode == "fight":
					activate_control(BattleLayout.Action.DASH)
			KEY_R:
				if mode == "fight":
					activate_control(BattleLayout.Action.RECALL)
			KEY_ESCAPE:
				if mode == "settings":
					mode = settings_return
				elif mode == "dock":
					mode = "home"
				elif mode == "home" and ship_drawer:
					ship_drawer = false
				elif mode == "level":
					close_upgrades()
				else:
					toggle_pause()
			KEY_ENTER:
				if mode == "home":
					start_run()
				elif mode in ["win", "loss"] and result_time >= RESULT_REVEAL_END:
					mode = "dock"

func handle_menu_pointer(event: InputEvent) -> bool:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		var pointer: int = event.index if event is InputEventScreenTouch else -1
		var canceled: bool = event is InputEventScreenTouch and event.canceled
		if event.pressed and not canceled:
			if menu_pointer == NO_POINTER:
				menu_pointer = pointer
				menu_press_point = event.position
				menu_press_page = mode
				chart_last_point = event.position
				chart_dragging = false
		elif pointer == menu_pointer:
			menu_pointer = NO_POINTER
			if chart_dragging and not canceled:
				chart_pan += event.position - chart_last_point
			if not canceled and not chart_dragging and menu_press_page == mode and event.position.distance_to(menu_press_point) < DRAG_THRESHOLD:
				menu_feedback = 0.14
				press(menu_press_point)
			chart_dragging = false
		return true
	if (event is InputEventScreenDrag and event.index == menu_pointer) or (event is InputEventMouseMotion and menu_pointer == -1):
		if mode == "home" and menu_press_page == "home" and not ship_drawer and CHART.has_point(menu_press_point - menu_origin()):
			if chart_dragging or event.position.distance_to(menu_press_point) >= DRAG_THRESHOLD:
				chart_dragging = true
				chart_pan += event.position - chart_last_point
				chart_last_point = event.position
		elif event.position.distance_to(menu_press_point) >= DRAG_THRESHOLD:
			menu_pointer = NO_POINTER
			menu_feedback = 0.0
		return true
	return false

func handle_battle_pointer(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			begin_battle_press(event.index, event.position)
		else:
			end_battle_press(event.index, event.position, event.canceled)
	elif event is InputEventScreenDrag:
		move_battle_press(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_battle_press(-1, event.position)
		else:
			end_battle_press(-1, event.position)
	elif event is InputEventMouseMotion:
		move_battle_press(-1, event.position)
	else:
		return false
	return true

func begin_battle_press(pointer: int, point: Vector2) -> void:
	var control := battle_layout.control_at(point)
	if control >= 0 and (control != BattleLayout.Action.UPGRADE or upgrade_points > 0):
		control_presses[pointer] = {"control": control, "origin": point}
	elif arena_pointer == NO_POINTER and battle_layout.arena.has_point(point):
		arena_pointer = pointer
		arena_down = point
		touch_origin = battle_layout.inverse_world * point

func move_battle_press(pointer: int, point: Vector2) -> void:
	if pointer == arena_pointer:
		if arena_dragged or point.distance_to(arena_down) >= DRAG_THRESHOLD:
			arena_dragged = true
			read_drag(battle_layout.inverse_world * point)
	elif control_presses.has(pointer):
		var pending: Dictionary = control_presses[pointer]
		if point.distance_to(pending.origin) >= DRAG_THRESHOLD or not battle_layout.control_contains(pending.control, point):
			control_presses.erase(pointer)

func end_battle_press(pointer: int, point: Vector2, canceled := false) -> void:
	if pointer == arena_pointer:
		var world_point := battle_layout.inverse_world * point
		if not canceled and not arena_dragged and point.distance_to(arena_down) < DRAG_THRESHOLD \
				and battle_layout.arena.has_point(point) and world_point.y < PILOT_AREA.position.y:
			aim_point = world_point
		arena_pointer = NO_POINTER
		arena_dragged = false
		touch_vector = Vector2.ZERO
		movement = Vector2.ZERO
	elif control_presses.has(pointer):
		var pending: Dictionary = control_presses[pointer]
		control_presses.erase(pointer)
		if not canceled and point.distance_to(pending.origin) < DRAG_THRESHOLD \
				and battle_layout.control_contains(pending.control, point):
			activate_control(pending.control)

func activate_control(control: int) -> void:
	if control == BattleLayout.Action.PAUSE:
		toggle_pause()
		return
	if control == BattleLayout.Action.UPGRADE:
		open_level()
		return
	control_feedback[control] = 0.20
	match control:
		BattleLayout.Action.AIM:
			aim_point = Vector2.ZERO
			play_sound(1)
		BattleLayout.Action.RECALL:
			recall_balls()
		BattleLayout.Action.DASH:
			dash()

func read_drag(position: Vector2) -> void:
	var offset := position - touch_origin
	touch_vector = (offset / 42.0).limit_length()
	if offset.length() > 56:
		touch_origin = position - offset.normalized() * 56.0

func toggle_pause() -> void:
	if mode == "fight":
		mode = "pause"
		clear_drag()
	elif mode == "pause":
		mode = "fight"

func press(point: Vector2) -> bool:
	if mode in ["home", "dock"]:
		point -= menu_origin()
	match mode:
		"home":
			press_home(point)
		"dock":
			if DOCK_EXIT.has_point(point):
				mode = "home"
				play_sound(1)
			else:
				for resource in range(2):
					if harvest_rect(resource).has_point(point):
						harvest(resource)
				for kind in range(BUILDINGS.size()):
					if facility_rect(kind).has_point(point):
						improve_facility(kind)
		"level":
			var local := point - battle_layout.dialog_origin
			if UPGRADE_CLOSE.has_point(local):
				close_upgrades()
				return true
			if UPGRADE_CONFIRM.has_point(local):
				choose(selected_upgrade)
				return true
			for i in range(options.size()):
				if choice_rect(i).has_point(point):
					selected_upgrade = options[i]
					break
		"pause":
			point -= battle_layout.dialog_origin
			if PAUSE_BUTTONS[0].has_point(point):
				toggle_pause()
			elif PAUSE_BUTTONS[1].has_point(point):
				open_settings()
			elif PAUSE_BUTTONS[2].has_point(point):
				finish(false)
		"settings":
			change_audio(point - settings_origin())
		"win", "loss":
			if result_time >= RESULT_REVEAL_END and RESULT_DONE.has_point(point - battle_layout.dialog_origin):
				mode = "dock"
	return true

func press_home(point: Vector2) -> void:
	if ship_drawer:
		for index in range(2):
			if ship_option_rect(index).has_point(point):
				if index == 0 or buildings[2] > 0:
					pilot_type = index
					ship_drawer = false
					save_dock()
					play_sound(1)
				return
		ship_drawer = false
		return
	if LAUNCH.has_point(point):
		start_run()
	elif HOME_SETTINGS.has_point(point):
		open_settings()
	elif HOME_RECENTER.has_point(point):
		chart_pan = Vector2.ZERO
	elif HOME_PORT.has_point(point):
		enter_dock(dock_port)
	elif HOME_SHIP.has_point(point):
		ship_drawer = true
		play_sound(1)
	elif CHART.has_point(point):
		var world_point := point - chart_pan.round()
		for index in range(PORTS.size()):
			if world_point.distance_to(PORTS[index]) <= 26:
				enter_dock(index)
				return
		for index in range(REGION_TARGETS.size()):
			if REGION_TARGETS[index].has_point(world_point):
				if index == 0 or wins > 0:
					sector = index
					save_dock()
					play_sound(1)
				else:
					chart_notice_time = clock + 3.0

func enter_dock(index: int) -> void:
	dock_port = index
	mode = "dock"
	save_dock()
	play_sound(1)

func open_settings() -> void:
	settings_return = mode
	mode = "settings"
	play_sound(1)

func settings_level_rect(index: int) -> Rect2:
	return Rect2(65, 325 + index * 85, 350, 52)

func handle_audio_pointer(event: InputEvent) -> bool:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		var pointer: int = event.index if event is InputEventScreenTouch else -1
		if not event.pressed or (event is InputEventScreenTouch and event.canceled):
			if audio_drag < 0 or pointer != audio_pointer:
				return false
			audio_drag = -1
			audio_pointer = -2
			save_dock()
			return true
		for index in range(2):
			var point: Vector2 = event.position - settings_origin()
			if settings_level_rect(index).has_point(point):
				audio_pointer = pointer
				audio_drag = index
				set_audio_level(index, point.x)
				return true
	elif audio_drag >= 0:
		if (event is InputEventScreenDrag and event.index == audio_pointer) or (event is InputEventMouseMotion and audio_pointer == -1):
			set_audio_level(audio_drag, event.position.x - settings_origin().x)
			return true
	return false

func change_audio(point: Vector2) -> void:
	if AUDIO_DONE.has_point(point):
		audio_drag = -1
		audio_pointer = -2
		save_dock()
		mode = settings_return
		play_sound(1)
	elif MOTION_OPTION.has_point(point):
		reduced_fx = not reduced_fx
		save_dock()
		play_sound(1)

func set_audio_level(index: int, position: float) -> void:
	var rect := settings_level_rect(index)
	var value := roundf(clampf((position - rect.position.x - 8) / (rect.size.x - 16), 0, 1) * 10) / 10.0
	if index == 0:
		sound.music_level = value
	elif value != sound.effects_level:
		sound.effects_level = value
		sound.play_cue("hit")

func dash() -> void:
	if charges == 0 or dash_time > 0:
		return
	dash_direction = movement.normalized() if movement.length() > 0.1 else Vector2.UP
	dash_time = 0.17
	armor_time = maxf(armor_time, 0.4)
	charges -= 1
	emit_fx("wake", pilot, SKY, 0.28, 27, -dash_direction)
	play_sound(1)

func recall_balls() -> void:
	if mode != "fight" or recall_time > 0 or balls.is_empty():
		return
	recall_time = 5.0
	emit_fx("recall", pilot, SKY, 0.35, 72)
	for ball in balls:
		ball.returning = true
	play_sound(1)

func _physics_process(delta: float) -> void:
	clock += delta
	ship_slide = move_toward(ship_slide, float(ship_drawer), delta * 6.5)
	menu_feedback = maxf(0, menu_feedback - delta)
	if OS.get_name() == "Android":
		safe_area_poll -= delta
		if safe_area_poll <= 0:
			refresh_layout()
			safe_area_poll = 0.25
	if mode in ["fight", "win", "loss"]:
		tick_fx(delta)
	if mode in ["win", "loss"]:
		result_time += delta
	if mode == "fight":
		tick_battle(delta)
		for index in range(control_feedback.size()):
			control_feedback[index] = maxf(0, control_feedback[index] - delta)
		combo_emphasis = maxf(0, combo_emphasis - delta)
		if combo_hits > seen_combo and floori(float(combo_hits) / SURGE_HITS) > floori(float(seen_combo) / SURGE_HITS):
			combo_emphasis = 0.62
		seen_combo = combo_hits
		if not enemies.is_empty() or not hazards.is_empty():
			encounter_time = COMBAT_TAIL
		else:
			encounter_time = maxf(0, encounter_time - delta)
	var quiet := mode in ["pause", "settings", "level", "win", "loss"]
	sound.mix(delta, score_scene(), quiet)
	queue_redraw()

func score_scene() -> AudioDirector.Scene:
	if mode in ["home", "dock"] or (mode == "settings" and settings_return == "home"):
		return AudioDirector.Scene.PORT
	if mode in ["win", "loss"]:
		return AudioDirector.Scene.SEARCH
	if boss_spawned:
		return AudioDirector.Scene.BOSS
	return AudioDirector.Scene.COMBAT if encounter_time > 0 else AudioDirector.Scene.SEARCH

func tick_battle(delta: float) -> void:
	elapsed += delta
	combo_time = maxf(0, combo_time - delta)
	if combo_time <= 0:
		combo_hits = 0
	recall_time = maxf(0, recall_time - delta)
	wave_banner = maxf(0, wave_banner - delta)
	armor_time = maxf(0, armor_time - delta)
	var keyboard := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	movement = (keyboard + touch_vector).limit_length()
	var speed := 222.0 + 48 * pilot_type
	if dash_time > 0:
		var previous_dash := dash_time
		dash_time -= delta
		movement = dash_direction
		speed = 615
		if floori(maxf(0, dash_time) * 25) < floori(previous_dash * 25):
			emit_fx("wake", pilot, SKY, 0.25, 28, -dash_direction)
	pilot = (pilot + movement * speed * delta).clamp(PILOT_AREA.position, PILOT_AREA.end)
	if charges < max_charges:
		recharge += delta
		if recharge >= 4.5:
			charges += 1
			recharge = 0
	update_spawns(delta)
	update_enemies(delta)
	update_hazards(delta)
	if hp <= 0:
		finish(false)
		return
	shot_clock -= delta
	if shot_clock <= 0 and active_cores() < core_capacity and enemies.any(enemy_in_play):
		volley()
		shot_clock = maxf(0.32, 0.74 - haste * 0.07 - pilot_type * 0.08)
	update_balls(delta)
	if mode != "fight":
		return
	update_pickups(delta)
	bank_upgrade_points()

func update_spawns(delta: float) -> void:
	if wave < WAVES.size() and elapsed >= next_wave_at() and next_batch >= wave_batches.size():
		batch_arrival = next_wave_at()
		prepare_wave(WAVES[wave])
		wave += 1
		wave_banner = 2.0
	if next_batch < wave_batches.size() and elapsed >= batch_arrival:
		if encounter_time <= 0:
			sound.play_cue("contact")
		send_batch(wave_batches[next_batch], (wave + next_batch) % 2 == 0)
		next_batch += 1
		batch_arrival = elapsed + BATCH_INTERVAL
	if elapsed >= ELITE_ARRIVAL and not elite_spawned:
		elite_spawned = true
		send_batch([Vector3i(4, 0, 0)], false)
	if elapsed >= BOSS_ARRIVAL and not boss_spawned:
		boss_spawned = true
		spawn_enemy(3, Vector2(240, ARENA.position.y + 24))
		reinforcement_time = 3.0
		wave_banner = 3.0
		play_sound(3)
	if boss_spawned:
		reinforcement_time -= delta
		if reinforcement_time <= 0 and enemies.size() <= 10:
			reinforcement_time = 6.0
			send_batch([Vector3i(0, 1, 0), Vector3i(0, 6, 0)], reinforcement_side)
			reinforcement_side = not reinforcement_side

func next_wave_at() -> float:
	return WAVES[wave][0] if wave < WAVES.size() else BOSS_ARRIVAL

func prepare_wave(formation: Array) -> void:
	wave_batches.clear()
	next_batch = 0
	for row in range(1, formation.size()):
		var batch: Array[Vector3i] = []
		for lane in range(8):
			var column := 7 - lane if sector == 1 and wave % 2 == 1 else lane
			var symbol: String = formation[row][column]
			var kind := "ors".find(symbol)
			if kind < 0:
				continue
			batch.append(Vector3i(kind, lane, row - 1))
			if batch.size() == BATCH_SIZE:
				wave_batches.append(batch)
				batch = []
		if not batch.is_empty():
			wave_batches.append(batch)

func send_batch(batch: Array, from_left: bool) -> void:
	for index in range(batch.size()):
		var member: Vector3i = batch[index]
		var destination := Vector2(65 + member.y * 50, 169 + member.z * 22)
		if member.x == 4:
			destination.x = 240
		if from_left:
			destination = Vector2(100 + index * 58, 200 + member.z * 34 + member.y * 7)
		var start := Vector2(destination.x, ARENA.position.y - 30 - index * 13)
		if from_left:
			start = Vector2(ARENA.position.x - 30 - index * 19, destination.y - 26)
		spawn_enemy(member.x, start, destination)

func spawn_enemy(kind: int, position: Vector2, entry := Vector2.ZERO) -> void:
	var capacity: int = [16, 10, 37, BOSS_HEALTH, 185][kind]
	if kind < 3:
		capacity += maxi(wave - 1, 0)
	capacity = roundi(capacity * (1.0 + sector * 0.22))
	next_id += 1
	enemies.append({"id": next_id, "kind": kind, "pos": position, "hp": capacity, "max_hp": capacity,
		"slow": 0.0, "phase": rng.randf_range(0, TAU), "flash": 0.0, "fired": false,
		"attack": 1.5, "recoil": Vector2.ZERO, "entry": entry})

func radius(kind: int) -> float:
	return [15.0, 12.0, 20.0, 35.0, 26.0][kind]

func update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		enemy.slow = maxf(0, enemy.slow - delta)
		enemy.flash = maxf(0, enemy.flash - delta)
		enemy.recoil = enemy.recoil.move_toward(Vector2.ZERO, 40 * delta)
		var slow_factor := 0.48 if enemy.slow > 0 else 1.0
		if enemy.entry != Vector2.ZERO:
			enemy.pos = enemy.pos.move_toward(enemy.entry, ENTRY_SPEED * delta * slow_factor)
			if enemy.pos == enemy.entry:
				enemy.entry = Vector2.ZERO
			continue
		var kind: int = enemy.kind
		if kind == 3:
			enemy.pos.y = move_toward(enemy.pos.y, 345, delta * 42 * slow_factor)
			enemy.pos.x = 240 + sin(elapsed * 0.53) * (132 if sector == 0 else 95)
			boss_clock -= delta
			if boss_clock <= 0 and enemy.pos.y > 230:
				var direction: Vector2 = enemy.pos.direction_to(pilot)
				if sector == 0:
					for j in range(-2, 3):
						hazards.append({"pos": enemy.pos, "vel": direction.rotated(j * 0.22) * 183})
				else:
					for lane in range(8):
						if absf((65 + lane * 50) - pilot.x) >= 42 or lane == floori(elapsed) % 8:
							hazards.append({"pos": Vector2(65 + lane * 50, enemy.pos.y + 27), "vel": Vector2(0, 217)})
					hazards.append({"pos": enemy.pos, "vel": direction * 241})
				boss_clock = 1.60 if float(enemy.hp) / enemy.max_hp > 0.5 else 1.20
		elif kind == 4:
			enemy.pos.y += 26 * delta * slow_factor
			enemy.attack -= delta
			if enemy.attack <= 0:
				enemy.attack = 2.1
				for offset in [-35, 0, 35]:
					hazards.append({"pos": enemy.pos + Vector2(offset, 12), "vel": Vector2(0, 203)})
			if enemy.pos.y > ARENA.end.y - 20:
				enemies.remove_at(i)
				hurt(24, true)
				continue
		else:
			var drift := sin(elapsed * 2.4 + float(enemy.phase)) * (13 if kind == 1 else 0)
			var speed: float = [27.0, 40.0, 23.0][kind]
			enemy.pos.x = clampf(enemy.pos.x + drift * delta, 42, 438)
			enemy.pos.y += (speed + sector * 8) * delta * slow_factor
			if kind == 2 and enemy.pos.y > 365 and not enemy.fired:
				enemy.fired = true
				var direction: Vector2 = enemy.pos.direction_to(pilot)
				hazards.append({"pos": enemy.pos, "vel": direction * 195})
			if enemy.pos.y > ARENA.end.y - 9:
				enemies.remove_at(i)
				hurt(5 if kind != 2 else 10, true)
				continue
		if pilot.distance_squared_to(enemy.pos) < pow(radius(kind) + 11, 2):
			hurt(20 if kind != 1 else 13, false)

func hurt(amount: int, breach: bool) -> void:
	if armor_time > 0 and not breach:
		return
	hp = maxi(0, hp - amount)
	armor_time = 0.8
	emit_fx("break", pilot, CORAL, 0.32, 42)
	kick_impact(3.8)
	sound.play_cue("hurt")

func update_hazards(delta: float) -> void:
	for i in range(hazards.size() - 1, -1, -1):
		var shot := hazards[i]
		shot.pos += shot.vel * delta
		if not ARENA.has_point(shot.pos):
			hazards.remove_at(i)
		elif pilot.distance_squared_to(shot.pos) < 18.0 * 18.0:
			hurt(15, false)
			hazards.remove_at(i)

func enemy_in_play(enemy: Dictionary) -> bool:
	return ARENA.has_point(enemy.pos)

func target_nearest() -> Vector2:
	if aim_point != Vector2.ZERO:
		return pilot.direction_to(aim_point)
	var best := INF
	var result := Vector2.UP
	for enemy in enemies:
		if not enemy_in_play(enemy):
			continue
		var distance := pilot.distance_squared_to(enemy.pos)
		if distance < best:
			best = distance
			result = pilot.direction_to(enemy.pos)
	return result if result.length_squared() > 0 else Vector2.UP

func active_cores() -> int:
	var count := 0
	for ball in balls:
		if ball.kind == -1:
			count += 1
	return count

func volley() -> void:
	var aim := target_nearest()
	var charged := surge_ready
	surge_ready = false
	var damage: float = (14 + buildings[1] * 2 + level / 2.0) * (1.28 if charged else 1.0)
	muzzle_time = 0.105
	shot_heading = aim
	if charged:
		emit_fx("surge", pilot, GOLD, 0.47, 69, aim)
		kick_impact(2.4)
		play_impact(6)
	send_ball(-1, aim, damage, charged)
	if pilot_type == 1:
		send_ball(-2, aim.rotated(-0.28), damage * 0.52)
		send_ball(-2, aim.rotated(0.28), damage * 0.52)
	for index in range(modules.size()):
		if modules[index] > 0:
			var spread := 0.13 * (1 + index % 3) * (1 if index % 2 == 0 else -1)
			send_ball(index, aim.rotated(spread), damage + 4 * modules[index] + (10 if index >= BASE_BALLS else 0), charged)

func send_ball(kind: int, direction: Vector2, power: float, charged: bool = false) -> void:
	if balls.size() >= 135:
		return
	var penetration := 2 if kind in [3, 7, 8, 9] else 0
	balls.append({"pos": pilot + direction * 14, "vel": direction * (582 if charged else 514), "kind": kind,
		"power": roundi(power), "wall_hits": 4 + bounces, "life": 3.2 + bounces * 0.34,
		"target": -1, "cooldown": 0.0, "returning": false, "penetration": penetration,
		"banks": 0, "charged": charged, "trail": []})

func update_balls(delta: float) -> void:
	for index in range(balls.size() - 1, -1, -1):
		var ball := balls[index]
		var from: Vector2 = ball.pos
		var trail: Array = ball.trail
		trail.append(from)
		if trail.size() > (3 if reduced_fx else 6):
			trail.pop_front()
		if ball.returning:
			ball.vel = ball.pos.direction_to(pilot) * 780
			ball.pos = ball.pos.move_toward(pilot, 780 * delta)
			if ball.pos.distance_squared_to(pilot) <= 13 * 13:
				if ball.kind == -1:
					emit_fx("hit", pilot, MINT, 0.12, 17)
				balls.remove_at(index)
			continue
		ball.life -= delta
		ball.cooldown -= delta
		if sector == 1 and ball.pos.y > 288 and ball.pos.y < 435:
			var current := 1 if floori(elapsed / 12.0) % 2 == 0 else -1
			ball.vel.x = clampf(ball.vel.x + 162 * current * delta, -520, 520)
		ball.pos += ball.vel * delta
		if ball.pos.x < ARENA.position.x + 5 or ball.pos.x > ARENA.end.x - 5:
			ball.pos.x = clampf(ball.pos.x, ARENA.position.x + 5, ARENA.end.x - 5)
			ball.vel.x *= -1
			ball.wall_hits -= 1
			ball.banks = mini(3, ball.banks + 1)
			emit_fx("wall", ball.pos, GOLD, 0.24, 36, ball.vel.normalized())
			sound.play_cue("rail")
		if ball.pos.y < ARENA.position.y + 5:
			ball.pos.y = ARENA.position.y + 5
			ball.vel.y *= -1
			ball.wall_hits -= 1
			emit_fx("wall", ball.pos, SKY, 0.21, 27, ball.vel.normalized())
		if (ball.vel.y > 0 and ball.pos.distance_squared_to(pilot) <= 24 * 24) or ball.pos.y > ARENA.end.y - 3 or ball.life <= 0 or ball.wall_hits < 0:
			ball.returning = true
			continue
		connect_ball(ball, from)
		if mode != "fight":
			return

func connect_ball(ball: Dictionary, from: Vector2) -> void:
	var step: Vector2 = ball.pos - from
	var step_length := step.length_squared()
	if step_length < 0.001:
		return
	var target: Dictionary = {}
	var nearest := 1.001
	for enemy in enemies:
		if not enemy_in_play(enemy) or (ball.cooldown > 0 and ball.target == enemy.id):
			continue
		var span := radius(enemy.kind) + 5
		var offset: Vector2 = from - enemy.pos
		if absf(offset.x) > span + absf(step.x) or absf(offset.y) > span + absf(step.y):
			continue
		var start := offset.length_squared() - span * span
		var along := offset.dot(step)
		var discriminant := along * along - step_length * start
		if discriminant < 0:
			continue
		var contact := 0.0 if start <= 0 else (-along - sqrt(discriminant)) / step_length
		if contact >= 0 and contact <= 1 and contact < nearest:
			target = enemy
			nearest = contact
	if target.is_empty():
		return
	var contact_point := from + step * nearest
	var direction: Vector2 = ball.vel.normalized()
	var normal: Vector2 = target.pos.direction_to(contact_point)
	if normal.is_zero_approx():
		normal = -direction
	ball.cooldown = 0.12
	ball.target = target.id
	if ball.penetration > 0:
		ball.penetration -= 1
	elif ball.vel.dot(normal) < 0:
		ball.vel = ball.vel.bounce(normal)
		ball.pos = target.pos + normal * (radius(target.kind) + 5.1)
		ball.trail.append(contact_point)
	var bonus: bool = ball.banks > 0 or ball.charged
	var power := roundi(ball.power * (1 + ball.banks * 0.18))
	ball_hit(target, ball.kind, power, contact_point, direction, bonus)

func ball_hit(enemy: Dictionary, kind: int, power: int, contact: Vector2,
		direction: Vector2, bonus: bool) -> void:
	var center: Vector2 = enemy.pos
	var color: Color = CHOICES[kind][2] if kind >= 0 else PEACH
	var fused := kind >= BASE_BALLS
	var heavy := bonus or fused
	var freeze := kind in [1, 4, 5, 8]
	enemy.recoil = direction * (6 if heavy else 3)
	emit_fx("hit", contact, color, 0.22, 46 if heavy else 29, -direction)
	play_impact(4, 1 + minf(combo_hits, 18) * 0.009)
	if freeze:
		enemy.slow = 2.6
		if fused or enemy.flash <= 0:
			emit_fx("frost", center, SKY, 0.31, 48 if fused else 32)
			sound.play_cue("ice")
	damage_enemy(enemy, power, GOLD if bonus else color, heavy)
	if mode != "fight":
		return
	if kind in [0, 4, 6, 7]:
		var reach := 83 if fused else 59
		emit_fx("blast", center, color, 0.39 if fused else 0.28, reach)
		if fused:
			kick_impact(2.5)
			play_impact(5)
		for near in enemies.duplicate():
			if near.id != enemy.id and enemy_in_play(near) and center.distance_squared_to(near.pos) < reach * reach:
				if freeze:
					near.slow = 2.2
				damage_enemy(near, maxi(3, floori(power * 0.5)), color, fused)
	if mode != "fight":
		return
	if kind in [2, 5, 6, 9]:
		var count := 3 if kind >= BASE_BALLS else 1
		for near in enemies.duplicate():
			if near.id == enemy.id or not enemy_in_play(near) or center.distance_squared_to(near.pos) > 125 * 125:
				continue
			emit_fx("lightning", center, LILAC, 0.25, 1, near.pos - center)
			sound.play_cue("arc")
			if freeze:
				near.slow = 2.2
			damage_enemy(near, maxi(3, floori(power * 0.5)), LILAC, fused)
			count -= 1
			if count == 0 or mode != "fight":
				break

func damage_enemy(enemy: Dictionary, power: int, color: Color = CREAM, heavy: bool = false) -> void:
	if mode != "fight" or enemy.hp <= 0:
		return
	enemy.hp -= power
	enemy.flash = 0.11
	hit_label(enemy, power, color, heavy)
	combo_hits += 1
	combo_time = CHAIN_WINDOW
	best_combo = maxi(combo_hits, best_combo)
	if combo_hits % SURGE_HITS == 0:
		surge_ready = true
		emit_fx("surge", enemy.pos, GOLD, 0.32, 54)
	if enemy.hp > 0:
		return
	enemies.erase(enemy)
	kills += 1
	emit_fx("break", enemy.pos, enemy_tint(enemy.kind), 0.54 if enemy.kind >= 3 else 0.32,
		100 if enemy.kind == 3 else 50 if enemy.kind == 4 else 32)
	if enemy.kind == 3:
		kick_impact(5.0)
		play_impact(5)
		finish(true)
		return
	earned += [1, 1, 3, 0, 6][enemy.kind]
	if enemy.kind == 4:
		kick_impact(4)
		play_impact(5)
	pickups.append({"pos": enemy.pos, "value": [2, 2, 5, 0, 7][enemy.kind], "age": 0.0})

func update_pickups(delta: float) -> void:
	for index in range(pickups.size() - 1, -1, -1):
		var item := pickups[index]
		item.age += delta
		item.pos.y += 68 * delta
		var distance := pilot.distance_to(item.pos)
		if distance < 92 or item.age > 3.3:
			item.pos = item.pos.move_toward(pilot, 375 * delta)
		if item.pos.distance_to(pilot) < 17:
			xp += item.value
			emit_fx("pickup", item.pos, MINT if item.value < 5 else GOLD, 0.24, 18, item.pos.direction_to(pilot))
			pickups.remove_at(index)

func xp_needed() -> int:
	var tiers := level - 1
	return 8 + level * 3 + floori(tiers * tiers / 12.0)

func bank_upgrade_points() -> void:
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		upgrade_points += 1

func open_level() -> void:
	if mode != "fight" or upgrade_points == 0:
		return
	if options.is_empty():
		prepare_upgrades()
	clear_drag()
	mode = "level"
	play_sound(2)

func close_upgrades() -> void:
	selected_upgrade = -1
	mode = "fight"

func prepare_upgrades() -> void:
	var fusions: Array[int] = []
	var pool: Array[int] = [12]
	if haste < 5:
		pool.append(10)
	if bounces < 4:
		pool.append(11)
	if core_capacity < 5:
		pool.append(13)
	var free_slot := modules.count(0) > modules.size() - BALL_SLOTS
	for i in range(modules.size()):
		if (modules[i] > 0 and modules[i] < 3) or (i < BASE_BALLS and modules[i] == 0 and free_slot):
			pool.append(i)
	for i in range(RECIPES.size()):
		var recipe: Vector2i = RECIPES[i]
		if modules[recipe.x] >= 2 and modules[recipe.y] >= 2 and modules[i + BASE_BALLS] == 0:
			fusions.append(i + BASE_BALLS)
	for i in range(pool.size() - 1, 0, -1):
		var other := rng.randi_range(0, i)
		var entry := pool[i]
		pool[i] = pool[other]
		pool[other] = entry
	options.clear()
	options.append_array(fusions)
	for index in pool:
		if options.size() >= 3:
			break
		options.append(index)

func choose(index: int) -> void:
	if mode != "level" or upgrade_points <= 0 or index not in options:
		return
	match index:
		10: haste += 1
		11: bounces += 2
		12: hp = mini(max_hp, hp + 36)
		13: core_capacity += 1
		_:
			if index >= BASE_BALLS and modules[index] == 0:
				var recipe: Vector2i = RECIPES[index - BASE_BALLS]
				modules[recipe.x] = 0
				modules[recipe.y] = 0
			modules[index] += 1
	upgrade_points -= 1
	options.clear()
	selected_upgrade = -1
	if upgrade_points == 0:
		close_upgrades()
	else:
		prepare_upgrades()
	play_sound(2)

func finish(won: bool) -> void:
	if mode not in ["fight", "pause"]:
		return
	last_reward = floori(earned / 3.0) + (20 if won else 0) + floori(elapsed / 30.0)
	last_salt_reward = 0
	metal += last_reward
	if elapsed >= 12 or won:
		sorties += 1
		last_salt_reward = buildings[3] + int(won)
		salt += last_salt_reward
		sweeps = 2
		var placed := 0
		for offset in range(salvage.size()):
			var cell := (sorties * 5 + offset * 7) % salvage.size()
			if lots[cell] == -1 and salvage[cell] == 0:
				salvage[cell] = 4 if placed == 0 else 2 + placed % 2
				placed += 1
				if placed == 3:
					break
		dock_note = "潮水送来货物，点图标打捞"
	if won:
		wins += 1
	save_dock()
	clear_drag()
	result_time = 0.0
	mode = "win" if won else "loss"
	play_sound(2 if won else 3)

func kick_impact(amount: float) -> void:
	if not reduced_fx:
		impact_shake = maxf(impact_shake, amount)

func play_impact(index: int, pitch: float = 1.0) -> void:
	sound.play_cue(["hit", "blast", "surge"][index - 4], pitch)

func play_sound(index: int) -> void:
	sound.play_cue(["hit", "motion", "ui", "alert"][index])

func _draw() -> void:
	if battle_layout == null:
		return
	interface_press = menu_press_point
	interface_pressure = 0.0
	if menu_press_page == mode:
		interface_pressure = 1.0 if menu_pointer != NO_POINTER else menu_feedback / 0.14
	draw_rect(layout_canvas, INK)
	if mode == "home" or (mode == "settings" and settings_return == "home"):
		place_interface(menu_origin())
		draw_home()
		if mode == "settings":
			draw_audio_settings()
		return
	if mode == "dock":
		place_interface(menu_origin())
		draw_dock()
		return
	var boss_hp := -1.0
	for enemy in enemies:
		if enemy.kind == 3:
			boss_hp = float(enemy.hp) / enemy.max_hp
	var world := battle_layout.world
	draw_set_transform_matrix(world)
	draw_arena(clock, sector)
	draw_course()
	if impact_shake > 0 and not reduced_fx:
		world.origin += world.basis_xform(Vector2(roundf(sin(clock * 73) * impact_shake),
			roundf(cos(clock * 58) * impact_shake * 0.48)))
	var sprite_scale := Vector2.ONE * world.x.x
	for item in pickups:
		var point: Vector2 = item.pos
		draw_at_world_point(point, world, sprite_scale)
		draw_rect(Rect2(point - Vector2(7, 7), Vector2(14, 14)), Color(MINT, 0.09))
		pixel_sprite("scrap", item.pos, 2)
		if not reduced_fx and fposmod(item.age, 0.9) < 0.27:
			draw_flare(point + Vector2(7, -6), Vector2.UP, 4.0, Color(CREAM, 0.62))
	for enemy in enemies:
		draw_at_world_point(enemy.pos, world, sprite_scale)
		draw_enemy(enemy, sector, clock)
		if enemy.kind == 3 and enemy.pos.y > 220 and boss_clock < 0.31:
			var charge := clampf(1 - boss_clock / 0.31, 0, 1)
			draw_leader_warning(enemy.pos, pilot, charge)
	draw_set_transform_matrix(world)
	for ball in balls:
		var color: Color = PEACH if ball.kind < 0 else CHOICES[ball.kind][2]
		if ball.returning:
			color = color.lerp(MIST, 0.6)
		draw_shot(ball, color, world)
	for hazard in hazards:
		draw_orb(hazard.pos, hazard.vel, CORAL, true)
	for effect in effects:
		if effect.kind == "wake" and not reduced_fx:
			var image_fade := 1.0 - float(effect.age) / float(effect.duration)
			draw_at_world_point(effect.pos, world, sprite_scale)
			pixel_sprite("pilot" if pilot_type == 0 else "swift", effect.pos, 3, Color(SKY, 0.35 * image_fade))
			draw_set_transform_matrix(world)
		draw_combat_effect(effect)
	draw_at_world_point(pilot, world, sprite_scale)
	draw_pilot(pilot, pilot_type, movement, armor_time, clock, ship_fittings(true))
	if muzzle_time > 0:
		var muzzle := (pilot + shot_heading * (18 + (0.1 - muzzle_time) * 92)).snapped(Vector2(2, 2))
		var size := Vector2.ONE * (3 + muzzle_time * 55)
		draw_at_world_point(muzzle, world, sprite_scale)
		draw_rect(Rect2(muzzle - size / 2, size), Color(GOLD, muzzle_time / 0.105))
	draw_set_transform(Vector2.ZERO)
	draw_damage_labels(world)
	mask_arena()
	draw_battle_hud(boss_hp)
	draw_battle_controls()
	if mode == "level":
		draw_choices()
	elif mode == "pause":
		draw_pause()
	elif mode == "settings":
		draw_audio_settings()
	elif mode in ["win", "loss"]:
		draw_results()

func draw_at_world_point(point: Vector2, world: Transform2D, scale: Vector2) -> void:
	draw_set_transform(world * point - point * scale, 0, scale)

func mask_arena() -> void:
	var edge := battle_layout.arena
	# Clip world painting before drawing the HUD, including shake and particles at the rails.
	draw_rect(Rect2(0, 0, layout_canvas.size.x, edge.position.y), INK)
	draw_rect(Rect2(0, edge.end.y, layout_canvas.size.x, layout_canvas.end.y - edge.end.y), INK)
	draw_rect(Rect2(0, edge.position.y, edge.position.x, edge.size.y), INK)
	draw_rect(Rect2(edge.end.x, edge.position.y, layout_canvas.end.x - edge.end.x, edge.size.y), INK)
	draw_rect(edge.grow(2), STEEL, false, 2)

func draw_battle_hud(boss_hp: float) -> void:
	var hud := battle_layout.hud
	var origin := hud.position
	words(SEA_NAMES[sector], origin + Vector2(0, 25), 25)
	var searching := score_scene() == AudioDirector.Scene.SEARCH
	var phase := "巡航搜索" if searching else "第 %d/%d 波" % [wave, WAVES.size()]
	if boss_hp >= 0:
		phase = ("断链巨鳐" if sector == 0 else "沉舰看守") if wave_banner > 0 else "首领战"
	words(phase, origin + Vector2(1, 49), 15, SKY if searching else GOLD)
	words("%02d:%02d" % [floori(elapsed / 60.0), floori(fmod(elapsed, 60.0))],
		origin + Vector2(hud.size.x * 0.5, 30), 23, CREAM, true)
	if not boss_spawned:
		var seconds := maxi(0, ceili(next_wave_at() - elapsed))
		var countdown := "下波 %d · %02d秒" % [wave + 1, seconds] if wave < WAVES.size() else "首领 · %02d秒" % seconds
		words(countdown, origin + Vector2(hud.size.x * 0.5, 51), 13, GOLD if seconds <= 3 else MIST, true)
	var pause := battle_layout.controls[BattleLayout.Action.PAUSE]
	var pressed := control_is_pressed(BattleLayout.Action.PAUSE)
	pause = press_tile(pause, PANEL, STEEL, float(pressed))
	for offset in [-7, 3]:
		draw_rect(Rect2(pause.get_center() + Vector2(offset, -9), Vector2(4, 18)), CREAM)
	var rank := battle_layout.controls[BattleLayout.Action.UPGRADE]
	var health := Rect2(Vector2(origin.x, rank.position.y), Vector2(rank.position.x - origin.x - 15, rank.size.y))
	tile(health, PANEL, STEEL)
	words("船体 %d/%d" % [maxi(0, hp), max_hp], health.position + Vector2(10, 22), 17, CREAM)
	gauge(Rect2(health.position + Vector2(10, 31), Vector2(health.size.x - 20, 5)), float(hp) / max_hp, CORAL)
	draw_upgrade_control(rank)
	if boss_hp >= 0:
		gauge(Rect2(origin + Vector2(0, 111), Vector2(hud.size.x, 5)), boss_hp, GOLD)
	else:
		draw_rect(Rect2(origin + Vector2(0, 112), Vector2(hud.size.x, 1)), STEEL)
	draw_combo(hud, pause.position.x)

func draw_upgrade_control(rank: Rect2) -> void:
	var ready := upgrade_points > 0
	var held := control_is_pressed(BattleLayout.Action.UPGRADE)
	var face := press_tile(rank, PANEL.lerp(MINT, 0.13) if ready else PANEL, MINT if ready else STEEL, float(held))
	words("强化等级", face.position + Vector2(9, 23), 13, CREAM if ready else MIST)
	draw_level_stars(face.position + Vector2(67, 18), level, 6, 3.1, 8)
	gauge(Rect2(face.position + Vector2(9, 32), Vector2(face.size.x - 18, 4)), float(xp) / xp_needed(), MINT)
	if ready:
		var dot := battle_layout.upgrade_badge + face.position - rank.position
		draw_circle(dot + Vector2(0, 2), 13, Color("#080a15"), true, -1, true)
		draw_circle(dot, 12, Color("#cf293e"), true, -1, true)
		words(str(upgrade_points), dot + Vector2(0, 5), 14, Color.WHITE, true)

func draw_level_stars(origin: Vector2, count: int, columns: int, radius: float, spacing: float) -> void:
	var rows := ceili(float(count) / columns)
	var step := minf(spacing, 26.0 / maxi(1, rows))
	for index in range(count):
		var row := floori(float(index) / columns)
		var center := origin + Vector2((index % columns) * spacing, (row - (rows - 1) * 0.5) * step)
		var vertices := PackedVector2Array()
		for tip in range(10):
			var length := minf(radius, step * 0.48) * (1.0 if tip % 2 == 0 else 0.46)
			vertices.append(center + Vector2.from_angle(tip * PI / 5 - PI * 0.5) * length)
		draw_colored_polygon(vertices, Color(GOLD, interface_opacity))

func draw_combo(hud: Rect2, right: float) -> void:
	if combo_hits < 2 or combo_time <= 0:
		return
	var age := CHAIN_WINDOW - combo_time
	var opacity := clampf(1.0 - (age - 0.26) / 0.66, 0, 1)
	if opacity <= 0:
		return
	var accent := combo_emphasis > 0
	var color := Color(GOLD if accent else MINT, opacity)
	var center := Vector2(right - 52, hud.position.y + 49 - minf(7, age * 12))
	if accent:
		draw_rect(Rect2(center + Vector2(-45, -12), Vector2(4, 4)), color)
		draw_rect(Rect2(center + Vector2(41, -12), Vector2(4, 4)), color)
	words("%d 连击" % combo_hits, center, 20 if accent else 17, color, true)

func draw_course() -> void:
	for lane in range(7):
		var x := 90 + lane * 50
		for row in range(9):
			draw_rect(Rect2(x, 160 + row * 56, 2, 13), Color(MIST, 0.12))
	if sector == 1:
		var direction := 1 if floori(elapsed / 12.0) % 2 == 0 else -1
		draw_rect(Rect2(25, 288, 430, 147), Color(LILAC, 0.09))
		for i in range(8):
			var x := 43 + fposmod(i * 59 + elapsed * 28 * direction, 394)
			var tip := Vector2(x, 311 + i % 3 * 47)
			draw_polyline(PackedVector2Array([tip + Vector2(-8 * direction, -7), tip,
				tip + Vector2(-8 * direction, 7)]), Color(LILAC, 0.31), 2)
	if aim_point != Vector2.ZERO:
		var aim := target_nearest()
		for i in range(1, 20):
			var mark := pilot + aim * i * 22
			var left := ARENA.position.x + 5
			var right := ARENA.end.x - 5
			mark.x = left + (right - left) - absf(fposmod(mark.x - left, 2 * (right - left)) - (right - left))
			if mark.y < ARENA.position.y:
				break
			draw_rect(Rect2(mark - Vector2(2, 2), Vector2(4, 4)), Color(GOLD, 0.42))
		draw_rect(Rect2(aim_point - Vector2(9, 9), Vector2(18, 18)), GOLD, false, 2)
	if elapsed < SEARCH_INTRO:
		var scan := elapsed / SEARCH_INTRO
		draw_polyline(pixel_ring(pilot, 22 + scan * 101, 12), Color(SKY, 0.33 * (1 - scan)), 2)

func control_is_pressed(control: int) -> bool:
	for pending in control_presses.values():
		if pending.control == control:
			return true
	return false

func draw_battle_controls() -> void:
	var recall_ready := recall_time <= 0 and not balls.is_empty()
	var recall_status := "%.1f 秒" % recall_time if recall_time > 0 else ("可用" if recall_ready else "等待出球")
	var dash_status := "%d/%d" % [charges, max_charges]
	if charges == 0:
		dash_status += "  %.1f 秒" % (4.5 - recharge)
	draw_skill(BattleLayout.Action.AIM, "辅助瞄准", "自动瞄准" if aim_point == Vector2.ZERO else "恢复自动",
		GOLD if aim_point != Vector2.ZERO else SKY, true)
	draw_skill(BattleLayout.Action.RECALL, "召回", recall_status, SKY, recall_ready)
	draw_skill(BattleLayout.Action.DASH, "闪避", dash_status, MINT, charges > 0 and dash_time <= 0)
	var dash_rect := battle_layout.controls[BattleLayout.Action.DASH]
	if charges < max_charges:
		gauge(Rect2(dash_rect.position + Vector2(10, 59), Vector2(dash_rect.size.x - 20, 3)), recharge / 4.5, GOLD)
	draw_ball_status()

func draw_skill(control: int, title: String, status: String, accent: Color, available: bool) -> void:
	var rect := battle_layout.controls[control]
	var pressed := control_is_pressed(control)
	var feedback: float = 0.7 if pressed else control_feedback[control] * 3
	var fill := PANEL.lerp(accent, 0.19 if available else 0.02)
	var face := press_tile(rect, fill, accent if available else STEEL, feedback)
	var icons := ["crosshair", "recall", "dash"]
	pixel_sprite(icons[control], face.get_center() + Vector2(-face.size.x * 0.33, -9), 2, accent)
	words(title, face.get_center() + Vector2(8, -5), 18, CREAM, true)
	words(status, face.get_center() + Vector2(0, 17), 14, accent if available else MIST, true)

func draw_ball_status() -> void:
	tile(battle_layout.ball_bar, PANEL, STEEL)
	var counts := {}
	for ball in balls:
		counts[ball.kind] = counts.get(ball.kind, 0) + 1
	var equipped: Array[int] = []
	for kind in range(modules.size()):
		if modules[kind] > 0:
			equipped.append(kind)
	draw_ball_slot(0, "主球", "%d/%d" % [core_capacity - int(counts.get(-1, 0)), core_capacity],
		GOLD if surge_ready else PEACH)
	for slot in range(1, BALL_SLOTS + 1):
		if slot <= equipped.size():
			var kind := equipped[slot - 1]
			draw_ball_slot(slot, CHOICES[kind][0], "×%d" % counts.get(kind, 0), CHOICES[kind][2], modules[kind])
		else:
			draw_ball_slot(slot, "空槽", "—", MIST)

func draw_ball_slot(index: int, label: String, quantity: String, color: Color, stars := 0) -> void:
	var slot := battle_layout.ball_slot(index)
	if index > 0:
		draw_rect(Rect2(slot.position + Vector2(0, 7), Vector2(1, slot.size.y - 14)), STEEL)
	var width := art_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var left := slot.get_center().x - (width + 13) * 0.5
	var icon := Vector2(left + 4, slot.position.y + 15).round()
	draw_rect(Rect2(icon - Vector2(4, 2), Vector2(8, 4)), color)
	draw_rect(Rect2(icon - Vector2(2, 4), Vector2(4, 8)), color)
	draw_rect(Rect2(icon - Vector2(1, 2), Vector2(2, 2)), CREAM)
	words(label, Vector2(left + 13, slot.position.y + 20), 14, CREAM)
	words(quantity, slot.get_center() + Vector2(20 if stars > 0 else 0, 15), 13, color, true)
	if stars > 0:
		draw_level_stars(slot.get_center() + Vector2(-21, 10), stars, 3, 3.7, 9)

func harvest_rect(resource: int) -> Rect2:
	return Rect2(36 + resource * 210, 267, 198, 110)

func facility_rect(index: int) -> Rect2:
	return Rect2(36 + index % 2 * 210, 455 + floori(index / 2.0) * 101, 198, 86)

func ship_option_rect(index: int) -> Rect2:
	return Rect2(61, 431 + index * 88 + ship_drawer_offset(), 358, 74)

func ship_drawer_offset() -> float:
	return roundf(64 * (1.0 - smoothstep(0, 1, ship_slide)))

func ship_fittings(in_battle: bool) -> Vector3i:
	var spent := level - 1 - upgrade_points if in_battle else 0
	var color_tier := maxi(maxi(buildings[0], buildings[1]), maxi(buildings[2], mini(3, spent)))
	var armor := int(buildings[0] > 0 or spent >= 2)
	var guns := int(buildings[1] > 0 or spent > 0)
	var engines := int(buildings[2] > 0 or spent >= 3)
	return Vector3i(color_tier, armor, guns | (engines << 1))

func choice_rect(index: int) -> Rect2:
	return Rect2(battle_layout.dialog_origin + Vector2(40, 319 + index * 103), Vector2(400, 91))

func draw_home() -> void:
	draw_chart(sector, wins > 0)
	draw_dock_resource(Rect2(36, 57, 161, 51), "iron", "铁料", metal, GOLD)
	draw_dock_resource(Rect2(206, 57, 161, 51), "salt", "晶盐", salt, SKY)
	var settings_face := press_tile(HOME_SETTINGS, PANEL, STEEL)
	pixel_sprite("gear", settings_face.get_center(), 3, CREAM)
	words("航海图", Vector2(36, 148), 25, CREAM)
	words("拖动海图 · 点选海域", Vector2(157, 147), 15, MIST)
	var center_face := press_tile(HOME_RECENTER, PANEL, STEEL)
	pixel_sprite("crosshair", center_face.get_center(), 3, SKY)
	words(SEA_NAMES[sector], Vector2(37, 624), 20, MINT if sector == 0 else LILAC)
	if clock < chart_notice_time:
		words("通关盐雾海沟后解锁", Vector2(246, 624), 14, GOLD)
	else:
		words("断链巨鳐" if sector == 0 else "沉舰看守", Vector2(361, 624), 14, MIST, true)
	var port_face := press_tile(HOME_PORT, PANEL, STEEL)
	pixel_sprite("building0" if dock_port == 0 else "beacon", port_face.position + Vector2(26, 33), 2)
	words(PORT_NAMES[dock_port], port_face.position + Vector2(51, 29), 16, CREAM)
	words("可打捞 %d 次" % sweeps, port_face.position + Vector2(51, 49), 13, MINT)
	var ship_face := press_tile(HOME_SHIP, PANEL, MINT if ship_drawer else STEEL)
	draw_ship(ship_face.position + Vector2(31, 32), pilot_type, 2, ship_fittings(false))
	words("巡潮艇" if pilot_type == 0 else "疾燕", ship_face.position + Vector2(62, 28), 18, CREAM)
	words("选择舰艇", ship_face.position + Vector2(62, 49), 13, MIST)
	pixel_sprite("arrow", ship_face.position + Vector2(200, 32), 2, MINT)
	button(LAUNCH, "出航", MINT)
	if ship_slide > 0:
		draw_ship_drawer()

func draw_ship_drawer() -> void:
	var rise := Vector2(0, ship_drawer_offset())
	draw_rect(Rect2(0, 177, 480, 475), Color(INK, 0.76 * ship_slide))
	interface_opacity = ship_slide
	tile(Rect2(Vector2(45, 353) + rise, Vector2(390, 286)), PANEL, STEEL)
	words("选择舰艇", Vector2(65, 397) + rise, 25, CREAM)
	for index in range(2):
		var unlocked := index == 0 or buildings[2] > 0
		var accent := MINT if index == pilot_type else (SKY if unlocked else STEEL)
		var face := press_tile(ship_option_rect(index), PANEL if index == pilot_type else INK, accent)
		draw_ship(face.position + Vector2(43, 31), index, 4, ship_fittings(false), not unlocked)
		words("巡潮艇" if index == 0 else "疾燕", face.position + Vector2(92, 29), 19, CREAM)
		words(("船体耐久高" if index == 0 else "速度快 · 额外弹球") if unlocked else "推进站解锁",
			face.position + Vector2(93, 54), 14, MIST)
		if index == pilot_type:
			pixel_sprite("crosshair", face.position + Vector2(328, 37), 3, MINT)
	interface_opacity = 1.0

func draw_dock() -> void:
	draw_harbor(clock)
	var port_accent := MINT if dock_port == 0 else GOLD
	if dock_port == 1:
		draw_rect(Rect2(0, 0, 480, 187), Color(LILAC, 0.13))
	pixel_sprite("building0" if dock_port == 0 else "beacon", Vector2(406, 92), 5)
	words(PORT_NAMES[dock_port], Vector2(36, 103), 36, CREAM)
	draw_dock_resource(Rect2(36, 124, 198, 48), "iron", "铁料", metal, GOLD)
	draw_dock_resource(Rect2(246, 124, 198, 48), "salt", "晶盐", salt, SKY)
	words("货物打捞", Vector2(36, 239), 22, CREAM)
	words("剩余 %d/2" % sweeps, Vector2(367, 237), 15, port_accent)
	for resource in range(2):
		var cargo := best_harvest(resource)
		var color := GOLD if resource == 0 else SKY
		var available := cargo.x >= 0 and sweeps > 0
		var face := press_tile(harvest_rect(resource), PANEL if available else INK, color if available else STEEL)
		pixel_sprite("iron" if resource == 0 else "salt", face.position + Vector2(42, 42), 5)
		words("打捞铁料" if resource == 0 else "打捞晶盐", face.position + Vector2(82, 44), 17, CREAM)
		words("收取 +%d" % (cargo.z if resource == 0 else cargo.w) if available else "无可打捞",
			face.position + Vector2(82, 72), 15, color if available else MIST)
	words("设施地块", Vector2(36, 428), 22, CREAM)
	for kind in range(BUILDINGS.size()):
		draw_facility(kind)
	tile(Rect2(36, 676, 408, 52), PANEL, STEEL)
	words(dock_note, Vector2(49, 706), 14, CREAM)
	button(DOCK_EXIT, "返回航海图", MINT)

func draw_facility(kind: int) -> void:
	var rank := buildings[kind]
	var color: Color = BUILDINGS[kind][2]
	var rect := press_tile(facility_rect(kind), PANEL, color.darkened(0.33))
	pixel_sprite("building%d" % kind, rect.position + Vector2(31, 33), 4)
	words(BUILDINGS[kind][0], rect.position + Vector2(65, 29), 17, color)
	words(BUILDINGS[kind][1], rect.position + Vector2(65, 52), 13, MIST)
	if rank > 0:
		draw_level_stars(rect.position + Vector2(153, 25), rank, 3, 4.3, 10)
	words("满级" if rank >= 3 else ("建造" if rank == 0 else "升级"), rect.position + Vector2(17, 74), 13, CREAM)
	if rank < 3:
		pixel_sprite("iron", rect.position + Vector2(102, 69), 1)
		words(str(price(kind)), rect.position + Vector2(114, 74), 14, GOLD)
		if kind == 3 or rank == 2:
			pixel_sprite("salt", rect.position + Vector2(154, 69), 1)
			words("1", rect.position + Vector2(164, 74), 14, SKY)

func draw_dock_resource(rect: Rect2, sprite: String, title: String, count: int, color: Color) -> void:
	tile(rect, INK, color.darkened(0.35))
	var center_y := rect.get_center().y
	pixel_sprite(sprite, Vector2(rect.position.x + 27, center_y), 3)
	words(title, Vector2(rect.position.x + 56, center_y + 6), 17, CREAM)
	words(str(count), Vector2(rect.end.x - 29, center_y + 7), 21, color, true)

func draw_choices() -> void:
	shade()
	var offset := battle_layout.dialog_origin
	place_interface(offset)
	tile(Rect2(24, 202, 432, 501), PANEL, STEEL)
	words("强化等级", Vector2(240, 250), 34, CREAM, true)
	words("剩余升级点 %d" % upgrade_points, Vector2(240, 278), 16, GOLD, true)
	words("弹球槽 %d/%d · 基础球升到二级可融合" %
		[modules.size() - modules.count(0), BALL_SLOTS], Vector2(240, 301), 14, MIST, true)
	for i in range(options.size()):
		var index := options[i]
		var choice: Array = CHOICES[index]
		var rect := choice_rect(i)
		rect.position -= offset
		var selected := index == selected_upgrade
		rect = press_tile(rect, PANEL.lerp(choice[2], 0.11) if selected else INK,
			choice[2] if selected else choice[2].darkened(0.38))
		if selected:
			pixel_sprite("crosshair", rect.end - Vector2(25, 28), 2, choice[2])
		pixel_sprite("scrap", rect.position + Vector2(31, 44), 4, choice[2])
		var title: String = choice[0]
		if index >= BASE_BALLS and index < modules.size() and modules[index] == 0:
			title += "  ·  融合"
		words(title, rect.position + Vector2(64, 34), 23, choice[2])
		if index < modules.size() and (index < BASE_BALLS or modules[index] > 0):
			var title_width := art_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
			draw_level_stars(rect.position + Vector2(78 + title_width, 26), modules[index] + 1, 3, 5.8, 13)
		words(choice[1], rect.position + Vector2(65, 65), 16, CREAM)
	var back := press_tile(UPGRADE_CLOSE, PANEL, STEEL)
	words("继续航行", back.get_center() + Vector2(0, 6), 18, CREAM, true)
	if selected_upgrade >= 0:
		button(UPGRADE_CONFIRM, "升级 · 1点", MINT)
	else:
		press_tile(UPGRADE_CONFIRM, INK, STEEL, 0.0)
		words("选择一张卡", UPGRADE_CONFIRM.get_center() + Vector2(0, 6), 17, MIST, true)

func draw_pause() -> void:
	shade()
	place_interface(battle_layout.dialog_origin)
	tile(Rect2(29, 260, 422, 334), PANEL, STEEL)
	words("已暂停", Vector2(240, 326), 38, CREAM, true)
	button(PAUSE_BUTTONS[0], "继续航行", MINT)
	var settings_face := press_tile(PAUSE_BUTTONS[1], INK, STEEL)
	words("设置", settings_face.get_center() + Vector2(0, 7), 21, CREAM, true)
	var port_face := press_tile(PAUSE_BUTTONS[2], INK, STEEL)
	words("返回港口", port_face.get_center() + Vector2(0, 7), 21, LILAC, true)

func draw_audio_settings() -> void:
	shade()
	place_interface(settings_origin())
	tile(Rect2(29, 224, 422, 414), PANEL, STEEL)
	words("设置", Vector2(240, 278), 32, CREAM, true)
	for i in range(2):
		var rect := settings_level_rect(i)
		var level: float = sound.music_level if i == 0 else sound.effects_level
		var color := SKY if i == 0 else MINT
		words("音乐" if i == 0 else "音效", rect.position + Vector2(0, -5), 18, CREAM)
		words("%d%%" % roundi(level * 100), Vector2(rect.end.x - 26, rect.position.y - 5), 15, color, true)
		rect = press_tile(rect, INK, STEEL, float(audio_drag == i))
		gauge(Rect2(rect.position + Vector2(9, 20), Vector2(rect.size.x - 18, 11)), level, color)
		var knob := Vector2(lerpf(rect.position.x + 8, rect.end.x - 8, level), rect.get_center().y)
		draw_rect(Rect2(knob - Vector2(4, 10), Vector2(8, 20)), color)
	var motion_face := press_tile(MOTION_OPTION, INK, STEEL)
	words("特效强度  ·  %s" % ("柔和" if reduced_fx else "完整"),
		motion_face.get_center() + Vector2(0, 6), 19, CREAM, true)
	button(AUDIO_DONE, "完成", MINT)

func draw_results() -> void:
	shade(0.83 * smoothstep(0.0, 0.40, result_time))
	var reveal := smoothstep(RESULT_REVEAL_START, RESULT_REVEAL_END, result_time)
	if reveal <= 0:
		return
	var rise := 0.0 if reduced_fx else 12 * (1.0 - reveal)
	place_interface(battle_layout.dialog_origin + Vector2(0, rise))
	interface_opacity = reveal
	tile(Rect2(29, 228, 422, 399), PANEL, STEEL)
	pixel_sprite("scrap", Vector2(240, 285), 5, GOLD)
	words("海域已守住" if mode == "win" else "船体失守", Vector2(240, 353), 38, CREAM, true)
	words("获得资源", Vector2(240, 393), 17, MIST, true)
	draw_dock_resource(Rect2(47, 411, 184, 61), "iron", "铁料", last_reward, GOLD)
	draw_dock_resource(Rect2(249, 411, 184, 61), "salt", "晶盐", last_salt_reward, SKY)
	words("击破 %d" % kills, Vector2(138, 509), 17, CREAM, true)
	words("最高连击 %d" % best_combo, Vector2(340, 509), 17, MINT, true)
	button(RESULT_DONE, "返回港口", MINT)
	interface_opacity = 1.0
