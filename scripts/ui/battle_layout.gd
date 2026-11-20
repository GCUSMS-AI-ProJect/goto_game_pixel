extends RefCounted

# AIM, RECALL, DASH and UPGRADE have no on-screen button (dash is a double tap now);
# their rects stay empty so old indices keep working.
enum Action { AIM, RECALL, DASH, PAUSE, UPGRADE }

const DESIGN_SIZE := Vector2(480, 854)
const HUD_HEIGHT := 62.0
const HUD_ROW := 40.0
const PAUSE_SIZE := 40.0
const GAP := 4.0
# The sea is never shorter or taller than this in world units, whatever the phone.
const MIN_WORLD_HEIGHT := 640.0
const MAX_WORLD_HEIGHT := 1100.0

var safe: Rect2
var hud: Rect2
var progress: Rect2
var arena: Rect2
# Height of the play field in world units, chosen so the arena fills the screen.
var world_height: float
var controls: Array[Rect2] = []
var world: Transform2D
var inverse_world: Transform2D
var dialog_origin: Vector2

func _init(canvas: Rect2, safe_area: Rect2, world_arena: Rect2, gesture_margin := 0.0) -> void:
	var available := canvas.intersection(safe_area)
	var width := floorf(minf(available.size.x - 16, DESIGN_SIZE.x - 16))
	var left := floorf(available.get_center().x - width * 0.5)
	var top := ceilf(available.position.y) + 6
	var bottom := floorf(available.end.y)
	safe = Rect2(left, top, width, bottom - top)
	hud = Rect2(left, top, width, HUD_HEIGHT)
	progress = Rect2(left, top + HUD_ROW + 8, width, 10)
	# Edge to edge: the sea uses the whole width and runs to the bottom of the screen.
	var room := Rect2(available.position.x, hud.end.y + GAP, available.size.x, bottom - hud.end.y - GAP)
	var scale := room.size.x / world_arena.size.x
	world_height = clampf(floorf(room.size.y / scale), MIN_WORLD_HEIGHT, MAX_WORLD_HEIGHT)
	if world_height * scale > room.size.y:
		scale = room.size.y / world_height
	var size := Vector2(world_arena.size.x, world_height) * scale
	arena = Rect2((room.get_center().x - size.x * 0.5), room.position.y, size.x, size.y).abs()
	world = Transform2D(0, Vector2(scale, scale), 0, arena.position - world_arena.position * scale)
	inverse_world = world.affine_inverse()
	var right := minf(safe.end.x, canvas.end.x - gesture_margin)
	controls.assign([Rect2(), Rect2(), Rect2(),
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
	return rect.grow(6).has_point(point)
