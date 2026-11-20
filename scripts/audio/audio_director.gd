extends Node

enum Scene { PORT, SEARCH, COMBAT, BOSS }

const SCORE = [
	preload("res://assets/audio/music/harbor.ogg"),
	preload("res://assets/audio/music/search.ogg"),
	preload("res://assets/audio/music/voyage.ogg"),
	preload("res://assets/audio/music/boss.ogg"),
]

# Peak levels and minimum spacing between repeated cues.
const CUES = {
	"hit": [preload("res://assets/audio/sfx/hit.wav"), -17.0, 0.092],
	"rail": [preload("res://assets/audio/sfx/rail.wav"), -25.0, 0.18],
	"ice": [preload("res://assets/audio/sfx/ice.wav"), -19.0, 0.24],
	"arc": [preload("res://assets/audio/sfx/arc.wav"), -18.0, 0.27],
	"blast": [preload("res://assets/audio/sfx/blast.wav"), -13.0, 0.32],
	"surge": [preload("res://assets/audio/sfx/surge.wav"), -12.0, 0.34],
	"ui": [preload("res://assets/audio/sfx/ui.wav"), -18.0, 0.09],
	"motion": [preload("res://assets/audio/sfx/motion.wav"), -17.0, 0.15],
	"hurt": [preload("res://assets/audio/sfx/hurt.wav"), -16.0, 0.24],
	"alert": [preload("res://assets/audio/sfx/alert.wav"), -11.0, 0.33],
	"departure": [preload("res://assets/audio/sfx/departure.wav"), -16.0, 0.85],
	"contact": [preload("res://assets/audio/sfx/contact.wav"), -14.0, 2.0],
	"thump": [preload("res://assets/audio/sfx/thump.wav"), -12.0, 0.06],
	"coin": [preload("res://assets/audio/sfx/coin.wav"), -21.0, 0.035],
}
# Cues that may overlap themselves, up to this many voices at once.
const POLYPHONIC := {"hit": 3, "thump": 3, "coin": 3}
# Cues that get a small random pitch and level change on every play.
const VARIED := ["hit", "thump", "coin", "rail", "ice", "arc", "blast", "hurt"]

var music_level := 0.7
var effects_level := 0.8
var music_players: Array[AudioStreamPlayer] = []
var score_gain := [0.0, 0.0, 0.0, 0.0]
var voices: Dictionary = {}
var last_played: Dictionary = {}
var priority_time := -2.0
var accent_time := -2.0
var duck_until := -2.0
var clock := 0.0
var duck_gain := 1.0
var music_focus := 1.0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for stream in SCORE:
		var player := AudioStreamPlayer.new()
		var loop := stream.duplicate() as AudioStreamOggVorbis
		loop.loop = true
		player.stream = loop
		player.volume_db = -80
		add_child(player)
		music_players.append(player)
		player.play()
	for name in CUES:
		var voice := AudioStreamPlayer.new()
		voice.stream = CUES[name][0]
		voice.max_polyphony = POLYPHONIC.get(name, 1)
		add_child(voice)
		voices[name] = voice

func mix(delta: float, scene: Scene, quiet: bool) -> void:
	clock += delta
	var target_duck := 0.69 if clock < duck_until else 1.0
	duck_gain = lerpf(duck_gain, target_duck, 1 - exp(-delta * (17 if target_duck < duck_gain else 4)))
	music_focus = lerpf(music_focus, 0.56 if quiet else 1.0, 1 - exp(-delta * 8))
	var target := [
		0.65 if scene == Scene.PORT else 0.0,
		0.74 if scene == Scene.SEARCH else 0.0,
		0.61 if scene == Scene.COMBAT or scene == Scene.BOSS else 0.0,
		0.34 if scene == Scene.BOSS else 0.0,
	]
	for index in range(score_gain.size()):
		var fade_rate := 3.3 if target[index] > score_gain[index] and scene >= Scene.COMBAT else 2.4
		score_gain[index] = lerpf(score_gain[index], target[index], 1 - exp(-delta * fade_rate))
		if index >= music_players.size():
			continue
		var level: float = score_gain[index] * music_level * duck_gain * music_focus
		music_players[index].volume_db = linear_to_db(maxf(level, 0.0001))

func play_cue(name: String, pitch: float = 1.0) -> void:
	if effects_level <= 0:
		return
	var cue: Array = CUES[name]
	var voice: AudioStreamPlayer = voices.get(name)
	if voice == null or clock - float(last_played.get(name, -2.0)) < cue[2]:
		return
	if voice.playing and not POLYPHONIC.has(name):
		return
	if name in ["hit", "rail", "ice", "arc"] and clock - priority_time < 0.15:
		return
	if name in ["rail", "ice", "arc"]:
		if clock - accent_time < 0.13:
			return
		accent_time = clock
	if name in ["surge", "blast", "alert"]:
		if clock - priority_time < 0.19 and name != "alert":
			return
		priority_time = clock
		duck_until = clock + 0.28
	last_played[name] = clock
	var level_offset := 0.0
	if name in VARIED:
		pitch *= randf_range(0.92, 1.08)
		level_offset = randf_range(-2.0, 2.0)
	voice.pitch_scale = pitch
	voice.volume_db = cue[1] + level_offset + linear_to_db(effects_level)
	voice.play()
