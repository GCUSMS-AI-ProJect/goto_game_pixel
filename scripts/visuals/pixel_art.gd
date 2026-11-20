extends Node2D

const ARENA := Rect2(23, 132, 434, 588)
const INK := Color("#0b1320")
const PANEL := Color("#172638")
const STEEL := Color("#344c62")
const CREAM := Color("#fff0cd")
const MIST := Color("#a4bbc4")
const MINT := Color("#79eac1")
const GOLD := Color("#ffe081")
const PEACH := Color("#ffb47d")
const CORAL := Color("#ff7775")
const LILAC := Color("#bb9bf2")
const SKY := Color("#83cefc")
const ART_FONT := preload("res://assets/fonts/outpost_sans.ttf")
const UI_GLYPHS := preload("res://assets/fonts/outpost_sans_ui.ttf")
var art_font := FontVariation.new()
var interface_opacity := 1.0
var interface_origin := Vector2.ZERO
var interface_press := Vector2.INF
var interface_pressure := 0.0
var interface_box := StyleBoxFlat.new()
var button_box := StyleBoxFlat.new()
const WATER := preload("res://assets/backgrounds/battle_sea.png")
const HARBOR := preload("res://assets/backgrounds/harbor.png")
const SPRITES := {
	"pilot": preload("res://assets/sprites/ships/tide_patrol.png"),
	"swift": preload("res://assets/sprites/ships/swift.png"),
	"enemy0": preload("res://assets/sprites/enemies/enemy_01.png"),
	"enemy1": preload("res://assets/sprites/enemies/enemy_02.png"),
	"enemy2": preload("res://assets/sprites/enemies/enemy_03.png"),
	"enemy3": preload("res://assets/sprites/enemies/chain_ray.png"),
	"wreck": preload("res://assets/sprites/enemies/wreck_guardian.png"),
	"enemy4": preload("res://assets/sprites/enemies/enemy_04.png"),
	"scrap": preload("res://assets/sprites/resources/scrap.png"),
	"iron": preload("res://assets/sprites/resources/iron.png"),
	"salt": preload("res://assets/sprites/resources/crystal_salt.png"),
	"building0": preload("res://assets/sprites/ports/dockyard.png"),
	"building1": preload("res://assets/sprites/ports/alloy_furnace.png"),
	"building2": preload("res://assets/sprites/ports/propulsion_station.png"),
	"building3": preload("res://assets/sprites/ports/tide_net.png"),
	"beacon": preload("res://assets/sprites/ports/lighthouse.png"),
	"gear": preload("res://assets/sprites/ui/settings.png"),
	"crosshair": preload("res://assets/sprites/ui/crosshair.png"),
	"arrow": preload("res://assets/sprites/ui/arrow_up.png"),
	"recall": preload("res://assets/sprites/ui/recall.png"),
	"dash": preload("res://assets/sprites/ui/dash.png"),
	"cannons": preload("res://assets/sprites/ship_parts/cannons.png"),
	"armor": preload("res://assets/sprites/ship_parts/armor.png"),
	"thrusters": preload("res://assets/sprites/ship_parts/thrusters.png"),
}

func setup_art() -> void:
	art_font.base_font = ART_FONT
	art_font.fallbacks = [UI_GLYPHS]
	interface_box.set_corner_radius_all(2)
	interface_box.set_border_width_all(1)
	interface_box.shadow_size = 2
	interface_box.shadow_offset = Vector2(0, 3)
	interface_box.anti_aliasing = false
	button_box.set_corner_radius_all(8)
	button_box.shadow_size = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func pixel_sprite(name: String, position: Vector2, scale_factor: int, tint := Color.WHITE,
		stretch := Vector2.ONE) -> void:
	var texture: Texture2D = SPRITES[name]
	var size := (texture.get_size() * scale_factor * stretch).snapped(Vector2(2, 2))
	draw_texture_rect(texture, Rect2((position - size * 0.5).snapped(Vector2(2, 2)), size), false,
		Color(tint, tint.a * interface_opacity))

