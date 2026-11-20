extends "res://scripts/visuals/chart_art.gd"

const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const BattleLayout = preload("res://scripts/ui/battle_layout.gd")
const MetaProgress = preload("res://scripts/game/meta_progress.gd")
const SAVE = "user://dock.cfg"
const LAUNCH = Rect2(60, 580, 360, 84)
const PAUSE_BUTTONS = [Rect2(47, 362, 386, 62), Rect2(47, 437, 386, 62), Rect2(47, 512, 386, 62)]
const MOTION_OPTION = Rect2(49, 492, 382, 54)
const RESULT_DONE = Rect2(47, 668, 386, 52)
const RESULT_AGAIN := Rect2(47, 590, 386, 66)
const OPEN_CHEST := Rect2(103, 459, 274, 54)
const RESULT_REVEAL_START := 0.19
const RESULT_REVEAL_END := 0.62
const HOME_SETTINGS = Rect2(424, 14, 44, 44)
const HOME_SHIP := Rect2(140, 290, 200, 190)
const HOME_STAGE := Rect2(90, 518, 300, 42)
const HOME_PERKS := Rect2(412, 76, 56, 56)
const HOME_OFFLINE := Rect2(12, 142, 196, 44)
const TAB_TOP := 790.0
const TAB_NAMES := ["港口", "舰队", "出航", "福利", "设置"]
const PERKS_SIGN := Rect2(60, 332, 360, 54)
const PERKS_CLOSE := Rect2(60, 712, 360, 56)
# Pages drawn on the menu canvas rather than over the battle.
const MENU_PAGES := ["home", "dock", "perks"]
const AUDIO_DONE = Rect2(49, 561, 382, 56)
const DRAG_THRESHOLD := 12.0
# Dash is earned: it unlocks at this run level and is triggered by a double tap.
const DASH_UNLOCK_LEVEL := 3
const DOUBLE_TAP_GAP := 0.32
const TAP_MAX_TIME := 0.26
const TAP_MAX_TRAVEL := 18.0
const NO_POINTER := -2
const ANDROID_GESTURE_MARGIN := 36.0
const CHAIN_WINDOW = 1.45
const SURGE_HITS = 8
const SEARCH_INTRO := 0.6
const COMBAT_TAIL := 2.0
const BATCH_SIZE := 4
const BATCH_INTERVAL := 1.3
const ELITE_ARRIVAL := 52.0
const BOSS_ARRIVAL := 118.0
const BOSS_HEALTH := 900
# Small enemies trickle in between waves so the screen is never empty.
const SWARM_INTERVAL := 1.6
const MAX_ENEMIES := 32
# Battle speed while the upgrade cards are open.
const LEVEL_SLOWMO := 0.2
const ENTRY_SPEED := 128.0
const SHIP_RADIUS := 13.0
const RAM_DAMAGE := 12
const VICTORY_SLOWMO := 1.1
const SLOWMO_RATE := 0.3
const SCRAP_CHIME_GAP := 0.5
const WAVES = [
	[SEARCH_INTRO, "oo.oo.oo", "..o..o.."],
	[8.0, "o.oooo.o", ".o.rr.o."],
	[17.0, "..s..s..", "oroooro.", ".oo..oo."],
	[28.0, "o.roor.o", ".s....s.", "oo.oo.oo"],
	[40.0, "rr.ooos.", "oo.r..sr", "o.oo.oo."],
	[56.0, "s.oooo.s", ".ro..or.", "r.oss.or"],
	[74.0, "os.oo..s", "rr.oo.rr", "o.s..s.o"],
	[94.0, "sro..ors", "or.s..ro", "rooooo.r"],
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
var pilot := Vector2(240, 760)
var movement := Vector2.ZERO
var touch_vector := Vector2.ZERO
var touch_origin := Vector2.ZERO
var arena_pointer := NO_POINTER
var arena_down := Vector2.ZERO
var arena_dragged := false
var control_presses := {}
# Short presses anywhere in the arena, by pointer, to detect double taps.
var tap_presses := {}
var last_tap_time := -9.0
var last_tap_point := Vector2.ZERO
var last_move_dir := Vector2.UP
var notice_text := ""
var notice_time := 0.0
var skills_seen := {}
var notice_color := GOLD
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
var result_time := 0.0
var victory_time := 0.0
var swarm_clock := 0.0
var scrap_streak := 0
var scrap_chime_time := 0.0
var enemies: Array[Dictionary] = []
var balls: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var sound := AudioDirector.new()
var meta := MetaProgress.new()
var chest_tier := 0
var chest_metal := 0
var chest_salt := 0
var chest_open_time := -1.0
var first_win_bonus := false
var boss_left := -1.0
var seconds_to_boss := 0.0

func _ready() -> void:
	setup_art()
	rng.randomize()
	load_dock()
	meta.roll_day()
	meta.accrue_offline(offline_rate())
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
	ARENA.size.y = battle_layout.world_height
	clear_drag()

func menu_origin() -> Vector2:
	return (layout_canvas.get_center() - BattleLayout.DESIGN_SIZE * 0.5).floor()

# Menu pages use the 480x854 design frame. On taller screens the top bar is pinned to the
# top edge and the tab bar to the bottom edge; these are their offsets from the centred frame.
func menu_shift_top() -> float:
	return minf(0.0, ceilf(layout_safe.position.y) - menu_origin().y)

func menu_shift_bottom() -> float:
	return maxf(0.0, floorf(layout_safe.end.y) - BattleLayout.DESIGN_SIZE.y - menu_origin().y)

# Ship movement zone: the lower part of the sea, whatever its height.
func pilot_area() -> Rect2:
	return Rect2(40, ARENA.end.y - 402, 400, 372)

func settings_origin() -> Vector2:
	return menu_origin() if settings_return in MENU_PAGES else battle_layout.dialog_origin

func load_dock() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE) != OK:
		return
	meta.load_from(config)
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
	meta.last_seen = MetaProgress.now()
	meta.save_to(config)
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
	pilot = Vector2(240, ARENA.end.y - 112)
	max_hp = 100 + 15 * buildings[0] - 15 * pilot_type
	hp = max_hp
	xp = 0
	level = 1
	upgrade_points = 0
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
	victory_time = 0.0
	swarm_clock = 2.5
	scrap_streak = 0
	scrap_chime_time = 0.0
	last_tap_time = -9.0
	notice_text = ""
	notice_time = 0.0
	skills_seen.clear()
	reset_fx()
	clear_drag()
	mode = "fight"
	sound.play_cue("departure")

