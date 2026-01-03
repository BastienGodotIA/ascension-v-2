extends Node
class_name EnemySpawner

const Log = preload("res://scripts/core/log.gd")

signal enemy_killed(base_gold: int, base_xp: int, source: String, enemy_id: String)

# --- Config loot / spawn
@export var spawn_every_sec: float = 1.0
@export var base_gold: int = 8
@export var base_xp: int = 4

# --- Mode visuel (v1.7)
@export var spawn_visuals: bool = false
@export var enemy_scene: PackedScene = preload("res://scenes/run/Enemy.tscn")
@export var enemies_container_path: NodePath = "../Enemies"

# --- Params visu
@export var spawn_x: float = 20.0
@export var spawn_y_min: float = 160.0
@export var spawn_y_max: float = 260.0
@export var move_speed: float = 250.0
@export var kill_x: float = 220.0

@onready var spawn_timer: Timer = get_node_or_null("SpawnTimer") as Timer
@onready var enemies_container: Node = get_node_or_null(enemies_container_path) as Node

var _spawn_count: int = 0
var _running: bool = false

func _ready() -> void:
	randomize()

	Log.i("COMBAT", "EnemySpawner ready 👾")

	Log.d("COMBAT", "Spawner nodes check", {
		"spawn_timer": spawn_timer != null,
		"enemies_container": enemies_container != null,
		"enemy_scene": enemy_scene != null,
		"spawn_visuals": spawn_visuals
	})

	if spawn_timer == null:
		Log.e("COMBAT", "SpawnTimer manquant ❌", {"expected": "EnemySpawner/SpawnTimer"})
		return

	spawn_timer.one_shot = false
	spawn_timer.autostart = false
	spawn_timer.wait_time = max(0.05, spawn_every_sec)

	if not spawn_timer.timeout.is_connected(_on_spawn_tick):
		spawn_timer.timeout.connect(_on_spawn_tick)

	Log.ok("COMBAT", "SpawnTimer prêt ✅", {
		"wait": spawn_timer.wait_time,
		"one_shot": spawn_timer.one_shot,
		"base_gold": base_gold,
		"base_xp": base_xp
	})

func reset() -> void:
	_spawn_count = 0
	_cleanup_enemies()
	Log.d("COMBAT", "Spawner reset 🔄", {"spawn_count": _spawn_count})

func start() -> void:
	if _running:
		Log.w("COMBAT", "Spawner START ignoré (déjà running) ⚠️")
		return

	if spawn_timer == null:
		Log.e("COMBAT", "Impossible start: SpawnTimer null ❌")
		return

	_running = true
	spawn_timer.wait_time = max(0.05, spawn_every_sec)
	spawn_timer.start()

	Log.i("COMBAT", "Spawner START ▶️", {
		"every_sec": spawn_timer.wait_time,
		"spawn_visuals": spawn_visuals
	})

func stop() -> void:
	if not _running:
		Log.d("COMBAT", "Spawner STOP ignoré (pas running)", {})
		return

	_running = false
	if spawn_timer != null:
		spawn_timer.stop()

	Log.i("COMBAT", "Spawner STOP ⏹️")

	# Important: éviter les “restes” visuels entre runs
	_cleanup_enemies()

func simulate_manual_kill(source := "btn_sim_kill") -> void:
	# Debug: on force un kill direct même en mode visuel
	Log.i("COMBAT", "Manual kill requested 💀", {"source": source})
	_spawn_count += 1
	var enemy_id := "E%03d" % _spawn_count
	_emit_kill(base_gold, base_xp, source, enemy_id)

func _on_spawn_tick() -> void:
	_spawn_count += 1
	var enemy_id := "E%03d" % _spawn_count

	Log.d("COMBAT", "Spawn event 👾", {
		"enemy_id": enemy_id,
		"source": "spawner_auto",
		"base_gold": base_gold,
		"base_xp": base_xp,
		"spawn_visuals": spawn_visuals
	})

	if not spawn_visuals:
		_emit_kill(base_gold, base_xp, "spawner_auto", enemy_id)
		return

	_spawn_visual_enemy(enemy_id, "spawner_auto")

func _spawn_visual_enemy(enemy_id: String, source: String) -> void:
	if enemy_scene == null:
		Log.e("COMBAT", "enemy_scene null ❌ -> fallback kill direct", {"enemy_id": enemy_id})
		_emit_kill(base_gold, base_xp, "fallback_no_scene", enemy_id)
		return

	if enemies_container == null:
		Log.e("COMBAT", "Enemies container null ❌", {"path": str(enemies_container_path)})
		_emit_kill(base_gold, base_xp, "fallback_no_container", enemy_id)
		return

	var inst = enemy_scene.instantiate()
	if inst == null:
		Log.e("COMBAT", "Instantiate enemy failed ❌", {"enemy_id": enemy_id})
		_emit_kill(base_gold, base_xp, "fallback_instantiate_failed", enemy_id)
		return

	enemies_container.add_child(inst)

	# Placement explicite (évite bas-gauche 0,0)
	var y := randf_range(spawn_y_min, spawn_y_max)
	if inst is Node2D:
		(inst as Node2D).position = Vector2(spawn_x, y)

	# Configure + connect
	if inst.has_method("init_from_spawner"):
		inst.call("init_from_spawner", enemy_id, move_speed, kill_x, source)

	if inst.has_signal("reached_kill_x"):
		if not inst.reached_kill_x.is_connected(_on_enemy_reached_kill):
			inst.reached_kill_x.connect(_on_enemy_reached_kill.bind(base_gold, base_xp, source))

	if inst.has_method("activate"):
		inst.call("activate")

	Log.d("COMBAT", "Enemy visual spawned ✅", {
		"enemy_id": enemy_id,
"pos": str((inst as Node2D).position) if (inst is Node2D) else "<not Node2D>",
		"move_speed": move_speed,
		"kill_x": kill_x
	})

func _on_enemy_reached_kill(enemy_id: String, p_gold: int, p_xp: int, source: String) -> void:
	Log.d("COMBAT", "Enemy reached kill_x -> emit kill", {
		"enemy_id": enemy_id,
		"gold": p_gold,
		"xp": p_xp,
		"source": source
	})
	_emit_kill(p_gold, p_xp, source, enemy_id)

func _emit_kill(p_gold: int, p_xp: int, source: String, enemy_id: String) -> void:
	enemy_killed.emit(p_gold, p_xp, source, enemy_id)

func _cleanup_enemies() -> void:
	if enemies_container == null:
		return
	var n := 0
	for c in enemies_container.get_children():
		n += 1
		c.queue_free()
	if n > 0:
		Log.d("COMBAT", "Cleanup enemies 🧹", {"count": n})
