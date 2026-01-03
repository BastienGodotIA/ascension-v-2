extends Area2D
class_name Enemy

const Log = preload("res://scripts/core/log.gd")

signal request_kill(base_gold: int, base_xp: int, source: String, enemy_id: String)

@export var debug_logs: bool = true

var enemy_id: String = ""
var base_gold: int = 0
var base_xp: int = 0
var source: String = "unknown"

var move_speed: float = 250.0
var kill_x: float = 220.0
var dir: float = 1.0 # 1 = vers la droite, -1 = vers la gauche

var _active: bool = false

func _ready() -> void:
	set_process(false)

# cfg attendu :
# {
#   "enemy_id": "E001",
#   "base_gold": 8,
#   "base_xp": 4,
#   "source": "spawner_auto",
#   "move_speed": 250.0,
#   "kill_x": 220.0,
#   "dir": 1.0,
#   "pos": Vector2(...)
# }
func activate(cfg: Dictionary = {}) -> void:
	enemy_id = str(cfg.get("enemy_id", enemy_id))
	base_gold = int(cfg.get("base_gold", base_gold))
	base_xp = int(cfg.get("base_xp", base_xp))
	source = str(cfg.get("source", source))

	move_speed = float(cfg.get("move_speed", move_speed))
	kill_x = float(cfg.get("kill_x", kill_x))
	dir = float(cfg.get("dir", dir))

	if cfg.has("pos") and cfg["pos"] is Vector2:
		global_position = cfg["pos"]

	_active = true
	set_process(true)

	if debug_logs:
		Log.d("ENEMY", "Activate", {
			"enemy_id": enemy_id,
			"move_speed": move_speed,
			"kill_x": kill_x,
			"dir": dir,
			"source": source,
			"pos": str(global_position)
		})

func _process(delta: float) -> void:
	if not _active:
		return

	global_position.x += (move_speed * dir) * delta

	# atteint la zone "kill"
	var reached: bool = (dir >= 0.0 and global_position.x >= kill_x) or (dir < 0.0 and global_position.x <= kill_x)
	if reached:
		if debug_logs:
			Log.d("ENEMY", "Reached kill_x ✅", {
				"enemy_id": enemy_id,
				"source": source,
				"pos": str(global_position)
			})

		_active = false
		set_process(false)

		emit_signal("request_kill", base_gold, base_xp, source, enemy_id)
		queue_free()
