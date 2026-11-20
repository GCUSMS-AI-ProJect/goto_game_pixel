extends RefCounted

enum Action { AIM, RECALL, DASH, PAUSE, UPGRADE }

const DESIGN_SIZE := Vector2(480, 854)
const HUD_HEIGHT := 114.0
const SKILL_HEIGHT := 68.0
const BALL_HEIGHT := 48.0
const GAP := 9.0

var safe: Rect2
var hud: Rect2
var arena: Rect2
var ball_bar: Rect2
var controls: Array[Rect2] = []
var world: Transform2D
var inverse_world: Transform2D
var dialog_origin: Vector2
var upgrade_badge: Vector2

func _init(canvas: Rect2, safe_area: Rect2, world_arena: Rect2, gesture_margin := 0.0) -> void:
	var available := canvas.intersection(safe_area)
	var width := floorf(minf(available.size.x - 36, DESIGN_SIZE.x - 36))
	var left := floorf(available.get_center().x - width * 0.5)
	var top := ceilf(available.position.y) + 8
	var bottom := floorf(available.end.y) - 13
	safe = Rect2(left, top, width, bottom - top)
	hud = Rect2(left, top, width, HUD_HEIGHT)
	ball_bar = Rect2(left, bottom - BALL_HEIGHT, width, BALL_HEIGHT)
	var skills_top := ball_bar.position.y - GAP - SKILL_HEIGHT
	var control_left := maxf(left, canvas.position.x + gesture_margin)
	var control_right := minf(safe.end.x, canvas.end.x - gesture_margin)
	var skill_width := floorf((control_right - control_left - 2 * GAP) / 3.0)
	for index in range(3):
		var x := control_left + index * (skill_width + GAP)
		var size_x := control_right - x if index == 2 else skill_width
		controls.append(Rect2(x, skills_top, size_x, SKILL_HEIGHT))
	controls.append(Rect2(control_right - 58, top, 58, 58))
	controls.append(Rect2(control_right - 118, top + 64, 118, 43))
	upgrade_badge = controls[Action.UPGRADE].position + Vector2(0, 3)
	var arena_top := hud.end.y + GAP
	arena = Rect2(left + 2, arena_top, width - 4, skills_top - GAP - arena_top)
	var scale := arena.size / world_arena.size
	world = Transform2D(0, scale, 0, arena.position - world_arena.position * scale)
	inverse_world = world.affine_inverse()
	dialog_origin = (safe.get_center() - DESIGN_SIZE * 0.5).round()

func control_at(point: Vector2) -> int:
	for index in range(controls.size()):
		if control_contains(index, point):
			return index
	return -1

func control_contains(index: int, point: Vector2) -> bool:
	var rect := controls[index]
	if index == Action.UPGRADE:
		return rect.grow_individual(2, 6, 0, 7).has_point(point) or upgrade_badge.distance_squared_to(point) <= 13 * 13
	return rect.has_point(point)

func ball_slot(index: int) -> Rect2:
	var width := floorf(ball_bar.size.x / 4.0)
	var x := ball_bar.position.x + index * width
	return Rect2(x, ball_bar.position.y, ball_bar.end.x - x if index == 3 else width, BALL_HEIGHT)