func clear_drag() -> void:
	arena_pointer = NO_POINTER
	arena_dragged = false
	control_presses.clear()
	tap_presses.clear()
	menu_pointer = NO_POINTER
	chart_dragging = false
	menu_feedback = 0.0
	touch_vector = Vector2.ZERO
	movement = Vector2.ZERO

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		save_dock()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		meta.accrue_offline(offline_rate())
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode in ["fight", "level"]:
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
					dash()
			KEY_R:
				if mode == "fight":
					activate_control(BattleLayout.Action.RECALL)
			KEY_ESCAPE:
				if mode == "settings":
					mode = settings_return
				elif mode in ["dock", "perks"]:
					mode = "home"
				elif mode == "home" and ship_drawer:
					ship_drawer = false
				elif mode != "level":
					toggle_pause()
			KEY_1, KEY_2, KEY_3:
				var pick: int = event.keycode - KEY_1
				if mode == "level" and pick < options.size():
					choose(options[pick])
			KEY_ENTER:
				if mode == "home":
					start_run()
				elif mode in ["win", "loss"]:
					if chest_open_time < 0:
						press_results(Vector2.ZERO)
					elif result_time - chest_open_time >= 0.4:
						start_run()

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
		if event.position.distance_to(menu_press_point) >= DRAG_THRESHOLD:
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
		return
	if point.y <= battle_layout.hud.end.y:
		return
	# Second quick tap: dash toward where it landed (or the way the ship was heading).
	if clock - last_tap_time < DOUBLE_TAP_GAP and point.distance_to(last_tap_point) < 120:
		last_tap_time = -9.0
		dash(battle_layout.inverse_world * point)
	else:
		tap_presses[pointer] = {"time": clock, "origin": point}
	if arena_pointer == NO_POINTER:
		arena_pointer = pointer
		arena_down = point
		touch_origin = battle_layout.inverse_world * point

func move_battle_press(pointer: int, point: Vector2) -> void:
	if tap_presses.has(pointer) and point.distance_to(tap_presses[pointer].origin) > TAP_MAX_TRAVEL:
		tap_presses.erase(pointer)
	if pointer == arena_pointer:
		if arena_dragged or point.distance_to(arena_down) >= DRAG_THRESHOLD:
			arena_dragged = true
			read_drag(battle_layout.inverse_world * point)
	elif control_presses.has(pointer):
		var pending: Dictionary = control_presses[pointer]
		if point.distance_to(pending.origin) >= DRAG_THRESHOLD or not battle_layout.control_contains(pending.control, point):
			control_presses.erase(pointer)

func end_battle_press(pointer: int, point: Vector2, canceled := false) -> void:
	if tap_presses.has(pointer):
		var tap: Dictionary = tap_presses[pointer]
		tap_presses.erase(pointer)
		if not canceled and clock - float(tap.time) < TAP_MAX_TIME and point.distance_to(tap.origin) <= TAP_MAX_TRAVEL:
			last_tap_time = clock
			last_tap_point = point
	if pointer == arena_pointer:
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
	if mode in MENU_PAGES:
		point -= menu_origin()
	match mode:
		"home":
			press_home(point)
		"dock":
			var tab := tab_at(point)
			if tab >= 0:
				activate_tab(tab)
			else:
				var high := point - Vector2(0, menu_shift_top())
				for resource in range(2):
					if harvest_rect(resource).has_point(high):
						harvest(resource)
				for kind in range(BUILDINGS.size()):
					if facility_rect(kind).has_point(high):
						improve_facility(kind)
		"level":
			for i in range(options.size()):
				if choice_rect(i).has_point(point):
					choose(options[i])
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
		"perks":
			press_perks(point)
		"win", "loss":
			press_results(point)
	return true

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

func dash_unlocked() -> bool:
	return level >= DASH_UNLOCK_LEVEL

func dash(toward := Vector2.INF) -> void:
	if mode != "fight" or not dash_unlocked() or charges == 0 or dash_time > 0:
		return
	if movement.length() > 0.1:
		dash_direction = movement.normalized()
	elif toward != Vector2.INF and pilot.distance_to(toward) > 24:
		dash_direction = pilot.direction_to(toward)
	else:
		dash_direction = last_move_dir
	dash_time = 0.17
	armor_time = maxf(armor_time, 0.4)
	charges -= 1
	emit_fx("wake", pilot, SKY, 0.28, 27, -dash_direction)
	play_sound(1)
	buzz(18)

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
	var fx_rate := 1.0
	if mode == "fight" and victory_time > 0:
		fx_rate = SLOWMO_RATE
	elif mode == "fight" and hitstop > 0:
		fx_rate = 0.15
	elif mode == "level":
		fx_rate = LEVEL_SLOWMO
	if mode in ["fight", "level", "win", "loss"]:
		tick_fx(delta * fx_rate)
	if mode == "level":
		tick_battle(delta * LEVEL_SLOWMO)
	if mode in ["win", "loss"]:
		result_time += delta
	if mode == "fight" and victory_time > 0:
		victory_time -= delta
		update_balls(delta * SLOWMO_RATE)
		if victory_time <= 0:
			victory_time = 0.0
			finish(true)
	elif mode == "fight" and hitstop > 0:
		hitstop = maxf(0, hitstop - delta)
	elif mode == "fight":
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
	if mode in MENU_PAGES or (mode == "settings" and settings_return in MENU_PAGES):
		return AudioDirector.Scene.PORT
	if mode in ["win", "loss"]:
		return AudioDirector.Scene.SEARCH
	if boss_spawned:
		return AudioDirector.Scene.BOSS
	return AudioDirector.Scene.COMBAT

func tick_battle(delta: float) -> void:
	elapsed += delta
	combo_time = maxf(0, combo_time - delta)
	if combo_time <= 0:
		combo_hits = 0
	recall_time = maxf(0, recall_time - delta)
	wave_banner = maxf(0, wave_banner - delta)
	notice_time = maxf(0, notice_time - delta)
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
	if movement.length() > 0.2:
		last_move_dir = movement.normalized()
	var zone := pilot_area()
	pilot = (pilot + movement * speed * delta).clamp(zone.position, zone.end)
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
	if victory_time > 0:
		return
	shot_clock -= delta
	if shot_clock <= 0 and active_cores() < core_capacity and enemies.any(enemy_in_play):
		volley()
		shot_clock = maxf(0.32, 0.74 - haste * 0.07 - pilot_type * 0.08)
	update_balls(delta)
	if not battle_live():
		return
	update_pickups(delta)
	bank_upgrade_points()
	if upgrade_points > 0 and mode == "fight":
		open_level()

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
	if not boss_spawned:
		swarm_clock -= delta
		if swarm_clock <= 0:
			swarm_clock = SWARM_INTERVAL - minf(0.7, elapsed / 160.0)
			send_swarm()
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

func send_swarm() -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var x := rng.randf_range(70, 410)
	var kind := 1 if rng.randf() < 0.4 else 0
	for index in range(3):
		var destination := Vector2(clampf(x + (index - 1) * 34, 50, 430), 165 + rng.randf_range(0, 70))
		spawn_enemy(kind, Vector2(destination.x, ARENA.position.y - 24 - index * 16), destination)

func battle_live() -> bool:
	return mode in ["fight", "level"]

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
	var capacity: int = [9, 6, 24, BOSS_HEALTH, 150][kind]
	if kind < 3:
		capacity += maxi(wave - 1, 0)
	capacity = roundi(capacity * (1.0 + sector * 0.22))
	next_id += 1
	var skill := roll_skill(kind)
	enemies.append({"id": next_id, "kind": kind, "pos": position, "hp": capacity, "max_hp": capacity,
		"slow": 0.0, "phase": rng.randf_range(0, TAU), "flash": 0.0, "fired": false,
		"attack": 1.5, "recoil": Vector2.ZERO, "entry": entry, "skill": skill,
		"skill_clock": rng.randf_range(1.6, 3.0), "dodge_cd": 0.0, "dodge_vel": Vector2.ZERO})
	if skill != "" and not skills_seen.has(skill) and kind != 3:
		skills_seen[skill] = true
		if skill == "heal":
			notice("小心：绿十字敌人会给周围回血", MINT)
		elif skill == "dodge":
			notice("小心：蓝箭头敌人会闪避弹球", SKY)