func words(value: String, position: Vector2, size: int, color := CREAM, centered := false) -> void:
	if centered:
		position.x -= art_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string(art_font, position.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, color.a * interface_opacity))

func tile(rect: Rect2, fill: Color, border: Color) -> void:
	interface_box.bg_color = Color(fill, fill.a * interface_opacity)
	interface_box.border_color = Color(border, border.a * interface_opacity)
	interface_box.shadow_color = Color(0.01, 0.02, 0.05, 0.52 * interface_opacity)
	draw_style_box(interface_box, rect)

func press_amount(rect: Rect2) -> float:
	return interface_pressure if rect.has_point(interface_press - interface_origin) else 0.0

func press_tile(rect: Rect2, fill: Color, accent: Color, amount := -1.0) -> Rect2:
	var pressure := press_amount(rect) if amount < 0 else amount
	rect.position.y += 2 * pressure
	var face := fill.lerp(accent, 0.12).lightened(0.065 * pressure)
	button_box.bg_color = Color(face, fill.a * interface_opacity)
	button_box.shadow_offset = Vector2(0, 2 * (1.0 - pressure))
	button_box.shadow_color = Color(0.01, 0.02, 0.05, (0.25 - 0.10 * pressure) * interface_opacity)
	draw_style_box(button_box, rect)
	return rect

func button(rect: Rect2, title: String, color: Color) -> void:
	var face := press_tile(rect, color, color)
	words(title, face.get_center() + Vector2(0, 7), 22, INK, true)

func place_interface(origin: Vector2) -> void:
	interface_origin = origin
	draw_set_transform(origin)

func shade(opacity := 0.83) -> void:
	draw_set_transform(Vector2.ZERO)
	draw_rect(get_viewport_rect(), Color(INK, opacity))

func draw_harbor(time: float) -> void:
	draw_texture_rect(HARBOR, Rect2(0, 0, 480, 189), false)
	draw_rect(Rect2(0, 145, 480, 44), Color(INK, 0.41))
	draw_rect(Rect2(0, 184, 480, 3), STEEL)
	for i in range(4):
		var x := fmod(90.0 + 125 * i + time * (5 + i), 480)
		draw_rect(Rect2(floorf(x / 3) * 3, 159 + i * 4, 12, 2), Color(MIST, 0.30))

func draw_arena(time: float, region: int) -> void:
	draw_texture_rect(WATER, ARENA, false, Color("#d6bceb") if region == 1 else Color("#c6efe8"))
	for i in range(12):
		var x := 30 + i * 35
		var y := 136 + int(fmod(time * (6 + i % 4) + 125 * i, 570))
		draw_rect(Rect2(x, y, 3 + i % 3 * 3, 3), Color(SKY, 0.14))
	draw_rect(ARENA.grow(2), STEEL, false, 2)
	var rail_color := LILAC if region == 1 else MINT
	for x in [24, 451]:
		draw_rect(Rect2(x, 136, 5, 579), Color(INK, 0.82))
		for y in range(147, 710, 26):
			draw_rect(Rect2(x, y, 5, 9), Color(rail_color, 0.19))
			draw_rect(Rect2(x, y, 5, 2), Color(rail_color, 0.36))
	draw_rect(Rect2(23, 445, 434, 275), Color(MINT, 0.025))
	for x in range(30, 455, 22):
		draw_rect(Rect2(x, 445, 10, 2), Color(MINT, 0.23))
		draw_rect(Rect2(x, 711, 11, 3), Color(CORAL, 0.56))

func enemy_tint(kind: int) -> Color:
	match kind:
		0: return PEACH
		1: return SKY
		2: return MINT
		_: return CORAL

