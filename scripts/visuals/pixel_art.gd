extends Node2D

# World-space play field. Width is fixed; the height follows the screen so tall phones get
# a taller sea instead of empty bands (set by the layout).
var ARENA := Rect2(23, 132, 434, 740)
# One texel of the interface.
const PX := 3.0
# Saturated arcade palette: enemies lean violet/pink, the player cyan, rewards gold, damage pink.
const INK := Color("#170b2e")
const PANEL := Color("#2b1f5c")
const STEEL := Color("#5a48a8")
const CREAM := Color("#fff8ea")
const MIST := Color("#c3b6e8")
const MINT := Color("#4dffb0")
const GOLD := Color("#ffd23f")
const PEACH := Color("#ff9a3d")
const CORAL := Color("#ff4f7a")
const LILAC := Color("#b45cff")
const SKY := Color("#3fe0ff")
const SEA_FOAM := Color("#7fd2ff")
const SEA_LOOP_SECONDS := 24.0
const OPEN_SEA := preload("res://assets/backgrounds/open_sea_tile.png")
const FOAM_TILE := preload("res://assets/backgrounds/sea_foam_tile.png")
const ART_FONT := preload("res://assets/fonts/outpost_sans.ttf")
const UI_GLYPHS := preload("res://assets/fonts/outpost_sans_ui.ttf")
var art_font := FontVariation.new()
var interface_opacity := 1.0
var interface_origin := Vector2.ZERO
var interface_press := Vector2.INF
var interface_pressure := 0.0
# Every sprite with a one-pixel ink outline baked in, built once at start-up.
var sprites := {}
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for name in SPRITES:
		sprites[name] = outlined(SPRITES[name])

func outlined(texture: Texture2D) -> Texture2D:
	var source := texture.get_image()
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	var size := source.get_size() + Vector2i(2, 2)
	var base := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	base.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i.ONE)
	var result := base.duplicate() as Image
	for y in range(size.y):
		for x in range(size.x):
			if base.get_pixel(x, y).a > 0.5:
				continue
			for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + step
				if n.x >= 0 and n.y >= 0 and n.x < size.x and n.y < size.y and base.get_pixelv(n).a > 0.5:
					result.set_pixel(x, y, INK)
					break
	return ImageTexture.create_from_image(result)

func pixel_sprite(name: String, position: Vector2, scale_factor: int, tint := Color.WHITE,
		stretch := Vector2.ONE) -> void:
	var texture: Texture2D = sprites.get(name, SPRITES[name])
	var size := (texture.get_size() * scale_factor * stretch).snapped(Vector2(2, 2))
	draw_texture_rect(texture, Rect2((position - size * 0.5).snapped(Vector2(2, 2)), size), false,
		Color(tint, tint.a * interface_opacity))

func words(value: String, position: Vector2, size: int, color := CREAM, centered := false, right := false) -> void:
	var width := art_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if centered:
		position.x -= width * 0.5
	elif right:
		position.x -= width
	var alpha := color.a * interface_opacity
	# Light text of headline size gets an ink outline so it reads on any background.
	if size >= 17 and color.get_luminance() > 0.35:
		draw_string_outline(art_font, position.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
			maxi(4, size / 5), Color(INK, alpha))
	draw_string(art_font, position.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, alpha))

# Raised edge for panels and readouts.
func bevel(rect: Rect2, fill: Color) -> void:
	var alpha := interface_opacity * fill.a
	var light := Color(fill.lightened(0.42), alpha)
	var dark := Color(fill.darkened(0.5), alpha)
	rect = Rect2(rect.position.round(), rect.size.round())
	draw_rect(rect.grow(PX), Color(INK, interface_opacity))
	draw_rect(rect, Color(fill, alpha))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, PX)), light)
	draw_rect(Rect2(rect.position, Vector2(PX, rect.size.y)), light)
	draw_rect(Rect2(rect.position.x, rect.end.y - PX * 2, rect.size.x, PX * 2), dark)
	draw_rect(Rect2(rect.end.x - PX, rect.position.y, PX, rect.size.y), dark)

# Small square block (badges, pills, counters).
func tile_solid(rect: Rect2, fill: Color) -> void:
	bevel(rect, fill)

# Panel behind dialogs and cards.
func tile(rect: Rect2, fill: Color, _border: Color) -> void:
	bevel(rect, fill)

func press_amount(rect: Rect2) -> float:
	return interface_pressure if rect.has_point(interface_press - interface_origin) else 0.0

func press_tile(rect: Rect2, fill: Color, accent: Color, amount := -1.0) -> Rect2:
	var pressure := press_amount(rect) if amount < 0 else amount
	var travel := roundf(PX * clampf(pressure, 0.0, 1.0))
	rect = Rect2(rect.position.round(), rect.size.round())
	var base := rect
	rect.position.y += travel
	var face := fill.lerp(accent, 0.22).lightened(0.11).darkened(0.10 * pressure)
	var alpha := interface_opacity * fill.a
	# One-texel corner steps and two solid bands give the button its shape and depth.
	var band_width := rect.size.x - PX * 2
	draw_rect(Rect2(base.position.x + PX, base.end.y, band_width, PX), Color(INK, 0.60 * alpha))
	draw_rect(Rect2(rect.position.x + PX, rect.position.y, band_width, PX), Color(face.lightened(0.26), alpha))
	draw_rect(Rect2(rect.position.x, rect.position.y + PX, rect.size.x, rect.size.y - PX * 3), Color(face, alpha))
	draw_rect(Rect2(rect.position.x + PX, rect.end.y - PX * 2, band_width, PX * 2), Color(face.darkened(0.28), alpha))
	return rect