# Tougher enemies learn tricks as the run goes on: healers patch up their pack,
# dodgers sidestep a ball every few seconds. The elite does both; the boss heals.
func roll_skill(kind: int) -> String:
	var threat := elapsed + sector * 25.0
	match kind:
		0:
			if threat > 45 and rng.randf() < 0.14:
				return "heal"
		1:
			if threat > 22 and rng.randf() < minf(0.45, 0.18 + threat / 300.0):
				return "dodge"
		2:
			if threat > 35 and rng.randf() < 0.4:
				return "heal"
		3:
			return "heal"
		4:
			return "both"
	return ""

func can_heal(enemy: Dictionary) -> bool:
	return enemy.skill == "heal" or enemy.skill == "both"

func can_dodge(enemy: Dictionary) -> bool:
	return (enemy.skill == "dodge" or enemy.skill == "both") and enemy.dodge_cd <= 0

func notice(text: String, color: Color) -> void:
	notice_text = text
	notice_time = 2.6
	notice_color = color

func heal_pulse(source: Dictionary) -> void:
	var boss: bool = source.kind == 3
	var reach := 0.0 if boss else 105.0
	var healed := false
	for ally in enemies:
		if ally.hp >= ally.max_hp or ally.hp <= 0 or ally.entry != Vector2.ZERO:
			continue
		if ally.id != source.id and (boss or source.pos.distance_squared_to(ally.pos) > reach * reach):
			continue
		var amount := maxi(2, roundi(ally.max_hp * (0.05 if ally.kind == 3 else 0.3)))
		ally.hp = mini(ally.max_hp, ally.hp + amount)
		tag_label(ally, "+%d" % amount, MINT)
		healed = true
	if healed:
		emit_fx("recall", source.pos, MINT, 0.5, reach if not boss else 80.0)
		sound.play_cue("heal")

func try_dodge(enemy: Dictionary, ball: Dictionary, direction: Vector2) -> bool:
	if not can_dodge(enemy) or ball.charged or rng.randf() > 0.6:
		return false
	enemy.dodge_cd = 2.0 if enemy.kind == 4 else 2.8
	var side := direction.orthogonal()
	if rng.randf() < 0.5:
		side = -side
	if enemy.pos.x + side.x * 45 < 50 or enemy.pos.x + side.x * 45 > 430:
		side = -side
	enemy.dodge_vel = side * 560
	ball.cooldown = 0.3
	ball.target = enemy.id
	emit_fx("hit", enemy.pos, SKY, 0.2, 30, -side)
	tag_label(enemy, "闪避", SKY)
	sound.play_cue("motion", 1.45)
	return true

func radius(kind: int) -> float:
	return [19.0, 15.0, 25.0, 44.0, 32.0][kind]

func update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		enemy.slow = maxf(0, enemy.slow - delta)
		enemy.flash = maxf(0, enemy.flash - delta)
		enemy.recoil = enemy.recoil.move_toward(Vector2.ZERO, 90 * delta)
		var slow_factor := 0.48 if enemy.slow > 0 else 1.0
		if enemy.entry != Vector2.ZERO:
			enemy.pos = enemy.pos.move_toward(enemy.entry, ENTRY_SPEED * delta * slow_factor)
			if enemy.pos == enemy.entry:
				enemy.entry = Vector2.ZERO
			continue
		var kind: int = enemy.kind
		enemy.dodge_cd = maxf(0, enemy.dodge_cd - delta)
		if enemy.dodge_vel != Vector2.ZERO:
			enemy.pos += enemy.dodge_vel * delta
			enemy.pos.x = clampf(enemy.pos.x, 42, 438)
			enemy.dodge_vel = enemy.dodge_vel.move_toward(Vector2.ZERO, 2600 * delta)
		if can_heal(enemy):
			enemy.skill_clock -= delta
			if enemy.skill_clock <= 0:
				enemy.skill_clock = 6.0 if kind == 3 else 3.4
				heal_pulse(enemy)
		if kind == 3:
			var dive_clock := fposmod(elapsed - BOSS_ARRIVAL, 18.0)
			var diving := dive_clock >= 5.0 and dive_clock < 12.0
			var patrol_y := maxf(345.0, pilot_area().position.y + 100) if diving else 345.0
			var speed := 42.0 if enemy.pos.y < 345.0 and not diving else 115.0
			enemy.pos.y = move_toward(enemy.pos.y, patrol_y, delta * speed * slow_factor)
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
		else:
			var drift := sin(elapsed * 2.4 + float(enemy.phase)) * (13 if kind == 1 else 0)
			var speed: float = [27.0, 40.0, 23.0][kind]
			enemy.pos.x = clampf(enemy.pos.x + drift * delta, 42, 438)
			enemy.pos.y += (speed + sector * 8) * delta * slow_factor
			if kind == 2 and enemy.pos.y > 365 and not enemy.fired:
				enemy.fired = true
				var direction: Vector2 = enemy.pos.direction_to(pilot)
				hazards.append({"pos": enemy.pos, "vel": direction * 195})
		var body_radius := radius(kind)
		if enemy.pos.y - body_radius > ARENA.end.y:
			enemies.remove_at(i)
			continue
		var contact_distance := body_radius + SHIP_RADIUS
		if armor_time <= 0 and pilot.distance_squared_to(enemy.pos) < contact_distance * contact_distance:
			collide_with_ship(enemy, contact_distance)
			if hp <= 0 or victory_time > 0:
				return

func collide_with_ship(enemy: Dictionary, contact_distance: float) -> void:
	var away := pilot.direction_to(enemy.pos)
	if away == Vector2.ZERO:
		away = Vector2.UP
	var impact := pilot + away * SHIP_RADIUS
	enemy.pos = pilot + away * (contact_distance + 4)
	enemy.pos.x = clampf(enemy.pos.x, 42, 438)
	emit_fx("hit", impact, PEACH, 0.22, 40, away)
	hurt(13 if enemy.kind == 1 else 20)
	damage_enemy(enemy, RAM_DAMAGE, PEACH)

func hurt(amount: int) -> void:
	if armor_time > 0:
		return
	hp = maxi(0, hp - amount)
	armor_time = 0.8
	emit_fx("break", pilot, CORAL, 0.32, 42)
	kick_impact(5.5)
	sound.play_cue("hurt")
	sound.play_cue("thump", 0.75)
	buzz(40)

func update_hazards(delta: float) -> void:
	for i in range(hazards.size() - 1, -1, -1):
		var shot := hazards[i]
		shot.pos += shot.vel * delta
		if not ARENA.has_point(shot.pos):
			hazards.remove_at(i)
		elif pilot.distance_squared_to(shot.pos) < 20.0 * 20.0:
			hurt(15)
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
		if not battle_live():
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
	if try_dodge(target, ball, direction):
		return
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
	if ball.charged:
		freeze_frame(0.045, elapsed)
	ball_hit(target, ball.kind, power, contact_point, direction, bonus)

