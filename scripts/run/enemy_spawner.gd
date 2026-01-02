extends Node
class_name EnemySpawner

const Log = preload("res://scripts/core/log.gd")

# Signal standard : "un ennemi est mort" (même si c'est simulé)
# base_gold/base_xp = récompense "brute" de l'ennemi
# source = d'où vient l'évènement (spawner_auto / manual_btn / etc.)
# enemy_id = identifiant debug pour suivre un ennemi
signal enemy_killed(base_gold: int, base_xp: int, source: String, enemy_id: String)

@export var spawn_every_sec: float = 1.0
@export var base_gold: int = 8
@export var base_xp: int = 4

@onready var spawn_timer: Timer = get_node_or_null("SpawnTimer") as Timer

var _spawn_count: int = 0

func _ready() -> void:
	Log.i("COMBAT", "EnemySpawner ready 👾")

	if spawn_timer == null:
		Log.e("COMBAT", "SpawnTimer manquant ❌", {"path": "EnemySpawner/SpawnTimer"})
		return

	# Setup timer
	spawn_timer.wait_time = spawn_every_sec
	spawn_timer.one_shot = false
	spawn_timer.autostart = false

	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	Log.ok("COMBAT", "SpawnTimer prêt ✅", {
		"wait": spawn_timer.wait_time,
		"one_shot": spawn_timer.one_shot,
		"base_gold": base_gold,
		"base_xp": base_xp
	})

func reset() -> void:
	_spawn_count = 0
	Log.d("COMBAT", "Spawner reset 🔄", {"spawn_count": _spawn_count})

func start() -> void:
	if spawn_timer == null:
		Log.e("COMBAT", "Spawner start failed ❌ (no timer)")
		return

	spawn_timer.wait_time = spawn_every_sec
	spawn_timer.start()
	Log.i("COMBAT", "Spawner START ▶️", {"every_sec": spawn_timer.wait_time})

func stop() -> void:
	if spawn_timer == null:
		return
	spawn_timer.stop()
	Log.i("COMBAT", "Spawner STOP ⏹️")

func simulate_manual_kill() -> void:
	_emit_kill("manual_btn")

func _on_spawn_timer_timeout() -> void:
	_emit_kill("spawner_auto")

func _emit_kill(source: String) -> void:
	_spawn_count += 1
	var enemy_id: String = "E" + str(_spawn_count).pad_zeros(3)

	# Log spawner (base reward)
	Log.d("COMBAT", "Spawn event 👾", {
		"enemy_id": enemy_id,
		"source": source,
		"base_gold": base_gold,
		"base_xp": base_xp
	})

	emit_signal("enemy_killed", base_gold, base_xp, source, enemy_id)
