extends RefCounted
# Daily loop between runs: 7-day sign-in, three daily tasks, the first win of the day,
# and harbour income that builds up while the game is closed. No drawing here.

# [iron, salt] for each day of the 7-day sign-in cycle.
const SIGN_REWARDS := [[10, 0], [15, 0], [20, 0], [25, 1], [30, 0], [40, 0], [50, 3]]
# [label, stat, goal, iron reward]
const TASKS := [
	["出航 3 次", "runs", 3, 15],
	["击破 150 个敌人", "kills", 150, 20],
	["单局连击达到 40", "combo", 40, 25],
]
const OFFLINE_CAP_HOURS := 8.0

var day := -1
var sign_streak := 0
var signed_day := -1
var task_progress: Array[int] = [0, 0, 0]
var task_claimed: Array[bool] = [false, false, false]
var first_win_day := -1
var last_seen := 0
var offline_pending := 0

# Local calendar day as an integer, so "yesterday" is simply today - 1.
static func today() -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return floori((Time.get_unix_time_from_system() + bias * 60) / 86400.0)

static func now() -> int:
	return int(Time.get_unix_time_from_system())

func load_from(config: ConfigFile) -> void:
	day = int(config.get_value("meta", "day", -1))
	sign_streak = clampi(int(config.get_value("meta", "sign_streak", 0)), 0, SIGN_REWARDS.size())
	signed_day = int(config.get_value("meta", "signed_day", -1))
	first_win_day = int(config.get_value("meta", "first_win_day", -1))
	last_seen = int(config.get_value("meta", "last_seen", 0))
	offline_pending = maxi(0, int(config.get_value("meta", "offline_pending", 0)))
	var progress: Array = config.get_value("meta", "task_progress", [0, 0, 0])
	var claimed: Array = config.get_value("meta", "task_claimed", [false, false, false])
	if progress.size() == TASKS.size() and claimed.size() == TASKS.size():
		for i in range(TASKS.size()):
			task_progress[i] = maxi(0, int(progress[i]))
			task_claimed[i] = bool(claimed[i])
	roll_day()

func save_to(config: ConfigFile) -> void:
	config.set_value("meta", "day", day)
	config.set_value("meta", "sign_streak", sign_streak)
	config.set_value("meta", "signed_day", signed_day)
	config.set_value("meta", "first_win_day", first_win_day)
	config.set_value("meta", "last_seen", last_seen)
	config.set_value("meta", "offline_pending", offline_pending)
	config.set_value("meta", "task_progress", task_progress)
	config.set_value("meta", "task_claimed", task_claimed)

# Daily tasks restart at local midnight.
func roll_day() -> void:
	var current := today()
	if day == current:
		return
	day = current
	task_progress.assign([0, 0, 0])
	task_claimed.assign([false, false, false])

func can_sign() -> bool:
	return signed_day != today()

# Index of the reward the next sign-in gives; a missed day restarts the cycle.
func next_sign_index() -> int:
	if signed_day != today() - 1 and signed_day != today():
		return 0
	return sign_streak % SIGN_REWARDS.size()

func sign() -> Array:
	if not can_sign():
		return []
	var index := next_sign_index()
	sign_streak = index + 1
	signed_day = today()
	return SIGN_REWARDS[index]

func first_win_available() -> bool:
	return first_win_day != today()

# Returns true when this was the first win of the day (rewards are doubled).
func record_run(kills: int, best_combo: int, won: bool) -> bool:
	roll_day()
	task_progress[0] += 1
	task_progress[1] += kills
	task_progress[2] = maxi(task_progress[2], best_combo)
	if won and first_win_available():
		first_win_day = today()
		return true
	return false

func task_done(index: int) -> bool:
	return task_progress[index] >= int(TASKS[index][2])

func claim_task(index: int) -> int:
	if not task_done(index) or task_claimed[index]:
		return 0
	task_claimed[index] = true
	return int(TASKS[index][3])

func has_rewards() -> bool:
	if can_sign():
		return true
	for i in range(TASKS.size()):
		if task_done(i) and not task_claimed[i]:
			return true
	return false

# Adds income for the time since last_seen, capped, and stamps the current time.
func accrue_offline(rate_per_hour: int) -> void:
	var stamp := now()
	if last_seen > 0 and stamp > last_seen:
		var hours := minf(OFFLINE_CAP_HOURS, (stamp - last_seen) / 3600.0)
		offline_pending = mini(offline_pending + floori(hours * rate_per_hour),
			roundi(OFFLINE_CAP_HOURS * rate_per_hour))
	last_seen = stamp

func collect_offline() -> int:
	var amount := offline_pending
	offline_pending = 0
	return amount