func ball_hit(enemy: Dictionary, kind: int, power: int, contact: Vector2,
		direction: Vector2, bonus: bool) -> void:
	var center: Vector2 = enemy.pos
	var color: Color = CHOICES[kind][2] if kind >= 0 else PEACH
	var fused := kind >= BASE_BALLS
	var heavy := bonus or fused
	var freeze := kind in [1, 4, 5, 8]
	enemy.recoil = direction * (13 if heavy else 7)
	emit_fx("hit", contact, color, 0.22, 46 if heavy else 29, -direction)
	# Each step of the chain raises the hit a semitone, capped at an octave.
	play_impact(4, pow(2.0, mini(12, floori(combo_hits / 3.0)) / 12.0))
	if heavy:
		sound.play_cue("thump", 1.15)
	if bonus and kind < 0 and power >= 20:
		kick_impact(1.6)
	if freeze:
		enemy.slow = 2.6
		if fused or enemy.flash <= 0:
			emit_fx("frost", center, SKY, 0.31, 48 if fused else 32)
			sound.play_cue("ice")
	damage_enemy(enemy, power, GOLD if bonus else color, heavy)
	if not battle_live():
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
	if not battle_live():
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
			if count == 0 or not battle_live():
				break

func damage_enemy(enemy: Dictionary, power: int, color: Color = CREAM, heavy: bool = false) -> void:
	if not battle_live() or enemy.hp <= 0 or victory_time > 0:
		return
	enemy.hp -= power
	enemy.flash = 0.11
	hit_label(enemy, power, color, heavy)
	combo_hits += 1
	combo_time = CHAIN_WINDOW
	combo_pop = 1.0
	best_combo = maxi(combo_hits, best_combo)
	if combo_hits % SURGE_HITS == 0:
		surge_ready = true
		emit_fx("surge", enemy.pos, GOLD, 0.32, 54)
	if enemy.hp > 0:
		return
	enemies.erase(enemy)
	kills += 1
	emit_fx("break", enemy.pos, enemy_tint(enemy.kind), 0.54 if enemy.kind >= 3 else 0.36,
		120 if enemy.kind == 3 else 64 if enemy.kind == 4 else 44)
	emit_fx("hit", enemy.pos, CREAM, 0.16, 52, Vector2.UP)
	sound.play_cue("crush", 0.8 if enemy.kind >= 2 else 1.0)
	sound.play_cue("thump", 0.9 if enemy.kind >= 2 else 1.0)
	if enemy.kind == 3:
		if hp > 0:
			begin_victory(enemy.pos)
		return
	earned += [1, 1, 3, 0, 6][enemy.kind]
	if enemy.kind == 4:
		kick_impact(6)
		play_impact(5)
		freeze_frame(0.08, elapsed)
		buzz(35)
	else:
		kick_impact(1.4)
	drop_scrap(enemy.pos, [2, 2, 5, 0, 7][enemy.kind])

# Splits a reward into a few pieces that burst outward, then home in on the ship.
func drop_scrap(origin: Vector2, value: int) -> void:
	var pieces := mini(value, 3)
	for index in range(pieces):
		var share := floori(float(value) / pieces) + (1 if index < value % pieces else 0)
		var burst := Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(110, 210)
		pickups.append({"pos": origin, "vel": burst, "value": share, "age": 0.0})

# Boss down: clear the field, flash, slow time, then show the result.
func begin_victory(origin: Vector2) -> void:
	if mode == "level":
		close_upgrades()
	for other in enemies:
		emit_fx("break", other.pos, enemy_tint(other.kind), 0.5, 48)
	enemies.clear()
	hazards.clear()
	emit_fx("blast", origin, GOLD, 0.8, 180)
	emit_fx("surge", origin, CREAM, 0.6, 120)
	kick_impact(9.0)
	play_impact(5)
	screen_flash = 0.45
	victory_time = VICTORY_SLOWMO
	buzz(120)

func update_pickups(delta: float) -> void:
	scrap_chime_time = maxf(0, scrap_chime_time - delta)
	if scrap_chime_time <= 0:
		scrap_streak = 0
	for index in range(pickups.size() - 1, -1, -1):
		var item := pickups[index]
		item.age += delta
		if item.age < 0.22:
			# Burst outward first, braking hard.
			item.pos += item.vel * delta
			item.vel = item.vel.move_toward(Vector2.ZERO, 900 * delta)
		else:
			# Then the ship pulls every piece in, faster the longer it flies.
			var pull: float = 260.0 + 1500.0 * (item.age - 0.22)
			item.pos = item.pos.move_toward(pilot, pull * delta)
		item.pos = item.pos.clamp(ARENA.position, ARENA.end)
		if item.age > 0.22 and item.pos.distance_to(pilot) < 17:
			xp += item.value
			emit_fx("pickup", item.pos, MINT if item.value < 3 else GOLD, 0.24, 18, item.pos.direction_to(pilot))
			# Pickups in quick succession climb a major scale.
			var step: int = [0, 2, 4, 5, 7, 9, 11, 12][mini(scrap_streak, 7)]
			sound.play_cue("coin", pow(2.0, step / 12.0))
			scrap_streak += 1
			scrap_chime_time = SCRAP_CHIME_GAP
			pickups.remove_at(index)

func xp_needed() -> int:
	var tiers := level - 1
	# Roughly twice the old curve: a level every 10-15 s early, slower later.
	return 16 + level * 11 + tiers * tiers * 2

func bank_upgrade_points() -> void:
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		upgrade_points += 1
		if level == DASH_UNLOCK_LEVEL:
			charges = max_charges
			notice("解锁闪避 · 双击屏幕冲刺", SKY)

func open_level() -> void:
	if mode != "fight" or upgrade_points == 0:
		return
	if options.is_empty():
		prepare_upgrades()
	clear_drag()
	mode = "level"
	play_sound(2)

func close_upgrades() -> void:
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
	if upgrade_points == 0:
		close_upgrades()
	else:
		prepare_upgrades()
	play_sound(2)