func draw_enemy(enemy: Dictionary, sector: int, time: float) -> void:
	var kind: int = enemy.kind
	var size: int = [3, 3, 4, 5, 4][kind]
	var wave := sin(time * (8 if kind < 3 else 5) + float(enemy.phase))
	var pos: Vector2 = enemy.pos + enemy.recoil + Vector2(0, wave * 1.55)
	var tint := Color("#83cefc") if enemy.slow > 0 else Color.WHITE
	var stretch := Vector2(1 + wave * 0.045, 1 - wave * 0.055)
	if enemy.flash > 0:
		var impact := clampf(float(enemy.flash) / 0.11, 0, 1)
		tint = tint.lerp(PEACH, impact * 0.6)
		tint = tint.lightened(impact * 0.18)
		stretch *= Vector2(1 + impact * 0.13, 1 - impact * 0.15)
	draw_rect(Rect2(pos + Vector2(-14, size * 4 - 2), Vector2(28, 5)), Color(INK, 0.73))
	var sprite := "wreck" if kind == 3 and sector == 1 else "enemy%d" % kind
	if enemy.slow > 0:
		draw_rect(Rect2(pos - Vector2(17, 15) * size / 3.0, Vector2(34, 30) * size / 3.0), Color(SKY, 0.17))
	pixel_sprite(sprite, pos, size, tint, stretch)
	if kind != 3 and enemy.hp < enemy.max_hp:
		var bar_width := 38 if kind == 4 else 28
		gauge(Rect2(pos.x - bar_width / 2.0, pos.y - size * 5 - 5, bar_width, 3),
			float(enemy.hp) / enemy.max_hp, enemy_tint(kind))

func draw_orb(position: Vector2, velocity: Vector2, color: Color, hazard := false) -> void:
	var normal := velocity.normalized()
	for i in range(1, 4):
		var trail := (position - normal * (6 + i * 5)).snapped(Vector2(2, 2))
		draw_rect(Rect2(trail - Vector2(2, 2), Vector2(4, 4)), Color(color, 0.48 / i))
	position = position.snapped(Vector2(2, 2))
	draw_rect(Rect2(position.x - 5, position.y - 3, 10, 6), color)
	draw_rect(Rect2(position.x - 3, position.y - 5, 6, 10), color)
	draw_rect(Rect2(position.x - 2, position.y - 2, 4, 4), CREAM if not hazard else PEACH)

func draw_ship(position: Vector2, type: int, scale_factor: int, fittings: Vector3i, locked := false) -> void:
	var refits := clampi(fittings.x, 0, 3)
	var hull_colors := [Color.WHITE, SKY, MINT, GOLD] if type == 0 else [Color.WHITE, LILAC, PEACH, GOLD]
	var tint: Color = hull_colors[refits] if not locked else MIST.darkened(0.25)
	pixel_sprite("pilot" if type == 0 else "swift", position, scale_factor, tint)
	if fittings.y > 0:
		pixel_sprite("armor", position + Vector2(0, 3 * scale_factor), scale_factor, tint)
	if fittings.z & 1:
		pixel_sprite("cannons", position - Vector2(0, 3 * scale_factor), scale_factor)
	if fittings.z & 2:
		pixel_sprite("thrusters", position + Vector2(0, 5 * scale_factor), scale_factor)

func draw_pilot(position: Vector2, type: int, moving: Vector2, armor: float, time: float, fittings := Vector3i.ZERO) -> void:
	if armor > 0 and int(time * 18) % 2 == 0:
		draw_rect(Rect2(position - Vector2(21, 19), Vector2(42, 38)), Color(MINT, 0.53), false, 2)
	var drift := Vector2(-moving.x * 3, 14)
	var engine := (position + drift).snapped(Vector2(2, 2))
	draw_rect(Rect2(engine.x - 3, engine.y, 6, 5 + int(time * 19) % 6), PEACH)
	draw_ship(position, type, 3, fittings)

func gauge(rect: Rect2, fraction: float, fill: Color) -> void:
	draw_rect(rect, INK)
	var width := roundf(rect.size.x * clampf(fraction, 0, 1))
	draw_rect(Rect2(rect.position, Vector2(width, rect.size.y)), fill)