func button(rect: Rect2, title: String, color: Color) -> void:
	var face := press_tile(rect, color, color)
	caption(title, face.get_center() + Vector2(0, 9), 26)

# Button caption: cream text with a hard one-texel drop shadow.
func caption(title: String, position: Vector2, size: int, color := CREAM) -> void:
	words(title, position + Vector2(PX, PX), size, Color(INK, 0.9), true)
	words(title, position, size, color, true)

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
	draw_sea(ARENA, time, region)
	draw_rect(ARENA.grow(2), STEEL, false, 2)
	var rail_color := LILAC if region == 1 else MINT
	for x in [24, 451]:
		draw_rect(Rect2(x, ARENA.position.y + 4, 5, ARENA.size.y - 9), Color(INK, 0.82))
		for y in range(int(ARENA.position.y) + 15, int(ARENA.end.y) - 10, 26):
			draw_rect(Rect2(x, y, 5, 9), Color(rail_color, 0.19))
			draw_rect(Rect2(x, y, 5, 2), Color(rail_color, 0.36))
	for x in range(30, 455, 22):
		draw_rect(Rect2(x, ARENA.end.y - 9, 11, 3), Color(CORAL, 0.56))

func draw_sea(area: Rect2, time: float, region := 0) -> void:
	var phase := fposmod(time, SEA_LOOP_SECONDS) / SEA_LOOP_SECONDS
	var sway := sin(phase * TAU)
	var swell := Vector2(9.0 * sway, phase * OPEN_SEA.get_height()).round()
	var foam := Vector2(-15.0 * sway, phase * FOAM_TILE.get_height() * 2.0).round()
	var water_tint := Color(2.25, 0.55, 1.12) if region == 1 else Color.WHITE
	var foam_tint := Color(1.0, 0.67, 1.0) if region == 1 else Color.WHITE
	draw_sea_layer(OPEN_SEA, area, swell, water_tint)
	draw_sea_layer(FOAM_TILE, area, foam, foam_tint)

func draw_sea_layer(texture: Texture2D, area: Rect2, offset: Vector2, tint: Color) -> void:
	var texture_size := texture.get_size()
	var tile_size := texture_size * PX
	var wrapped := Vector2(fposmod(offset.x, texture_size.x), fposmod(offset.y, texture_size.y))
	var first := area.position - tile_size + wrapped * PX
	var columns := ceili((area.end.x - first.x) / tile_size.x)
	var rows := ceili((area.end.y - first.y) / tile_size.y)
	for row in range(rows):
		for column in range(columns):
			var origin := first + Vector2(column, row) * tile_size
			var visible := Rect2(origin, tile_size).intersection(area)
			if visible.has_area():
				var source := Rect2((visible.position - origin) / PX, visible.size / PX)
				draw_texture_rect_region(texture, visible, source, tint)

func enemy_tint(kind: int) -> Color:
	match kind:
		0: return PEACH
		1: return SKY
		2: return MINT
		_: return CORAL

func draw_enemy(enemy: Dictionary, sector: int, time: float) -> void:
	var kind: int = enemy.kind
	var size: int = [4, 4, 5, 6, 5][kind]
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
	if enemy.flash > 0.04:
		# Modulate above 1 pushes every lit texel to white: a one-beat hit silhouette.
		pixel_sprite(sprite, pos, size, Color(6, 6, 6, 0.9), stretch)
	var skill: String = enemy.get("skill", "")
	var badge := pos + Vector2(-size * 5 - 4, -size * 5 + 2)
	if skill in ["heal", "both"]:
		# Healers wear a green cross and a slow pulsing aura.
		var pulse := 0.5 + 0.5 * sin(time * 4 + float(enemy.phase))
		draw_rect(Rect2(pos - Vector2(19, 19) * size / 3.0, Vector2(38, 38) * size / 3.0), Color(MINT, 0.10 + 0.08 * pulse))
		draw_rect(Rect2(badge - Vector2(6, 6), Vector2(12, 12)), INK)
		draw_rect(Rect2(badge - Vector2(4, 1.5), Vector2(8, 3)), MINT)
		draw_rect(Rect2(badge - Vector2(1.5, 4), Vector2(3, 8)), MINT)
		badge.x += 14
	if skill in ["dodge", "both"]:
		# Dodgers show a cyan double chevron; it greys out while the dodge recharges.
		var ready: bool = enemy.get("dodge_cd", 0.0) <= 0
		var tone := SKY if ready else STEEL
		draw_rect(Rect2(badge - Vector2(6, 6), Vector2(12, 12)), INK)
		for step in [-2, 2]:
			draw_rect(Rect2(badge + Vector2(step - 2, -3), Vector2(2, 2)), tone)
			draw_rect(Rect2(badge + Vector2(step, -1), Vector2(2, 2)), tone)
			draw_rect(Rect2(badge + Vector2(step - 2, 1), Vector2(2, 2)), tone)
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
		draw_rect(Rect2(position - Vector2(27, 25), Vector2(54, 50)), Color(MINT, 0.6), false, 3)
	var drift := Vector2(-moving.x * 4, 19)
	var engine := (position + drift).snapped(Vector2(2, 2))
	draw_rect(Rect2(engine.x - 5, engine.y, 10, 7 + int(time * 19) % 8), INK)
	draw_rect(Rect2(engine.x - 3, engine.y, 6, 5 + int(time * 19) % 8), GOLD)
	draw_ship(position, type, 4, fittings)

func gauge(rect: Rect2, fraction: float, fill: Color) -> void:
	draw_rect(rect, INK)
	var width := roundf(rect.size.x * clampf(fraction, 0, 1))
	draw_rect(Rect2(rect.position, Vector2(width, rect.size.y)), fill)