func finish(won: bool) -> void:
	if mode not in ["fight", "pause", "level"]:
		return
	# Runs now have several times more kills than before, so scrap converts at 1/8.
	last_reward = floori(earned / 8.0) + (20 if won else 0) + floori(elapsed / 30.0)
	first_win_bonus = meta.record_run(kills, best_combo, won)
	if first_win_bonus:
		last_reward *= 2
	# Every run ends with a chest; a win gives the gold one.
	chest_tier = 2 if won else (1 if elapsed >= 60 else 0)
	chest_metal = [6, 12, 25][chest_tier] + rng.randi_range(0, 5)
	chest_salt = [0, rng.randi_range(0, 1), 2][chest_tier]
	chest_open_time = -1.0
	boss_left = -1.0
	for enemy in enemies:
		if enemy.kind == 3:
			boss_left = float(enemy.hp) / enemy.max_hp
	seconds_to_boss = maxf(0, BOSS_ARRIVAL - elapsed)
	last_salt_reward = 0
	metal += last_reward + chest_metal
	salt += chest_salt
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
	var page := settings_return if mode == "settings" else mode
	if page in MENU_PAGES:
		place_interface(menu_origin() + Vector2(0, menu_shift_top() if page == "dock" else 0.0))
		if page == "dock":
			draw_dock()
		else:
			draw_home()
		if mode == "perks":
			draw_perks()
		elif mode == "settings":
			draw_audio_settings()
		return
	var boss_hp := -1.0
	for enemy in enemies:
		if enemy.kind == 3:
			boss_hp = float(enemy.hp) / enemy.max_hp
	var world := battle_layout.world
	draw_set_transform_matrix(world)
	draw_arena(0.0 if reduced_fx else clock, sector)
	draw_course()
	if impact_shake > 0 and not reduced_fx:
		world.origin += world.basis_xform(Vector2(roundf(sin(clock * 73) * impact_shake),
			roundf(cos(clock * 58) * impact_shake * 0.48)))
	var sprite_scale := Vector2.ONE * world.x.x
	for item in pickups:
		var point: Vector2 = item.pos
		draw_at_world_point(point, world, sprite_scale)
		draw_rect(Rect2(point - Vector2(7, 7), Vector2(14, 14)), Color(MINT, 0.09))
		pixel_sprite("scrap", item.pos, 3)
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
			pixel_sprite("pilot" if pilot_type == 0 else "swift", effect.pos, 4, Color(SKY, 0.35 * image_fade))
			draw_set_transform_matrix(world)
		draw_combat_effect(effect)
	draw_at_world_point(pilot, world, sprite_scale)
	draw_pilot(pilot, pilot_type, movement, armor_time, clock, ship_fittings(true))
	draw_ball_orbit(world)
	draw_at_world_point(pilot, world, sprite_scale)
	if muzzle_time > 0:
		var muzzle := (pilot + shot_heading * (18 + (0.1 - muzzle_time) * 92)).snapped(Vector2(2, 2))
		var size := Vector2.ONE * (3 + muzzle_time * 55)
		draw_at_world_point(muzzle, world, sprite_scale)
		draw_rect(Rect2(muzzle - size / 2, size), Color(GOLD, muzzle_time / 0.105))
	draw_set_transform(Vector2.ZERO)
	draw_damage_labels(world)
	if screen_flash > 0:
		draw_rect(battle_layout.arena, Color(1, 1, 1, minf(0.85, screen_flash * 2)))
	mask_arena()
	draw_low_health()
	draw_battle_hud(boss_hp)
	draw_battle_controls()
	draw_notice()
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
	var pause := battle_layout.controls[BattleLayout.Action.PAUSE]
	# Level badge.
	var badge := Rect2(origin, Vector2(40, 40))
	tile_solid(badge, GOLD)
	words(str(level), badge.get_center() + Vector2(0, 8), 22, INK, true)
	# Hull bar with XP strip underneath.
	var coin_width := 92.0
	var bar := Rect2(origin + Vector2(48, 4), Vector2(pause.position.x - origin.x - 48 - coin_width - 14, 24))
	var health := float(maxi(0, hp)) / max_hp
	draw_rect(bar.grow(2), INK)
	draw_rect(bar, Color(CORAL, 0.25))
	draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * health), bar.size.y)), CORAL)
	draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * health), 5)), Color(1, 1, 1, 0.3))
	words("%d/%d" % [maxi(0, hp), max_hp], bar.get_center() + Vector2(0, 7), 17, CREAM, true)
	var experience := Rect2(bar.position + Vector2(0, bar.size.y + 5), Vector2(bar.size.x, 5))
	draw_rect(experience.grow(1), INK)
	draw_rect(Rect2(experience.position, Vector2(roundf(experience.size.x * float(xp) / xp_needed()), 5)), MINT)
	# Scrap collected this run.
	var coins := Rect2(Vector2(bar.end.x + 10, origin.y + 4), Vector2(coin_width, 30))
	tile_solid(coins, INK)
	pixel_sprite("scrap", coins.position + Vector2(17, 15), 2)
	words(str(earned), Vector2(coins.end.x - 10, coins.get_center().y + 7), 18, GOLD, false, true)
	# Pause.
	var pressed := control_is_pressed(BattleLayout.Action.PAUSE)
	var face := press_tile(pause, PANEL, STEEL, float(pressed))
	for offset in [-7, 3]:
		draw_rect(Rect2(face.get_center() + Vector2(offset, -9), Vector2(4, 18)), CREAM)
	draw_progress(boss_hp)
	draw_combo()
	draw_wave_banner()

# Run progress to the boss; turns into the boss health bar once it arrives.
func draw_progress(boss_hp: float) -> void:
	var rect := battle_layout.progress
	draw_rect(rect.grow(2), INK)
	if boss_hp >= 0:
		draw_rect(rect, Color(CORAL, 0.25))
		draw_rect(Rect2(rect.position, Vector2(roundf(rect.size.x * boss_hp), rect.size.y)), CORAL)
		words("首领 %d%%" % ceili(boss_hp * 100), rect.get_center() + Vector2(0, 6), 14, CREAM, true)
		return
	draw_rect(rect, PANEL)
	var reach := clampf(elapsed / BOSS_ARRIVAL, 0, 1)
	draw_rect(Rect2(rect.position, Vector2(roundf((rect.size.x - 12) * reach), rect.size.y)), GOLD)
	for entry in WAVES:
		var x := rect.position.x + (rect.size.x - 12) * float(entry[0]) / BOSS_ARRIVAL
		draw_rect(Rect2(x, rect.position.y, 2, rect.size.y), Color(INK, 0.6))
	var elite_x := rect.position.x + (rect.size.x - 12) * ELITE_ARRIVAL / BOSS_ARRIVAL
	draw_rect(Rect2(elite_x - 4, rect.position.y - 3, 8, rect.size.y + 6), LILAC if not elite_spawned else STEEL)
	var skull := Rect2(rect.end.x - 20, rect.position.y - 6, 24, 24)
	tile_solid(skull, CORAL)
	words("王", skull.get_center() + Vector2(0, 6), 15, CREAM, true)

func draw_combo() -> void:
	if combo_hits < 2 or combo_time <= 0:
		return
	var age := CHAIN_WINDOW - combo_time
	var opacity := clampf(1.0 - (age - 0.26) / 0.66, 0, 1)
	if opacity <= 0:
		return
	var accent := combo_emphasis > 0
	# Colour climbs every 10 hits so long chains look different at a glance.
	var tiers := [MINT, SKY, GOLD, PEACH, CORAL]
	var tier: Color = tiers[mini(floori(combo_hits / 10.0), tiers.size() - 1)]
	var color := Color(GOLD if accent else tier, opacity)
	var arena := battle_layout.arena
	var anchor := Vector2(arena.end.x - 14, arena.position.y + 46)
	var size := roundi((34.0 if accent else 30.0) * (1.0 + combo_pop * 0.3) + minf(10, combo_hits / 8.0))
	words("×%d" % combo_hits, anchor, size, color, false, true)
	words("连击", anchor + Vector2(0, 20), 14, Color(CREAM, opacity), false, true)

func draw_wave_banner() -> void:
	if wave_banner <= 0:
		return
	var arena := battle_layout.arena
	var boss := boss_spawned
	var total := 3.0 if boss else 2.0
	var age := total - wave_banner
	var pop := 1.0 + maxf(0, 0.35 - age) * 1.6
	if reduced_fx:
		pop = 1.0
	var opacity := clampf(wave_banner / 0.4, 0, 1)
	var text := "首领来袭！" if boss else "第 %d 波" % wave
	var color := CORAL if boss else GOLD
	words(text, Vector2(arena.get_center().x, arena.position.y + arena.size.y * 0.3), roundi(44 * pop),
		Color(color, opacity), true)

