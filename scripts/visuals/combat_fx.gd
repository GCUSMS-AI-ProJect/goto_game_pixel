extends "res://scripts/visuals/pixel_art.gd"

const MAX_EFFECTS := 72
const MAX_DAMAGE_LABELS := 22

var effects: Array[Dictionary] = []
var damage_labels: Array[Dictionary] = []
var impact_shake := 0.0
var muzzle_time := 0.0
var reduced_fx := false

func reset_fx() -> void:
	effects.clear()
	damage_labels.clear()
	impact_shake = 0
	muzzle_time = 0

func tick_fx(delta: float) -> void:
	impact_shake = move_toward(impact_shake, 0, delta * 18)
	muzzle_time = move_toward(muzzle_time, 0, delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += delta
		if effects[i].age >= effects[i].duration:
			effects.remove_at(i)
	for i in range(damage_labels.size() - 1, -1, -1):
		damage_labels[i].age += delta
		if damage_labels[i].age >= 0.51:
			damage_labels.remove_at(i)

func emit_fx(kind: String, point: Vector2, color: Color, duration: float,
		size: float = 1.0, direction: Vector2 = Vector2.UP) -> void:
	if effects.size() >= MAX_EFFECTS:
		effects.pop_front()
	effects.append({"kind": kind, "pos": point, "color": color, "age": 0.0,
		"duration": duration, "size": size, "dir": direction})

func hit_label(enemy: Dictionary, damage: int, color: Color, heavy: bool) -> void:
	for i in range(damage_labels.size() - 1, -1, -1):
		var label := damage_labels[i]
		if label.id == enemy.id and label.age < 0.11:
			label.damage += damage
			label.heavy = label.heavy or heavy
			if heavy:
				label.color = color
			return
	if damage_labels.size() >= MAX_DAMAGE_LABELS:
		damage_labels.pop_front()
	damage_labels.append({"id": enemy.id, "pos": enemy.pos, "damage": damage,
		"color": color, "age": 0.0, "heavy": heavy})

func draw_damage_labels(world: Transform2D) -> void:
	for label in damage_labels:
		var pos: Vector2 = label.pos + Vector2((int(label.id) % 3 - 1) * 10, -15 - label.age * 82)
		pos.y = maxf(158, pos.y)
		pos = world * pos
		var opacity := clampf((0.51 - float(label.age)) * 8, 0, 1)
		var size := 17 if label.heavy else 13
		words(str(label.damage), pos + Vector2(1, 2), size, Color(INK, opacity), true)
		words(str(label.damage), pos, size, Color(label.color, opacity), true)

func draw_combat_effect(effect: Dictionary) -> void:
	var origin: Vector2 = effect.pos
	var color: Color = effect.color
	var direction: Vector2 = effect.dir
	var progress: float = effect.age / effect.duration
	var size: float = effect.size
	var fade := 1.0 - progress
	match effect.kind:
		"hit", "wall":
			var ricochet: bool = effect.kind == "wall"
			var core := (10.0 if ricochet else 8.0) * fade
			if progress < 0.36:
				draw_flare(origin, direction, core * (1.1 if reduced_fx else 1.65), Color(color, fade * 0.83))
				draw_flare(origin, direction, core * 0.65, Color(CREAM, fade))
			if not reduced_fx and not ricochet and size > 40:
				var edge := pixel_ring(origin, 6 + 20 * sqrt(progress), 8)
				draw_polyline(edge, Color(color, 0.54 * fade), 2)
			draw_fragments(origin, color, direction, progress, size, 3 if reduced_fx else 8, false)
		"wake":
			var wake_scale := size * (0.18 + progress * 0.82)
			var wake_dir := direction.orthogonal()
			for side in [-1, 1]:
				var tip := origin + wake_dir * wake_scale * float(side)
				draw_line(tip.snapped(Vector2(2, 2)), (origin + direction * wake_scale * 0.8).snapped(Vector2(2, 2)),
					Color(SKY, fade * 0.68), 2)
			if not reduced_fx:
				draw_fragments(origin, Color("#9adceb"), direction, progress, size, 5, false)
		"pickup":
			for index in range(3 if reduced_fx else 6):
				var delta := Vector2.from_angle(index * 1.0472 + progress * 2)
				var point := origin + delta * (5 + 18 * fade) + direction * 8 * progress
				draw_flare(point, delta, 2 + fade * 4, Color(color, fade))
		"lightning":
			var steps := PackedVector2Array([origin])
			var normal := direction.orthogonal().normalized()
			for step in range(1, 6):
				var offset := sin(step * 2.8 + floorf(progress * 4) * 1.1) * (8 + step % 2 * 5)
				steps.append((origin + direction * (step / 6.0) + normal * offset).snapped(Vector2(2, 2)))
			steps.append(origin + direction)
			draw_polyline(steps, Color(color, fade * 0.29), 10)
			draw_polyline(steps, Color(color, fade * 0.9), 4)
			draw_polyline(steps, Color(CREAM, fade * 0.9), 2)
		"blast", "frost", "break", "surge", "recall":
			var reach := size * (0.24 + 0.76 * (1 - fade * fade))
			var ring_color := Color(color, fade * 0.87)
			var corners := 6 if effect.kind == "frost" else 12
			draw_polyline(pixel_ring(origin, reach, corners), ring_color, 2 if reduced_fx else 3)
			if effect.kind != "recall" and not reduced_fx:
				var fill := pixel_ring(origin, reach * 0.72, corners)
				fill.resize(corners)
				draw_colored_polygon(fill, Color(color, fade * 0.13))
				if progress < 0.38:
					draw_polyline(pixel_ring(origin, reach * 0.58, corners), Color(CREAM, fade * 0.8), 2)
			if effect.kind != "recall":
				draw_fragments(origin, color, direction, progress, size, 8 if reduced_fx else 16, true)
			if effect.kind in ["blast", "surge"] and progress < 0.23:
				draw_flare(origin, Vector2.UP, size * (0.16 + fade * 0.16), Color(CREAM, fade * 0.87))
		_:
			draw_fragments(origin, color, direction, progress, size, 4 if reduced_fx else 8, false)

func draw_flare(origin: Vector2, axis: Vector2, length: float, color: Color) -> void:
	if length < 1:
		return
	var point := origin.snapped(Vector2(2, 2))
	var along := axis.normalized()
	var across := along.orthogonal()
	if length < 6:
		draw_line(point - along * length, point + along * length, color, 2)
		draw_line(point - across * length * 0.45, point + across * length * 0.45, color, 2)
		return
	draw_colored_polygon(PackedVector2Array([
		(point + along * length).snapped(Vector2(2, 2)),
		(point + across * length * 0.42).snapped(Vector2(2, 2)),
		(point - along * length).snapped(Vector2(2, 2)),
		(point - across * length * 0.42).snapped(Vector2(2, 2)),
	]), color)

func draw_leader_warning(origin: Vector2, aim: Vector2, charge: float) -> void:
	var ring := pixel_ring(origin, 49 - charge * 10, 12)
	var count := mini(12, 3 + floori(charge * 10))
	for index in range(count):
		var a := ring[index]
		var b := ring[index + 1]
		draw_line(a.lerp(b, 0.14), a.lerp(b, 0.86), Color(CORAL, 0.5 + charge * 0.44), 2)
	var direction := origin.direction_to(aim)
	var tip := (origin + direction * 60).snapped(Vector2(2, 2))
	var edge := direction.orthogonal() * 7
	var tail := tip - direction * 8
	draw_polyline(PackedVector2Array([tail + edge, tip, tail - edge]), Color(PEACH, 0.42 + charge * 0.5), 2)

func pixel_ring(origin: Vector2, radius: float, corners: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(corners):
		var point := origin + Vector2.from_angle(TAU * i / corners) * radius
		points.append(point.snapped(Vector2(2, 2)))
	points.append(points[0])
	return points

func draw_fragments(origin: Vector2, color: Color, axis: Vector2, progress: float,
		spread: float, count: int, radial: bool) -> void:
	var angle := axis.angle()
	for i in range(count):
		var direction := Vector2.from_angle(angle + (TAU * i / count if radial else (i - (count - 1) * 0.5) * 0.23))
		var distance := (0.28 + 0.64 * sqrt(progress)) * spread * (0.62 + 0.18 * (i % 4))
		var point := (origin + direction * distance + Vector2.DOWN * progress * progress * 10).snapped(Vector2(2, 2))
		var width := (6.0 if i % 3 == 0 else 4.0) if progress < 0.64 else 2.0
		var tint := CREAM if i % 4 == 0 and progress < 0.45 else color
		draw_rect(Rect2(point, Vector2(width, width)), Color(tint, 1 - progress))
		if i % 3 == 0 and not reduced_fx:
			draw_line(point - direction * (4 + progress * 11), point, Color(color, (1 - progress) * 0.5), 2)

func draw_shot(ball: Dictionary, tint: Color, world: Transform2D) -> void:
	var pos: Vector2 = ball.pos
	var heading: Vector2 = ball.vel.normalized()
	var history: Array = ball.trail
	var returning: bool = ball.returning
	var radiant: bool = ball.charged or ball.banks > 0
	var radius := 5 if ball.kind >= 0 else 4
	if radiant:
		radius += 2
	if returning:
		radius = 3
	var previous := pos
	for i in range(history.size() - 1, -1, -1):
		var point: Vector2 = history[i]
		var weight := float(i + 1) / history.size()
		draw_line(point, previous, Color(tint, weight * (0.28 if returning else 0.62)), maxf(1, radius * weight * 1.12))
		previous = point
	pos = pos.snapped(Vector2(2, 2))
	var scale := Vector2.ONE * world.x.x
	draw_set_transform(world * pos - pos * scale, 0, scale)
	if radiant and not returning and not reduced_fx:
		draw_rect(Rect2(pos - Vector2.ONE * (radius + 4), Vector2.ONE * (2 * radius + 8)), Color(tint, 0.16))
	draw_rect(Rect2(pos - Vector2(radius, radius - 2), Vector2(2 * radius, 2 * radius - 4)), tint)
	draw_rect(Rect2(pos - Vector2(radius - 2, radius), Vector2(2 * radius - 4, 2 * radius)), tint)
	var core := pos + (heading * 2).snapped(Vector2(1, 1))
	draw_rect(Rect2(core - Vector2(2, 2), Vector2(4, 4)), CREAM if not returning else MIST)
	draw_set_transform_matrix(world)
