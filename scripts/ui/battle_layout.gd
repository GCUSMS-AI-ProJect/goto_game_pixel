extends RefCounted

# AIM, RECALL and UPGRADE are automatic now; their rects stay empty so old indices keep working.
enum Action { AIM, RECALL, DASH, PAUSE, UPGRADE }

const DESIGN_SIZE := Vector2(480, 854)
const HUD_HEIGHT := 66.0
const HUD_ROW := 40.0
const PAUSE_SIZE := 40.0
const DASH_SIZE := 84.0
const GAP := 8.0

var safe: Rect2
var hud: Rect2
var progress: Rect2
var arena: Rect2
var controls: Array[Rect2] = []
var world: Transform2D
var inverse_world: Transform2D
var dialog_origin: Vector2

func _init(canvas: Rect2, safe_area: Rect2, world_arena: Rect2, gesture_margin := 0.0) -> void:
	var available := canvas.intersection(safe_area)
	var width := floorf(minf(available.size.x - 24, DESIGN_SIZE.x - 24))
	var left := floorf(available.get_center().x - width * 0.5)
	var top := ceilf(available.position.y) + 8
	var bottom := floorf(available.end.y) - 10
	safe = Rect2(left, top, width, bottom - top)
	hud = Rect2(left, top, width, HUD_HEIGHT)
	progress = Rect2(left, top + HUD_ROW + 10, width, 12)
	# One uniform scale keeps sprites square; the arena is centred in what is left.
	var room := Rect2(left, hud.end.y + GAP, width, bottom - hud.end.y - GAP)
	var scale := minf(room.size.x / world_arena.size.x, room.size.y / world_arena.size.y)
	var size := (world_arena.size * scale).floor()
	arena = Rect2((room.get_center().x - size.x * 0.5), room.position.y, size.x, size.y)
	world = Transform2D(0, Vector2(scale, scale), 0, arena.position - world_arena.position * scale)
	inverse_world = world.affine_inverse()
	var right := minf(safe.end.x, canvas.end.x - gesture_margin)
	controls.assign([Rect2(), Rect2(),
		Rect2(right - DASH_SIZE - 14, arena.end.y - DASH_SIZE - 18, DASH_SIZE, DASH_SIZE),
		Rect2(right - PAUSE_SIZE, top, PAUSE_SIZE, PAUSE_SIZE),
		Rect2()])
	dialog_origin = (safe.get_center() - DESIGN_SIZE * 0.5).round()

func control_at(point: Vector2) -> int:
	for index in range(controls.size()):
		if control_contains(index, point):
			return index
	return -1

func control_contains(index: int, point: Vector2) -> bool:
	var rect := controls[index]
	if not rect.has_area():
		return false
	if index == Action.DASH:
		# Round button with a forgiving touch radius.
		return rect.get_center().distance_to(point) <= rect.size.x * 0.62
	return rect.grow(6).has_point(point)