func control_is_pressed(control: int) -> bool:
	for pending in control_presses.values():
		if pending.control == control:
			return true
	return false

# Dash has no button: once unlocked, a small charge meter sits in the bottom-left corner.
func draw_battle_controls() -> void:
	var arena := battle_layout.arena
	if not dash_unlocked():
		var hint := "Lv%d 解锁闪避" % DASH_UNLOCK_LEVEL
		words(hint, Vector2(arena.position.x + 14, arena.end.y - 16), 14, Color(MIST, 0.7))
		return
	var ready := charges > 0 and dash_time <= 0
	var origin := Vector2(arena.position.x + 14, arena.end.y - 40)
	words("双击闪避", origin + Vector2(0, -6), 14, SKY if ready else MIST)
	for index in range(max_charges):
		var cell := Rect2(origin + Vector2(index * 22, 2), Vector2(16, 16))
		draw_rect(cell.grow(3), INK)
		if index < charges:
			draw_rect(cell, SKY)
			draw_rect(Rect2(cell.position, Vector2(cell.size.x, 3)), Color(1, 1, 1, 0.5))
		elif index == charges:
			draw_rect(cell, Color(STEEL, 0.6))
			draw_rect(Rect2(cell.position + Vector2(0, cell.size.y * (1 - recharge / 4.5)),
				Vector2(cell.size.x, cell.size.y * recharge / 4.5)), Color(SKY, 0.55))
		else:
			draw_rect(cell, Color(STEEL, 0.6))

func draw_notice() -> void:
	if notice_time <= 0:
		return
	var arena := battle_layout.arena
	var opacity := clampf(notice_time / 0.4, 0, 1)
	var center := Vector2(arena.get_center().x, arena.position.y + arena.size.y * 0.42)
	var width := art_font.get_string_size(notice_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 32
	interface_opacity = opacity
	tile_solid(Rect2(center - Vector2(width * 0.5, 22), Vector2(width, 40)), Color(INK, 0.92))
	words(notice_text, center + Vector2(0, 5), 19, notice_color, true)
	interface_opacity = 1.0

# Equipped ball types circle the ship instead of filling a bar at the bottom.
func draw_ball_orbit(world: Transform2D) -> void:
	var equipped: Array[int] = []
	for kind in range(modules.size()):
		if modules[kind] > 0:
			equipped.append(kind)
	if equipped.is_empty():
		return
	draw_set_transform_matrix(world)
	for index in range(equipped.size()):
		var angle := clock * 2.2 + TAU * index / equipped.size()
		var point := (pilot + Vector2.from_angle(angle) * Vector2(34, 26)).snapped(Vector2(2, 2))
		var color: Color = CHOICES[equipped[index]][2]
		draw_rect(Rect2(point - Vector2(6, 6), Vector2(12, 12)), INK)
		draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), color)
		draw_rect(Rect2(point - Vector2(2, 3), Vector2(3, 3)), Color(1, 1, 1, 0.7))

func draw_low_health() -> void:
	var share := float(hp) / max_hp
	if share > 0.35 or hp <= 0:
		return
	var pulse := 0.25 + 0.2 * (0.5 + 0.5 * sin(clock * (6 + (0.35 - share) * 20)))
	var arena := battle_layout.arena
	for band in range(4):
		var depth := 6.0 + band * 6
		var color := Color(CORAL, pulse * (1.0 - band * 0.22))
		draw_rect(Rect2(arena.position, Vector2(arena.size.x, depth)), color)
		draw_rect(Rect2(arena.position.x, arena.end.y - depth, arena.size.x, depth), color)
		draw_rect(Rect2(arena.position, Vector2(depth, arena.size.y)), color)
		draw_rect(Rect2(arena.end.x - depth, arena.position.y, depth, arena.size.y), color)

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

func draw_course() -> void:
	for lane in range(7):
		var x := 90 + lane * 50
		for row in range(ceili(ARENA.size.y / 56.0)):
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
	return Rect2(battle_layout.dialog_origin + Vector2(22 + index * 148, 318), Vector2(140, 236))

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
	draw_tabs(0)

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

func choice_is_fusion(index: int) -> bool:
	return index >= BASE_BALLS and index < modules.size() and modules[index] == 0

func draw_choices() -> void:
	shade(0.5)
	var offset := battle_layout.dialog_origin
	place_interface(offset)
	var bounce := 0.0 if reduced_fx else sin(clock * 6) * 3
	words("升级！", Vector2(240, 262 + bounce), 46, GOLD, true)
	var hint := "点一张卡立即生效"
	if upgrade_points > 1:
		hint += "  ·  还有 %d 次" % upgrade_points
	words(hint, Vector2(240, 296), 16, CREAM, true)
	for i in range(options.size()):
		var index := options[i]
		var choice: Array = CHOICES[index]
		var accent: Color = choice[2]
		var fusion := choice_is_fusion(index)
		var rect := choice_rect(i)
		rect.position -= offset
		var face_color := LILAC if fusion else (PANEL.lerp(accent, 0.28) if index < modules.size() else PANEL)
		rect = press_tile(rect, face_color, accent)
		if fusion:
			words("融合", rect.position + Vector2(rect.size.x * 0.5, 24), 15, INK, true)
		pixel_sprite("scrap", rect.position + Vector2(rect.size.x * 0.5, 74), 6, accent if not fusion else CREAM)
		words(choice[0], rect.position + Vector2(rect.size.x * 0.5, 138), 25, CREAM, true)
		if index < modules.size() and not fusion:
			draw_level_stars(rect.position + Vector2(rect.size.x * 0.5 - 13, 156), modules[index] + 1, 3, 5.5, 13)
		draw_wrapped(choice[1], rect.position + Vector2(12, 188), rect.size.x - 24, 15,
			INK if fusion else CREAM)

# Character-wise wrap for short Chinese descriptions inside cards.
func draw_wrapped(text: String, origin: Vector2, width: float, size: int, color: Color) -> void:
	var line := ""
	var y := origin.y
	for character in text:
		var attempt := line + character
		if line != "" and art_font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			words(line, Vector2(origin.x + width * 0.5, y), size, color, true)
			line = character
			y += size + 5
		else:
			line = attempt
	if line != "":
		words(line, Vector2(origin.x + width * 0.5, y), size, color, true)

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

func captain_level() -> int:
	return 1 + floori(sqrt(sorties * 1.5))

func offline_rate() -> int:
	return 6 + 3 * buildings[3]

