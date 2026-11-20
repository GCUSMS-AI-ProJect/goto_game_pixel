extends "res://scripts/visuals/combat_fx.gd"

const CHART := Rect2(36, 177, 408, 416)
const PORT_MARK := Vector2(78, 453)
const SHOAL_MARK := Vector2(160, 367)
const WRECK_MARK := Vector2(341, 264)
const REGION_TARGETS := [Rect2(135, 343, 190, 57), Rect2(275, 232, 172, 80)]
const PORTS := [PORT_MARK, Vector2(364, 489)]
const PORT_NAMES := ["前哨港口", "灯塔港"]
const SEA_NAMES := ["盐雾海沟", "沉船暗流"]

const CHART_TEXTURE := preload("res://assets/backgrounds/nautical_chart.png")
var chart_pan := Vector2.ZERO

func draw_chart(selected: int, unlocked: bool) -> void:
	draw_rect(CHART, Color("#102c3d"))
	var shift := chart_pan.round()
	var world_view := Rect2(CHART.position - shift, CHART.size)
	var start := Vector2i((world_view.position / 24).floor())
	var finish := Vector2i((world_view.end / 24).ceil())
	for y in range(start.y, finish.y):
		for x in range(start.x, finish.x):
			var sea_hash := hash(Vector2i(x, y))
			if sea_hash % 3 == 0:
				var point := Vector2(x * 24 + sea_hash % 15, y * 24 + sea_hash % 11) + shift
				draw_rect(Rect2(point, Vector2(3 + sea_hash % 5, 2)), Color("#214657"))
	var old_origin := interface_origin
	place_interface(old_origin + shift)
	draw_texture_rect(CHART_TEXTURE, Rect2(24, 180, 432, 432), false)
	draw_route(PackedVector2Array([PORT_MARK, Vector2(117, 426), Vector2(127, 392), SHOAL_MARK,
		Vector2(240, 410), Vector2(303, 451), PORTS[1]]), MINT)
	draw_route(PackedVector2Array([SHOAL_MARK, Vector2(234, 357), Vector2(258, 319), Vector2(294, 299), WRECK_MARK]),
		GOLD if unlocked else Color(MIST, 0.52))
	for index in range(PORTS.size()):
		var position: Vector2 = PORTS[index]
		var tint := MINT if index == 0 else GOLD
		var port := press_tile(Rect2(position - Vector2(21, 21), Vector2(42, 42)), INK, tint,
			press_amount(Rect2(position - Vector2(26, 26), Vector2(52, 52))))
		pixel_sprite("building0" if index == 0 else "beacon", port.get_center(), 2)
		words(PORT_NAMES[index], position + Vector2(0, 40), 15, tint, true)
	draw_region_pin(0, SHOAL_MARK, selected == 0, true)
	draw_region_pin(1, WRECK_MARK, selected == 1, unlocked)
	place_interface(old_origin)
	# Keep world markers and the scrolling sea inside the chart window.
	draw_rect(Rect2(-220, -120, 920, CHART.position.y + 120), INK)
	draw_rect(Rect2(-220, CHART.end.y, 920, 420), INK)
	draw_rect(Rect2(-220, CHART.position.y, 220 + CHART.position.x, CHART.size.y), INK)
	draw_rect(Rect2(CHART.end.x, CHART.position.y, 240, CHART.size.y), INK)
	draw_rect(CHART, STEEL, false, 2)
	var compass := CHART.position + Vector2(24, 24)
	draw_polyline(pixel_ring(compass, 13, 8), MIST, 1)
	words("N", compass + Vector2(0, 5), 13, CREAM, true)

func draw_route(points: PackedVector2Array, color: Color) -> void:
	for i in range(1, points.size()):
		var segment := points[i - 1].distance_to(points[i])
		var marks := maxi(2, roundi(segment / 11))
		for j in range(marks):
			var position := points[i - 1].lerp(points[i], float(j) / marks).snapped(Vector2(2, 2))
			draw_rect(Rect2(position, Vector2(4, 3)), color)

func draw_region_pin(region: int, position: Vector2, selected: bool, unlocked: bool) -> void:
	var color := GOLD if selected else MIST
	if unlocked and not selected:
		color = MINT
	var pressure := press_amount(REGION_TARGETS[region])
	var fill := PANEL.lerp(GOLD, 0.14) if selected else INK
	var pin := press_tile(Rect2(position - Vector2(16, 16), Vector2(32, 32)), fill, color, pressure)
	position = pin.get_center()
	if unlocked:
		words(str(region + 1), position + Vector2(0, 6), 17, color, true)
	else:
		draw_arc(position - Vector2(0, 2), 5, PI, TAU, 8, MIST, 2)
		draw_rect(Rect2(position - Vector2(6, 1), Vector2(12, 9)), MIST)
	var label := Vector2(position.x + (24 if region == 0 else -48), position.y + (4 if region == 0 else 40))
	var width := 94 if region == 0 else 100
	press_tile(Rect2(label - Vector2(0, 20), Vector2(width, 29)), Color(fill, 0.90), color, 0.0)
	words(SEA_NAMES[region], label + Vector2(8, 0), 17, CREAM if unlocked else MIST)