func draw_home() -> void:
	var sea_area := Rect2(layout_canvas.position - menu_origin(), layout_canvas.size)
	draw_sea(sea_area, 0.0 if reduced_fx else clock * 0.5, sector)
	# The pier starts a little lower on tall screens and its planks run down to the tab bar.
	var low := menu_shift_bottom()
	var pier := roundf(low * 0.35)
	for plank in range(ceili((TAB_TOP + low - 686 - pier) / 18.0)):
		var y := 686 + pier + plank * 18
		draw_rect(Rect2(-240, y, 960, 18), Color("#8a5a2b") if plank % 2 == 0 else Color("#7a4e24"))
		for x in range(-240, 720, 64):
			draw_rect(Rect2(x + (plank % 2) * 32, y, 3, 18), Color("#5e3a19"))
	draw_rect(Rect2(-240, 680 + pier, 960, 6), INK)
	var bob := 0.0 if reduced_fx else sin(clock * 1.8) * 6
	var hull := Vector2(240, 375 + bob)
	for ring in range(3):
		var spread := fmod(clock * 22 + ring * 26, 78)
		draw_polyline(pixel_ring(hull + Vector2(0, 52), 44 + spread, 16), Color(SEA_FOAM, 0.45 * (1 - spread / 78)), 3)
	draw_ship(hull, pilot_type, 9, ship_fittings(false))
	var ship := press_tile(Rect2(145, 432, 190, 48), PANEL, SKY, press_amount(HOME_SHIP))
	caption("巡潮艇  ▸" if pilot_type == 0 else "疾燕  ▸", ship.get_center() + Vector2(0, 8), 21)
	# Top bar: captain level, resources, settings, pinned to the top edge.
	place_interface(menu_origin() + Vector2(0, menu_shift_top()))
	var avatar := Rect2(12, 14, 44, 44)
	tile_solid(avatar, GOLD)
	words(str(captain_level()), avatar.get_center() + Vector2(0, 9), 24, INK, true)
	draw_pill(Rect2(66, 18, 160, 36), "iron", metal, GOLD)
	draw_pill(Rect2(236, 18, 160, 36), "salt", salt, SKY)
	var settings_face := press_tile(HOME_SETTINGS, PANEL, STEEL)
	pixel_sprite("gear", settings_face.get_center(), 3, CREAM)
	# Daily first win.
	var card := Rect2(12, 76, 176, 56)
	tile(card, PANEL, STEEL)
	words("每日首胜", card.position + Vector2(12, 24), 17, CREAM)
	var pending := meta.first_win_available()
	words("奖励 ×2" if pending else "今日已完成", card.position + Vector2(12, 46), 15, GOLD if pending else MINT)
	if meta.offline_pending > 0:
		var claim := press_tile(HOME_OFFLINE, GOLD, GOLD)
		pixel_sprite("iron", claim.position + Vector2(24, 22), 2)
		words("离线收益 +%d" % meta.offline_pending, claim.position + Vector2(46, 29), 17, INK)
	var perks := press_tile(HOME_PERKS, CREAM, CREAM)
	words("福利", perks.get_center() + Vector2(0, 7), 18, INK, true)
	if meta.has_rewards():
		red_dot(perks.position + Vector2(perks.size.x - 2, 2))
	place_interface(menu_origin())
	# Sea selector.
	var stage := press_tile(HOME_STAGE, Color(INK, 0.9), GOLD)
	var label := "第 %d 海域 · %s  ▸" % [sector + 1, SEA_NAMES[sector]]
	if clock < chart_notice_time:
		label = "通关盐雾海沟后解锁"
	words(label, stage.get_center() + Vector2(0, 7), 18, GOLD, true)
	var launch := press_tile(LAUNCH, CORAL, CORAL)
	caption("出  航", launch.get_center() + Vector2(0, 15), 42)
	draw_tabs(2)
	if ship_slide > 0:
		draw_ship_drawer()

func draw_pill(rect: Rect2, sprite: String, count: int, color: Color) -> void:
	tile_solid(rect, Color(INK, 0.85))
	pixel_sprite(sprite, rect.position + Vector2(20, rect.size.y * 0.5), 2)
	words(str(count), Vector2(rect.end.x - 12, rect.get_center().y + 8), 20, color, false, true)

func red_dot(center: Vector2) -> void:
	center = center.round()
	draw_rect(Rect2(center - Vector2(6, 3), Vector2(12, 6)), CORAL)
	draw_rect(Rect2(center - Vector2(3, 6), Vector2(6, 12)), CORAL)

func draw_tabs(active: int) -> void:
	place_interface(menu_origin() + Vector2(0, menu_shift_bottom()))
	draw_rect(Rect2(-240, TAB_TOP, 960, 420), INK)
	draw_rect(Rect2(-240, TAB_TOP, 960, 3), STEEL)
	var icons := ["building0", "pilot", "arrow", "scrap", "gear"]
	for index in range(TAB_NAMES.size()):
		var on := index == active
		var cell := Rect2(4 + index * 96, TAB_TOP + 5, 88, 53)
		var face := press_tile(cell, STEEL if on else PANEL, GOLD if on else STEEL)
		var center := Vector2(face.get_center().x, face.position.y + 16)
		pixel_sprite(icons[index], center, 3 if on else 2, Color.WHITE if on else Color(MIST, 0.8))
		words(TAB_NAMES[index], center + Vector2(0, 26), 15, GOLD if on else MIST, true)
		if index == 3 and meta.has_rewards():
			red_dot(center + Vector2(18, -12))
	place_interface(menu_origin())

# point is relative to menu_origin().
func tab_at(point: Vector2) -> int:
	point.y -= menu_shift_bottom()
	if point.y < TAB_TOP or point.y > TAB_TOP + 64:
		return -1
	return clampi(floori(point.x / 96.0), 0, TAB_NAMES.size() - 1)

func activate_tab(index: int) -> void:
	ship_drawer = false
	match index:
		0:
			enter_dock(dock_port)
			return
		1:
			mode = "home"
			ship_drawer = true
		2:
			mode = "home"
		3:
			open_perks()
			return
		4:
			open_settings()
			return
	play_sound(1)

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
	var tab := tab_at(point)
	var high := point - Vector2(0, menu_shift_top())
	if tab >= 0:
		activate_tab(tab)
	elif LAUNCH.grow(8).has_point(point):
		start_run()
	elif HOME_SETTINGS.has_point(high):
		open_settings()
	elif HOME_PERKS.has_point(high):
		open_perks()
	elif HOME_OFFLINE.has_point(high) and meta.offline_pending > 0:
		metal += meta.collect_offline()
		save_dock()
		sound.play_cue("coin")
	elif HOME_STAGE.has_point(point):
		if wins > 0:
			sector = 1 - sector
			save_dock()
			play_sound(1)
		else:
			chart_notice_time = clock + 2.5
	elif HOME_SHIP.has_point(point):
		ship_drawer = true
		play_sound(1)

func open_perks() -> void:
	meta.roll_day()
	mode = "perks"
	play_sound(1)

func task_claim_rect(index: int) -> Rect2:
	return Rect2(318, 452 + index * 86, 108, 50)

func draw_perks() -> void:
	shade(0.72)
	place_interface(menu_origin())
	tile(Rect2(24, 150, 432, 630), PANEL, STEEL)
	words("每日福利", Vector2(240, 205), 34, CREAM, true)
	words("七日签到", Vector2(46, 250), 19, GOLD)
	var claimed := meta.next_sign_index() if meta.can_sign() else meta.sign_streak
	for d in range(MetaProgress.SIGN_REWARDS.size()):
		var box := Rect2(44 + d * 57, 262, 50, 58)
		var today_box := meta.can_sign() and d == meta.next_sign_index()
		var done := d < claimed
		tile_solid(box, GOLD if today_box else (Color(MINT, 0.85) if done else INK))
		var ink := INK if today_box or done else MIST
		words("%d天" % (d + 1), box.position + Vector2(25, 19), 13, ink, true)
		var reward: Array = MetaProgress.SIGN_REWARDS[d]
		words("%d" % reward[0], box.position + Vector2(25, 39), 15, ink, true)
		if reward[1] > 0:
			words("+%d盐" % reward[1], box.position + Vector2(25, 54), 11, ink, true)
	if meta.can_sign():
		button(PERKS_SIGN, "签到领取", GOLD)
	else:
		var face := press_tile(PERKS_SIGN, INK, STEEL, 0.0)
		words("今日已签到", face.get_center() + Vector2(0, 7), 19, MIST, true)
	words("每日任务", Vector2(46, 425), 19, GOLD)
	for i in range(MetaProgress.TASKS.size()):
		var task: Array = MetaProgress.TASKS[i]
		var row := Rect2(44, 440 + i * 86, 392, 74)
		tile(row, INK, STEEL)
		words(task[0], row.position + Vector2(14, 28), 18, CREAM)
		var goal := int(task[2])
		var progress := mini(meta.task_progress[i], goal)
		var track := Rect2(row.position + Vector2(14, 44), Vector2(160, 10))
		draw_rect(track.grow(2), Color(PANEL, interface_opacity))
		draw_rect(Rect2(track.position, Vector2(roundf(track.size.x * progress / goal), track.size.y)), MINT)
		words("%d/%d" % [progress, goal], Vector2(track.end.x + 10, track.end.y + 2), 14, MIST)
		var claim := task_claim_rect(i)
		if meta.task_claimed[i]:
			words("已领取", claim.get_center() + Vector2(0, 7), 17, MINT, true)
		elif meta.task_done(i):
			button(claim, "领 +%d" % task[3], GOLD)
		else:
			var face := press_tile(claim, PANEL, STEEL, 0.0)
			words("+%d" % task[3], face.get_center() + Vector2(0, 7), 17, MIST, true)
	var close := press_tile(PERKS_CLOSE, PANEL, STEEL)
	words("返回", close.get_center() + Vector2(0, 8), 22, CREAM, true)

func press_perks(point: Vector2) -> void:
	if PERKS_SIGN.has_point(point) and meta.can_sign():
		var reward := meta.sign()
		metal += int(reward[0])
		salt += int(reward[1])
		save_dock()
		sound.play_cue("coin")
		return
	for i in range(MetaProgress.TASKS.size()):
		if task_claim_rect(i).has_point(point):
			var gain := meta.claim_task(i)
			if gain > 0:
				metal += gain
				save_dock()
				sound.play_cue("coin")
			return
	if PERKS_CLOSE.has_point(point) or tab_at(point) >= 0:
		mode = "home"
		play_sound(1)

func chest_progress() -> float:
	if chest_open_time < 0:
		return 0.0
	return clampf((result_time - chest_open_time) / 0.35, 0, 1)

func press_results(point: Vector2) -> void:
	if result_time < RESULT_REVEAL_END:
		return
	if chest_open_time < 0:
		chest_open_time = result_time
		sound.play_cue("blast")
		sound.play_cue("coin", 1.5)
		buzz(30)
		return
	if result_time - chest_open_time < 0.4:
		return
	var local := point - battle_layout.dialog_origin
	if RESULT_AGAIN.has_point(local):
		start_run()
	elif RESULT_DONE.has_point(local):
		mode = "home"
		play_sound(1)

func draw_results() -> void:
	shade(0.83 * smoothstep(0.0, 0.40, result_time))
	var reveal := smoothstep(RESULT_REVEAL_START, RESULT_REVEAL_END, result_time)
	if reveal <= 0:
		return
	var rise := 0.0 if reduced_fx else 12 * (1.0 - reveal)
	place_interface(battle_layout.dialog_origin + Vector2(0, rise))
	interface_opacity = reveal
	var won := mode == "win"
	tile(Rect2(24, 140, 432, 600), PANEL, STEEL)
	words("海域已守住！" if won else "船体失守", Vector2(240, 205), 40, GOLD if won else CREAM, true)
	var note := "首领已击破"
	if not won:
		note = "首领只剩 %d%% 血量！" % ceili(boss_left * 100) if boss_left >= 0 \
			else "再坚持 %d 秒就能见到首领" % ceili(seconds_to_boss)
	words(note, Vector2(240, 240), 18, MINT if won else CORAL, true)
	if first_win_bonus:
		var badge := Rect2(140, 254, 200, 30)
		tile_solid(badge, GOLD)
		words("今日首胜 · 奖励 ×2", badge.get_center() + Vector2(0, 6), 15, INK, true)
	var opened := chest_progress()
	draw_chest(Vector2(240, 380), chest_tier, opened)
	if opened <= 0:
		button(OPEN_CHEST, "开启宝箱", GOLD)
	else:
		interface_opacity = reveal * opened
		draw_dock_resource(Rect2(47, 462, 184, 56), "iron", "铁料", last_reward + chest_metal, GOLD)
		draw_dock_resource(Rect2(249, 462, 184, 56), "salt", "晶盐", chest_salt, SKY)
		words("击破 %d" % kills, Vector2(138, 556), 18, CREAM, true)
		words("最高连击 %d" % best_combo, Vector2(340, 556), 18, MINT, true)
		button(RESULT_AGAIN, "再来一局", CORAL)
		var home := press_tile(RESULT_DONE, PANEL, STEEL)
		words("返回主页", home.get_center() + Vector2(0, 7), 20, CREAM, true)
	interface_opacity = 1.0

func draw_chest(center: Vector2, tier: int, opened: float) -> void:
	var body_color: Color = [Color("#b0703a"), Color("#c9d2ea"), GOLD][tier]
	var trim: Color = [Color("#6d3f1d"), STEEL, PEACH][tier]
	if opened <= 0 and not reduced_fx and fmod(clock, 1.2) < 0.3:
		center.x += roundf(sin(clock * 60) * 3)
	if opened > 0:
		for ray in range(12):
			var direction := Vector2.from_angle(TAU * ray / 12 + clock * 0.6)
			draw_line(center + Vector2(0, -20), center + Vector2(0, -20) + direction * 92 * opened,
				Color(1.0, 0.93, 0.55, 0.55 * interface_opacity), 14)
		for coin in range(8):
			var arc := Vector2.from_angle(-PI * (0.15 + 0.7 * coin / 7.0))
			var point := center + Vector2(0, -30) + arc * 110 * opened + Vector2(0, 60 * opened * opened)
			pixel_sprite("scrap", point, 3)
	var body := Rect2(center + Vector2(-64, -8), Vector2(128, 74))
	draw_rect(body.grow(4), Color(INK, interface_opacity))
	draw_rect(body, Color(body_color, interface_opacity))
	for x in [-42, 32]:
		draw_rect(Rect2(center + Vector2(x, -8), Vector2(10, 74)), Color(trim, interface_opacity))
	var lift := Vector2(0, -36 * opened)
	var lid := Rect2(center + Vector2(-68, -46) + lift, Vector2(136, 40))
	draw_rect(lid.grow(4), Color(INK, interface_opacity))
	draw_rect(lid, Color(body_color.lightened(0.15), interface_opacity))
	draw_rect(Rect2(lid.position + Vector2(0, lid.size.y - 8), Vector2(lid.size.x, 8)), Color(trim, interface_opacity))
	if opened <= 0:
		var lock := Rect2(center + Vector2(-10, -14), Vector2(20, 22))
		draw_rect(lock.grow(3), Color(INK, interface_opacity))
		draw_rect(lock, Color(GOLD if tier < 2 else CORAL, interface_opacity))
